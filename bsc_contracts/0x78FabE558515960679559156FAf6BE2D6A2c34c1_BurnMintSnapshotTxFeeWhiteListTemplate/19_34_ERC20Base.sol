// contracts/ERC20Base.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./common/BaseGovernanceWithUserUpgradable.sol";

abstract contract ERC20Base is ERC20Upgradeable, BaseGovernanceWithUserUpgradable{
    uint8 private _decimals;

    function __ERC20Base_init(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_, 
        uint256 amount_        
    ) internal onlyInitializing {
        __BaseGovernanceWithUser_init();
        __ERC20_init_unchained(name_, symbol_);
        __ERC20Base_init_unchained(decimals_, amount_);
    }

    function __ERC20Base_init_unchained(
        uint8 decimals_, 
        uint256 amount_        
    ) internal onlyInitializing {
        _decimals = decimals_;
        _mint(_msgSender(), amount_);
    }

    function decimals() public view virtual override(ERC20Upgradeable) returns (uint8) {
        return _decimals;
    }
}