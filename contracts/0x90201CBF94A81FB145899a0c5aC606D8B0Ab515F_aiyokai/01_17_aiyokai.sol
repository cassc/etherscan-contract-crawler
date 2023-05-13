// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract aiyokai is
  ERC721,
  EIP712,
  ReentrancyGuard,
  Ownable,
  DefaultOperatorFilterer
{
  using ECDSA for bytes32;

  uint256 public constant PRICE = 0.05 ether;

  struct Attribute {
    uint256 tokenId;
    string metadataUrl;
  }

  bytes32 private constant _TYPEHASH =
    keccak256("Attribute(uint256 tokenId,string metadataUrl)");

  address public artist;
  bool public isOnSale = true;
  bool public isMetadataFrozen;
  mapping(uint256 => string) public tokenIdToMetadataUrl;
  uint256[] private _mintedTokenIdList;

  address private _verifyAddress;

  constructor(address verifyAddress, address artistAddress)
    ERC721("AI Yokai", "AIYOKAI")
    EIP712("AI Yokai", "1.0.0")
  {
    _verifyAddress = verifyAddress;
    artist = artistAddress;
  }

  modifier onlyOwnerOrArtist() {
    require(
      msg.sender == owner() || msg.sender == artist,
      "AI Yokai: Only the owner or artist can call this function."
    );
    _;
  }

  function verifyParams(Attribute calldata params, bytes calldata signature)
    public
    view
    returns (bool)
  {
    bytes memory b = abi.encode(
      _TYPEHASH,
      params.tokenId,
      keccak256(bytes(params.metadataUrl))
    );
    address signer = _hashTypedDataV4(keccak256(b)).recover(signature);
    return signer == _verifyAddress;
  }

  function mintedTokenIdList() external view returns (uint256[] memory) {
    return _mintedTokenIdList;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    require(_exists(tokenId), "AI Yokai: URI query for nonexistent token");
    return tokenIdToMetadataUrl[tokenId];
  }

  function mint(Attribute calldata params, bytes calldata signature)
    external
    payable
    nonReentrant
  {
    require(isOnSale, "AI Yokai: Not on sale");
    require(verifyParams(params, signature), "AI Yokai: Invalid signature");
    require(msg.value == PRICE, "AI Yokai: Invalid value");

    _mintAndTransfer(_msgSender(), params.tokenId, params.metadataUrl);
  }

  function mintForFree(
    address to,
    uint256[] memory tokenId,
    string[] memory metadataUrl
  ) external onlyOwnerOrArtist {
    require(
      tokenId.length == metadataUrl.length,
      "AI Yokai: Invalid array length"
    );
    uint256 count = tokenId.length;
    for (uint256 i; i < count; i++) {
      uint256 _tokenId = tokenId[i];
      string memory _metadataUrl = metadataUrl[i];
      _mintAndTransfer(to, _tokenId, _metadataUrl);
    }
  }

  function setIsOnSale(bool _isOnSale) external onlyOwner {
    isOnSale = _isOnSale;
  }

  function setMetadataUrl(uint256 tokenId, string memory metadataUrl)
    external
    onlyOwner
  {
    require(!isMetadataFrozen, "AI Yokai: Metadata is already frozen");
    require(_exists(tokenId), "AI Yokai: Invalid tokenId");
    tokenIdToMetadataUrl[tokenId] = metadataUrl;
  }

  function setIsMetadataFrozen(bool _isMetadataFrozen) external onlyOwner {
    require(!isMetadataFrozen, "AI Yokai: isMetadataFrozen cannot be changed");
    isMetadataFrozen = _isMetadataFrozen;
  }

  function withdraw() external onlyOwner {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }

  function _mintAndTransfer(
    address to,
    uint256 tokenId,
    string memory metadataUrl
  ) internal {
    tokenIdToMetadataUrl[tokenId] = metadataUrl;

    _mintedTokenIdList.push(tokenId);
    _safeMint(artist, tokenId);
    _safeTransfer(artist, to, tokenId, "");
  }

  /**
   * Operator Filter Registry
   */
  function setApprovalForAll(address operator, bool approved)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId)
    public
    override
    onlyAllowedOperatorApproval(operator)
  {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}