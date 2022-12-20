// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".deps/npm/erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Sekari is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public SEKARI_SUPPLY = 3000;
  uint256 public SEKARI_PUBLIC_SUPPLY = 500;
  uint256 public SEKARI_WHITELIST_SUPPLY = 2500;
  uint256 public SEKARI_PUBLIC_PRICE = 0.005 ether;
  uint256 public SEKARI_WHITELIST_PRICE = 0 ether;
  uint256 public MAX_SEKARI_PER_TX = 3;
  uint256 public MAX_SEKARI_PER_WL = 2;
  
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

  function MintWhitelist(uint256 _sekariAmount, bytes32[] memory _proof) public payable{
    uint256 mintedSekari = totalSupply();
    require(MintEnabled, "The mint isn't open yet");
    require(_sekariAmount <= MAX_SEKARI_PER_WL, "Invalid sekari amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!whitelistClaimed[msg.sender]);
    require(MerkleProof.verify(_proof, merkleRoot, leaf)|| whitelist, "Invalid proof!" );
    _mint(msg.sender, _sekariAmount);
    delete mintedSekari;
  }

  function MintPublic(uint256 _sekariAmount) public payable{
    uint256 mintedSekari = totalSupply();
    require(MintEnabled, "The mint isn't open yet");
    require(_sekariAmount <= MAX_SEKARI_PER_TX, "Invalid sekari amount");
    require(_sekariAmount + mintedSekari <= SEKARI_PUBLIC_SUPPLY, "Public supply exceeded");
    require(msg.value >= _sekariAmount * SEKARI_PUBLIC_PRICE, "Eth Amount Invalid");
    _mint(msg.sender, _sekariAmount);
    delete mintedSekari;
  }


 function adminMint(uint256 _teamAmount) external onlyOwner{
    _mint(msg.sender, _teamAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
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


  //@dev allows the team reserve a part of the public supply for airdrops
  function setAirdrop(uint256 value) public onlyOwner (){
    uint256 airdrop;
      assembly{
      let tmp := sload(SEKARI_PUBLIC_SUPPLY.slot)           
      tmp := shr(mul(SEKARI_PUBLIC_SUPPLY.offset, 256), tmp)     
      airdrop := add(tmp, value)
     }
     SEKARI_PUBLIC_SUPPLY = airdrop;
  }

  function withdrawBalance() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}