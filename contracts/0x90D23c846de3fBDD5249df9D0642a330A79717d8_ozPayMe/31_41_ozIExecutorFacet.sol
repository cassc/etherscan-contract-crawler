// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '../../arbitrum/AppStorage.sol';


interface ozIExecutorFacet {

    /**
     * @notice Final swap
     * @dev Exchanges the amount using the account's slippage.
     * If it fails, it doubles the slippage, divides the amount between two and tries again.
     * If none works, sends the swap's baseToken instead to the user.
     * @param swap_ Struct containing the swap configuration depending on the
     * relation of the account's stablecoin and its Curve pool.
     * @param slippage_ Slippage of the account
     * @param user_ Owner of the account where the emergency transfers will occur in case 
     * any of the swaps can't be completed due to slippage.
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function executeFinalTrade( 
        TradeOps calldata swap_, 
        uint slippage_,
        address user_,
        uint lockNum_
    ) external payable;

    /**
     * @dev Updates the two main variables that will be used on the calculation
     * of the Ozel Index.
     * @param amount_ ETH (WETH internally) sent to the account (after fee discount)
     * @param user_ Owner of the account
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function updateExecutorState(
        uint amount_, 
        address user_,
        uint lockNum_
    ) external payable;

    /**
     * @notice Helper for burn() on oz20Facet when redeeming OZL for funds
     * @dev Allows the modification of the system state, and the user's interaction
     * with it, outside this main contract.
     * @param user_ Owner of account
     * @param newAmount_ ETH (WETH internally) transacted
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function modifyPaymentsAndVolumeExternally(
        address user_, 
        uint newAmount_,
        uint lockNum_
    ) external;

    /**
     * @notice Helper for _transfer() on oz420Facet
     * @dev Executes the logic that will cause the transfer of OZL from one user to another
     * @param sender_ Sender of OZL tokens
     * @param receiver_ Receiver of sender_'s transfer
     * @param amount_ OZL tokens to send to receiver_
     * @param senderBalance_ Sender_'s total OZL balance
     * @param lockNum_ Index of the bit which authorizes the function call
     */
    function transferUserAllocation( 
        address sender_, 
        address receiver_, 
        uint amount_, 
        uint senderBalance_,
        uint lockNum_
    ) external;
}