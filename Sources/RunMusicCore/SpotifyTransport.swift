import Foundation

public struct SpotifyPlaylistExportRequest: Sendable, Equatable { public let userID:String; public let name:String; public let trackURIs:[String]; public init(userID:String,name:String,trackURIs:[String]){self.userID=userID;self.name=name;self.trackURIs=trackURIs} }
public struct SpotifyRequestBuilder: Sendable {
    public let baseURL:URL
    public init(baseURL:URL=URL(string:"https://api.spotify.com/v1")!){self.baseURL=baseURL}
    public func currentUser(accessToken:String)->HTTPRequest{HTTPRequest(url:baseURL.appendingPathComponent("me"),headers:["Authorization":"Bearer \(accessToken)"])}
    public func createPlaylist(userID:String,name:String,accessToken:String)throws->HTTPRequest{let body=try JSONSerialization.data(withJSONObject:["name":name,"public":false]);return HTTPRequest(method:.post,url:baseURL.appendingPathComponent("users/\(userID)/playlists"),headers:["Authorization":"Bearer \(accessToken)","Content-Type":"application/json"],body:body)}
    public func addTracks(playlistID:String,trackURIs:[String],accessToken:String)throws->[HTTPRequest]{try stride(from:0,to:trackURIs.count,by:100).map{start in let chunk=Array(trackURIs[start..<min(start+100,trackURIs.count)]);let body=try JSONSerialization.data(withJSONObject:["uris":chunk]);return HTTPRequest(method:.post,url:baseURL.appendingPathComponent("playlists/\(playlistID)/tracks"),headers:["Authorization":"Bearer \(accessToken)","Content-Type":"application/json"],body:body)}}
}
public struct SpotifyUserDTO: Codable, Sendable, Equatable { public let id:String }
public struct SpotifyPlaylistDTO: Codable, Sendable, Equatable { public let id:String; public let uri:String?; public let externalURLs:[String:URL]?; enum CodingKeys:String,CodingKey{case id,uri;case externalURLs="external_urls"} }
public struct SpotifyExportResult: Sendable, Equatable { public let playlistID:String; public let playlistURL:URL?; public let uploadedTrackCount:Int }
public struct SpotifyPlaylistClient: Sendable {
    private let transport:any HTTPTransport; private let requestBuilder:SpotifyRequestBuilder
    public init(transport:any HTTPTransport,requestBuilder:SpotifyRequestBuilder=SpotifyRequestBuilder()){self.transport=transport;self.requestBuilder=requestBuilder}
    public func currentUserID(accessToken:String) async throws->String{let response=try await transport.send(requestBuilder.currentUser(accessToken:accessToken));try validate(response);return try decode(SpotifyUserDTO.self,from:response.body).id}
    public func export(name:String,orderedTrackURIs:[String],accessToken:String) async throws->SpotifyExportResult{let userID=try await currentUserID(accessToken:accessToken);let create=try requestBuilder.createPlaylist(userID:userID,name:name,accessToken:accessToken);let createResponse=try await transport.send(create);try validate(createResponse);let playlist=try decode(SpotifyPlaylistDTO.self,from:createResponse.body);for request in try requestBuilder.addTracks(playlistID:playlist.id,trackURIs:orderedTrackURIs,accessToken:accessToken){let response=try await transport.send(request);try validate(response)};return SpotifyExportResult(playlistID:playlist.id,playlistURL:playlist.externalURLs?["spotify"],uploadedTrackCount:orderedTrackURIs.count)}
    private func validate(_ response:HTTPResponse)throws{if response.statusCode==429{let retryAfter=response.headers.first{$0.key.caseInsensitiveCompare("Retry-After")==.orderedSame}?.value;throw IntegrationTransportError.rateLimited(retryAfterSeconds:retryAfter.flatMap(TimeInterval.init))};guard (200..<300).contains(response.statusCode) else{throw IntegrationTransportError.httpStatus(response.statusCode)}}
    private func decode<T:Decodable>(_ type:T.Type,from data:Data)throws->T{do{return try JSONDecoder().decode(type,from:data)}catch{throw IntegrationTransportError.decoding(String(describing:error))}}
}
