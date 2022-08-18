// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

//import "hardhat/console.sol";
import "./ERC721.sol"; 
import "./EldersDataStructures.sol";
import "./Interfaces.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


//VIXED THE ISSUE IN THIS VERION

contract Elders is ERC721 {

    function name() external pure returns (string memory) { return "EthernalElves Elders"; }
    function symbol() external pure returns (string memory) { return "ELD"; }
       
    using EldersDataStructures for EldersDataStructures.EldersMeta;

    IERC1155Lite public artifacts;
    IEldersMetaDataHandler public eldermetaDataHandler;

    bool private initialized;
    bool public isMintOpen;
    bool public isRevealed;    
    address public validator;   
    uint256 public pvConstant;
    uint256[3][6] public baseValues;
    uint256[3][6] public uniques;
    uint256 uniquesCount;
    bytes32 ketchup;
    
    mapping(uint256 => uint256) public eldersMeta; //memory slot for Elder Metadata
    mapping(uint256 => address) public elderOwner; //memory slot for Owners, Timestamp and Actions    
    mapping(address => bool)    public auth; //memory slot for Authorized addresses
    mapping(bytes => uint256)  public usedSignatures; //memory slot for used signatures

    uint256[5][6] private uniqueBodys;
    uint256 uniqueBodyCount;

    function initialize() public {
    
       require(!initialized, "Already initialized");
       admin                = msg.sender;   
       maxSupply            = 2222; 
       initialized          = true;
       validator            = 0x5A5f094437df669a2ec79a99589bB0E7aa9c26Bb;
       pvConstant           = 200;
       baseValues[0]        = [15,20,25];
       baseValues[1]        = [15,20,25];
       baseValues[2]        = [20,25,15];
       baseValues[3]        = [20,25,15];
       baseValues[4]        = [25,15,20];
       baseValues[5]        = [25,15,20];

    }


    function mint(uint256 quantity) external returns (uint256 id) {
    
        isPlayer();
        require(isMintOpen, "Minting is closed");
        uint256 price = totalSupply <= 1800 ? 7 : 11;
        uint256 totalCost = price * quantity;

        require(artifacts.balanceOf(msg.sender, 1) >= totalCost, "Not Enough Artifacts");
        require(maxSupply - quantity >= 0, "No Elders Left");        
        
        artifacts.burn(msg.sender, 1, totalCost);

        return _mintElder(msg.sender, quantity);

    }


     function _mintElder(address _to, uint256 qty) private returns (uint16 id) {
        ////
        for(uint256 i = 0; i < qty; i++) {
        
        id = uint16(totalSupply + 1);   
        
        uint256 rand = _rand() + i; 
        
        uint256 uniqueChance = uint256(_randomize(rand, "Unique", id)) % 10000;

        EldersDataStructures.EldersMeta memory elders;        
        
               

            elders.elderClass           = uint256(_randomize(rand, "Class", id)) % 6;
            elders.strength             = baseValues[elders.elderClass][0];
            elders.agility              = baseValues[elders.elderClass][1];
            elders.intellegence         = baseValues[elders.elderClass][2];  

            elders.healthPoints         = pvConstant+((((elders.elderClass + elders.strength))*elders.strength)/10);
            elders.attackPoints         = (elders.agility * 65/100) + (elders.strength * 35/100);
            elders.mana                 = pvConstant+((((elders.elderClass + elders.intellegence))*elders.intellegence)/10);

            elders.primaryWeapon        = 1;
            elders.secondaryWeapon      = 1;
            elders.armor                = 1;
            elders.level                = 1;

            elders.head                 = uint256((uint256(_randomize(rand, "head", id)) % 16) + 1);            
         
            elders.race                 = rand % 100 > 97 ? 4 : uint256(uint256(_randomize(rand, "race", id)) % 4) + 1;

            uint256 uniqueId = ((rand % 2) + 3);       
            
           
           
        if(uniqueChance < (uniqueBodyCount + 1) * 35 && uniqueBodys[elders.elderClass][uniqueId] == 0) {

            uniqueBodys[elders.elderClass][uniqueId] = id;
            elders.body     = uniqueId;
            uniqueBodyCount++;
         

        }else{

            elders.body                 = uint256((uint256(_randomize(rand, "body", id)) % 2) + 13);        

        }

            eldersMeta[id] = EldersDataStructures.setElder( elders.strength, elders.agility, elders.intellegence,  
                                                            elders.attackPoints, elders.healthPoints, elders.mana, 
                                                            elders.primaryWeapon, elders.secondaryWeapon, elders.armor,
                                                            elders.level, elders.head, elders.body, elders.race, 
                                                            elders.elderClass);           

         _mint(_to, id);           

        }
     
     }

    function tokenURI(uint256 _id) external view returns(string memory) {

      //return eldermetaDataHandler.getTokenURI(uint16(_id), eldersMeta[_id], isRevealed);
      string memory tokenURI = 'https://api.ethernalelves.com/api/elders/';
      return string(abi.encodePacked(tokenURI, Strings.toString(_id)));

    }

    function tokenURIOnChain(uint256 _id) external view returns(string memory) {

     return eldermetaDataHandler.getTokenURI(uint16(_id), eldersMeta[_id], isRevealed);     

    }

    function getElder(uint256 _id) external view returns(EldersDataStructures.EldersMeta memory) {

      return EldersDataStructures.getElder(eldersMeta[_id]);

    }


    function generateElderDna(
                uint256 strength,
                uint256 agility,
                uint256 intellegence,
                uint256 primaryWeapon, 
                uint256 secondaryWeapon,
                uint256 armor,
                uint256 level,
                uint256 head,
                uint256 body,
                uint256 race,
                uint256 elderClass
    )
    external view returns (uint256 elderDNA) {

        EldersDataStructures.EldersMeta memory elders;             

            elders.strength             = strength;
            elders.agility              = agility;
            elders.intellegence         = intellegence;
            elders.healthPoints         = pvConstant+((((elderClass + strength))*strength)/10);
            elders.attackPoints         = (agility * 65/100) + (strength * 35/100);
            elders.mana                 = pvConstant+((((elderClass + intellegence))*intellegence)/10);
            elders.primaryWeapon        = primaryWeapon;
            elders.secondaryWeapon      = secondaryWeapon;
            elders.armor                = armor;
            elders.level                = level;
            elders.head                 = head;                   
            elders.body                 = body;
            elders.race                 = race;
            elders.elderClass           = elderClass;

        elderDNA = EldersDataStructures.setElder(  elders.strength, elders.agility, elders.intellegence,  
                                            elders.attackPoints, elders.healthPoints, elders.mana, 
                                            elders.primaryWeapon, elders.secondaryWeapon, elders.armor,
                                            elders.level, elders.head, elders.body, elders.race, 
                                            elders.elderClass); 
        return elderDNA;
     
    }


    function decodeElderDna(uint256 character) external view returns(EldersDataStructures.EldersMeta memory) {
      return EldersDataStructures.getElder(character);
    } 


    
    function stake(uint256[] calldata _id) external {

         isPlayer();
          
         for(uint256 i = 0; i < _id.length; i++) {
         isElderOwner(_id[i]);         
         require(ownerOf[_id[i]] != address(this));
         _transfer(msg.sender, address(this), _id[i]);      
         elderOwner[_id[i]] = msg.sender;
         }
                    
    }

     function unstake(uint256[] calldata _id, uint256[] calldata elder, bytes[] memory signatures, bytes[] memory authCodes) external {

         isPlayer();
         address owner = msg.sender;

          for (uint256 index = 0; index < _id.length; index++) {  
            isElderOwner(_id[index]);
            require(usedSignatures[signatures[index]] == 0, "Signature already used");   
            require(_isSignedByValidator(encodeSentinelForSignature(_id[index], owner, elder[index], authCodes[index]),signatures[index]), "incorrect signature");
            usedSignatures[signatures[index]] = 1;

            eldersMeta[_id[index]] = elder[index];//add new dna from gameplay
            elderOwner[_id[index]] = address(0);
            _transfer(address(this), owner, _id[index]);      

            }
                    
    }


    
/*

█▀▄▀█ █▀█ █▀▄ █ █▀▀ █ █▀▀ █▀█ █▀
█░▀░█ █▄█ █▄▀ █ █▀░ █ ██▄ █▀▄ ▄█
*/

    function onlyOperator() internal view {    
       require(auth[msg.sender] == true, "not operator");

    }

    function onlyOwner() internal view {    
        require(admin == msg.sender, "not admin");
    }

    function isPlayer() internal {    
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}
        require((msg.sender == tx.origin && size == 0));
        ketchup = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    function isElderOwner(uint256 id) internal view {    
        require(msg.sender == elderOwner[id] || msg.sender == ownerOf[id], "not your elder");
    }


    function _randomize(uint256 ran, string memory dom, uint256 ness) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(ran,dom,ness)));}

    function _rand() internal view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, block.basefee, ketchup)));}




/*
▄▀█ █▀▄ █▀▄▀█ █ █▄░█   █▀▀ █░█ █▄░█ █▀▀ ▀█▀ █ █▀█ █▄░█ █▀
█▀█ █▄▀ █░▀░█ █ █░▀█   █▀░ █▄█ █░▀█ █▄▄ ░█░ █ █▄█ █░▀█ ▄█
*/

    function setAddresses(address _artifacts, address _inventory)  public {
       onlyOwner();
       
       artifacts            = IERC1155Lite(_artifacts);
       eldermetaDataHandler   = IEldersMetaDataHandler(_inventory);
       
    } 

    function flipMint () public {
        onlyOwner();
        isMintOpen = !isMintOpen;
    }

    function flipReveal () public {
        onlyOwner();
        isRevealed = !isRevealed;
    }   

    function setValidator(address _validator)  public {
       onlyOwner();
       validator = _validator;
    }
    
    function setAuth(address[] calldata adds_, bool status) public {
       onlyOwner();
       
        for (uint256 index = 0; index < adds_.length; index++) {
            auth[adds_[index]] = status;
        }
    }


    function encodeSentinelForSignature(uint256 id, address owner, uint256 elder, bytes memory authCode) public pure returns (bytes32) {
        return keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", 
                    keccak256(
                            abi.encodePacked(id, owner, elder, authCode))
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