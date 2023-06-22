// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ERC20Impl is ERC20Upgradeable, OwnableUpgradeable {
    uint8 private _decimals;

    function __ERC20Impl_init(
        string memory name,
        string memory symbol,
        uint8 tokenDecimals,
        address owner
    ) external initializer {
        _decimals = tokenDecimals;
        __Ownable_init();
        __ERC20_init(name, symbol);
        _transferOwnership(owner);
        _mint(owner, 100000000 * (10**_decimals));
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        ERC20Upgradeable._mint(to, amount);
    }
}