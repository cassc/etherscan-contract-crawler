// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IEIP2981.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IRarible.sol";
import "@manifoldxyz/royalty-registry-solidity/contracts/specs/IFoundation.sol";

import "./IRoyaltyInternal.sol";

interface IRoyalty is IEIP2981, IRaribleV1, IRaribleV2, IFoundation, IRoyaltyInternal {
    /**
     * @dev Default royalty for all tokens without a specific royalty.
     */
    function defaultRoyalty() external view returns (TokenRoyalty memory);

    /**
     * @dev Get the number of token specific overrides.  Used to enumerate over all configurations
     */
    function getTokenRoyaltiesCount() external view returns (uint256);

    /**
     * @dev Get a token royalty configuration by index.  Use in conjunction with getTokenRoyaltiesCount to get all per token configurations
     */
    function getTokenRoyaltyByIndex(uint256 index) external view returns (TokenRoyaltyConfig memory);
}