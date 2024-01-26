class SMTP {
    # "mail.freedompay.com"
    [String]$SmtpServer = $null
    [String]$fromAddress = $null

    [String[]]$toAddress = $null
    [String[]]$ccAddress = $null
    [String[]]$bccAddress = $null

    [String]$subject = $null
    [String]$header = $null
    [String]$footer = $null
    [String]$body = ''

    [String[]]$attachment = $null

    SMTP() {}

    SMTP([int]$env) {
        $this.setSMTPServer($env)
    }

    SMTP([int]$env, [String]$toAddress) {
        $this.setSMTPServer($env)
        $this.toAddress = $toAddress
    }

    SMTP([int]$env, [String]$toAddress, [String]$ccAddress) {
        $this.setSMTPServer($env)
        $this.toAddress = $toAddress
        $this.ccAddress = $ccAddress
    }

    [void]setSMTPServer([int]$env) {
        switch ($env) {
            1 { $this.SmtpServer = "allentown.africa.local" }
            2 { $this.SmtpServer = "allentown.africa.local" }
            3 { $this.SmtpServer = "MAIL.FREEDOMPAY.COM" }
            4 { $this.SmtpServer = "MAIL.FREEDOMPAY.COM" }
            Default { $this.SmtpServer = "allentown.africa.local" }
        }
    }

    [String]getSMTPServer() {
        return $this.SmtpServer
    }

    [bool]testSMTPConnection() {
        $test = Test-NetConnection $this.SmtpServer -Port 25 -WarningAction SilentlyContinue
        return $test.TcpTestSucceeded
    }

    [void]setFromAddress([String]$from) {
        $this.fromAddress = $from
    }

    [void]setToAddress([String]$toAddress) {
        $this.toAddress += $toAddress
    }

    [void]setCCAddress([String]$ccAddress) {
        $this.ccAddress += $ccAddress
    }

    [void]setSubject([String]$sub) {
        $this.subject = $sub
    }

    [String]getSubject() {
        return $this.subject
    }

    [void]setHeader([String]$header) {
        $this.header = $header
    }

    [void]seFooter([String]$footer) {
        $this.footer = $footer
    }

    [void]updateBody([String]$txt) {
        $this.body += $txt
    }

    [String]getBody(){
        return $this.body
    }

    [void]setAttachment([String]$file) {
        $this.attachment += $file
    }

    [void]sendEmail() {
        Send-MailMessage `
            -From $this.fromAddress `
            -To $this.toAddress `
            -Cc $this.ccAddress `
            -Subject $this.subject `
            -Body $this.getEmailWrapper() `
            -SmtpServer $this.SmtpServer `
            -Port 25 `
            -BodyAsHtml

        # Write-Host $this.getEmailWrapper()
    }

    # Add CSS style formatting
    [String]getHTMLHead() {
        [String]$html = "<!DOCTYPE html><html><head><style>"
        $html += "body,h1,h2,h3,h4,p,ul,li,div {margin: 0;padding: 0;text-decoration: none; font-family: Cambria, Cochin, Georgia, Times, 'Times New Roman', serif;}"
        $html += "h3 {text-decoration: underline;}"
        $html += ".header {margin-bottom: 20px;}"
        $html += ".list-block {margin: 10px 20px;}"
        $html += ".list-item {margin: 10px 20px;}"
        $html += ".container {margin: 20px auto;width: 85%;}"
        $html += ".nested-list {margin-left: 20px;}"
        $html += ".email-body {margin-top: 50px;padding: 0 25px;}"
        $html += ".body-para {margin: 20px 0;}"
        $html += ".footer {margin-top: 50px;}"
        $html += "</style></head>"
        return $html
    }

    # Email Body
    [String]getEmailWrapper() {
        [String]$result = $this.getHTMLHead()
        $result += '<body><div class="container">'
        $result += '<div class="header">' + $this.header + '<hr></div>'
        $result += "<div>$($this.body)</div>"
        $result += '<div class="footer"><hr>' + $this.footer + '</div>'
        $result += "</div></body></html>"
        return $result
    }
}