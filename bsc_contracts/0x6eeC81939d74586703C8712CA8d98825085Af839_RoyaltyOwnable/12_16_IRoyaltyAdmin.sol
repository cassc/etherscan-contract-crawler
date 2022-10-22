// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "./IRoyaltyInternal.sol";

interface IRoyaltyAdmin {
    /**
     * @dev Set per token royalties.  Passing a recipient of address(0) will delete any existing configuration
     */
    function setTokenRoyalties(IRoyaltyInternal.TokenRoyaltyConfig[] calldata royalties) external;

    /**
     * @dev Set a default royalty configuration.  Will be used if no token specific configuration is set
     */
    function setDefaultRoyalty(IRoyaltyInternal.TokenRoyalty calldata royalty) external;
}