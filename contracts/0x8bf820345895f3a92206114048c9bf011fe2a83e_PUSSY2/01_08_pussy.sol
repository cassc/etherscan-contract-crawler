// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PUSSY2 is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _owner) ERC20("pussy2.0", "PUSSY2.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _mint(_owner, 1e30);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "you don't have the minter role");
        _mint(to, amount);
    }
}