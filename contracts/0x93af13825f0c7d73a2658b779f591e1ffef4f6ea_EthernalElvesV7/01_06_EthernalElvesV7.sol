// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721.sol"; 
import "./DataStructures.sol";
import "./Interfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//import "hardhat/console.sol"; 

// We are the Ethernal. The Ethernal Elves         
// Written by 0xHusky & Beff Jezos. 
// Version 7.0.0


contract EthernalElvesV7 is ERC721 {

    function name() external pure returns (string memory) { return "Ethernal Elves"; }
    function symbol() external pure returns (string memory) { return "ELV"; }
       
    using DataStructures for DataStructures.ActionVariables;
    using DataStructures for DataStructures.Elf;
    using DataStructures for DataStructures.Token; 

    IElfMetaDataHandler elfmetaDataHandler;
    ICampaigns campaigns;
    IERC20Lite public ren;
    
    using ECDSA for bytes32;
    
//STATE   

    bool public isGameActive;
    bool public isMintOpen;
    bool public isWlOpen;
    bool private initialized;

    address dev1Address;
    address dev2Address;
    address terminus;
    address public validator;
   
    uint256 public INIT_SUPPLY; 
    uint256 public price;
    bytes32 internal ketchup;
    
    uint256[] public _remaining; 
    mapping(uint256 => uint256) public sentinels; //memory slot for Elfs
    mapping(address => uint256) public bankBalances; //memory slot for bank balances
    mapping(address => bool)    public auth;
    mapping(address => uint16)  public whitelist; 


    bool public isTerminalOpen;

    mapping(bytes => uint16)  public usedRenSignatures; 
    mapping(bytes => uint16)  public usedSentinelSignatures; 
/////NEW STORAGE FROM THIS LINE V5///////////////////////////////////////////////////////
    
   
    function setBridge(address _bridge)  public {
       onlyOwner();     
       terminus             = _bridge;       
    }    
    
    function setAuth(address[] calldata adds_, bool status) public {
       onlyOwner();
       
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }

    function setValidator(address _validator) public {
       onlyOwner();
       validator = _validator;
    }

//EVENTS

    event Action(address indexed from, uint256 indexed action, uint256 indexed tokenId);         

 
   
//GAMEPLAY//
 function stake(uint256[] calldata _id) external {

         isPlayer();
          
         for(uint256 i = 0; i < _id.length; i++) {
         isSentinelOwner(_id[i]);
         require(ownerOf[_id[i]] != address(this));

        DataStructures.Elf memory elf = DataStructures.getElf(sentinels[_id[i]]);
        DataStructures.ActionVariables memory actions;
        elf.owner = msg.sender;

        actions.traits   = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
        actions.class    = DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);
        
        sentinels[_id[i]] = DataStructures._setElf(elf.owner, elf.timestamp, elf.action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);
        
        _transfer(msg.sender, address(this), _id[i]);      
         
        }                    
    }

     function unstake(uint256[] calldata _id, uint256[] calldata sentinel, bytes[] memory signatures, bytes[] memory authCodes) external {

         isPlayer();
         address owner = msg.sender;
         uint256 action = 0;

          for (uint256 index = 0; index < _id.length; index++) {  
            isSentinelOwner(_id[index]);
            require(ownerOf[_id[index]] == address(this), "Elf not owned by this contract");
            require(usedSentinelSignatures[signatures[index]] == 0, "Signature already used");   
            require(_isSignedByValidator(encodeSentinelForSignature(_id[index], owner, sentinel[index], authCodes[index]),signatures[index]), "incorrect signature");
            usedSentinelSignatures[signatures[index]] = 1;

            DataStructures.Elf memory elf = DataStructures.getElf(sentinel[index]);
            DataStructures.ActionVariables memory actions;
            //check if owners are the same. Check is owner is sender.
            
            elf.owner = address(0);    //Nuke current holder
           
            actions.traits = DataStructures.packAttributes(elf.hair, elf.race, elf.accessories);
            actions.class =  DataStructures.packAttributes(elf.sentinelClass, elf.weaponTier, elf.inventory);

            sentinels[_id[index]] = DataStructures._setElf(elf.owner, elf.timestamp, action, elf.healthPoints, elf.attackPoints, elf.primaryWeapon, elf.level, actions.traits, actions.class);

            
            _transfer(address(this), owner, _id[index]);      

            }
                    
    }


        //////////FOR OFFCHAIN USE ONLY/////////////
    function generateSentinelDna(
                address owner, uint256 timestamp, uint256 action, uint256 healthPoints, 
                uint256 attackPoints, uint256 primaryWeapon, uint256 level, 
                uint256 traits, uint256 class)

    external pure returns (uint256 sentinel) {

     sentinel = DataStructures._setElf(owner, timestamp, action, healthPoints, attackPoints, primaryWeapon, level, traits, class);
    
    return sentinel;
}


function decodeSentinelDna(uint256 character) external view returns(DataStructures.Elf memory elf) {
      elf = DataStructures.getElf(character);
} 

  
//PUBLIC VIEWS
    function tokenURI(uint256 _id) external view returns(string memory) {

       string memory tokenURI = 'https://api.ethernalelves.com/api/sentinels/';
      return string(abi.encodePacked(tokenURI, Strings.toString(_id)));

    
    }


function getSentinel(uint256 _id) external view returns(uint256 sentinel){
    return sentinel = sentinels[_id];
}


function getToken(uint256 _id) external view returns(DataStructures.Token memory token){
   
    return DataStructures.getToken(sentinels[_id]);
}

function elves(uint256 _id) external view returns(address owner, uint timestamp, uint action, uint healthPoints, uint attackPoints, uint primaryWeapon, uint level) {

    uint256 character = sentinels[_id];

    owner =          address(uint160(uint256(character)));
    timestamp =      uint(uint40(character>>160));
    action =         uint(uint8(character>>200));
    healthPoints =   uint(uint8(character>>208));
    attackPoints =   uint(uint8(character>>216));
    primaryWeapon =  uint(uint8(character>>224));
    level =          uint(uint8(character>>232));   

}

//Modifiers but as functions. Less Gas
    function isPlayer() internal {    
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}
        require((msg.sender == tx.origin && size == 0));
        ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
    }


    function onlyOwner() internal view {    
        require(admin == msg.sender || auth[msg.sender] == true || dev1Address == msg.sender || dev2Address == msg.sender);
    }

    function isSentinelOwner(uint256 id) internal view {  

        DataStructures.Elf memory elf = DataStructures.getElf(sentinels[id]);
        require(ownerOf[id] == msg.sender || elf.owner == msg.sender, "NotYourElf");
    }

//ADMIN Only
    function withdrawAll() public {
        onlyOwner();
        uint256 balance = address(this).balance;
        
        uint256 devShare = balance/2;      

        require(balance > 0);
        _withdraw(dev1Address, devShare);
        _withdraw(dev2Address, devShare);
    }

    //Internal withdraw
    function _withdraw(address _address, uint256 _amount) private {

        (bool success, ) = _address.call{value: _amount}("");
        require(success);
    }

    function flipActiveStatus() external {
        onlyOwner();
        isGameActive = !isGameActive;
    }

     function encodeSentinelForSignature(uint256 id, address owner, uint256 sentinel, bytes memory authCode) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                    keccak256(
                            abi.encodePacked(id, owner, sentinel, authCode))
                            )
                        );
    } 


    function _isSignedByValidator(bytes32 _hash, bytes memory _signature) private view returns (bool) {
                
                bytes32 r;
                bytes32 s;
                uint8 v;
                    assembly {
                            r := mload(add(_signature, 0x20))
                            s := mload(add(_signature, 0x40))
                            v := byte(0, mload(add(_signature, 0x60)))
                        }
                    
                        address signer = ecrecover(_hash, v, r, s);
                        return signer == validator;
  
            }
  

}