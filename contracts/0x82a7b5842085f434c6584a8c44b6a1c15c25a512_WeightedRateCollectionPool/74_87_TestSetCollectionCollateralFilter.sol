// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "../../filters/SetCollectionCollateralFilter.sol";

/**
 * @title Test Contract Wrapper for SetCollectionCollateralFilter
 * @author MetaStreet Labs
 */
contract TestSetCollectionCollateralFilter is SetCollectionCollateralFilter {
    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    constructor(address token, uint256[] memory tokenIds) {
        _initialize(token, tokenIds);
    }

    /**************************************************************************/
    /* Wrapper for Primary API */
    /**************************************************************************/

    /**
     * @dev External wrapper function for _collateralSupported
     */
    function collateralSupported(
        address token,
        uint256 tokenId,
        uint256 index,
        bytes calldata context
    ) external view returns (bool) {
        return _collateralSupported(token, tokenId, index, context);
    }
}