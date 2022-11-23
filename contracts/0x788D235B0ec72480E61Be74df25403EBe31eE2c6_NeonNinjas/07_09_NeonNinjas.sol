// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract NeonNinjas is ERC721A ,Ownable, ReentrancyGuard  {

  using Strings for uint256;

//initial stats 
uint256 public MaxSupply = 999;
uint256 public price = 0 ether;
uint256 public maxPerWallet = 1;

//SaleState --> initial close
bool public whitelistSale = false;
bool public waitlistSale = false;
bool public publicSale = false;

//Art
string public metaDataURI;

//Whitelist & waitlist
bytes32 private wlMerkleRoot;
bytes32 private waMerkleRoot;
mapping (address => bool) public whitelistMinted;
mapping (address => bool) public waitlistMinted;
mapping (address => bool) public publicMinted;

//OwnerAdress
address private OwnerAdress = 0x4c0CCd9cc894c1CCA6995b088c5886C9d0E3aaB5;

constructor() ERC721A("NeonNinjas", "NEONNINJA") {}

// Sale state functions //
function setWhitelistSale() external onlyOwner {
  whitelistSale = !whitelistSale;
}

function setWaitlistSale() external onlyOwner {
  waitlistSale = !whitelistSale;
}

function setPublicSale() external onlyOwner {
  publicSale = !publicSale;
}

// Mint functions //

function whitelistMint (bytes32[] calldata _merkleProof) public payable {
  require(whitelistSale, 'WL sale is not live!');
  require(!whitelistMinted[_msgSender()], 'Wallet already minted!');
  require(totalSupply() + 1 <= MaxSupply, 'Max supply exceeded!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf), 'proof is not valid!');

  whitelistMinted[_msgSender()] = true;
  _safeMint(_msgSender(), 1);
}

function waitlistMint (bytes32[] calldata _merkleProof) public payable {
  require(waitlistSale, 'Waitlist sale is not live!');
  require(!waitlistMinted[_msgSender()], 'Wallet already minted!');
  require(totalSupply() + 1 <= MaxSupply, 'Max supply exceeded!');
  bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
  require(MerkleProof.verify(_merkleProof, waMerkleRoot, leaf), 'proof is not valid!');

  waitlistMinted[_msgSender()] = true;
  _safeMint(_msgSender(), 1);
}

function publicMint () public payable {
  require(publicSale, 'PublicSale sale is not live!');
  require(!publicMinted[_msgSender()], 'Wallet already minted!');
  require(totalSupply() + 1 <= MaxSupply, 'Max supply exceeded!');

  publicMinted[_msgSender()] = true;
  _safeMint(_msgSender(), 1);
}

function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
  _safeMint(_receiver, _mintAmount);
 }

// Art
function _startTokenId() internal view virtual override returns (uint256) {
  return 1;
}

function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
  require(_exists(_tokenId), 'TokenID does not exsist!');

  string memory currentBaseURI = _baseURI();
  return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), '.json'))
      : '';
}

function setBaseURI(string memory _metaDataURI) external onlyOwner {
  metaDataURI = _metaDataURI;
}

function _baseURI() internal view virtual override returns (string memory) {
  return metaDataURI;
}


//Mintamount
function setMaxAmountPerWallet (uint256 _maxPerWallet) public onlyOwner {
  maxPerWallet = _maxPerWallet;
}

//Set whitelist & waitlist
function setWlMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
    wlMerkleRoot = _wlMerkleRoot;
}

function setWaMerkleRoot(bytes32 _waMerkleRoot) public onlyOwner {
  waMerkleRoot = _waMerkleRoot;
}


//withdraw funds
function withdraw() public onlyOwner {
  payable(OwnerAdress).transfer(address(this).balance); 
}




}