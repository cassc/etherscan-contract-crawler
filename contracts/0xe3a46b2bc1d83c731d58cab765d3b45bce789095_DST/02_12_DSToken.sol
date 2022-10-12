// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/*
  Base ERC20 implmentation for DAYSTARTER tokens - DST(DAYSTARTER Token) and DSP(DAYSTARTER Point).

  Minter can
    - mint DSP but can't mint DST
*/
abstract contract DSToken is ERC20Burnable, AccessControl {
    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory _name,
        string memory _symbol) ERC20(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function mint(address targetAddr, uint256 balance) public virtual onlyRole(MINTER_ROLE) {
        _mint(targetAddr, balance);
    }
}