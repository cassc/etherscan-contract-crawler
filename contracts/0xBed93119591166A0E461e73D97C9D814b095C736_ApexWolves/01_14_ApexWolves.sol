// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract ApexWolves is Ownable, ERC721A, ReentrancyGuard {

  mapping(address => uint256) public allowlist;
  mapping(address => bool) public whitelistClaimed;

  string private _baseTokenURI;
  bytes32 public whitelistRoot; 
  uint256 public MAX_PER_WALLET = 10;
  uint256 public collectionSize_ = 5059;
  bool public mintActive;
  bool public whitelistActive;

  constructor() ERC721A("ApexWolves", "APEX", MAX_PER_WALLET, collectionSize_) {
    mintActive = false;
    whitelistActive = false;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender,                                    "The caller is another contract");
    _;
  }

  function mint() external callerIsUser {
    require(mintActive == true,                                         "Mint is not active");
    require(totalSupply() + 1 <= collectionSize,                        "Reached max supply");
    require(numberMinted(msg.sender) + 1 <= MAX_PER_WALLET,             "Cannot mint this many");
    _safeMint(msg.sender, 1);
  }

  function devMint(uint256 quantity) external onlyOwner {
    require(totalSupply() + quantity <= collectionSize,                 "Reached max supply");
    _safeMint(msg.sender, quantity);
  }

  function whitelistMint(bytes32[] calldata _merkleProof) external callerIsUser {
    require(whitelistActive == true,                                    "Whitelist mint is not active");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, whitelistRoot, leaf),      "Incorrect proof passed to validation");
    require(!whitelistClaimed[msg.sender],                              "Owner has already minted reserved whitelist wolf");
    require(totalSupply() + 1 <= collectionSize,                        "Reached max supply");
    require(numberMinted(msg.sender) + 1 <= MAX_PER_WALLET,             "Cannot mint this many");
    whitelistClaimed[msg.sender] = true;
    _safeMint(msg.sender, 1);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function setWhitelistRoot(bytes32 _root) external onlyOwner {
    whitelistRoot = _root;
  }

  function toggleMint() external onlyOwner() {
    mintActive = !mintActive;
  } 

  function toggleWhitelist() external onlyOwner() {
    whitelistActive = !whitelistActive;
  } 

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}