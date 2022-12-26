// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".deps/npm/erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MUTATION16 is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public MUTATION_SUPPLY = 2222;
  uint256 public MUTATION_PRICE = 0 ether;
  uint256 public MAX_MUTATION_PER_WL = 3;
  
  bool public MintEnabled = false;

  bytes32 private merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  string public uriSuffix = ".json";
  string public baseURI = "";
  
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
    _mint(msg.sender, 1);
  }

  function MintWhitelist(uint256 _MUTATIONAmount, bytes32[] memory _proof) public payable{
    uint256 mintedMUTATION = totalSupply();
    require(MintEnabled, "The mint isn't open yet");
    require(_MUTATIONAmount <= MAX_MUTATION_PER_WL, "Invalid MUTATION amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!whitelistClaimed[msg.sender]);
    require(MerkleProof.verify(_proof, merkleRoot, leaf)|| whitelist, "Invalid proof!" );
    _mint(msg.sender, _MUTATIONAmount);
    delete mintedMUTATION;
  }


 function adminMint(uint256 _teamAmount) external onlyOwner{
    _mint(msg.sender, _teamAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setWLMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setMintStatus(bool _state) public onlyOwner {
    MintEnabled = _state;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
  }

  function withdrawBalance() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}