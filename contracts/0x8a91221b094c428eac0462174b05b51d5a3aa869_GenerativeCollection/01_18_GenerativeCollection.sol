// contracts/GenerativeCollection.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error NotEnoughEther(uint256 requiredEtherAmount);
error ExceededMaxSupply(uint256 maxSupply);
error ExceededMaxPurchaseable(uint256 maxPurchaseable);

contract GenerativeCollection is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Burnable,
  ReentrancyGuard,
  Pausable,
  Ownable
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  uint256 public constant MAX_SUPPLY = 10_000;
  uint256 public constant MAX_NFT_PURCHASEABLE = 20;

  uint256 private _reserved = 75;
  uint256 private _mintPrice = 0.05 ether;

  string _metadataBaseURI;

  constructor() ERC721('Moongang', 'MOONGANG') {
    _metadataBaseURI = 'https://moonwalk.mypinata.cloud/ipfs/QmQcD3nVBM2Zy93BhnA5fkxPUF7zdMk5saAvzZfGSTJZjN/';

    // increment so first minted ID is 1
    _tokenIdCounter.increment();

    pause();
  }

  modifier whenAmountIsZero(uint256 numberOfTokens) {
    require(numberOfTokens != 0, 'Mint amount cannot be zero');

    _;
  }

  modifier whenNotExceedMaxPurchaseable(uint256 numberOfTokens) {
    if (numberOfTokens < 0 || numberOfTokens > MAX_NFT_PURCHASEABLE) {
      revert ExceededMaxPurchaseable({ maxPurchaseable: MAX_NFT_PURCHASEABLE });
    }

    _;
  }

  modifier whenNotExceedMaxSupply(uint256 numberOfTokens) {
    if (totalSupply() + numberOfTokens > (MAX_SUPPLY - _reserved)) {
      revert ExceededMaxSupply({ maxSupply: (MAX_SUPPLY) });
    }

    _;
  }

  modifier hasEnoughEther(uint256 numberOfTokens) {
    if (msg.value < _mintPrice * numberOfTokens) {
      revert NotEnoughEther({
        requiredEtherAmount: _mintPrice * numberOfTokens
      });
    }

    _;
  }

  function mintNft(uint256 numberOfTokens)
    public
    payable
    nonReentrant
    whenNotPaused
    whenAmountIsZero(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }
  }

  function giveAwayNft(address to, uint256 numberOfTokens)
    public
    nonReentrant
    onlyOwner
  {
    require(numberOfTokens <= _reserved, 'Exceeds reserved supply');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }

    _reserved -= numberOfTokens;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokenIds;
  }

  function getMintPrice() public view returns (uint256) {
    return _mintPrice;
  }

  function setMintPrice(uint256 newPrice) public onlyOwner {
    _mintPrice = newPrice;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  function baseURI() public view virtual returns (string memory) {
    return _baseURI();
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _metadataBaseURI = baseUri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    // This forwards all available gas. Be sure to check the return value!
    (bool success, ) = msg.sender.call{ value: balance }('');

    require(success, 'Transfer failed.');
  }

  receive() external payable {}
}