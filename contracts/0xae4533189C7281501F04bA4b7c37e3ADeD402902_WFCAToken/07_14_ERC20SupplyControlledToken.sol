// SPDX-License-Identifier: Not Licensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

/**
 * An abstract contract that provides subclasses
 * with decimals, cap and initial supply functionalities.
 */
abstract contract ERC20SupplyControlledToken is ERC20Capped {
    uint8 private immutable _decimals;

    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        uint8 decimals_,
        uint256 supplyCap_,
        uint256 initialSupply_,
        address initialSupplyRecipient
    ) ERC20(tokenName_, tokenSymbol_) ERC20Capped(supplyCap_) {
        _decimals = decimals_;

        require(initialSupply_ <= supplyCap_, "ERC20Capped: cap exceeded");
        if ((0 < initialSupply_) && (initialSupplyRecipient != address(0))) {
            ERC20._mint(initialSupplyRecipient, initialSupply_);
        } else if (0 < initialSupply_) {
            ERC20._mint(msg.sender, initialSupply_);
        }
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}