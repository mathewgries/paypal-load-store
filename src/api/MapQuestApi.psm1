using module '..\libs\RequestHandler.psm1'

Function getCoordinates([PSCustomObject]$data) {
    [PSCustomObject]$params = @{
        Uri         = $data.Uri
        contentType = 'application/json'
    }

    return RequestHandler($params)
}
