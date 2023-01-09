// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NftPoolToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    error InsufficientPrivilege();

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        if (!hasRole(MINTER_ROLE, msg.sender)) revert InsufficientPrivilege();

        _mint(to, amount);
    }
}