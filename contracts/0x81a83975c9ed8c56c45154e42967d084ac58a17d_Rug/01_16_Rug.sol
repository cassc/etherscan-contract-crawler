// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Rug is ERC721AQueryable, Ownable, ReentrancyGuard {
  using Strings for uint256;
  
  uint256 public PUBLIC_RUGS = 4555;
  uint256 public RUG_PRICE = 0 ether;
  uint256 public MAX_PUBLIC_PLUS_ADMIN_RUGS = 5555;
  uint256 public MAX_RUGS_PER_TX = 1;
  
  bool public publicMintEnabled = false;
  bool public whitelistMintEnabled = false;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public publicClaimed;
  string public uriSuffix = ".json";
  string public baseURI = "";
  
  
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {
  }

  function MintWhitelist(uint256 _rugAmount, bytes32[] memory _proof) public payable{
    uint256 TOTALRUGS = totalSupply();
    require(whitelistMintEnabled, "The whitelist sale is not rugged yet!");
    require(TOTALRUGS + _rugAmount <= PUBLIC_RUGS, "RUG supply exceeded");
    require(!whitelistClaimed[_msgSender()], "Address already rugged!");
    require(_rugAmount == MAX_RUGS_PER_TX, "Invalid rug amount");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_proof, merkleRoot, leaf), "Invalid proof!");
    whitelistClaimed[msg.sender] = true;
    _mint(msg.sender, _rugAmount);
    delete TOTALRUGS;
  }

  function MintPublic(uint256 _rugAmount) public payable{
    uint256 TOTALRUGS = totalSupply();
    require(publicMintEnabled, "The public sale is not rugged yet!");
    require(TOTALRUGS + _rugAmount <= PUBLIC_RUGS, "RUG supply exceeded");
    require(!publicClaimed[msg.sender], "Address already rugged!");
    require(_rugAmount == 1, "Invalid rug amount");
    publicClaimed[msg.sender] = true;
    _safeMint(msg.sender, _rugAmount);
    delete TOTALRUGS;
  }


 function adminMint(uint256 _teamAmount) external ownerMint{
    require(totalSupply() + _teamAmount <= MAX_PUBLIC_PLUS_ADMIN_RUGS, "Max supply exceeded!");
    _mint(msg.sender, _teamAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function setPublicMintEnabled(bool _state) public onlyOwner {
    publicMintEnabled = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
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