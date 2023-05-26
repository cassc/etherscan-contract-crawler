/*


@@@@@@@@@@   @@@@@@@@  @@@@@@@   @@@@@@   @@@  @@@   @@@@@@      @@@  @@@  @@@   @@@@@@   @@@@@@@    @@@@@@   
@@@@@@@@@@@  @@@@@@@@  @@@@@@@  @@@@@@@@  @@@  @@@  @@@@@@@@     @@@  @@@  @@@  @@@@@@@@  @@@@@@@@  @@@@@@@   
@@! @@! @@!  @@!         @@!    @@!  @@@  @@!  [email protected]@  @@!  @@@     @@!  @@!  @@!  @@!  @@@  @@!  @@@  [email protected]@       
[email protected]! [email protected]! [email protected]!  [email protected]!         [email protected]!    [email protected]!  @[email protected]  [email protected]!  @!!  [email protected]!  @[email protected]     [email protected]!  [email protected]!  [email protected]!  [email protected]!  @[email protected]  [email protected]!  @[email protected]  [email protected]!       
@!! [email protected] @[email protected]  @!!!:!      @!!    @[email protected][email protected][email protected]!  @[email protected]@[email protected]!   @[email protected][email protected][email protected]!     @!!  [email protected]  @[email protected]  @[email protected][email protected][email protected]!  @[email protected][email protected]!   [email protected]@!!    
[email protected]!   ! [email protected]!  !!!!!:      !!!    [email protected]!!!!  [email protected]!!!    [email protected]!!!!     [email protected]!  !!!  [email protected]!  [email protected]!!!!  [email protected][email protected]!     [email protected]!!!   
!!:     !!:  !!:         !!:    !!:  !!!  !!: :!!   !!:  !!!     !!:  !!:  !!:  !!:  !!!  !!: :!!        !:!  
:!:     :!:  :!:         :!:    :!:  !:!  :!:  !:!  :!:  !:!     :!:  :!:  :!:  :!:  !:!  :!:  !:!      !:!   
:::     ::    :: ::::     ::    ::   :::   ::  :::  ::   :::      :::: :: :::   ::   :::  ::   :::  :::: ::   
 :      :    : :: ::      :      :   : :   :   :::   :   : :       :: :  : :     :   : :   :   : :  :: : : 

   
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetakaWars is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;
  
  event BaseURIChanged(string newBaseURI);
  event Minted(address minter, uint256 amount);
  event Withdraw(address indexed account, uint256 amount);

  uint256 public MAX_SUPPLY = 3333;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedURI = "ipfs://QmVck5kbCL3Pwh2oZXconJNjg2tbd6VryygabaKpzDUSUG/";
  address private withdrawAddress = 0xD16482199f418d61C3b0314Cd19347c32A4A1f5b;
  
  uint256 public mintPrice = 0.06 ether;
  uint256 public pubPrice = 0.08 ether;
  uint256 public perAddressLimit = 1;

  bool public paused = false;
  bool public revealed = false;
  bool public onlyWhiteList = true;

  bytes32 public merkleRoot;
  
  mapping(address => uint256) private _alreadyMinted;

  constructor(string memory _initBaseURI) ERC721A("Metaka Wars", "METAKA") {
    setBaseURI(_initBaseURI);
  }

  // Accessors
  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function reveal() public onlyOwner {
      revealed = true;
  }

  function setMerkleRoot(bytes32 _root) public onlyOwner {
    merkleRoot = _root;
  }

  function setMintPrice(uint256 _newMintPrice) public onlyOwner {
    mintPrice = _newMintPrice;
  }

  function setPubPrice(uint256 _newPubPrice) public onlyOwner {
    pubPrice = _newPubPrice;
  }

  function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
    withdrawAddress = _withdrawAddress;
  }

  function setPerAddressLimit(uint256 _limit) public onlyOwner {
    perAddressLimit = _limit;
  }

  function setOnlyWhite(bool _onlyWhite) public onlyOwner {
    onlyWhiteList = _onlyWhite;
  }

  // Metadata
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    MAX_SUPPLY = _maxSupply;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIChanged(_newBaseURI);
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");
    if(revealed == false) {
        return string(abi.encodePacked(notRevealedURI, tokenId.toString(), baseExtension));
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // Mint
  function whiteListMint(bytes32[] calldata _merkleProof, uint256 quantity) public payable nonReentrant {
    require(quantity <= perAddressLimit, "Max mint number per address exceeded");
    require(_verify(_merkleProof), "User is not whitelisted");
    require(_alreadyMinted[msg.sender] < perAddressLimit, "Max minted NFT per address exceeded");
    require(msg.value >= mintPrice * quantity, "insufficient funds");
    _internalMint(msg.sender, quantity);
    _alreadyMinted[msg.sender] += quantity;
    emit Minted(msg.sender, mintPrice * quantity);
  }

  function ownerMint(uint256 quantity) public payable onlyOwner {
    _internalMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) public payable nonReentrant {
    require(quantity <= perAddressLimit, "Max mint number per address exceeded");
    require(!onlyWhiteList, "Not open for sale");
    require(_alreadyMinted[msg.sender] < perAddressLimit, "Max minted NFT per address exceeded");
    require(msg.value >= pubPrice * quantity, "insufficient funds");
    _internalMint(msg.sender, quantity);
    _alreadyMinted[msg.sender] += quantity;
    emit Minted(msg.sender, pubPrice * quantity);
  }

  function _internalMint(address to, uint256 quantity) private {
    require(!paused, "Sale is closed");
    uint256 supply = totalSupply();
    require(supply + quantity <= MAX_SUPPLY, "max NFT limit exceeded");
    _mint(to, quantity);
  }

  function _verify(bytes32[] calldata _merkleProof) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  // Withdraw
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool os, ) = withdrawAddress.call{value: balance}("");
    require(os, "Withdraw Failed");
    emit Withdraw(withdrawAddress, balance);
  }
}