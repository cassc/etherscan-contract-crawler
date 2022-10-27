// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".deps/npm/erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract EtherealAngels is ERC721A, Ownable, ReentrancyGuard {
  //using Strings for uint256;
  
  uint256 public ANGELS_SUPPLY = 3333;
  uint256 public ANGELS_PUBLIC_SUPPLY = 3000;
  uint256 public ANGELS_WHITELIST_SUPPLY = 333;
  uint256 public ANGELS_PUBLIC_PRICE = 0.02 ether;
  uint256 public ANGELS_WHITELIST_PRICE = 0.01 ether;
  uint256 public MAX_ANGELS_PER_TX = 3;
  
  bool public MintEnabled = false;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public publicClaimed;
  string public uriSuffix = ".json";
  string public baseURI = "";
  bool private whitelist = true;
  
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
  }

  function MintWhitelist(uint256 _angelsAmount, bytes32[] memory _proof) public payable{
    require(MintEnabled, "The gates aren't open yet");
    require(_angelsAmount <= MAX_ANGELS_PER_TX, "Invalid angels amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, merkleRoot, leaf) || whitelist, "Invalid proof!");
    require(msg.value >= _angelsAmount * ANGELS_WHITELIST_PRICE, "Eth Amount Invalid");
    _mint(msg.sender, _angelsAmount);
  }

  function MintPublic(uint256 _angelsAmount) public payable{
    require(MintEnabled, "The gates aren't open yet");
    require(_angelsAmount <= MAX_ANGELS_PER_TX, "Invalid angels amount");
    require(msg.value >= _angelsAmount * ANGELS_PUBLIC_PRICE, "Eth Amount Invalid");
    _mint(msg.sender, _angelsAmount);
  }

  function Airdrop(uint256 _angelsAmount, address toAirdrop) public onlyOwner{
    _mint(toAirdrop, _angelsAmount);
  }


 function adminMint(uint256 _teamAmount) external onlyOwner{
    _mint(msg.sender, _teamAmount);
  }

  function setSet(bool status) public onlyOwner{
    set = status;
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMintEnabled(bool _state) public onlyOwner {
    MintEnabled = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
  }


 function isValid(bytes32[] memory proof) public view returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      return MerkleProof.verify(proof, merkleRoot, leaf);
  }


  function withdrawBalance() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}