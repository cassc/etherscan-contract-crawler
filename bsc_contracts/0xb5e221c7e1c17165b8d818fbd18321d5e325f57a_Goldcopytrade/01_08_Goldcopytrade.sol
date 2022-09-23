// SPDX-License-Identifier: GPL-3.0-or-later Or MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Goldcopytrade is ERC20Upgradeable, OwnableUpgradeable {

    uint256 private constant _initialSupply = 15000000 *10**18;

    function initialize() public initializer {
        __ERC20_init('Goldcopytrade', 'GOT');
        __Ownable_init();

        _mint(msg.sender, _initialSupply);
    }
}