// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Collateral Filter API
 * @author MetaStreet Labs
 */
abstract contract CollateralFilter {
    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Invalid parameters
     */
    error InvalidCollateralFilterParameters();

    /**************************************************************************/
    /* API */
    /**************************************************************************/

    /**
     * @notice Get collateral filter name
     * @return Collateral filter name
     */
    function COLLATERAL_FILTER_NAME() external view virtual returns (string memory);

    /**
     * @notice Get collateral filter version
     * @return Collateral filter version
     */
    function COLLATERAL_FILTER_VERSION() external view virtual returns (string memory);

    /**
     * @notice Get collateral token
     * @return Collateral token contract
     */
    function collateralToken() external view virtual returns (address);

    /**
     * Query if collateral token is supported
     * @param token Collateral token contract
     * @param tokenId Collateral Token ID
     * @param index Collateral Token ID index
     * @param context ABI-encoded context
     * @return True if supported, otherwise false
     */
    function _collateralSupported(
        address token,
        uint256 tokenId,
        uint256 index,
        bytes calldata context
    ) internal view virtual returns (bool);
}