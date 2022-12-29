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

  uint256 public KOMACHI_TOTAL_SUPPLY = 4444;
  uint256 public KOMACHI_PUBLIC_SUPPLY = 444;
  uint256 public KOMACHI_WHITELIST_SUPPLY = 4000;
  uint256 public KOMACHI_PUBLIC_PRICE = 0.0075 ether; 
  uint256 public MAX_KOMACHI_PER_PUBLIC = 3;
  uint256 public MAX_KOMACHI_PER_WL = 2;
  
  bool public PublicMintEnabled = false;
  bool public WhitelistMintEnabled = false;

  bytes32 private merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public publicClaimed;
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
    require(WhitelistMintEnabled, "The mint isn't open yet");
    require(_KOMACHIAmount <= MAX_KOMACHI_PER_WL, "Invalid KOMACHI amount");
    require(mintedKOMACHI + _KOMACHIAmount <= KOMACHI_WHITELIST_SUPPLY, "Supply exceeded");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(!whitelistClaimed[msg.sender], "Whitelist already minted");
    require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!" );
    _mint(msg.sender, _KOMACHIAmount);
    whitelistClaimed[msg.sender] = true;
    delete mintedKOMACHI;
  }

  function PublicMint(uint256 _KOMACHIAmount) public payable{
    uint256 mintedKOMACHI = totalSupply();
    require(PublicMintEnabled, "The mint isn't open yet");
    require(!publicClaimed[msg.sender], "Address already minted");
    require(_KOMACHIAmount <= MAX_KOMACHI_PER_PUBLIC, "Invalid KOMACHI amount");
    require(_KOMACHIAmount + mintedKOMACHI <= KOMACHI_PUBLIC_SUPPLY, "Public supply exceeded");
    require(msg.value >= _KOMACHIAmount * KOMACHI_PUBLIC_PRICE, "Eth Amount Invalid");
    _mint(msg.sender, _KOMACHIAmount);
    publicClaimed[msg.sender] = true;
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

  function setWhitelistintStatus(bool _state) public onlyOwner {
    WhitelistMintEnabled = _state;
  }

  function setPublicMintStatus(bool _state) public onlyOwner {
    PublicMintEnabled = _state;
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