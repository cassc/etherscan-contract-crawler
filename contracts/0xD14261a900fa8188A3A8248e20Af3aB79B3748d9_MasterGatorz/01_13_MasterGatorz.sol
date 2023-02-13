// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/// @title MasterGatorz contract

contract MasterGatorz is 
     ERC721A, 
     IERC2981,
     Ownable, 
     ReentrancyGuard,
     DefaultOperatorFilterer
{

  using Strings for uint256;

  bytes32 public merkleRoot;

  address public royaltyAddress;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenUri = 'ipfs://QmUsNPmsU1zUFARdGuTP4f1prGZApxWcmh4BZCoUzd7JfU';
  
  uint256 public price = 0.0079 ether;
  uint256 public maxSupply = 2222; 
  uint256 public royalty = 50;
  uint256 public maxPerTx = 2;

  bool public paused = false;
  bool public whitelistM = false;
  bool public publicM = false;
  bool public revealed = false;
 
  mapping(address => bool) public addressClaimed;

  constructor() 
  ERC721A("MasterGatorz", "GATOR") {
    royaltyAddress = msg.sender;
  }

/// @dev === MODIFIER ===
  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, 'The sale is closed!');
    require(_mintAmount > 0 && _mintAmount <= maxPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'SOLD OUT!');
    require(msg.value >= price * _mintAmount, 'Insufficient funds!');
    require(!addressClaimed[_msgSender()], 'Address already claimed!');
    _;
  }

/// @dev === Minting Function - Input ====
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable 
  mintCompliance(_mintAmount) 
  {
    require(whitelistM, 'The whitelist sale is not enabled!');
    /// @notice Verify whitelist
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid signature!');

     addressClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  /// Public mint function
  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(publicM, 'The public sale is not enabled!');

     addressClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _amount, address _receiver) public payable onlyOwner {
    require(totalSupply() + _amount <= maxSupply, 'Sold out!');

    _safeMint(_receiver, _amount);
  }

/// @dev === Override ERC721A ===
  function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

/// @dev === PUBLIC READ-ONLY ===

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'Nonexistent token!');

    if (revealed == false) {
      return hiddenUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

/// @dev === Owner Control/Configuration Functions ===

  function setRevealed() public onlyOwner {
    revealed = true;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setHiddenUri(string memory _uriHidden) public onlyOwner {
    hiddenUri = _uriHidden;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function pause() public onlyOwner {
    paused = !paused;
  }

  function flipWhitelist() public onlyOwner {
    whitelistM = !whitelistM;
  }

  function flipPublic() public onlyOwner {
    publicM = !publicM;
  }

  function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
    royaltyAddress = _royaltyAddress;
  }

  function setRoyalty(uint256 _royalty) external onlyOwner {
        royalty = _royalty;
  }

  function setMaxPerTix(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
  }

  function setPrice(uint256 _price) external onlyOwner {
        price = _price;
  }

/// Opensea Royalty Enforcement
  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }  

/// @dev === INTERNAL READ-ONLY ===
  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

/// @dev === Withdraw ====
  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

//IERC2981 Royalty Standard
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external view override returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (royaltyAddress, (salePrice * royalty) / 1000);
    }                                                

/// @dev === Support Functions ==
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}