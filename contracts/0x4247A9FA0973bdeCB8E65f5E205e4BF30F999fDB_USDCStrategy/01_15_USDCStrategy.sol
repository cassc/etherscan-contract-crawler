// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


/// Openzeppelin imports
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// Yearn imports
import "./VaultInterface.sol";

/// Local imports
import "./YearnStrategy.sol";

/**
 * @title Implementation of the Yearn Strategy.
 *
 */
contract USDCStrategy is YearnStrategy {

    /// Constructor
    constructor() {

    }

    /// Public override member functions

    function decimals() public override virtual pure returns(uint256) {
        return 6;
    }

    function vaultAddress() public view override virtual returns(address) {

        return 0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE;
    }

    function vaultTokenAddress() public view override virtual returns(address) {

        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }

    function takeReward(address to_, uint256 amount_) public override {

        uint256 share = (10**decimals()) * amount_ / VaultInterface(vaultAddress()).pricePerShare();

        VaultInterface(vaultAddress()).withdraw(share, to_);
    }
}