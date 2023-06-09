// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

//            @   @                      
//          @@@   @@@                    
//        @@@@@   @@@@@                  
//      @@@@@       @@@@@                
//     @@@@           @@@@               
//   @@@@               @@@@             
//     @      OASIS      @               
//  @@@     AWAKENING     @@@            
//  @@@                   @@@            
//  @@@@                 @@@@            
//   @@@@@             @@@@@             
//     @@@@@@@@   @@@@@@@@               
//         @@@@@@@@@@@                   

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";

contract OasisAwakening is Ownable, ERC721A, ReentrancyGuard {
  
  uint256 public constant maxSupply = 369;
  
  uint256 private mintPrice = 0.17 ether;
  
  string private _baseTokenURI;

  mapping(address => bool) private allowlist;
  mapping(address => uint8) private backupAllowlist;

  enum SaleState {
    NotStarted,       //0
    Allowlist,        //1
    BackupAllowlist,  //2
    Public            //3
  }

  SaleState private saleState = SaleState.NotStarted;
  
  constructor() ERC721A("Oasis Awakening", "OA") {}

  function mint(uint8 quantity) external payable nonReentrant {
    require(totalSupply() + quantity <= maxSupply, "reached max supply");
    require(saleState != SaleState.NotStarted, "The sale has not started yet");
    require(msg.value >= mintPrice * quantity, "not enough funds.");
    require(tx.origin == msg.sender, "The caller is another contract");

    if (saleState == SaleState.Allowlist) {
      require(allowlist[msg.sender], "You are not on the allowlist");
      require(quantity == 1, "You can only mint one");
      require(_numberMinted(msg.sender) == 0, "You already minted one");
    } 
    else if (saleState == SaleState.BackupAllowlist) {
      require(backupAllowlist[msg.sender] - quantity >= 0, "You are not on the allowlist or reached your limit");
      backupAllowlist[msg.sender] = backupAllowlist[msg.sender] - quantity;
    } 
    else {
        require(saleState == SaleState.Public, "public sale is not active");
    }

    _mint(msg.sender, quantity);
  }

  function seedAllowlist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = true;
    }
  }

  function seedBackupAllowlist(address[] memory addresses) external onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      backupAllowlist[addresses[i]] = 10;
    }
  }

  function isAllowlisted(address owner) public view returns (bool) {
    return allowlist[owner];
  }

  function isBackupAllowlisted(address owner) public view returns (bool) {
    return backupAllowlist[owner] > 0;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  //Reserve tokens for community wallet 
  function reserve(uint256 n) public onlyOwner {
    require(totalSupply() + n <= maxSupply, "reached max supply");
    _mint(msg.sender, n);
  }

  function setSalePrice(uint256 _price) external onlyOwner {
    mintPrice = _price;
  }

  function setSaleState(SaleState _state) external onlyOwner {
    saleState = _state;
  }

  function getSaleState() public view returns (SaleState) {
    return saleState;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function ownershipOf(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
}