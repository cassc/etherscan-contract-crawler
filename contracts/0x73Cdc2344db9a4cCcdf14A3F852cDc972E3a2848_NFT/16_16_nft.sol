// SPDX-License-Identifier: MIT
//      _    _                    __        __         _     _ 
//     / \  | |__  _   _ ___ ___  \ \      / /__  _ __| | __| |
//    / _ \ | '_ \| | | / __/ __|  \ \ /\ / / _ \| '__| |/ _` |
//   / ___ \| |_) | |_| \__ \__ \   \ V  V / (_) | |  | | (_| |
//  /_/   \_\_.__/ \__, |___/___/    \_/\_/ \___/|_|  |_|\__,_|
//                 |___/                                       

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';


contract NFT is ERC721, PullPayment, Ownable, ReentrancyGuard {

  // Counter
  uint256 public spTokenId = 1;
  uint256 public ssrTokenId = 64;
  uint256 public srTokenId = 356;
  uint256 public rTokenId = 938;

  // Sale time
  uint256 public firstsalestart;

  // Merkle tree
  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistused; 
  mapping(address => uint256) public mintedNFTs; 

  // Mint Price
  uint256 public constant rMintPrice = 0.2 ether;
  uint256 public constant srMintPrice = 0.4 ether;
  uint256 public constant ssrMintPrice = 0.8 ether;
  uint256 public constant spMintPrice = 2.5 ether;
  uint256 public constant rMintPriceDiscount = 0.14 ether;
  uint256 public constant srMintPriceDiscount = 0.28 ether;
  uint256 public constant ssrMintPriceDiscount = 0.56 ether;

  // Event 
  event MetadataUpdate(uint256 _tokenId);
  event MaxNFTsReached(address user);

  // Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

  constructor() ERC721("Gazer", "GZ") {
    baseTokenURI = "";
    merkleRoot = "";
  }

  // Change merkle root hash
  function setMerkleRoot(bytes32 merkleRootHash) external onlyOwner{
    merkleRoot = merkleRootHash;
  }

  function mintTo(address[] memory addresses, uint256[] memory tokenIds) public onlyOwner returns (uint256) {
    for (uint256 i = 0; i < addresses.length; i++) {
      _safeMint(addresses[i], tokenIds[i]);
    }
    return tokenIds[0];
  }

  function airdrop(address[] memory addresses, uint256 level) public onlyOwner returns (uint256) {
    if(level == 1){
      for (uint256 i = 0; i < addresses.length; i++) {
        uint256 currentTokenId = spTokenId;
        require(currentTokenId < 64, "Maximum SP quantity reached") ;
        spTokenId++;
        _safeMint(addresses[i], currentTokenId);
      }
    }
    else if(level == 2){
      for (uint256 i = 0; i < addresses.length; i++) {
        uint256 currentTokenId = ssrTokenId;
        require(currentTokenId >= 64 && currentTokenId < 356, "Maximum SSR quantity reached");
        ssrTokenId++;
        _safeMint(addresses[i], currentTokenId);
      }
    }
    else if(level == 3){
      for (uint256 i = 0; i < addresses.length; i++) {
        uint256 currentTokenId = srTokenId;
        require(currentTokenId >= 356 && currentTokenId < 938, "Maximum SR quantity reached");
        srTokenId++;
        _safeMint(addresses[i], currentTokenId);
      }
    }
    else if(level == 4){
      for (uint256 i = 0; i < addresses.length; i++) {
        uint256 currentTokenId = rTokenId;
        require(currentTokenId >= 938 && currentTokenId <= 2100, "Maximum R quantity reached");
        rTokenId++;
        _safeMint(addresses[i], currentTokenId);
      }
    }
    else{
      revert();
    }
    return level;
  }

  function mintSP() public onlyOwner payable returns (uint256){
    uint256 currentTokenId = spTokenId;
    require(currentTokenId < 64, "Maximum SP quantity reached") ;
    require(msg.value >= spMintPrice, "Transaction value did not equal the mint price");
    spTokenId++;
    _safeMint(msg.sender, currentTokenId);
    _asyncTransfer(owner(), msg.value);
    return currentTokenId;
  }

  function mintSSR(bytes32[] calldata merkleProof) public payable nonReentrant returns (uint256) {
    uint256 currentTokenId = ssrTokenId;
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    bool iswhitelisted = MerkleProof.verify(merkleProof, merkleRoot, leaf);
    require(currentTokenId >= 64 && currentTokenId < 356, "Maximum SSR quantity reached");
    require(mintedNFTs[msg.sender] < 3, "You already own 3 NFTs");
    if (iswhitelisted && whitelistused[msg.sender] == false && block.timestamp <=  firstsalestart  + 3 days) {
      require(msg.value >= ssrMintPriceDiscount, "Transaction value did not equal the mint price");
      whitelistused[msg.sender] = true;
      mintedNFTs[msg.sender]++;
      ssrTokenId++;
      _safeMint(msg.sender, currentTokenId);
      _asyncTransfer(owner(), msg.value);
      return currentTokenId;
    }
    else if ((block.timestamp >=  firstsalestart  + 1 days) && (block.timestamp <=  firstsalestart  + 5 days)) { 
      require(msg.value >= ssrMintPrice, "Transaction value did not equal the mint price");
      mintedNFTs[msg.sender]++;
      ssrTokenId++;
      _safeMint(msg.sender, currentTokenId);
      _asyncTransfer(owner(), msg.value);
      return currentTokenId;
    }
    else{
      revert();
    }
  }

  function mintSR(bytes32[] calldata merkleProof) public payable nonReentrant returns (uint256) {
    uint256 currentTokenId = srTokenId;
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    bool iswhitelisted = MerkleProof.verify(merkleProof, merkleRoot, leaf);
    require(currentTokenId >= 356 && currentTokenId < 938, "Maximum SR quantity reached");
    require(mintedNFTs[msg.sender] < 3, "You already own 3 NFTs");
    if (iswhitelisted && whitelistused[msg.sender] == false && block.timestamp <=  firstsalestart  + 3 days) {
      require(msg.value >= srMintPriceDiscount, "Transaction value did not equal the mint price");
      whitelistused[msg.sender] = true;
      mintedNFTs[msg.sender]++;
      srTokenId++;
      _safeMint(msg.sender, currentTokenId);
      _asyncTransfer(owner(), msg.value);
      return currentTokenId;
    }
    else if ((block.timestamp >=  firstsalestart  + 1 days) && (block.timestamp <=  firstsalestart  + 5 days)) { 
      require(msg.value >= srMintPrice, "Transaction value did not equal the mint price");
      mintedNFTs[msg.sender]++;
      srTokenId++;
      _safeMint(msg.sender, currentTokenId);
      _asyncTransfer(owner(), msg.value);
      return currentTokenId;
    }
    else{
      revert();
    }
  }

  function mintR(bytes32[] calldata merkleProof) public payable nonReentrant returns (uint256) {
    uint256 currentTokenId = rTokenId;
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    bool iswhitelisted = MerkleProof.verify(merkleProof, merkleRoot, leaf);
    require(currentTokenId >= 938 && currentTokenId <= 2100, "Maximum R quantity reached");
    require(mintedNFTs[msg.sender] < 3, "You already own 3 NFTs");
    if (iswhitelisted && whitelistused[msg.sender] == false && block.timestamp <=  firstsalestart  + 3 days) {
      require(msg.value >= rMintPriceDiscount, "Transaction value did not equal the mint price");
      whitelistused[msg.sender] = true;
      mintedNFTs[msg.sender]++;
      rTokenId++;
      _safeMint(msg.sender, currentTokenId);
      _asyncTransfer(owner(), msg.value);
      return currentTokenId;
    }
    else if ((block.timestamp >=  firstsalestart  + 1 days) && (block.timestamp <=  firstsalestart  + 5 days)) {
      require(msg.value >= rMintPrice, "Transaction value did not equal the mint price");
      mintedNFTs[msg.sender]++;
      rTokenId++;
      _safeMint(msg.sender, currentTokenId);
      _asyncTransfer(owner(), msg.value);
      return currentTokenId;
    }
    else{
      revert();
    }
  }

  // Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  // Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
    emit MetadataUpdate(type(uint256).max);
  }

  // Overridden in order to make it an onlyOwner function
  function withdrawPayments(address payable payee) public override onlyOwner virtual {
    super.withdrawPayments(payee);
  }

  // Sets start time
  function setSaleStartTime(uint32 timestamp) external onlyOwner {
    firstsalestart = timestamp; 
  }
}