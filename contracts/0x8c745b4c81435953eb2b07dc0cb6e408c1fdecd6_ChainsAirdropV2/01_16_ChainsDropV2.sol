//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

//       ___          ___          ___                     ___          ___                   ___          ___       ___
//      /\  \        /\__\        /\  \         ___       /\__\        /\  \                 /\__\        /\  \     /\  \
//     /::\  \      /:/  /       /::\  \       /\  \     /::|  |      /::\  \               /::|  |      /::\  \    \:\  \
//    /:/\:\  \    /:/__/       /:/\:\  \      \:\  \   /:|:|  |     /:/\ \  \             /:|:|  |     /:/\:\  \    \:\  \
//   /:/  \:\  \  /::\  \ ___  /::\~\:\  \     /::\__\ /:/|:|  |__  _\:\~\ \  \           /:/|:|  |__  /::\~\:\  \   /::\  \
//  /:/__/ \:\__\/:/\:\  /\__\/:/\:\ \:\__\ __/:/\/__//:/ |:| /\__\/\ \:\ \ \__\         /:/ |:| /\__\/:/\:\ \:\__\ /:/\:\__\
//  \:\  \  \/__/\/__\:\/:/  /\/__\:\/:/  //\/:/  /   \/__|:|/:/  /\:\ \:\ \/__/         \/__|:|/:/  /\/__\:\ \/__//:/  \/__/
//   \:\  \           \::/  /      \::/  / \::/__/        |:/:/  /  \:\ \:\__\               |:/:/  /      \:\__\ /:/  /
//    \:\  \          /:/  /       /:/  /   \:\__\        |::/  /    \:\/:/  /               |::/  /        \/__/ \/__/
//     \:\__\        /:/  /       /:/  /     \/__/        /:/  /      \::/  /                /:/  /
//      \/__/        \/__/        \/__/                   \/__/        \/__/                 \/__/




// This is a free claimable "airdrop" contract that allows holders at the time of a snapshot to claim the level of their holdings plus everything below it.
contract ChainsAirdropV2 is ERC1155, Ownable {
  using ECDSA for bytes32;

  
  //Price
  uint public price = 25000000000000000;

  

  uint private constant LEGENDARY = 1;
  uint private constant MEGADIAMONDWHALE = 2;
  uint private constant MEGADIAMONDRING = 3;
  uint private constant DIAMONDRING = 4;
  uint private constant DIAMONDINGOT = 5;
  uint private constant PLATINUMRING =6;
  uint private constant PLATINUMINGOT = 7;
  uint private constant GOLDCHAINRING = 8;
  uint private constant GOLDETHRING = 9;
  uint private constant BASE = 10;
  uint private constant PUBLICFREE = 11;
  uint private constant PUBLICPAID = 12;

  bool public mintEnabled;

  // The address of the private key that signs a combination of the address and amount of Chains held as signatures for the mint.
  // NOTE: Always ensure you update your private key environment variable between testnet and mainnet deploys.
  address public systemAddress;

  // Tracks if the airdrop recipient has claimed.
  mapping(address => bool) public hasMinted;
   //wallet
   address public a1 = 0x1c29Fed7470938f31d21eaCcB89Ecea1D779684F;

  // Constructor

  constructor(address _systemAddress) ERC1155("https://gateway.pinata.cloud/ipfs/QmegySvHM3NqxaGKKZTpFVfo5LYc3pydfYnzZ37aDgRGhD/{id}") {
    systemAddress = _systemAddress;
  }

  // Mint Function

  /// @notice This function can only be called from the aidrop site and will fail if you attempt to call it from Etherscan since it requires the `_signature` parameter.
  function mint(uint256 _ownerCount, bool _megadiamondWhale,bool _diamondRing, bool _goldChain, bool _platinumRing, bytes calldata _signature) external {
    require(mintEnabled, "Mint disabled");
    require(!hasMinted[msg.sender], "Already minted");
    hasMinted[msg.sender] = true;

    // On the server, we send in a signature comprising of the msg.sender and the amount the address held at the time of the snapshot.
    require(isValidSignature(keccak256(abi.encodePacked(msg.sender, _ownerCount)), _signature), "Invalid signature");



    if (_ownerCount > 48) {
      mintLegendary(_diamondRing, _platinumRing,_megadiamondWhale, _goldChain);
    }else if (_ownerCount > 10 && _ownerCount < 31) {
      mintMegaDiamond(_diamondRing, _platinumRing,_megadiamondWhale, _goldChain);

    } else if (_ownerCount > 6 &&_ownerCount < 11 ) {
      mintDiamond(_goldChain,_platinumRing,_diamondRing);

    } else if (_ownerCount <= 6) {
      mintPlatinum(_goldChain,_platinumRing);

    } else if (_ownerCount <= 3 ) {
      mintGold(_goldChain);

    } else {
      mintBase();
    }
  }
 function PublicMint( uint _amount) external payable {
        require(mintEnabled, "Mint disabled");
        require(price * _amount == msg.value, "Wrong ETH amount");
                 
        _mint(msg.sender, PUBLICPAID, _amount, "");
    

   }

   function PublicFree(uint _amount) external payable {
    require(mintEnabled, "Mint disabled");
    require(!hasMinted[msg.sender], "Already minted");
    hasMinted[msg.sender] = true;
     _mint(msg.sender, PUBLICFREE, _amount, "");
      
       
    

   }
  // Private Functions
  function mintLegendary( bool _megadiamondWhale,bool _diamondRing, bool _goldChain, bool _platinumRing) private {
    mint(LEGENDARY);
    mint(_megadiamondWhale ? MEGADIAMONDWHALE :  MEGADIAMONDRING);
    mint(_diamondRing ? DIAMONDRING : DIAMONDINGOT );
    mint(_platinumRing ? PLATINUMRING : PLATINUMINGOT);
    mint(_goldChain ? GOLDCHAINRING :  GOLDETHRING);
    mint(BASE);
     
  }


  function mintMegaDiamond(bool megadiamondWhale,bool _diamondRing, bool _goldChain, bool _platinumIngot) private {
    mint(megadiamondWhale ? MEGADIAMONDWHALE :  MEGADIAMONDRING);
    mint(_diamondRing ? DIAMONDRING : DIAMONDINGOT );
    mint(_platinumIngot ? PLATINUMRING : PLATINUMINGOT);
    mint(_goldChain ? GOLDCHAINRING :  GOLDETHRING);
    mint(BASE);
  }

  function mintDiamond(bool _diamondRing, bool _goldChain, bool _platinumRing) private {
    mint(_diamondRing ? DIAMONDRING : DIAMONDINGOT );
    mint(_platinumRing ? PLATINUMRING : PLATINUMINGOT);
    mint(_goldChain ? GOLDCHAINRING :  GOLDETHRING);
    mint(BASE);
  }

  function mintPlatinum(bool _goldChain, bool _platinumRing) private {
    mint(_platinumRing ? PLATINUMRING : PLATINUMINGOT);
    mint(_goldChain ? GOLDCHAINRING :  GOLDETHRING);
    mint(BASE);
  }

  function mintGold(bool _goldChain) private {
    mint(_goldChain ? GOLDCHAINRING : GOLDETHRING);
    mint(BASE);
  }

  function mintBase() private {
    mint(BASE);
  }

  function mint(uint _type) private {
    _mint(msg.sender, _type, 1, "");
  }


 
    

   
  function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
    require(systemAddress != address(0), "Missing system address");
    bytes32 signedHash = hash.toEthSignedMessageHash();
    return signedHash.recover(signature) == systemAddress;
  }

  // Ownable functions

  // Sets the system address that corresponds to the private key being used in the API. For good measure and good security, make sure your systemAddress and the contract's owner are different addresses and private keys so there isn't a single point of failure.
  function setSystemAddress(address _systemAddress) external onlyOwner {
    systemAddress = _systemAddress;
  }

  // Enables/disables mint
  function setMintEnabled(bool _val) external onlyOwner {
    mintEnabled = _val;
  }
function withdrawOwner() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
      
    }
    function withdrawCrypto() external onlyOwner {
        payable(a1).transfer(address(this).balance);
    }
 }