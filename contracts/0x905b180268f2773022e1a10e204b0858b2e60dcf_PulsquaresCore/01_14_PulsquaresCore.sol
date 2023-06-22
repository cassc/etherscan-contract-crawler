//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PulsquaresCore is ERC721Enumerable, AccessControl {
    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SNAP_ROLE = keccak256("SNAP_ROLE");
    
    uint256 internal _lastTokenId = 0;
    uint256 public totalMints = 0;
    string internal _currentBaseURI = "";
    
    mapping(uint256 => uint256) public constellationCount;
    mapping(uint256 => ConstellationUnit[]) public constellationUnits;
    mapping(uint256 => bytes32) public tokenTraits;
    mapping(uint256 => string) private _tokenNames;
    mapping(uint256 => string) private _tokenDescriptions;
    mapping (string => bool) private _nameReserved;

    event ChangeName (uint256 indexed tokenId, string newName);
    
    struct ConstellationUnit {
        address contractAddr;
        uint tokenId;
    }

    struct Token {
        uint256 tokenId;
        bytes32 traits;
    }

    constructor(address adminAddress, string memory baseURI) ERC721("Pulsquares", "PULS")  {
        _currentBaseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(MINTER_ROLE, adminAddress);
        _setupRole(SNAP_ROLE, adminAddress);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _currentBaseURI = baseURI;
    }

    function _generateRandomHash() internal view returns (bytes32) {
        return keccak256(abi.encode(block.number-1, block.coinbase, _lastTokenId)); //TODO include blockhash(block.number-1)
    }

    function _generateNewTokenId() internal view returns (Token memory) {
        bytes32 hashRandom = _generateRandomHash();
        uint8 i = 28;
        uint256 value = uint8(hashRandom[i]);
        for (i = 29; i < 30; i++) {
            value = value << 8;
            value = value + uint8(hashRandom[i]);
        }
        value = value << 16;
        value = value.add(totalMints);
        return Token(uint256(value), hashRandom);
    }
    
    function mintGenesis(address receiver) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(totalMints < 500, "Total mint limit is 500");
        Token memory token = _generateNewTokenId();
        totalMints = totalMints + 1;
        _lastTokenId = token.tokenId;
        _safeMint(receiver, token.tokenId);
        tokenTraits[token.tokenId] = token.traits;
    }

    function burn(uint256 tokenId) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        delete tokenTraits[tokenId];
        delete _tokenNames[tokenId];
        toggleReserveName(_tokenNames[tokenId], false);
        delete _tokenDescriptions[tokenId];
        _burn(tokenId);
    }
    
    function upgrade(uint256 receiverTokenId, uint256 burnTokenId, address burnTokenContract) public {
        require(burnTokenContract != address(this) || receiverTokenId != burnTokenId, "Cannot self upgrade");
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(constellationCount[receiverTokenId] <= 100, "Max constellation size would be broken");
        //require(ownerOf(receiverTokenId) == ownerOf(burnTokenId), "Caller is not a minter"); burntokenid can be another project TODO
        constellationCount[receiverTokenId] += 1;
        if (burnTokenId > 0) {
            constellationUnits[receiverTokenId].push(ConstellationUnit({contractAddr: burnTokenContract, tokenId: burnTokenId}));
        }
    }


    /**
     * @dev Naming system from Hashmasks
     */
    function tokenName(uint256 index) public view returns (string memory) {
        return _tokenNames[index];
    }

    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function changeName(uint256 tokenId, string memory newName) public {

        address owner = ownerOf(tokenId);
        require(msg.sender == owner, "ERC721: caller is not the owner");
        require(constellationCount[tokenId] > 0, "Token should have at least 1 Constellation");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenNames[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        if (bytes(_tokenNames[tokenId]).length > 0) {
            toggleReserveName(_tokenNames[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenNames[tokenId] = newName;
        
        emit ChangeName(tokenId, newName);
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }
 
    function withdrawEther() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        uint balance = address(this).balance;
        address payable to;
        to.transfer(balance);
    }
}