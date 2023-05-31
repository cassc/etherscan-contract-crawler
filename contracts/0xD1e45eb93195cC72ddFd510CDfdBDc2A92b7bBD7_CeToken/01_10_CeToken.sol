// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CeToken is OwnableUpgradeable, ERC20Upgradeable {
    /**
     * Variables
     */

    address private _vault;

    /**
     * Events
     */

    event VaultChanged(address vault);

    /**
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == _vault, "Minter: not allowed");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    
    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        __Ownable_init();
        __ERC20_init_unchained(_name, _symbol);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function changeVault(address vault) external onlyOwner {
        require(vault != address(0));
        _vault = vault;
        emit VaultChanged(vault);
    }

    function getVaultAddress() external view returns (address) {
        return _vault;
    }
}