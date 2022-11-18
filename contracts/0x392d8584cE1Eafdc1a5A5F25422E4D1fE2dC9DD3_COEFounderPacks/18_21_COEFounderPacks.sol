// SPDX-License-Identifier: MIT

// solhint-disable-next-line
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./DefaultOperatorFilterer.sol";

contract COEFounderPacks is
  ERC721,
  IERC2981,
  ERC721Enumerable,
  ERC721Burnable,
  Pausable,
  Ownable,
  DefaultOperatorFilterer
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  event Mint(uint256 _tokenId, address sender, uint256 amount);

  event AllowList(bool isAllowListOnly);

  constructor(string memory customBaseURI_) ERC721("COEFounderPacks", "COEFP") {
    customBaseURI = customBaseURI_;
    _royaltyAmount = 250;
    _mintPrice = 0.1 ether;
    maxSupply = 3000;
    maxMintableAL = 2;
    //start token ID at 1
    _tokenIdCounter.increment();
    _pause();
  }

  /** Allowlist **/

  bool public _isAllowListOnly = true;

  mapping(bytes => bool) private signatureUsed;

  function setAllowListOnly(bool isAllowListOnlyActive) external onlyOwner {
    _isAllowListOnly = isAllowListOnlyActive;
    emit AllowList(isAllowListOnlyActive);
  }

  function recoverSigner(bytes32 hash, bytes memory signature) private pure returns (address) {
    bytes32 messageDigest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    return ECDSA.recover(messageDigest, signature);
  }

  /** MINTING **/

  uint256 public _mintPrice;
  uint256 public maxSupply;
  uint256 public maxMintableAL;
  mapping(address => uint256) public addressMinted;

  function devMint(uint256 amount) public onlyOwner {
    require(totalSupply() + amount <= maxSupply, "Amount exceeds supply.");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, _tokenIdCounter.current());
      _tokenIdCounter.increment();
    }
  }

  function mint(
    bytes32 hash,
    bytes memory signature,
    uint256 amount
  ) public payable whenNotPaused {
    require(totalSupply() + amount <= maxSupply, "Amount exceeds supply.");
    require(msg.value >= _mintPrice * amount, "Not enough ETH sent.");

    if (msg.sender != owner() && _isAllowListOnly) {
      require(amount <= maxMintableAL, "Amount exceeds max mintable AL.");
      require(recoverSigner(hash, signature) == owner(), "Address is not allowlisted");
      require(!signatureUsed[signature], "Signature has already been used.");
      signatureUsed[signature] = true;
    }

    emit Mint(_tokenIdCounter.current(), msg.sender, amount);

    for (uint256 i; i < amount; i++) {
      _safeMint(msg.sender, _tokenIdCounter.current());
      _tokenIdCounter.increment();
    }

    addressMinted[msg.sender] += amount;
  }

  function setMintPrice(uint256 newPrice) external onlyOwner {
    _mintPrice = newPrice;
  }

  /** ACTIVATION **/

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /** URI HANDLING **/

  string public customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return bytes(customBaseURI).length > 0 ? string(abi.encodePacked(customBaseURI, Strings.toString(tokenId))) : "";
  }

  /** ROYALTIES **/

  uint256 public _royaltyAmount;

  function setRoyaltyAmount(uint256 _amount) external onlyOwner {
    _royaltyAmount = _amount;
  }

  function royaltyInfo(uint256, uint256 salePrice)
    external
    view
    override
    returns (address receiver, uint256 royaltyAmount)
  {
    return (owner(), (salePrice * _royaltyAmount) / 10000);
  }

  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "Balance is zero");
    payable(owner()).transfer(address(this).balance);
  }

  /** OVERRIDES **/

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, IERC165, ERC721Enumerable)
    returns (bool)
  {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  /** OPENSEA TOOLKIT OVERRIDES **/

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}