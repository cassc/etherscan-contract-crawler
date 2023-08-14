// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import '../interfaces/IRelativePriceProvider.sol';
import './DynamicAsset.sol';

interface IVault {
    function convertToAssets(uint256 shares) external view returns (uint256);
}

/**
 * @title Asset with Dynamic Price
 * @notice Contract presenting an asset in a pool
 * @dev The relative price of an asset may change over time.
 * See ERC-4626: https://ethereum.org/en/developers/docs/standards/tokens/erc-4626/
 */
contract ERC4626Asset is DynamicAsset {
    IVault vault;

    constructor(
        address underlyingToken_,
        string memory name_,
        string memory symbol_,
        IVault _vault
    ) DynamicAsset(underlyingToken_, name_, symbol_) {
        vault = _vault;
    }

    /**
     * @notice get the relative price in WAD
     */
    function getRelativePrice() external view override returns (uint256) {
        return vault.convertToAssets(1e18);
    }
}