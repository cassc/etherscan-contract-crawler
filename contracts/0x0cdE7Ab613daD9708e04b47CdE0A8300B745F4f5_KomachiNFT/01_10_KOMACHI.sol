// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import ".deps/npm/erc721a/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KomachiNFT is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public KOMACHI_SUPPLY = 4444;
  uint256 public KOMACHI_PUBLIC_SUPPLY = 444;
  uint256 public KOMACHI_WHITELIST_SUPPLY = 4000;
  uint256 public KOMACHI_PUBLIC_PRICE = 0.0075 ether;
  uint256 public KOMACHI_WHITELIST_PRICE = 0 ether;
  uint256 public MAX_KOMACHI_PER_TX = 3;
  uint256 public MAX_KOMACHI_PER_WL = 2;
  
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

  function MintWLFree(uint256 _KOMACHIAmount, bytes32[] memory _proof) public payable{
    uint256 mintedKOMACHI = totalSupply();
    require(MintEnabled, "The mint isn't open yet");
    require(_KOMACHIAmount <= MAX_KOMACHI_PER_WL, "Invalid KOMACHI amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!whitelistClaimed[msg.sender]);
    require(MerkleProof.verify(_proof, merkleRoot, leaf)|| whitelist, "Invalid proof!" );
    _mint(msg.sender, _KOMACHIAmount);
    delete mintedKOMACHI;
  }

  function Mint(uint256 _KOMACHIAmount) public payable{
    uint256 mintedKOMACHI = totalSupply();
    require(MintEnabled, "The mint isn't open yet");
    require(_KOMACHIAmount <= MAX_KOMACHI_PER_TX, "Invalid KOMACHI amount");
    require(_KOMACHIAmount + mintedKOMACHI <= KOMACHI_PUBLIC_SUPPLY, "Public supply exceeded");
    require(msg.value >= _KOMACHIAmount * KOMACHI_PUBLIC_PRICE, "Eth Amount Invalid");
    _mint(msg.sender, _KOMACHIAmount);
    delete mintedKOMACHI;
  }


 function MintOnlyAdmin(uint256 _teamAmount) external onlyOwner{
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


  //@dev allows the team reserve a part of the public supply for airdrops
  function setAirdrop(uint256 value) public onlyOwner (){
    uint256 airdrop;
      assembly{
      let tmp := sload(KOMACHI_PUBLIC_SUPPLY.slot)           
      tmp := shr(mul(KOMACHI_PUBLIC_SUPPLY.offset, 256), tmp)     
      airdrop := add(tmp, value)
     }
     KOMACHI_PUBLIC_SUPPLY = airdrop;
  }

  function withdrawBalance() external onlyOwner {
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

}