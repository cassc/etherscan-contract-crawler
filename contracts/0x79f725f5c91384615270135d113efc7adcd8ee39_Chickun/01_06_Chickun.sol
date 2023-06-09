// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract Chickun is ERC721A, Ownable {
  bool public active = false;
  bool public presale = false;

  string  public baseURI;
  bytes32 public waitlistRoot;

  mapping (address => uint) public waitListMinted;
  mapping (address => uint) public publicMinted;

  uint public maxSupply;

  bool public canOpen = false;
  string public unrevealURI = "https://pin.ski/3nTrNXr";

  constructor () ERC721A("Chickun", "KUN") {
    maxSupply = 2222;
    _safeMint(msg.sender, 222);
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  function setUnrevealURI(string memory _unrevealURI) public onlyOwner {
    unrevealURI = _unrevealURI;
  }

  function setCanOpen(bool _canOpen) public onlyOwner {
    canOpen = _canOpen;
  }

  function setWaitlistRoot(bytes32 _waitlistRoot) public onlyOwner {
    waitlistRoot = _waitlistRoot;
  }

  function setActive(bool _active) public onlyOwner {
    active = _active;
  }

  function setPresale(bool _presale) public onlyOwner {
    presale = _presale;
  }

  function setMaxSupply(uint _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function openWaitListMint() public onlyOwner {
    active = true;
    presale = true;
  }

  function openPublicMint() public onlyOwner{
    active = true;
    presale = false;
  }

  function waitListMint(bytes32[] calldata proof, uint _amount) public {
    require(active && presale, "Contract is not active");
    require(_amount <= 2 && totalSupply() + _amount <= maxSupply, "Exceed max mint number or out of supply");
    require(waitListMinted[msg.sender] + _amount <= 2, "You can only mint two tokens");
    require(MerkleProof.verify(proof, waitlistRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof");

    waitListMinted[msg.sender] += _amount;
    _safeMint(msg.sender, _amount);
  }

  function publicMint(uint _amount) public {
    require(active && !presale, "Contract is not active");
    require(_amount <= 60 && totalSupply() + _amount <= maxSupply, "Exceed max mint number or out of supply");
    require(publicMinted[msg.sender] + _amount <= 60, "You can only mint 60 tokens");

    publicMinted[msg.sender] += _amount;
    _safeMint(msg.sender, _amount);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!canOpen) return unrevealURI;
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
  }
}