// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable {
    constructor() {
        // _disableInitializers();
    }

    function initialize(
        string memory __name,
        string memory __symbol
    ) public initializer {
        __Ownable_init();
        __ERC20_init(__name, __symbol);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }

    function renounceOwnership() public override onlyOwner {
        revert("renounceOwnership disabled!");
    }
}