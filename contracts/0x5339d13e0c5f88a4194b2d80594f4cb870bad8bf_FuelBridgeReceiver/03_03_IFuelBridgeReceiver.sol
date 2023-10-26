// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

interface IFuelBridgeReceiver {
    /**
     * @notice Emitted when childToken is burned for the Polygon PoS withdrawal.
     * @param  amount of parentToken transferred to stakers
     */
    event TransferredToStakers(uint256 amount);

    /**
     * @notice Transfers the total amount of parentTokens to the staking contract.
     */
    function transferToStakers() external;
}