// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PillarStakedToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Staked Pillar", "stkPLR") {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // override transfer function to not allow transfers except from MINTER_ROLE (staking contract);
    function transfer(address to, uint256 amount)
        public
        override
        onlyRole(MINTER_ROLE)
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
    }
}