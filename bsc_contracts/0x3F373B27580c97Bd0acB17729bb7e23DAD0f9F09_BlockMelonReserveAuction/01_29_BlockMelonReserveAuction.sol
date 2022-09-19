/**
 * @notice Submitted for verification at bscscan.com on 2022-09-18
 */

/*
 _______          ___            ___      ___          ___
|   __   \       |   \          /   |    |   \        |   |
|  |  \   \      |    \        /    |    |    \       |   |
|  |__/    |     |     \      /     |    |     \      |   |
|         /      |      \____/      |    |      \     |   |
|        /       |   |\        /|   |    |   |\  \    |   |
|   __   \       |   | \______/ |   |    |   | \  \   |   |
|  |  \   \      |   |          |   |    |   |  \  \  |   |
|  |__/    |     |   |          |   |    |   |   \  \ |   |
|         /      |   |          |   |    |   |    \  \|   |
|________/       |___|          |___|    |___|     \______|
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NFTReserveAuction.sol";

/**
 * @title BlockMelonReserveAuction
 * @author BlockMelon
 * @notice It has the following functionalities:
 *          - auction creation with a reserve price for NFTs
 *          - supported token standard: ERC-721
 *          - transfer the market fee to the treasury of BlockMelon and the revenue of the seller, royalty of the
 *              first owner and creator
 *          - the seller can update the price of its own sale.
 *          - the seller has the right to cancel its own sale.
 *          - a BlockMelon admin has the right to cancel any sale with a reason provided
 * @dev Implements a reserved auction for NFTs.
 * based on: 0x005d77e5eeab2f17e62a11f1b213736ca3c05cf6 `NFTMarketReserveAuction.sol`
 */
contract BlockMelonReserveAuction is NFTReserveAuction {
    function __BlockMelonReserveAuction_init(
        uint256 primaryBlockMelonFeeInBps,
        uint256 secondaryBlockMelonFeeInBps,
        uint256 secondaryCreatorFeeInBps,
        uint256 secondaryFirstOwnerFeeInBps,
        address payable blockMelonTreasury,
        address _adminContract
    ) external initializer {
        __Context_init_unchained();
        __BlockMelonPullPayment_init();
        __BlockMelonTreasury_init_unchained(blockMelonTreasury);
        __BlockMelonMarketConfig_init_unchained(
            primaryBlockMelonFeeInBps,
            secondaryBlockMelonFeeInBps,
            secondaryCreatorFeeInBps,
            secondaryFirstOwnerFeeInBps
        );
        __BlockMelonNFTPaymentManager_init_unchained();
        __NFTReserveAuction_init_unchained();

        _updateAdminContract(_adminContract);
    }

    /**
     * @notice Allows a market admin to update the market fees and auction configuration
     */
    function updateAuctionConfig(
        uint256 primaryBlockMelonFeeInBps,
        uint256 secondaryBlockMelonFeeInBps,
        uint256 secondaryCreatorFeeInBps,
        uint256 secondaryFirstOwnerFeeInBps,
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    ) external onlyBlockMelonAdmin {
        _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
        _updateFeesConfig(
            primaryBlockMelonFeeInBps,
            secondaryBlockMelonFeeInBps,
            secondaryCreatorFeeInBps,
            secondaryFirstOwnerFeeInBps
        );
    }

    /**
     * @notice Allows a market admin to update the treasury address
     */
    function setBlockMelonTreasury(address payable newTreasury)
        external
        onlyBlockMelonAdmin
    {
        _setBlockMelonTreasury(newTreasury);
    }

    /**
     * @notice Allows BlockMelon to change the admin contract address.
     */
    function updateAdminContract(address _adminContract)
        external
        onlyBlockMelonAdmin
    {
        _updateAdminContract(_adminContract);
    }
}