// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface INTokenStakefish {
    /**
     * @dev Claim the fee pool reward amount requested by the user for the given token IDs.
     *
     * @param tokenIds List of token IDs for which fee pool rewards are being claimed
     * @param amountsRequested List of claim amounts requested by the user for each token
     * @param to The recipient of claimed ETH
     *
     * @notice This function allows the user to claim the fee pool reward for the given set of validator NFT token IDs
     * The amountsRequested list must be strictly ordered with respect to the tokenIds list
     */
    function claimFeePool(
        uint256[] calldata tokenIds,
        uint256[] calldata amountsRequested,
        address to
    ) external;

    /**
     * @dev Get the `StakefishNTokenData` struct associated with the given token ID
     *
     * @param tokenId The token ID of the validator NFT
     *
     * @return A `StakefishNTokenData` struct containing the metadata associated with the given NFT token ID
     *
     * @notice This function allows users to retrieve the `StakefishNTokenData` struct that contains the metadata
     * associated with the specified validator NFT token ID. The metadata includes the token's name, symbol, asset address,
     * and maximum supply. This function can be used to retrieve additional details about a particular validator NFT token.
     */
    function getNFTData(uint256 tokenId)
        external
        view
        returns (DataTypes.StakefishNTokenData memory);
}