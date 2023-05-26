// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFTYToken is ERC20Upgradeable, OwnableUpgradeable {
    function initialize() public initializer {
        __ERC20_init("NFTY Token", "NFTY");
        __Ownable_init();
        _mint(owner(), 50000 * 10**uint256(decimals()));
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }
}