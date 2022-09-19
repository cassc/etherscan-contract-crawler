// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Card is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;


    bytes32 public constant ROOT_ROLE = keccak256("ROOT");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    event CardReceived(address recipient, uint id);

    constructor() ERC721("Gene Player Card", "NGPC") {
        _setRoleAdmin(MANAGER_ROLE, ROOT_ROLE);
        _setupRole(ROOT_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
    }

    function awardItem(address player, string memory tokenURI)
        public onlyRole(MANAGER_ROLE)
        returns (uint256)
    {
        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);
        _setTokenURI(newItemId, tokenURI);

        emit CardReceived(player, newItemId);

        _tokenIds.increment();
        return newItemId;
    }

    function addManager(address manager) public onlyRole(ROOT_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    function revokeManager(address manager) public onlyRole(ROOT_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}