// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PlanB is ERC20, AccessControl {
    // dead address can send to mint but normal transfer is disabled
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("PlanB DAO", "PLANB") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    function grantMintRole(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, account);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function approveToMinter(address minter, address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _approve(minter, to, amount);
    }
}