// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../CollateralFilter.sol";

/**
 * @title Set Collection Collateral Filter
 * @author MetaStreet Labs
 */
contract SetCollectionCollateralFilter is CollateralFilter {
    using EnumerableSet for EnumerableSet.UintSet;

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Supported token
     */
    address private _token;

    /**
     * @notice Set of supported token IDs
     */
    EnumerableSet.UintSet private _tokenIds;

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    /**
     * @notice SetCollectionCollateralFilter initializer
     */
    function _initialize(address token, uint256[] memory tokenIds_) internal {
        /* Validate root and node count */
        if (tokenIds_.length == 0) revert InvalidCollateralFilterParameters();

        /* Set supported token */
        _token = token;

        /* Add each token ID to set of token IDs */
        for (uint256 i; i < tokenIds_.length; i++) {
            _tokenIds.add(tokenIds_[i]);
        }
    }

    /**************************************************************************/
    /* Getters */
    /**************************************************************************/

    /**
     * @inheritdoc CollateralFilter
     */
    function COLLATERAL_FILTER_NAME() external pure override returns (string memory) {
        return "SetCollectionCollateralFilter";
    }

    /**
     * @inheritdoc CollateralFilter
     */
    function COLLATERAL_FILTER_VERSION() external pure override returns (string memory) {
        return "1.0";
    }

    /**
     * @notice Get collateral token
     * @return Collateral token contract
     */
    function collateralToken() external view override returns (address) {
        return _token;
    }

    /**
     * @notice Get collateral token IDs
     * @return Collateral token IDs
     */
    function collateralTokenIds() external view returns (uint256[] memory) {
        return _tokenIds.values();
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc CollateralFilter
     */
    function _collateralSupported(
        address token,
        uint256 tokenId,
        uint256,
        bytes calldata
    ) internal view override returns (bool) {
        /* Validate token supported */
        if (token != _token) return false;

        /* Validate token ID is in set of token IDs */
        return _tokenIds.contains(tokenId);
    }
}