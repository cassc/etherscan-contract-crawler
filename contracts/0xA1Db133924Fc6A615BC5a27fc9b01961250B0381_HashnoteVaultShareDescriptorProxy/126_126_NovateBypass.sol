// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IBatchAuctionSeller } from "../../interfaces/IBatchAuctionSeller.sol";

import { HashnoteVault } from "./base/HashnoteVault.sol";
import { HashnoteOptionsVaultStorage } from "../../storage/HashnoteOptionsVaultStorage.sol";

contract NovateBypass is HashnoteVault, HashnoteOptionsVaultStorage, IBatchAuctionSeller {
    /*///////////////////////////////////////////////////////////////
                    Constructor and initialization
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _share is the erc1155 contract that issues shares
     */
    constructor(address _share) HashnoteVault(_share) { }

    /**
     * @notice Called by auction when bidder claims winnings.
     */
    function novate(address, uint256, uint256[] calldata, uint256[] calldata) external override nonReentrant { }

    function settledAuction(uint256, uint256, int256) external override {
        auctionId = 0;
    }
}