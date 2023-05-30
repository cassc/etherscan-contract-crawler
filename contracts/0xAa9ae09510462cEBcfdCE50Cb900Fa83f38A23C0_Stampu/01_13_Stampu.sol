//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IERC2981.sol";

/////////////////////////////////////////////////////////////////////
//  ______     ______   ______     __    __     ______   __  __    //
// /\  ___\   /\__  _\ /\  __ \   /\ "-./  \   /\  == \ /\ \/\ \   //
// \ \___  \  \/_/\ \/ \ \  __ \  \ \ \-./\ \  \ \  _-/ \ \ \_\ \  //
//  \/\_____\    \ \_\  \ \_\ \_\  \ \_\ \ \_\  \ \_\    \ \_____\ //
//   \/_____/     \/_/   \/_/\/_/   \/_/  \/_/   \/_/     \/_____/ //
//                                                                 //
/////////////////////////////////////////////////////////////////////
contract Stampu is IERC2981, ERC1155, Ownable {
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  struct StampInfo {
    address payable artist;
    uint256 maxSupply;
    uint256 currentSupply;
    uint256 mintPrice;
    uint256 mintLimit; // mint limit per tx. 0 works as pause.
  }

  event SendPostcard(
    uint256 indexed postcardId,
    address indexed from,
    address indexed to,
    uint256 tokenId,
    string fromText,
    string toText,
    string message,
    uint256 value
  );

  using Strings for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;
  Counters.Counter private _postcardIdCounter;
  string internal _baseURI;
  address internal _royaltyRecipient;
  uint8 internal _royaltyFee; // out of 1000

  // Contract name
  string public name;
  // Contract symbol
  string public symbol;
  mapping(uint256 => StampInfo) public tokenIdToStampInfo;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    address royaltyRecipient,
    uint8 royaltyFee
  ) ERC1155("") {
    name = _name;
    symbol = _symbol;
    _baseURI = _uri;
    setRoyaltyRecipient(royaltyRecipient);
    setRoyaltyFee(royaltyFee);
  }

  function setURI(string memory newuri) public onlyOwner {
    _baseURI = newuri;
  }

  function uri(uint256 _id) public view override returns (string memory) {
    require(_id < _tokenIdCounter.current(), "nonexistent token");
    return string(abi.encodePacked(_baseURI, _id.toString()));
  }

  /**
   * @dev Adds new Stampus (mint is paused by default).
   */
  function addStampus(
    address payable[] calldata artists,
    uint256[] calldata maxSupplies,
    uint256[] calldata mintPrices
  ) public onlyOwner {
    require(artists.length == maxSupplies.length && artists.length == mintPrices.length, "input lengths do not match");

    for (uint256 i = 0; i < artists.length; i++) {
      uint256 tokenId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      tokenIdToStampInfo[tokenId] = StampInfo({
        artist: artists[i],
        maxSupply: maxSupplies[i],
        currentSupply: 0,
        mintPrice: mintPrices[i],
        mintLimit: 0 // paused by default. Can be unpaused through `setMintLimit`.
      });
    }
  }

  /**
   * @dev Updates artist address (in case of theft or lost wallet).
   */
  function updateArtistAddress(uint256 id, address payable artist) public onlyOwner {
    require(id < _tokenIdCounter.current(), "nonexistent token");
    require(artist != address(0), "Invalid artist address");
    StampInfo storage stampInfo = tokenIdToStampInfo[id];
    stampInfo.artist = artist;
  }

  /**
   * @dev Mints ignoring the mint limit and price (onlyOwner).
   */
  function preMint(
    address account,
    uint256 id,
    uint256 amount
  ) public onlyOwner {
    require(id < _tokenIdCounter.current(), "nonexistent token");
    StampInfo storage stampInfo = tokenIdToStampInfo[id];
    uint256 newSupply = stampInfo.currentSupply + amount;
    require(newSupply <= stampInfo.maxSupply, "exceeds max supply");
    stampInfo.currentSupply = newSupply;
    _mint(account, id, amount, "");
  }

  /**
   * @dev Mints Stampu(s).
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) public payable {
    require(id < _tokenIdCounter.current(), "nonexistent token");

    StampInfo storage stampInfo = tokenIdToStampInfo[id];
    // Owner is allowed to mint even when minting is paused.
    if (owner() != _msgSender()) {
      require(amount <= stampInfo.mintLimit, "exceeds the allowed mint limit");
    }

    require(msg.value >= stampInfo.mintPrice * amount, "insufficient mint price");
    uint256 newSupply = stampInfo.currentSupply + amount;
    require(newSupply <= stampInfo.maxSupply, "exceeds max supply");
    stampInfo.currentSupply = newSupply;

    uint256 artistCut = _getArtistCut(stampInfo.mintPrice * amount);
    (bool success, ) = stampInfo.artist.call{value: artistCut}("");
    require(success, "arist payment failed");

    _mint(account, id, amount, "");
  }

  /**
   * @dev Sets `mintLimit` of `tokenIds`.
   *
   * Setting `mintLimit` from 0 is equivalent to unpausing mint.
   */
  function setMintLimit(uint256[] calldata tokenIds, uint256[] calldata mintLimits) public onlyOwner {
    require(tokenIds.length == mintLimits.length, "input array lengths must be the same");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i];
      require(tokenId < _tokenIdCounter.current(), "nonexistent token");
      tokenIdToStampInfo[tokenId].mintLimit = mintLimits[i];
    }
  }

  /**
   * @dev Sends a postcard along with a Stampu and optionally with ETH.
   */
  function sendPostcard(
    address payable to,
    uint256 id,
    string calldata fromText,
    string calldata toText,
    string calldata message
  ) public payable {
    _sendPostcard(to, id, fromText, toText, message, msg.value);
  }

  function _sendPostcard(
    address payable to,
    uint256 id,
    string calldata fromText,
    string calldata toText,
    string calldata message,
    uint256 value
  ) private {
    if (value > 0) {
      (bool success, ) = to.call{value: value}("");
      require(success, "payment failed");
    }

    safeTransferFrom(_msgSender(), to, id, 1, "");
    emit SendPostcard(_postcardIdCounter.current(), _msgSender(), to, id, fromText, toText, message, value);
    _postcardIdCounter.increment();
  }

  /**
   * @dev Sends multiple postcards in a single transaction.
   */
  function batchSendPostcards(
    address payable[] calldata toAddresses,
    uint256 id,
    string calldata fromText,
    string calldata toText,
    string calldata message
  ) public payable {
    // Value should be a multiple of the number of receipents.
    // The contract will keep the remainder if any.
    uint256 valuePerPostCard = msg.value / toAddresses.length;
    for (uint256 i = 0; i < toAddresses.length; i++) {
      _sendPostcard(toAddresses[i], id, fromText, toText, message, valuePerPostCard);
    }
  }

  /**
   * @dev Withdraws fees accumulated in the contract (onlyOwner).
   */
  function withdrawFees() public onlyOwner {
    (bool sent, ) = msg.sender.call{value: address(this).balance}("");
    require(sent, "failed to send collected fees");
  }

  /**
   * @dev Mints and sends a postcard in a single transaction.
   */
  function mintAndSendPostcard(
    address payable to,
    uint256 id,
    string calldata fromText,
    string calldata toText,
    string calldata message
  ) public payable {
    mint(_msgSender(), id, 1);
    uint256 valueLeft = msg.value - tokenIdToStampInfo[id].mintPrice;
    _sendPostcard(to, id, fromText, toText, message, valueLeft);
  }

  // Royalty functions:
  function setRoyaltyRecipient(address royaltyRecipient) public onlyOwner {
    require(royaltyRecipient != address(0), "Invalid royalty recipient address");
    _royaltyRecipient = royaltyRecipient;
  }

  function setRoyaltyFee(uint8 royaltyFee) public onlyOwner {
    require(royaltyFee <= 1000, "Invalid royalty fee");
    _royaltyFee = royaltyFee;
  }

  function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
    return (_royaltyRecipient, (_salePrice * _royaltyFee) / 1000);
  }

  function supportsInterface(bytes4 interfaceId) public view override(IERC2981, ERC1155) returns (bool) {
    return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
  }

  // Utility functions:
  function _getArtistCut(uint256 mintPrice) internal pure returns (uint256) {
    return (mintPrice * 9) / 10;
  }
}