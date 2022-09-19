// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Interfaces.sol";

contract CardFragment is ERC1155, AccessControl {
    uint256 public constant FRAG = 0;

    bytes32 public constant ROOT_ROLE = keccak256("ROOT");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    address _related721Contract;

    event FragReceived(address recipient, uint amount);

    constructor(address relatedContract) ERC1155("https://static.geneplayer.io/card-frags/{id}.json") {
        //  _mint(msg.sender, FRAG, 10**18, "");
        _setRoleAdmin(MANAGER_ROLE, ROOT_ROLE);
        _setupRole(ROOT_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);

        _related721Contract = relatedContract;
    }

    function dispense(address recipient, uint amount) public onlyRole(MANAGER_ROLE) {
        _mint(recipient, FRAG, amount, "");
        emit FragReceived(recipient, amount);
    }

    function realize(string memory uri) public {
        require(balanceOf(msg.sender, FRAG) >= 5, "insufficient balance");
        _burn(msg.sender, FRAG,  5);

        ICard(_related721Contract).awardItem(msg.sender, uri);
    } 

    function addManager(address manager) public onlyRole(ROOT_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }
    function revokeManager(address manager) public onlyRole(ROOT_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}