// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./interfaces/IYearnVault.sol";
import "./interfaces/IBalanceCalculator.sol";

import "hardhat/console.sol";

contract YearnBalanceCalculator is IBalanceCalculator {
    function getUnderlying(address vault) public view returns (address) {
        return IYearnVault(vault).token();
    }

    function calcValue(
        address vault,
        uint256 amount
    ) public view returns (uint256) {
        uint256 totalAssets = IYearnVault(vault).totalAssets();
        uint256 vaultTotalSupply = IYearnVault(vault).totalSupply();
        if (vaultTotalSupply == 0) {
            return 0;
        }
        return (totalAssets * amount) / vaultTotalSupply;
    }
}