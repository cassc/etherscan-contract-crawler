// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IEggCollection {
    function getRevIdFromTokenId(uint eggTokenId) external view returns(uint);
}

contract Eggs is AccessControl {
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _eggIds;
    
    uint _maxId = 0;
    uint _maxRevId = 0;

    struct Egg{
        uint id;
        string name;
        string description;
        string veneer;
        string origin;
        uint energyLevel;
        string temperature;
        string byproduct;
        string weight;        
        string element;
        string sound;
    }

    struct Revealed {
        uint id;
        uint eggId;
    }


    struct EggUpload{
        uint id;
        string name;
        string description;
        string veneer;
        string origin;
        uint energyLevel;
        string eggImg;
        string eggAnni;
        uint avType; //1 citizen 2 nomad 0 both
        string temperature;
        string byproduct;
        string weight;
        string element;
        string sound;
    }

    IEggCollection EggCollection;

    mapping(uint => Egg) eggIdToData;
    mapping(uint => Revealed) revIdToRevealedData;
    mapping(uint => uint[]) eggIdToPossibleReveals;
    mapping(uint => bool) _revMinted;
    // mapping(uint => uint) idToSupply; 
    // mapping(uint => uint) eggIdToPrice;
    // mapping(uint => uint) revIdToSupply;
    mapping(uint => string) eggIdToHiddenImg;
    mapping(uint => string) eggIdToAnnimation;
    // mapping(uint => uint[]) radomSetToEggIds; // need to add this. 
    mapping(uint => uint) eggIdToAvType;
    // mapping(uint => uint) randomSetTotalSupply;

    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
        _setupRole(CONTRACT_ROLE, msg.sender);
    }

    function addContractRoles(address contractAddress)external onlyRole(UPDATER_ROLE){
        _grantRole(CONTRACT_ROLE, contractAddress);
    }

    function setUpInterfaces(address eggColl)external onlyRole(UPDATER_ROLE){
        EggCollection = IEggCollection(eggColl);
    }

    function uploadEggData(EggUpload[] calldata eggs)external onlyRole(UPDATER_ROLE){
        for (uint i; i<eggs.length;i++){
            uint _id = eggs[i].id;
            Egg memory egg = Egg({
                id: _id,
                name: eggs[i].name,
                description: eggs[i].description,
                veneer: eggs[i].veneer,
                origin: eggs[i].origin,
                energyLevel: eggs[i].energyLevel,
                temperature: eggs[i].temperature,
                byproduct: eggs[i].byproduct,
                weight: eggs[i].weight,
                element: eggs[i].element,
                sound: eggs[i].sound
            });
            eggIdToData[_id] = egg;
            eggIdToHiddenImg[_id] = eggs[i].eggImg;
            eggIdToAnnimation[_id] = eggs[i].eggAnni;
            eggIdToAvType[_id] = eggs[i].avType;
            if(_id > _maxId){
                _maxId = _id;
            }
        }
    }

    function setEggToAvType(uint eggId, uint avType)external onlyRole(UPDATER_ROLE){
        eggIdToAvType[eggId] = avType;
    }

    function setEggImage(uint eggId, string calldata img)external onlyRole(UPDATER_ROLE){
        eggIdToHiddenImg[eggId] = img;
    }
  
    function setEggAnimation(uint eggId, string calldata ani)external onlyRole(UPDATER_ROLE){
        eggIdToAnnimation[eggId] = ani;
    }

    function uploadRevealData(Revealed[] calldata reveals)external onlyRole(UPDATER_ROLE){
        for(uint i; i < reveals.length; i++){
            uint _id = reveals[i].id;
            eggIdToPossibleReveals[reveals[i].eggId].push(_id);
            revIdToRevealedData[_id] = reveals[i];
            if(_id > _maxRevId){
                _maxRevId = _id;
            }
        }
    }


    function pickRevealItem(uint eggId, uint eggsCount)external view returns(uint){
        require(_maxRevId >= eggsCount, "missing reveal items, risk of infinate loop");
        uint[] memory options = eggIdToPossibleReveals[eggId];
        console.log(options.length);
        uint random = uint(blockhash(block.number - 1)) % options.length;
        console.log(random);
        if(!_revMinted[options[random]]){
            return options[random];
        }else{
            while(_revMinted[options[random]]){
                random = uint(blockhash(block.number - 1)) % options.length;
            }
            return options[random];
        }
    }

    function okToAttach(uint eggId, uint avType)external view returns(bool){
        uint eggAv = eggIdToAvType[eggId];
        if(eggAv == 0){
            return true;
        }else if(eggAv == avType){
            return true;
        }else{
            return false;
        }
    }


    function eggsAttachedTokenUri(uint[] memory eggsTokenIds)external view returns(bytes memory){
        bytes memory dataURI = abi.encodePacked("");
        for(uint i; i<eggsTokenIds.length;i++){
            uint egg = EggCollection.getRevIdFromTokenId(eggsTokenIds[i]);
            dataURI = abi.encodePacked(
                dataURI,
                '"},{ "trait_type": "Pet ',
                Strings.toString(i),
                '", "value": "',
                "Creature - ", egg
            );
        }
        return dataURI;
    }

    function eggRevID(uint eggTokenId)external view returns(uint){
        
        return EggCollection.getRevIdFromTokenId(eggTokenId);
    }


    function eggSectionOne(uint itemId)internal view returns(bytes memory){
        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            eggIdToData[itemId].name,
            '", "description": "',
            eggIdToData[itemId].description,
            '", "image": "',
            eggIdToHiddenImg[itemId],
            '", "animation_url":"',
            eggIdToAnnimation[itemId],
            '", "attributes": [{ "trait_type": "Veneer", "value": "',
            eggIdToData[itemId].veneer,
            '"},{ "trait_type": "Origin", "value": "',
            eggIdToData[itemId].origin);
        return dataURI;
    }

    function eggSection2(uint itemId)internal view returns(bytes memory){
        bytes memory dataURI = abi.encodePacked(
            '"},{ "trait_type": "Byproduct", "value": "',
            eggIdToData[itemId].byproduct,
            '"},{ "trait_type": "Temperature", "value": "',
            eggIdToData[itemId].temperature,
            '"},{ "trait_type": "Weight", "value": "',
            eggIdToData[itemId].weight
            );
        return dataURI;
    }

    function individualTokenUri(uint itemId)external view returns(string memory){
        bytes memory dataURI = abi.encodePacked(
            eggSectionOne(itemId),
            eggSection2(itemId),
            '"},{ "display_type": "number", "trait_type": "Energy Level", "value": ',
            Strings.toString(eggIdToData[itemId].energyLevel),
            '},{ "trait_type": "Element", "value": "',
            eggIdToData[itemId].element,
            '"},{ "trait_type": "Sound", "value": "',
            eggIdToData[itemId].sound,
            '"}]}'
        );
        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }
}