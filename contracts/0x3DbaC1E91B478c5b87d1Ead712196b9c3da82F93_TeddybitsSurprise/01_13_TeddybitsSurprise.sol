// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TeddybitsSurprise is ERC1155Supply, Ownable, ReentrancyGuard {
    string private contractMetadataURI;

    mapping(uint256 => bool) private validInventoryType;
    
    mapping(address => bool) private teamAddress;
    mapping(uint256 => address) public burners;
    mapping(uint256 => string) public inventoryURI;

    modifier inventoryTypeExists(uint256 typeId) {
        require(bytes(inventoryURI[typeId]).length != 0, "Inventory type not exists.");
        _;
    }

    modifier teddyBitTeamOnly() {
        require(teamAddress[msg.sender] || owner() == _msgSender(), "Caller is not team or owner");
        _;
    }

    constructor(string memory _contractURI,address[] memory _teamAddress) ERC1155("") {
        contractMetadataURI = _contractURI;
        for (uint256 i = 0; i < _teamAddress.length; i++) {
            teamAddress[_teamAddress[i]] = true;
        }
    }

    //---------------- Only Owner ----------------
    function addShareholder(address[] memory _teamAddress) external onlyOwner {
        for (uint256 i = 0; i < _teamAddress.length; i++) {
            teamAddress[_teamAddress[i]] = true;
        }
    }

    function removeShareholder(address[] memory _teamAddress) external onlyOwner {
        for (uint256 i = 0; i < _teamAddress.length; i++) {
            teamAddress[_teamAddress[i]] = false;
        }
    }

    //---------------- teddyBitTeamOnly ----------------
    function airdrop(address to, uint256 typeId, uint256 amount) external inventoryTypeExists(typeId) teddyBitTeamOnly {
        _mint(to, typeId, amount, "");
    }

    function airdropMultiAddress(address[] memory receivers, uint256 typeId, uint256 amount) external inventoryTypeExists(typeId) teddyBitTeamOnly {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], typeId, amount, "");
        }
    }

    function setBurner(uint256 typeId, address burnAddress) external inventoryTypeExists(typeId) teddyBitTeamOnly {
        burners[typeId] = burnAddress;
    }

    function setValidInventory(uint256 typeId, string memory _uri, address burnAddress) external teddyBitTeamOnly {
        inventoryURI[typeId] = _uri;
        burners[typeId] = burnAddress;
    }

    function setInventoryURI(uint256 typeId, string memory _uri) external inventoryTypeExists(typeId) teddyBitTeamOnly {
        inventoryURI[typeId] = _uri;
    }

    function burnForAddress(uint256 typeId, address burnTokenAddress, uint256 amount) external nonReentrant inventoryTypeExists(typeId) {
        require(msg.sender == burners[typeId], "Invalid burner address");
        _burn(burnTokenAddress, typeId, amount);
    }

    function setContractURI(string memory _uri) external onlyOwner {
        contractMetadataURI = _uri;
    }
    
    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function uri(uint256 typeId) public view override inventoryTypeExists(typeId) returns (string memory) {
        return inventoryURI[typeId];
    }
}