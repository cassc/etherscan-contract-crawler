// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../CollateralFilter.sol";

/**
 * @title Ranged Collection Collateral Filter
 * @author MetaStreet Labs
 */
contract RangedCollectionCollateralFilter is CollateralFilter {
    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @notice Supported token
     */
    address private _token;

    /**
     * @notice Supported start token ID (inclusive)
     */
    uint256 private _startTokenId;

    /**
     * @notice Supported end token ID (inclusive)
     */
    uint256 private _endTokenId;

    /**************************************************************************/
    /* Initializer */
    /**************************************************************************/

    /**
     * @notice RangedCollectionCollateralFilter initializer
     */
    function _initialize(address token, uint256 startTokenId, uint256 endTokenId) internal {
        if (endTokenId < startTokenId) revert InvalidCollateralFilterParameters();

        _token = token;
        _startTokenId = startTokenId;
        _endTokenId = endTokenId;
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc CollateralFilter
     */
    function COLLATERAL_FILTER_NAME() external pure override returns (string memory) {
        return "RangedCollectionCollateralFilter";
    }

    /**
     * @inheritdoc CollateralFilter
     */
    function COLLATERAL_FILTER_VERSION() external pure override returns (string memory) {
        return "1.0";
    }

    /**
     * @inheritdoc CollateralFilter
     */
    function collateralToken() external view override returns (address) {
        return _token;
    }

    /**
     * @notice Get collateral token ID range
     * @return Start token ID (inclusive)
     * @return End token ID (inclusive)
     */
    function collateralTokenIdRange() external view returns (uint256, uint256) {
        return (_startTokenId, _endTokenId);
    }

    /**
     * @inheritdoc CollateralFilter
     */
    function _collateralSupported(
        address token,
        uint256 tokenId,
        uint256,
        bytes calldata
    ) internal view override returns (bool) {
        return token == _token && tokenId >= _startTokenId && tokenId <= _endTokenId;
    }
}