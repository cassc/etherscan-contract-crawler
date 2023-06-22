// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*
          _____                    _____            _____                    _____                    _____                    _____            _____                    _____                    _____          
         /\    \                  /\    \          /\    \                  /\    \                  /\    \                  /\    \          /\    \                  /\    \                  /\    \         
        /::\    \                /::\____\        /::\    \                /::\____\                /::\    \                /::\____\        /::\    \                /::\    \                /::\    \        
       /::::\    \              /:::/    /       /::::\    \              /:::/    /               /::::\    \              /:::/    /       /::::\    \              /::::\    \              /::::\    \       
      /::::::\    \            /:::/    /       /::::::\    \            /:::/    /               /::::::\    \            /:::/    /       /::::::\    \            /::::::\    \            /::::::\    \      
     /:::/\:::\    \          /:::/    /       /:::/\:::\    \          /:::/    /               /:::/\:::\    \          /:::/    /       /:::/\:::\    \          /:::/\:::\    \          /:::/\:::\    \     
    /:::/__\:::\    \        /:::/    /       /:::/__\:::\    \        /:::/____/               /:::/__\:::\    \        /:::/    /       /:::/__\:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
   /::::\   \:::\    \      /:::/    /       /::::\   \:::\    \      /::::\    \              /::::\   \:::\    \      /:::/    /       /::::\   \:::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
  /::::::\   \:::\    \    /:::/    /       /::::::\   \:::\    \    /::::::\    \   _____    /::::::\   \:::\    \    /:::/    /       /::::::\   \:::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
 /:::/\:::\   \:::\    \  /:::/    /       /:::/\:::\   \:::\____\  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \  /:::/    /       /:::/\:::\   \:::\    \  /:::/\:::\   \:::\ ___\  /\   \:::\   \:::\    \ 
/:::/  \:::\   \:::\____\/:::/____/       /:::/  \:::\   \:::|    |/:::/  \:::\    /::\____\/:::/  \:::\   \:::\____\/:::/____/       /:::/  \:::\   \:::\____\/:::/__\:::\   \:::|    |/::\   \:::\   \:::\____\
\::/    \:::\  /:::/    /\:::\    \       \::/    \:::\  /:::|____|\::/    \:::\  /:::/    /\::/    \:::\  /:::/    /\:::\    \       \::/    \:::\  /:::/    /\:::\   \:::\  /:::|____|\:::\   \:::\   \::/    /
 \/____/ \:::\/:::/    /  \:::\    \       \/_____/\:::\/:::/    /  \/____/ \:::\/:::/    /  \/____/ \:::\/:::/    /  \:::\    \       \/____/ \:::\/:::/    /  \:::\   \:::\/:::/    /  \:::\   \:::\   \/____/ 
          \::::::/    /    \:::\    \               \::::::/    /            \::::::/    /            \::::::/    /    \:::\    \               \::::::/    /    \:::\   \::::::/    /    \:::\   \:::\    \     
           \::::/    /      \:::\    \               \::::/    /              \::::/    /              \::::/    /      \:::\    \               \::::/    /      \:::\   \::::/    /      \:::\   \:::\____\    
           /:::/    /        \:::\    \               \::/____/               /:::/    /               /:::/    /        \:::\    \              /:::/    /        \:::\  /:::/    /        \:::\  /:::/    /    
          /:::/    /          \:::\    \               ~~                    /:::/    /               /:::/    /          \:::\    \            /:::/    /          \:::\/:::/    /          \:::\/:::/    /     
         /:::/    /            \:::\    \                                   /:::/    /               /:::/    /            \:::\    \          /:::/    /            \::::::/    /            \::::::/    /      
        /:::/    /              \:::\____\                                 /:::/    /               /:::/    /              \:::\____\        /:::/    /              \::::/    /              \::::/    /       
        \::/    /                \::/    /                                 \::/    /                \::/    /                \::/    /        \::/    /                \::/____/                \::/    /        
         \/____/                  \/____/                                   \/____/                  \/____/                  \/____/          \/____/                  ~~                       \/____/         
*/                                                                                                                                                                                                                 


import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract Alphalabs is ERC1155, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public MAX_SUPPLY = 777;
 
  uint256 public GIVEAWAY_RESERVED = 50;
    
  uint256 public tokenId = 0;

  string public baseURI = "ipfs://QmSmGhGDGFdF2myKwzEdciHYe8UGLcNMJFPZ3jdSK51Mtg/";

  bool public isWhitelistActive = false;
  bool public isReservedWhitelistActive = false;
  bool public isPublicActive = false;

  uint256 public price = 0.3 ether;

  bytes32 public merkleRootWhitelist;
  bytes32 public merkleRootReservedWhitelist;

  uint256 public minted = 0;
  uint256 public giveawayed = 0;

  mapping(address => bool) public _registeredMintWhitelist;
  mapping(address => bool) public _registeredMintReservedWhitelist;

  mapping(uint256 => bool) private _littleExtra; 

  address[] public _registeredAddresses;
  uint256 public _registerCount = 0;

  constructor() ERC1155(baseURI) {}

  // Accessors

  function setMAX_SUPPLY(uint256 new_supply) public onlyOwner {
      MAX_SUPPLY = new_supply;
  } 

  function setGIVEAWAY_RESERVED(uint256 new_amount) public onlyOwner {
      GIVEAWAY_RESERVED = new_amount;
  }

  function setTokenId(uint256 id) public onlyOwner {
    tokenId = id;
  }

  function setPrice(uint256 new_price) public onlyOwner {
      price = new_price;
  }

  function setWhitelistActive(bool _isActive) public onlyOwner {
    isWhitelistActive = _isActive;
  }

  function setReservedWhitelistActive(bool _isActive) public onlyOwner {
    isReservedWhitelistActive = _isActive;
  }

  function setPublicActive(bool _isActive) public onlyOwner {
    isPublicActive = _isActive;
  }

  function setWhitelistMerkleProof(bytes32 _merkleRoot) public onlyOwner {
    merkleRootWhitelist = _merkleRoot;
  }

  function setReservedWhitelistMerkleProof(bytes32 _merkleRoot) public onlyOwner {
    merkleRootReservedWhitelist = _merkleRoot;
  }

  function totalSupply() public view returns (uint256) {
    return minted + giveawayed;
  }

  function setBonus(uint256 new_bonus) public onlyOwner {
     _littleExtra[new_bonus] = true;
  }

  function alreadyRegistered(address wallet) public view returns (bool) {
    return (_registeredMintWhitelist[wallet] || _registeredMintReservedWhitelist[wallet]);
  }

  // Metadata

  function setURI(string memory new_uri) public onlyOwner {
    _setURI(new_uri);
  }

  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
  }

  // Minting

  function registerWhitelistMint(bytes32[] calldata merkleProof) public payable nonReentrant {
    address sender = _msgSender();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(isWhitelistActive, "Sale is closed");
    require(_registerCount < (MAX_SUPPLY - GIVEAWAY_RESERVED), "MAX Supply reached");
    require(MerkleProof.verify(merkleProof, merkleRootWhitelist, leaf), "Invalid proof");
    require(msg.value == price, "Incorrect payable amount");
    require(!_registeredMintWhitelist[sender], "Already registered");

    _registeredMintWhitelist[sender] = true;
    _registeredAddresses.push(sender);
    _registerCount++;
  }

  function registerReservedWhitelistMint(bytes32[] calldata merkleProof) public payable nonReentrant {
    address sender = _msgSender();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(isReservedWhitelistActive, "Sale is closed");
    require(_registerCount < (MAX_SUPPLY - GIVEAWAY_RESERVED), "MAX Supply reached");
    require(MerkleProof.verify(merkleProof, merkleRootReservedWhitelist, leaf), "Invalid proof");
    require(msg.value == price, "Incorrect payable amount");
    require(!_registeredMintReservedWhitelist[sender], "Already registered");

    _registeredMintReservedWhitelist[sender] = true;
    _registeredAddresses.push(sender);
    _registerCount++;
  }

  function registerPublicMint() public payable nonReentrant {
    address sender = _msgSender();

    require(isPublicActive, "Sale is closed");
    require(_registerCount < (MAX_SUPPLY - GIVEAWAY_RESERVED), "MAX Supply reached");
    require(msg.value == price, "Incorrect payable amount");

    _registeredAddresses.push(sender);
    _registerCount++;
  }

  function minting(uint256 amount) public onlyOwner {
    require(amount + minted + giveawayed <= MAX_SUPPLY, "MAX Supply reached");
    for (uint j = 0; j < amount; j++) {
      uint256 id = tokenId;

      if(_littleExtra[minted + 1]) {
        id = tokenId + 1;
      }

      _internalMint(_registeredAddresses[minted], id);
      minted++;
    }
  }

  function giveaway(address[] memory addresses, bool isExtra) public onlyOwner {
    require(addresses.length + minted + giveawayed <= MAX_SUPPLY, "MAX Supply reached");
    for (uint j = 0; j < addresses.length; j++) {
      uint256 id = tokenId;

      if(isExtra) {
        id = tokenId + 1;
      }

      _internalMint(addresses[j], id);
      giveawayed++;
    }
  }

  function clearArray() public onlyOwner {
    delete _registeredAddresses;
  }

  function cleanWitelistMapping(address add) public onlyOwner {
    _registeredMintWhitelist[add] = false;
  }

  function cleanReservedWitelistMapping(address add) public onlyOwner {
    _registeredMintReservedWhitelist[add] = false;
  }

  function withdraw() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  // Private

  function _internalMint(address to, uint256 token_id) private {
    require(minted + giveawayed < MAX_SUPPLY, "Will exceed maximum supply");
    _mint(to, token_id, 1, "");
  }

}