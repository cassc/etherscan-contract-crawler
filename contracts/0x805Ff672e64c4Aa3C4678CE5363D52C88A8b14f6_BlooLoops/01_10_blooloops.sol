// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
                                      ..                                                            
                                    #@@@@=                                                          
                               +%@%#@@[email protected]@:                                                         
                              *@@=+%@@* @@@%%%@@@@@%%%##*+=-:                                       
                              [email protected]@@#-.:  -**+=========++*#%@@@@%*=.                                  
                             .+%@@#-                        .-+%@@%=                                
                            [email protected]@%=                               .=%@@+                              
                          .%@@-                                    [email protected]@%:                            
                         [email protected]@%.                                      .#@@:                           
                         %@%                                         .%@@                           
                        [email protected]@:                             :-           :@@+                          
                        @@%                             [email protected]@%.          #@@                          
                       :@@=      .                      [email protected]@@@:         [email protected]@:                         
                       [email protected]@-    -%@@+                    [email protected]@@@@=        [email protected]@-                         
                       [email protected]@@@@@@@@*%@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@=                         
                        --*@@+--   ---=++---------------=+=  :----==*@@*--                          
                          [email protected]@-      .#@@@%-           .#@@@%:       [email protected]@=                            
                          [email protected]@-      %@@@@@@:          %@@@@@@.      [email protected]@=                            
                          [email protected]@-     :@@@@@@@*         [email protected]@@@@@@+      [email protected]@=                            
                         -*@@-     :@@@@@@@*         [email protected]@@@@@@+      [email protected]@*-                           
                       [email protected]@@@@=      @@@@@@@-          @@@@@@@:      [email protected]@@@@+                         
                      [email protected]@[email protected]@+     #@*=--+%@.        %@*=--+%@.     [email protected]@[email protected]@+                        
                      *@@  @@#             .                 .      #@@  @@*                        
  =*#%%%%%#+:         .::. :::                                     .=-: :=-.     @@@@@%#=           
  :*@@@%-*@@@.  [email protected]@@@@=   =******+:  :+******=       #@@@@@:  :#%@@@@# :@@@@%#+  @@@%*%@@% :-=+++=  
   [email protected]@@%.:%@@.  =%@@@@=  [email protected]@@@%@@@%  @@@@%@@@@-      [email protected]@@@@:  #@@*[email protected]@@ [email protected]@@[email protected]@@- @@@+ [email protected]@@[email protected]@@=%@@. 
    @@@@@@@@-    *@@@@-  #@@@= @@@@[email protected]@@% *@@@+       #@@@@:  @@@[email protected]@@.*@@% %@@+ @@@%%@@@% %@@**+=: 
    #@@@@@@@@%+. [email protected]@@@-  %@@@- %@@@:[email protected]@@# [email protected]@@*       #@@@@. [email protected]@@[email protected]@@:*@@@.%@@* %@@@@@@+  :#%%@@@# 
    *@@@*.-*@@@@[email protected]@@@-  *@@@[email protected]@@@ :@@@%-#@@@=       *@@@@. [email protected]@@@@@@@:*@@@@@@@* %@@%+-    -*+=:@@# 
    [email protected]@@% [email protected]@@@[email protected]@@@=:.:@@@@@@@@*  #@@@@@@@%.       [email protected]@@@--.=+*####*.=#####*+: %@@*      [email protected]@@%%#= 
    [email protected]@@@@@@@@*: :+++***:   ...        ....           -+++***.                   +**=       .       
    .====--:.                                                                                                                              
                                                                                                                                                   
*/

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract BlooLoops is ERC721A, IERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public PROVENANCE_HASH;

  uint256 constant MAX_SUPPLY = 8100;
  uint256 private _currentId;

  string public baseURI;
  string private _contractURI;

  enum SaleState {
      Closed,
      BlooList,
      Raffle,
      Public
  }
  SaleState public saleState = SaleState.Closed;

  uint256 public priceBlooList = 0.04 ether;
  uint256 public priceRaffle = 0.05 ether;
  uint256 public pricePublic = 0.06 ether;

  bytes32 public merkleRoot;
  mapping(address => uint256) private _alreadyMinted;

  address public beneficiary;
  address public royalties;
  uint256 public royaltiesFee;

  constructor(
    address _beneficiary,
    address _royalties,
    uint256 _initialRoyaltiesFee,
    string memory _initialBaseURI,
    string memory _initialContractURI
  ) ERC721A("Bloo Loops", "BLOO") {
    beneficiary = _beneficiary;
    royalties = _royalties;
    royaltiesFee = _initialRoyaltiesFee;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;

  }

  // Accessors

  function setProvenanceHash(string calldata hash) public onlyOwner {
    PROVENANCE_HASH = hash;
  }

  function setBeneficiary(address _beneficiary) public onlyOwner {
    beneficiary = _beneficiary;
  }

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }

    function setRoyaltiesFee(uint256 _royaltiesFee) public onlyOwner {
    royaltiesFee = _royaltiesFee;
  }

  function setSaleState(SaleState state) public onlyOwner {
      saleState = state;
  }

  function setMerkleProof(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function alreadyMinted(address addr) public view returns (uint256) {
    return _alreadyMinted[addr];
  }

  // Metadata

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  // Minting

  function mintBlooList(
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  ) public payable nonReentrant {
    address sender = _msgSender();

    require(saleState == SaleState.BlooList, "Sale is closed");
    require(amount <= maxAmount - _alreadyMinted[sender], "Insufficient mints left");
    require(_verify(merkleProof, sender, maxAmount), "Invalid proof");
    require(msg.value == priceBlooList * amount, "Incorrect payable amount");
    
    _alreadyMinted[sender] += amount;
    _internalMint(sender, amount);
  }

  function mintRaffle(
    uint256 amount,
    bytes32[] calldata merkleProof,
    uint256 maxAmount
  ) public payable nonReentrant {
    address sender = _msgSender();

    require(saleState == SaleState.Raffle, "Sale is closed");
    require(amount <= maxAmount - _alreadyMinted[sender], "Insufficient mints left");
    require(_verify(merkleProof, sender, maxAmount), "Invalid proof");
    require(msg.value == priceRaffle * amount, "Incorrect payable amount");

    _alreadyMinted[sender] += amount;
    _internalMint(sender, amount);
  }

  function mintPublic(
    uint256 amount
  ) public payable nonReentrant {
    address sender = _msgSender();

    require(saleState == SaleState.Public, "Sale is closed");
    require(msg.value == pricePublic * amount, "Incorrect payable amount");

    _internalMint(sender, amount);
  }

  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount);
  }

  function withdraw() public onlyOwner {
    payable(beneficiary).transfer(address(this).balance);
  }

  // Private

  function _internalMint(address to, uint256 amount) private {
    require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");
    _safeMint(to, amount);
  }

  function _verify(
    bytes32[] calldata merkleProof,
    address sender,
    uint256 maxAmount
  ) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount.toString()));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  // ERC721A

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  // ERC165

  function supportsInterface(bytes4 interfaceId) public view override(ERC721A, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC2981

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId; // silence solc warning
    royaltyAmount = (_salePrice / 1000) * royaltiesFee;
    return (royalties, royaltyAmount);
  }
}