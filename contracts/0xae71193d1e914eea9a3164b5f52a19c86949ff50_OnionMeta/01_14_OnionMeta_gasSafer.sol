// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OnionMeta is ERC721, Ownable {
  using Strings for uint256;
  using ECDSA for bytes32;
  
  bool public _isWhiteListSaleActive = false;
  bool public _isSaleActive = false;
  bool public _isAuctionActive = false;

  // Constants
  uint256 constant public MAX_SUPPLY = 1024;

  uint256 public mintPrice = 0.3 ether;
  uint256 public whiteListPrice = 0.3 ether;

  uint256 public totalSupply;
  uint256 public tierSupply = 184;
  uint256 public maxBalance = 1;
  uint256 public maxMint = 1;

  uint256 public auctionStartTime;
  uint256 public auctionTimeStep;
  uint256 public auctionStartPrice;
  uint256 public auctionEndPrice;
  uint256 public auctionPriceStep;
  uint256 public auctionStepNumber;

  uint256 public saleStartTime = 1642226400;

  string private _baseURIExtended;
  address private _signerAddress = 0x6a389354957955Bef004222B3dBF4FAb40Ace650;
  mapping(string => bool) private _usedNonces;
  mapping(address => bool) private whiteList;


  event TokenMinted(uint256 supply);

  constructor() ERC721("Onion Meta", "OM") {}

  function flipWhiteListSaleActive() public onlyOwner {
    _isWhiteListSaleActive = !_isWhiteListSaleActive;
  }

  function flipSaleActive() public onlyOwner {
    _isSaleActive = !_isSaleActive;
  }

  function flipAuctionActive() public onlyOwner {
    _isAuctionActive = !_isAuctionActive;
  }

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }
  
  function setWhiteListPrice(uint256 _whiteListPrice) public onlyOwner {
    whiteListPrice = _whiteListPrice;
  }

  function setWhiteList(address[] calldata _whiteList) external onlyOwner {
    for(uint i = 0; i < _whiteList.length; i++) {
      whiteList[_whiteList[i]] = true;
    }
  }

  function setTierSupply(uint256 _tierSupply) public onlyOwner {
    tierSupply = _tierSupply;
  }

  function setMaxBalance(uint256 _maxBalance) public onlyOwner {
    maxBalance = _maxBalance;
  }

  function setMaxMint(uint256 _maxMint) public onlyOwner {
    maxMint = _maxMint;
  }

  function setSaleStartTime(uint _saleStartTime) public onlyOwner{
    saleStartTime = _saleStartTime;
  }

  function setAuction(uint256 _auctionStartTime, uint256 _auctionTimeStep, uint256 _auctionStartPrice, uint256 _auctionEndPrice, uint256 _auctionPriceStep, uint256 _auctionStepNumber) public onlyOwner {
    auctionStartTime = _auctionStartTime;
    auctionTimeStep = _auctionTimeStep;
    auctionStartPrice = _auctionStartPrice;
    auctionEndPrice = _auctionEndPrice;
    auctionPriceStep = _auctionPriceStep;
    auctionStepNumber = _auctionStepNumber;
  }

  function withdraw(address to) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(to).transfer(balance);
  }

  function preserveMint(uint tokenQuantity, address to) public onlyOwner {
    require(totalSupply + tokenQuantity <= tierSupply, "Preserve mint would exceed tier supply");
    require(totalSupply + tokenQuantity <= MAX_SUPPLY, "Preserve mint would exceed max supply");
    _mintOnionMeta(tokenQuantity, to);
    emit TokenMinted(totalSupply);
  }

  function getTotalSupply() public view returns (uint256) {
    return totalSupply;
  }

  function getOnionMetaByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    uint256 _index;
    uint256 _loopThrough = totalSupply;
    for (uint256 i; i < _loopThrough; i++) {
      bool _exists = _exists(i);
      if (_exists){
        if (ownerOf(i) == _owner) { tokenIds[_index] = i; _index++;}
      }      
      else if (!_exists && tokenIds[tokenCount-1] == 0) {_loopThrough++;}
    }
    return tokenIds;
  }

  function getAuctionPrice() public view returns (uint256) {
    if (!_isAuctionActive) {
      return 0;
    }
    if (block.timestamp < auctionStartTime) {
      return auctionStartPrice;
    }
    uint256 step = (block.timestamp - auctionStartTime) / auctionTimeStep;
    if (step > auctionStepNumber) {
      step = auctionStepNumber;
    }
    return 
      auctionStartPrice > step * auctionPriceStep
        ? auctionStartPrice - step * auctionPriceStep
        : auctionEndPrice;
  }

  function hashTransaction(address sender, uint256 qty, string memory nonce) private pure returns(bytes32) {
    bytes32 hash = keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      keccak256(abi.encodePacked(sender, qty, nonce)))
    );
    
    return hash;
  }
  
  function matchAddresSigner(bytes32 hash, bytes memory signature) private view returns(bool) {
    return _signerAddress == hash.recover(signature);
  }
  
  function mintOnionMeta(bytes32 hash, bytes memory signature, string memory nonce, uint256 tokenQuantity) external payable {
    require(totalSupply + tokenQuantity <= tierSupply, "Sale would exceed tier supply");
    require(totalSupply + tokenQuantity <= MAX_SUPPLY, "Sale would exceed max supply");
    require(block.timestamp >= saleStartTime, "Sale not start");
    require(_isSaleActive, "Sale must be active to mint OnionMetas");
    require(balanceOf(msg.sender) + tokenQuantity <= maxBalance, "Sale would exceed max balance");
    require(tokenQuantity <= maxMint, "Sale would exceed max mint");
    require(tokenQuantity * mintPrice <= msg.value, "Not enough ether sent");    
    require(!_usedNonces[nonce], "HASH_USED");
    require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
    require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
   
    _mintOnionMeta(tokenQuantity, msg.sender);
    emit TokenMinted(totalSupply);  
    _usedNonces[nonce] = true;
  }

  function auctionMintOnionMeta(bytes32 hash, bytes memory signature, string memory nonce, uint tokenQuantity) public payable {
    require(totalSupply + tokenQuantity <= tierSupply, "Auction would exceed tier supply");
    require(totalSupply + tokenQuantity <= MAX_SUPPLY, "Auction would exceed max supply");
    require(_isAuctionActive, "Auction must be active to mint OnionMetas");
    require(block.timestamp >= auctionStartTime, "Auction not start");
    require(balanceOf(msg.sender) + tokenQuantity <= maxBalance, "Auction would exceed max balance");
    require(tokenQuantity <= maxMint, "Auction would exceed max mint");
    require(tokenQuantity * getAuctionPrice() <= msg.value, "Not enough ether sent");
    require(matchAddresSigner(hash, signature), "DIRECT_MINT_DISALLOWED");
    require(!_usedNonces[nonce], "HASH_USED");
    require(hashTransaction(msg.sender, tokenQuantity, nonce) == hash, "HASH_FAIL");
    _mintOnionMeta(tokenQuantity, msg.sender);
    emit TokenMinted(totalSupply);
    _usedNonces[nonce] = true;
  }

  function whiteListMintOnionMetas(uint tokenQuantity) public payable {
    require(_isWhiteListSaleActive, "Sale must be active to mint OnionMetas");
    require(whiteList[msg.sender], "Not in white list");
    require(totalSupply + tokenQuantity <= tierSupply, "Sale would exceed tier supply");
    require(totalSupply + tokenQuantity <= MAX_SUPPLY, "Sale would exceed max supply");
    require(balanceOf(msg.sender) + tokenQuantity <= maxBalance, "Sale would exceed max balance");
    require(tokenQuantity <= maxMint, "Sale would exceed max mint");
    require(tokenQuantity * whiteListPrice <= msg.value, "Not enough ether sent");
    _mintOnionMeta(tokenQuantity, msg.sender);
    emit TokenMinted(totalSupply);
    whiteList[msg.sender] = false;
  }

  function _mintOnionMeta(uint256 tokenQuantity, address recipient) internal {
    uint256 supply = totalSupply;
    for (uint256 i = 0; i < tokenQuantity; i++) {
      _mintInternal(recipient, supply + i);
    }
  }
  function _mintInternal(address to_, uint256 tokenId) internal {
    totalSupply++;
    _mint(to_, tokenId);
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}