:80 {
	root * /srv
	rewrite * /index.html
	header Cache-Control "no-store"
	file_server
}
