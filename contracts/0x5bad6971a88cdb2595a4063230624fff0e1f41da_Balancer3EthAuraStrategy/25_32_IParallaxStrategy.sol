//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ITokensRescuer.sol";

interface IParallaxStrategy is ITokensRescuer {
    /**
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               user - user from whom assets are debited for the deposit.
     *               holder - holder of position.
     *               positionId - id of the position.
     *               amounts - array of amounts to deposit.
     *               data - additional data for strategy.
     */
    struct DepositParams {
        uint256[] amountsOutMin;
        address[][] paths;
        address user;
        address holder;
        uint256 positionId;
        uint256[] amounts;
        bytes[] data;
    }

    /**
     * @param params parameters for withdraw.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               positionId - id of the position.
     *               earned - earnings for the current number of shares.
     *               amounts - array of amounts to deposit.
     *               receiver - address of the user who will receive
     *                          the withdrawn assets.
     *               holder - holder of position.
     *               data - additional data for strategy.
     */
    struct WithdrawParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 positionId;
        uint256 earned;
        uint256 amount;
        address receiver;
        address holder;
        bytes[] data;
    }

    /**
     * @notice Sets the minimum amount required for compounding.
     * @param compoundMinAmount The new minimum amount for compounding.
     */
    function setCompoundMinAmount(uint256 compoundMinAmount) external;

    /**
     * @notice Allows to deposit LP tokens directly
     *         Executes compound before depositing.
     *         Tokens that is depositing must be approved to this contract.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositLPs(DepositParams memory params) external returns (uint256);

    /**
     * @notice Allows to deposit strategy tokens directly.
     *         Executes compound before depositing.
     *         Tokens that is depositing must be approved to this contract.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositTokens(
        DepositParams memory params
    ) external returns (uint256);

    /**
     * @notice Allows to deposit native tokens.
     *         Executes compound before depositing.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens.
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable returns (uint256);

    /**
     * @notice Allows to deposit whitelisted ERC-20 token.
     *      ERC-20 token that is depositing must be approved to this contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external returns (uint256);

    /**
     * @notice withdraws needed amount of staked LPs
     *      Sends to the user his LP tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawLPs(WithdrawParams memory params) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      from the Sorbettiere staking smart-contract.
     *      Sends to the user his strategy tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawTokens(WithdrawParams memory params) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      Exchanges all received strategy tokens for ETH token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      Exchanges all received strategy tokens for whitelisted ERC20 token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external;

    /**
     * @notice Informs the strategy about the position transfer
     * @param from A wallet from which token (user position) will be transferred.
     * @param to A wallet to which token (user position) will be transferred.
     * @param tokenId An ID of a token to transfer which is related to user
     *                position.
     */
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Informs the strategy about the claim rewards.
     * @param strategyId An ID of an earning strategy.
     * @param user Holder of position.
     * @param positionId An ID of a position.
     */
    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external;

    /**
     * @notice claims all rewards
     *      Then exchanges them for strategy tokens.
     *      Receives LP tokens for liquidity and deposits received LP tokens to
     *      increase future rewards.
     *      Can only be called by the Parallax contact.
     * @param amountsOutMin an array of minimum values
     *                      that will be received during exchanges,
     *                      withdrawals or deposits of liquidity, etc.
     *                      All values can be 0 that means
     *                      that you agreed with any output value.
     * @return received LP tokens earned with compound.
     */
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external returns (uint256);

    /**
     * @notice Returns the maximum commission values for the current strategy.
     *      Can not be updated after the deployment of the strategy.
     *      Can be called by anyone.
     * @return max fee for this strategy
     */
    function getMaxFee() external view returns (uint256);

    /**
     * @notice A function that returns the accumulated fees.
     * @dev This is an external view function that returns the current
     *      accumulated fees.
     * @return The current accumulated fees as a uint256 value.
     */
    function accumulatedFees() external view returns (uint256);

    /**
     * @notice A function that returns the address of the strategy author.
     * @dev This is an external view function that returns the address
     *      associated with the author of the strategy.
     * @return The address of the strategy author as an 'address' type.
     */
    function STRATEGY_AUTHOR() external view returns (address);
}