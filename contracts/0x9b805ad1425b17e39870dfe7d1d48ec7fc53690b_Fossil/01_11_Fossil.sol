//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Fossil is ERC20Upgradeable, AccessControlUpgradeable {
    bytes32 private constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint private constant DECIMALS = 10**18;
    uint private constant MAX_SUPPLY = 500000000 * DECIMALS;

    function initialize() public initializer {
        __ERC20_init("Fossil", "FOSSIL");
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    }

    function mintBatch(address[] calldata addresses, uint _amount) external {
        require(totalSupply()<=MAX_SUPPLY-(_amount*addresses.length), "Fossil: max supply reached");
        require(hasRole(MINTER_ROLE, msg.sender), "Fossil: caller is not a minter");
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], _amount * DECIMALS);
        }
    }

    function setMinterRole(address minter, bool status) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Fossil: caller is not an admin");
        if(status) {
            _setupRole(MINTER_ROLE, minter);
        } else {
            revokeRole(MINTER_ROLE, minter);
        }
    }

    function mint(address _user, uint _amount) public {
        require(totalSupply()<=MAX_SUPPLY, "Fossil: max supply reached");
        require(hasRole(MINTER_ROLE, msg.sender), "Fossil: caller is not a minter");
        _mint(_user, _amount);
    }
}