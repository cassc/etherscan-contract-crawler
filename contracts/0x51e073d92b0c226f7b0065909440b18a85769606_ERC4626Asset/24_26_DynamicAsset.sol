// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '../interfaces/IRelativePriceProvider.sol';
import './Asset.sol';

/**
 * @title Asset with Dynamic Price
 * @notice Contract presenting an asset in a pool
 * @dev The relative price of an asset may change over time.
 * For example, the ratio of staked BNB : BNB increases as staking reward accrues.
 */
contract DynamicAsset is Asset, IRelativePriceProvider {
    constructor(
        address underlyingToken_,
        string memory name_,
        string memory symbol_
    ) Asset(underlyingToken_, name_, symbol_) {}

    /**
     * @notice get the relative price of 1 unit of token in WAD
     */
    function getRelativePrice() external view virtual returns (uint256) {
        return 1e18;
    }
}