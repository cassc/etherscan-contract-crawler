// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

  
//                    @@@@@@@@@@@@@@@@@@@                    
//                 @@@@@@             @@@@@@                 
//              @@@@@                     @@@@              
//            @@@@                          @@@@             
//           @@@@                             @@@@           
//          @@@@             @@@@@             @@@@         
//          @@@           @@@@@@@@@@@           @@@         
//          @@@         @@@         @@@         @@@         
//          @@@        @@@    @@@@   @@@        @@@         
//          @@@        @@@   @@@@@@  @@@        @@@         
//          @@@        @@@    @@@@   @@@        @@@          
//          @@@          @@@        @@@         @@@         
//          @@@           @@@@@@@@@@@           @@@        
//          @@@               @@@@              @@@        
//          @@@                                 @@@         
//          @@@                                 @@@         
// 


abstract contract MintableInterface {
    function mintTransfer(address to) public payable virtual;
}

contract Sorce is ERC721A, Ownable, ReentrancyGuard {
  constructor()  ERC721A("CULTIVATE - SORCE VIAL [POWERED]", "SORCE") {
  }
  
  string _baseTokenURI = "ipfs://QmeNKZ5sEhWXsgauRMkjo9ER4t7B5W7U4jdFfKEAoQaLL8";
  address private _bankWallet;

  bool private _saleOpened = false;
  bool migrationStarted = false;

  address dr1verContractAddress;

  mapping(address => uint256) private mintList;
  address[] private mintAddresses;

  struct Cult1vator {
      address addr;
      uint amount;
  }

  function toggleMigration() public onlyOwner {
        migrationStarted = !migrationStarted;
  }

  function toggleSaleState() public onlyOwner {
    _saleOpened = !_saleOpened;
  }

  bytes32 public merkleRoot = 0x443fe2a89c1738953911c5e699a2ae87fef212cd7ee77df8185854d141ec8812;

  function _verifyClaim(
    address who,
    uint16 allocation,
    bytes32[] memory merkleProof
  ) internal view returns (bool) {
      bytes32 node = keccak256(abi.encodePacked(who, allocation));
      return MerkleProof.verify(merkleProof, merkleRoot, node);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
      _baseTokenURI = baseURI;
  }

  function setMerkleRoot(bytes32 root) external onlyOwner {
      merkleRoot = root;
  }

  function setDr1verContract(address contractAddress) public onlyOwner {
      dr1verContractAddress = contractAddress;
  }

  function allowlistMint(uint16 quantity, bytes32[] calldata merkleProof, uint16 allocation) external {
    address sender = _msgSenderERC721A();
    require(tx.origin == sender, "KD: We like real users");
    require(_saleOpened, "KD: allowlist sale has not begun yet");
    require(mintList[sender] + quantity <= allocation, "KD: not allowed to mint that much");
    require(_verifyClaim(sender, allocation, merkleProof));
    _mint(sender, quantity);
    mintList[sender] += quantity;
    mintAddresses.push(sender);
  }

  function batchMigration(uint256[] memory tokenIds) public payable  {
    for(uint256 i=0; i < tokenIds.length; i++){
      migrateToken(tokenIds[i]);
    }
  }

  function migrateToken(uint256 tokenId) public payable  {
      require(migrationStarted == true, "Migration has not started");
      require(balanceOf(_msgSenderERC721A()) > 0, "Doesn't own the token"); // Check if the user own one of the sorce
      require(ownerOf(tokenId) == _msgSenderERC721A(), "Doesn't own the token");
      _burn(tokenId); // Burn the Sorce
      MintableInterface dr1verContract = MintableInterface(dr1verContractAddress);
      dr1verContract.mintTransfer{value:msg.value}(_msgSenderERC721A()); // Mint the Dr1ver
  }

  function airdrop(address to, uint256 quantity) public onlyOwner {
      _mint(to, quantity);
  }

  /*
   ** Retrieve the funds of the sale
   */
  function retrieveFunds() external nonReentrant {
    // Only the Bank Wallet or the owner can withraw the funds
    require(_msgSenderERC721A() == _bankWallet || _msgSenderERC721A() == owner(), "Not allowed");
    uint256 balance = address(this).balance;
    (bool success, ) = _bankWallet.call{value: balance}("");
    require(success, "TRANSFER_FAIL");
  }

  /**
   *  Set the address of the bank
   */
  function setBankWallet(address addr) external onlyOwner nonReentrant {
    require(addr != address(0), "Invalid address");
    _bankWallet = addr;
  }

  function getMintList() public view returns (Cult1vator[] memory){
    Cult1vator[] memory map = new Cult1vator[](mintAddresses.length);
    for (uint j = 0; j < mintAddresses.length; j++) {
        map[j] = Cult1vator(mintAddresses[j], mintList[mintAddresses[j]]);
    }
    return map;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
  }
}