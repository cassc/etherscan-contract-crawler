//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./ERC2981.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
    How this contract works:
      - 1-5000: only Tune owners can mint (originals)
      - 5001 and more: anyone can create a remix
      - Cover art is pinned to AI generated cover art
      - The audio_uri can be set at any time by owner
      - audio_uri can be frozen by the track owner
      - Users can set the 'name' of the track since titles of Tunes are not stored on-chain
      - We preserve the original minter to credit them
 */

contract Songs is ERC721, ReentrancyGuard, ERC2981, Ownable {
  struct Track {
    string track_name;
    address minter;
    string audio_uri;
    uint256 tune_token_id;
    address artist;
    bool freeze_audio_uri;
  }

  IERC721Enumerable public tunes;
  uint256 public totalRemixTracks = 0;
  uint256 public totalOriginalTracks = 0;
  uint8 public ROYALTY_PCT = 15;
  bool public freeze_royalty_pct = false;
  bool public freeze_cover_art_uri = false;

  string private BASE_COVER_ART_URI =
    "ipfs://Qmcu552EPV98N9vi96sGN72XJCeBF4n7jC5XtA1h3HF5kC/";
  uint256 private constant MAX_ORIGINAL_SUPPLY = 5000;

  mapping(uint256 => Track) private _original_tracks; // tokenId => Track
  mapping(uint256 => Track) private _remix_tracks; // tokenId => Track

  constructor(address tunesOfficialAddress) ERC721("Songs", "SONG") {
    tunes = IERC721Enumerable(tunesOfficialAddress);
  }

  modifier onlyTrackOwner(uint256 token_id) {
    require(ownerOf(token_id) == msg.sender, "You must be the track owner.");
    _;
  }

  modifier onlyOriginalTuneOwner(uint256 tune_token_id) {
    require(
      tunes.ownerOf(tune_token_id) == _msgSender(),
      "You must own the corresponding Tune to mint this."
    );
    _;
  }

  modifier lessThanTuneSupply(uint256 tokenId) {
    require(tokenId <= MAX_ORIGINAL_SUPPLY, "Tune ID is too high");
    require(tokenId > 0, "Tune ID cannot be 0");
    _;
  }

  function hasLength(string memory str) private pure returns (bool) {
    return bytes(str).length > 0;
  }

  function mintOriginalTrack(
    string memory track_name,
    string memory audio_uri,
    uint256 tune_token_id
  )
    public
    lessThanTuneSupply(tune_token_id)
    onlyOriginalTuneOwner(tune_token_id)
    nonReentrant
    returns (uint256 token_id)
  {
    require(hasLength(track_name), "Need a track name");
    require(hasLength(audio_uri), "Need an audio URI");
    _original_tracks[tune_token_id] = Track(
      track_name,
      _msgSender(),
      audio_uri,
      tune_token_id,
      address(0),
      false
    );
    _safeMint(_msgSender(), tune_token_id);
    token_id = tune_token_id;
    totalOriginalTracks += 1;
  }

  function mintRemixTrack(
    string memory track_name,
    string memory audio_uri,
    uint256 tune_token_id
  )
    public
    lessThanTuneSupply(tune_token_id)
    nonReentrant
    returns (uint256 token_id)
  {
    require(hasLength(track_name), "Need a track name");
    require(hasLength(audio_uri), "Need an audio URI");
    require(tune_token_id > 0, "Need a tune token id (1-5000)");

    token_id = MAX_ORIGINAL_SUPPLY + totalRemixTracks + 1;
    _remix_tracks[token_id] = Track(
      track_name,
      _msgSender(),
      audio_uri,
      tune_token_id,
      address(0),
      false
    );
    _safeMint(_msgSender(), token_id);
    _setReceiver(token_id, tunes.ownerOf(tune_token_id));
    _setRoyaltyPercentage(token_id, ROYALTY_PCT);
    totalRemixTracks += 1;
  }

  function setGlobalRoyaltyPercent(uint8 percent) public onlyOwner {
    require(!freeze_royalty_pct, "It is frozen");
    require(percent >= 0 && percent <= 100, "Percent must be between 0 - 100");
    ROYALTY_PCT = percent;
  }

  function freezeRoyaltyPercent() public onlyOwner {
    freeze_royalty_pct = true;
  }

  function setCoverArtURI(string memory uri) public onlyOwner {
    require(!freeze_cover_art_uri, "It is frozen");
    BASE_COVER_ART_URI = uri;
  }

  function freezeCoverArtURI() public onlyOwner {
    freeze_cover_art_uri = true;
  }

  function getTrack(uint256 token_id) private view returns (Track storage) {
    Track storage track = token_id > MAX_ORIGINAL_SUPPLY
      ? _remix_tracks[token_id]
      : _original_tracks[token_id];
    require(track.tune_token_id > 0);

    return track;
  }

  function artistOf(uint256 token_id) public view returns (address) {
    require(token_id > 0, "Token ID must be greater than 0");
    Track storage track = getTrack(token_id);
    return track.artist;
  }

  function setArtist(address artist, uint256 token_id)
    public
    onlyTrackOwner(token_id)
    nonReentrant
    returns (bool)
  {
    Track storage track = getTrack(token_id);
    track.artist = artist;
    return true;
  }

  function setAudioTrackURI(uint256 token_id, string memory audio_uri)
    public
    onlyTrackOwner(token_id)
    returns (bool)
  {
    require(hasLength(audio_uri), "Need an audio URI");
    Track storage track = getTrack(token_id);
    require(!track.freeze_audio_uri, "It is frozen");
    track.audio_uri = audio_uri;
    return true;
  }

  function freezeAudioTrackURI(uint256 token_id)
    public
    onlyTrackOwner(token_id)
  {
    Track storage track = getTrack(token_id);
    track.freeze_audio_uri = true;
  }

  function isFrozenAudioTrackURI(uint256 token_id) public view returns (bool) {
    Track memory track = getTrack(token_id);
    return track.freeze_audio_uri;
  }

  function audioTrackURI(uint256 token_id) public view returns (string memory) {
    Track memory track = getTrack(token_id);
    return track.audio_uri;
  }

  function minterOf(uint256 token_id) public view returns (address) {
    Track memory track = getTrack(token_id);
    return track.minter;
  }

  function coverArtURI(uint256 token_id) public view returns (string memory) {
    Track memory track = getTrack(token_id);
    uint256 tune_token_id = track.tune_token_id;
    return
      string(
        abi.encodePacked(
          BASE_COVER_ART_URI,
          Strings.toString(tune_token_id),
          "-composite.png"
        )
      );
  }

  function tuneTokenId(uint256 token_id) public view returns (uint256) {
    Track memory track = getTrack(token_id);
    return track.tune_token_id;
  }

  function isOriginal(uint256 token_id) public pure returns (bool) {
    return token_id <= MAX_ORIGINAL_SUPPLY && token_id > 0;
  }

  function tokenURI(uint256 token_id)
    public
    view
    override(ERC721)
    returns (string memory)
  {
    require(token_id > 0, "Invalid token id");

    string memory output;
    string memory json;

    Track memory track = getTrack(token_id);
    string memory edition = "Remix";
    if (isOriginal(token_id)) edition = "Original";

    json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            track.track_name,
            " (",
            edition,
            ")",
            '", "description": "Songs for Tunes lets artists make songs to sell on an open decentralized marketplace.", "image": "',
            coverArtURI(token_id),
            '", "animation_url": "',
            track.audio_uri,
            '", "attributes": [{"trait_type": "Edition", "value": "',
            edition,
            '"}], "tune_token_id": ',
            Strings.toString(track.tune_token_id),
            "}"
          )
        )
      )
    );

    output = string(abi.encodePacked("data:application/json;base64,", json));
    return output;
  }

  function totalSupply() public view returns (uint256) {
    return totalOriginalTracks + totalRemixTracks;
  }
}