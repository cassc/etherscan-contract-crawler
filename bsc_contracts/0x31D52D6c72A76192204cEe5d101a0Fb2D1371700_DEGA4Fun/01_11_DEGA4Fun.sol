// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "../../openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../openzeppelin/contracts/access/AccessControl.sol";

contract DEGA4Fun is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("DE.GA4FUN", "DEGAF") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _burn(account, amount);
    }
}