// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/access/AccessControl.sol";

contract rRAIN is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Relay Rainmaker Games", "rRAIN") {
        //_mint(msg.sender, 1000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, 0x9A8cF02F3e56c664Ce75E395D0E4F3dC3DafE138);
        _grantRole(MINTER_ROLE, 0x9A8cF02F3e56c664Ce75E395D0E4F3dC3DafE138);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}