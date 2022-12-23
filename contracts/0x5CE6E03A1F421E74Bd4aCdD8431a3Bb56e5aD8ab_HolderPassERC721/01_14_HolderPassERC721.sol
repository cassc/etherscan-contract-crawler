// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * ___  ____ _                          _   _       _     _            ______             
 * |  \/  (_) |                        | | | |     | |   | |           | ___ \            
 * | .  . |_| |_ __ _ _ __ ___   __ _  | |_| | ___ | | __| | ___ _ __  | |_/ /_ _ ___ ___ 
 * | |\/| | | __/ _` | '_ ` _ \ / _` | |  _  |/ _ \| |/ _` |/ _ \ '__| |  __/ _` / __/ __|
 * | |  | | | || (_| | | | | | | (_| | | | | | (_) | | (_| |  __/ |    | | | (_| \__ \__ \
 * \_|  |_/_|\__\__,_|_| |_| |_|\__,_| \_| |_/\___/|_|\__,_|\___|_|    \_|  \__,_|___/___/     
 * 
 * produced by http://mitama-mint.com/
 * written by zkitty.eth
 */

import { ERC721, IERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract HolderPassERC721 is ERC721, AccessControl, Ownable{
    /**
     * Token Configuration
     */
    string public imageDirURI;
    uint256 private _totalSupply;
    mapping(uint256 => bool) public hasGold;
    mapping(uint256 => uint256) public silverPassCounter;
    bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 constant SETTER_ROLE = keccak256("SETTER_ROLE");

    /**
     * Token metadata infromation
     */
    string public description = "Permanent royalty rights for Mitama ecosystem participants.";
    string public goldPassFile = "holderpass-gold.jpg";
    string public silverPassFile = "holderpass-silver.jpg";
    string public goldPassName = "Gold Pass #";
    string public silverPassName = "Silver Pass #";



    constructor(
        string memory _name,
        string memory _symbol,
        string memory _imageDirURI
    ) ERC721(_name, _symbol) {
        imageDirURI = _imageDirURI;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(SETTER_ROLE, msg.sender);
    }

    error InvalidTokenId();
    error InvalidAddress();
    function mintPass(uint256 mitamaTokenId, address to) external onlyRole(MINTER_ROLE) {
        if(mitamaTokenId >= 10000) revert InvalidTokenId(); // Mitama TokenID should be between 0 .. 9999 (total: 10,000 tokens)
        if(to == address(0)) revert InvalidAddress();

        if(!hasGold[mitamaTokenId]){
            _totalSupply ++;
            hasGold[mitamaTokenId] = true;
            _safeMint(to, mitamaTokenId);
        }else if(silverPassCounter[mitamaTokenId] < 6){
            _totalSupply++;
            silverPassCounter[mitamaTokenId]++;
            uint tokenId = silverPassCounter[mitamaTokenId] * 10000 + mitamaTokenId;
            _safeMint(to, tokenId);
        }else{
            silverPassCounter[mitamaTokenId]++;
            uint256 counter = silverPassCounter[mitamaTokenId] % 6 == 0 ? 6 
                : silverPassCounter[mitamaTokenId] % 6;
            uint256 tokenId = counter * 10000 + mitamaTokenId;
            _burn(tokenId);
            _safeMint(to, tokenId);
        }
    }

    /**
     * get holderList which has been minted by mitamaTokenId
     */
    
    error UnissuedPass();
    function getHolderList(uint256 mitamaTokenId) public view returns (address[] memory) {
        if(mitamaTokenId >= 10000) revert InvalidTokenId(); // Mitama TokenID should be between 0 .. 9999 (total: 10,000 tokens)

        if(!hasGold[mitamaTokenId]) return new address[](0); // Return Null array if the pass is not issued yet.

        if(hasGold[mitamaTokenId] && silverPassCounter[mitamaTokenId] == 0){
            // only goldPass has been minted.
            address[] memory holderList = new address[](1);
            holderList[0]=ownerOf(mitamaTokenId);
            return holderList;
        }else if(hasGold[mitamaTokenId] && silverPassCounter[mitamaTokenId] <= 6){
            uint256 length = silverPassCounter[mitamaTokenId];
            address[] memory holderList = new address[](length + 1);
            holderList[0] = ownerOf(mitamaTokenId);
            for(uint256 i=0; i < length; i++){
                holderList[1 + i] = ownerOf(mitamaTokenId + 10000 * (i + 1));
            }
            return holderList;
        }else{
            address[] memory holderList = new address[](7);
            holderList[0] = ownerOf(mitamaTokenId);
            for(uint256 i=0; i < 6; i++){
                holderList[1 + i] = ownerOf(mitamaTokenId + 10000 * (i + 1));
            }
            return holderList;
        }
    }
    
    /**
     * Setter functions
     */
    function setImageDirURI(string memory _imageDirURI) public onlyRole(SETTER_ROLE) {
        imageDirURI = _imageDirURI;
    }
    
    function setDescription(string memory _description) public onlyRole(SETTER_ROLE){
        description = _description;
    }

    function setGoldPassFile(string memory newGoldPassFile) public onlyRole(SETTER_ROLE){
        goldPassFile = newGoldPassFile;
    }

    function setGoldPassName(string memory newGoldPassName) public onlyRole(SETTER_ROLE){
        goldPassName = newGoldPassName;
    }

    function setSilverPassFile(string memory newSilverPassFile) public onlyRole(SETTER_ROLE){
        silverPassFile = newSilverPassFile;
    }

    function setSilverPassName(string memory newSilverPassName) public onlyRole(SETTER_ROLE){
        silverPassName = newSilverPassName;
    }

    /**
     * get Remaining Round of SilverPass
     */
    
    error GoldPassDoesntExpire();
    function getSilverPassRemainingRound(uint256 tokenId) public view returns (uint256) {
        if(tokenId < 10000) revert GoldPassDoesntExpire();
        if(!_exists(tokenId)) revert InvalidTokenId();
        uint256 mitamaTokenId = tokenId % 10000;
        uint256 counter = silverPassCounter[mitamaTokenId] % 6;
        uint256 passNumber = tokenId / 10000;
        uint256 diff = passNumber < counter ? passNumber  + 6 - counter : passNumber - counter;
        uint256 remainingRound = diff % 6 == 0 ? 6 : diff % 6;
        return remainingRound;
    } 

    /**
     * @notice inheritdoc IERC721Metadata
     */
    
    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        if(!_exists(tokenId)) revert InvalidTokenId();
        // Common metadata params
        string memory imageURI;
        string memory pass_name;
        string memory json;
        string memory base64_json;
        // GoldPass
        if(tokenId < 10000){
            imageURI = string(abi.encodePacked(imageDirURI, goldPassFile));
            pass_name = string(abi.encodePacked(goldPassName,Strings.toString(tokenId)));
            json = string(abi.encodePacked(
                '{"name":"',
                pass_name,
                '","symbol":"',
                ERC721.symbol(),
                '","description":"',
                description,
                '","image":"',
                imageURI,
                '"}'
            ));
            base64_json = Base64.encode(bytes(json));
            return string(abi.encodePacked('data:application/json;base64,', base64_json));
        }

        // SilverPass
        imageURI = string(abi.encodePacked(imageDirURI, silverPassFile));
        pass_name = string(abi.encodePacked(silverPassName,Strings.toString(tokenId % 10000)));
        string memory remainingRound = Strings.toString(getSilverPassRemainingRound(tokenId));
        json = string(abi.encodePacked(
            '{"name":"',
            pass_name,
            '","symbol":"',
            ERC721.symbol(),
            '","description":"',
            description,
            '","image":"',
            imageURI,
            '","attributes":[{"display_type":"number","trait_type":"RemainingRound","value":',
            remainingRound,
            '}]}'
        ));
        base64_json = Base64.encode(bytes(json));
        return string(abi.encodePacked('data:application/json;base64,', base64_json));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

}