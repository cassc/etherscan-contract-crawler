// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.18;

import "../libraries/utils/DataTypes.sol";

interface IPunkGateway {
    /**
     * @dev Allows users to borrow an estimate `amount` of the reserve underlying asset according to the value of the nft
     * @param reserveId The id of the reserve
     * @param punkIndex The tokenId of the nft to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     **/
    function borrow(
        uint256 reserveId,
        uint256 punkIndex,
        uint256 interestRateMode
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve
     * @param borrowId The id of the borrow to repay
     * @return The final amount repaid
     **/
    function repay(uint256 borrowId)
        external
        payable
        returns (uint256);

    /**
     * @dev Function to claim the liquidate NFT.
     * @param borrowId The id of liquidate borrow target
     **/
    function claimCall(uint256 borrowId) external;
}