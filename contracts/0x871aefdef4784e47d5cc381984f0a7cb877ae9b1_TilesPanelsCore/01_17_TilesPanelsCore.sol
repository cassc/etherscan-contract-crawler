//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./TilesBlocksCore.sol";

contract TilesPanelsCore is ERC721Enumerable, AccessControl, Ownable {
    struct Panel {
        string name;
        string description;
        uint16 size;
        uint16 degradationLevel;
        bool isEmpty;
    }

    uint256 constant TOTAL_MAX_2 = 50;
    uint256 constant TOTAL_MAX_4 = 500;
    uint256 constant TOTAL_MAX_6 = 200;
    uint256 constant TOTAL_MAX_9 = 250;
    uint256 constant TOTAL_MAX_16 = 80;
    uint256 constant TOTAL_MAX_25 = 20;
    uint256 constant TOTAL_MAX_36 = 5;

    using SafeMath for uint256;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    string public scriptArweave;
    string public scriptIPFS;  

    address internal BLOCKS_CONTRACT;

    mapping  (uint256 => uint256[]) public tokenBlocks;
    mapping (uint256 => Panel) public tokens;

    mapping  (uint256 => uint256) public totalMints;
    uint256 public totalGlobalMints = 0;
    string internal _currentBaseURI = "";

    event PanelCreated (uint _tokenId, uint256[] _blocksTokenIds);
    event PanelDeconstructed (uint _tokenId);
    
    constructor(address adminAddress, address ownerAddress, string memory baseURI, address blocks_contract) ERC721("Tiles Panels", "TILP")  {
        _currentBaseURI = baseURI;
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        BLOCKS_CONTRACT = blocks_contract;
        transferOwnership(ownerAddress);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }

    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        _currentBaseURI = baseURI;
    }

    function setScriptIPFS(string memory _scriptIPFS) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        scriptIPFS = _scriptIPFS;
    }

    function setScriptArweave(string memory _scriptArweave) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        scriptArweave = _scriptArweave;
    }
    
    function _isValidLength(uint256 len) internal pure returns(bool) {
        return (len == 2 ||
                len == 4 ||
                len == 6 ||
                len == 9 ||
                len == 16 ||
                len == 25 ||
                len == 36);
    }

    function _checkTotalMints(uint256 size) internal view returns(bool) {
        if(size == 2) {
            return totalMints[size] < TOTAL_MAX_2;
        }
        if(size == 4) {
            return totalMints[size] < TOTAL_MAX_4;
        }
        else if(size == 6) {
            return totalMints[size] < TOTAL_MAX_6;
        }
        else if(size == 9) {
            return totalMints[size] < TOTAL_MAX_9;
        }
        else if(size == 16) {
            return totalMints[size] < TOTAL_MAX_16;
        }
        else if(size == 25) {
            return totalMints[size] < TOTAL_MAX_25;
        }
        else if(size == 36) {
            return totalMints[size] < TOTAL_MAX_36;
        }
        return false;
        
    }

    function deconstruct(uint256 _tokenId) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(tokenBlocks[_tokenId].length > 0, "Panel is empty");
        delete tokenBlocks[_tokenId];
        if (tokens[_tokenId].degradationLevel < 4)
            tokens[_tokenId].degradationLevel++;
        tokens[_tokenId].name = '';
        tokens[_tokenId].description = '';
        tokens[_tokenId].isEmpty = true;

        emit PanelDeconstructed(_tokenId);
    }

    function fillEmptyToken(uint256 _tokenId, string memory _name, string memory _desc, uint256[] memory _blocksTokenIds) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(tokens[_tokenId].isEmpty, "Panel is not empty");
        uint256 aLength = _blocksTokenIds.length;
        require(tokens[_tokenId].size == aLength, "Size differs from blocks count. Partial Panels not allowed");

        for(uint i=0; i < aLength; i++) {
            uint bTid = _blocksTokenIds[i];
            require(TilesBlocksCore(BLOCKS_CONTRACT).ownerOf(bTid) == ownerOf(_tokenId), "Receiver needs to own all tokens"); //also checks if token exists
            TilesBlocksCore(BLOCKS_CONTRACT).burn(bTid);
        }

        tokenBlocks[_tokenId] = _blocksTokenIds;
        tokens[_tokenId].name = _name;
        tokens[_tokenId].description = _desc;
        tokens[_tokenId].isEmpty = false;

        emit PanelCreated (_tokenId, _blocksTokenIds);
    }

    function mintGenesis(address _receiver, string memory _name, string memory _desc, uint16 _size, uint256[] memory _blocksTokenIds) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        require(_isValidLength(_size), "Invalid size");
        require(_checkTotalMints(_size), "Exceeds total mints for this size");

        bool isEmpty = false;
        uint256 aLength = _blocksTokenIds.length;
        if (aLength > 0) { //not empty
            require(_size == aLength, "Size differs from blocks count. Partial Panels not allowed");
            for(uint i=0; i < aLength; i++) {
                uint bTid = _blocksTokenIds[i];
                require(TilesBlocksCore(BLOCKS_CONTRACT).ownerOf(bTid) == _receiver, "Receiver needs to own all tokens"); //also checks if token exists
                TilesBlocksCore(BLOCKS_CONTRACT).burn(bTid);
            }
        }
        else {
            isEmpty = true;
        }
        
        totalGlobalMints++;
        uint256 token = totalGlobalMints;

        totalMints[_size] = totalMints[_size] + 1;
        tokenBlocks[token] = _blocksTokenIds;


        tokens[token] = Panel({name: _name, description: _desc, size: _size, degradationLevel: 0, isEmpty: isEmpty});
        _safeMint(_receiver, token);
        
        emit PanelCreated (token, _blocksTokenIds);
    }

    function burn(uint256 tokenId) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _burn(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }
 
    function withdrawEther() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not admin");
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}