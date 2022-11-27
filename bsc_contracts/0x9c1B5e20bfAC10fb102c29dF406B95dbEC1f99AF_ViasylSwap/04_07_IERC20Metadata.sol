/*
 *		VIASYLSWAP (PYKA)
 *
 *		Total Supply: 100,000,000
 * 
 * 
 *		ViasylSwap Website
 *
 *		https://viasylswap.org/
 *		https://viasyl.io
 *
 *
 *		Social Profiles
 *
 *		https://t.me/ViasylSwap
 *		https://t.me/ViasylSwapAnn
 *		https://twitter.com/ViasylSwap
 *		https://viasylswap.org/SocialProfiles
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}