package main

import (
	"os"
	"time"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"flag"
	"crypto/md5"
	"path/filepath"
	"mime"
	"context"
	"strings"
	"net/url"
	"github.com/dreampuf/evernote-sdk-golang/client"
	"github.com/dreampuf/evernote-sdk-golang/edam"
)

var (
	EvernoteKey = os.Getenv("EVERNOTE_API_CLIENT_ID")
	EvernoteSecret = os.Getenv("EVERNOTE_API_CLIENT_SECRET")
)

func EvernoteEnv(isSandbox bool) client.EnvironmentType {
	if isSandbox {
		return client.SANDBOX
	}
	return client.PRODUCTION
}

func TokenFilePath () (string) {
	prog, err := os.Executable()
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}
	progDir := filepath.Dir(prog)
	return filepath.Join(progDir, ".access_token")
}

func CreateNewNote (noteTitle *string, resources [] *edam.Resource) (*edam.Note) {

	ourNote := edam.NewNote()
	ourNote.Title = noteTitle

	nBody := `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note>
`

	for _, resource := range resources {
		hashHex := fmt.Sprintf("%x", resource.Data.BodyHash)
		nBody = nBody + "    <en-media type=\"" + *resource.Mime + "\" hash=\"" + hashHex + "\"/>\n"
	}

	nBody = nBody + "</en-note>"

	ourNote.Content = &nBody
	ourNote.Resources = resources
	return ourNote
}

func NoteResource (filePath string) (*edam.Resource) {
	fileHandle, err := os.Open(filePath)
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}
	defer fileHandle.Close()

	hash := md5.New()
	fileStat, _ := fileHandle.Stat()

	fileName := filepath.Base(filePath)
	fileExt := filepath.Ext(fileName)
	fileType := mime.TypeByExtension(fileExt)
	if fileType == "" {
		fileType = "text/plain"
	}
	fileSize := int32(fileStat.Size())

	if _, err := io.Copy(hash, fileHandle); err != nil {
		log.Fatalf("error: %s", err.Error())
	}

	bodyBytes, err := ioutil.ReadFile(filePath)
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}

	ourData := edam.NewData()
	ourData.Size = &fileSize
	ourData.BodyHash = hash.Sum(nil)
	ourData.Body = bodyBytes
	
	ourResource := edam.NewResource()
	ourResource.Data = ourData
	ourResource.Mime = &fileType
	ourResource.Attributes = edam.NewResourceAttributes()
	ourResource.Attributes.FileName = &fileName

	return ourResource
}

func InitOauthToken(c *client.EvernoteClient, tokenFilePath string) {
	requestToken, loginUrl, err := c.GetRequestToken("http://localhost/")
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}
	log.Println(loginUrl)
	log.Println("Redirected URL?")
	var rUrl string
	fmt.Scan(&rUrl)
	u, err := url.Parse(rUrl)
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}
	q := u.Query()
	if requestToken.Token != q.Get("oauth_token") {
		log.Fatalln("error: Request token mismatch.")
	}
	oauthVerifier := q.Get("oauth_verifier")
	accessToken, err := c.GetAuthorizedToken(requestToken, oauthVerifier)
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}
	if err := ioutil.WriteFile(tokenFilePath, []byte(accessToken.Token), 0600); err != nil {
		log.Fatalf("error: %s", err.Error())
	}
}

func ReadOauthToken(tokenFilePath string) (string) {
	oauthToken, err := ioutil.ReadFile(tokenFilePath)
	if err != nil {
		log.Fatalf("error: %s", err.Error())
	}
	if len(oauthToken) == 0 {
		log.Fatalln("error: Invalid access token.")
	}
	return strings.TrimRight(string(oauthToken), "\n")
}

func main () {
	now := time.Now().Local()
	createdAt := now.Format("2006-01-02 15:04:05")
	noteTitle := flag.String("note-title", createdAt, "")
	isSandbox := flag.Bool("sandbox", false, "")
	isInit := flag.Bool("init", false, "")
	flag.Parse()

	c := client.NewClient(EvernoteKey, EvernoteSecret, EvernoteEnv(*isSandbox))
	tokenFilePath := TokenFilePath()
	
	if *isInit == true {
		InitOauthToken(c, tokenFilePath)
		os.Exit(0)
	}

	accessToken := ReadOauthToken(tokenFilePath)
	ctx, _ := context.WithTimeout(context.Background(), time.Duration(15) * time.Second)
	us, err := c.GetUserStore()
	if err != nil {
		log.Fatalf("GetUserStore error: %s", err.Error())
	}
	userUrls, err := us.GetUserUrls(ctx, accessToken)
	if err != nil {
		log.Fatalf("GetUserUrls error: %s", err.Error())
	}
	ns, err := c.GetNoteStoreWithURL(userUrls.GetNoteStoreUrl())
	if err != nil {
		log.Fatalf("GetNoteStoreWithURL error: %s", err.Error())
	}
	notebook, err := ns.GetDefaultNotebook(ctx, accessToken)
	if err != nil {
		log.Fatalf("GetDefaultNotebook error: %s", err.Error())
	}
	if notebook == nil {
		log.Fatalln("GetDefaultNotebook error: Invalid Note")
	}

	resources := [] *edam.Resource {}
	for _, argFile := range flag.Args() {
		filePath, _ := filepath.Abs(argFile)
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			log.Printf("warn: %s", err.Error())
			continue
		}
		resources = append(resources, NoteResource(filePath))
	}

	if len(resources) == 0 {
		log.Fatalln("error: No suitable files found. ")
	}

	newNote := CreateNewNote(noteTitle, resources)
	note, err := ns.CreateNote(ctx, accessToken, newNote)
	if err != nil {
		log.Fatalf("CreateNote error: %s", err.Error())
	}
	if note == nil {
		log.Fatalln("CreateNote error: Note is null.")
	}
	log.Println("All files Uploaded successfully.")
	os.Exit(0)
}
