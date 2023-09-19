// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IInvestmentStrategy.sol";
import "./IEigenLayrDelegation.sol";
import "./IServiceManager.sol";

/**
 * @title Interface for the primary entrypoint for funds into EigenLayr.
 * @author Layr Labs, Inc.
 * @notice See the `InvestmentManager` contract itself for implementation details.
 */
interface IInvestmentManager {
    // packed struct for queued withdrawals
    struct WithdrawerAndNonce {
        address withdrawer;
        uint96 nonce;
    }

    /**
     * Struct type used to specify an existing queued withdrawal. Rather than storing the entire struct, only a hash is stored.
     * In functions that operate on existing queued withdrawals -- e.g. `startQueuedWithdrawalWaitingPeriod` or `completeQueuedWithdrawal`,
     * the data is resubmitted and the hash of the submitted data is computed by `calculateWithdrawalRoot` and checked against the
     * stored hash in order to confirm the integrity of the submitted data.
     */
    struct QueuedWithdrawal {
        IInvestmentStrategy[] strategies;
        IERC20[] tokens;
        uint256[] shares;
        address depositor;
        WithdrawerAndNonce withdrawerAndNonce;
        uint32 withdrawalStartBlock;
        address delegatedAddress;
    }

    /**
     * @notice Deposits `amount` of `token` into the specified `strategy`, with the resultant shares credited to `depositor`
     * @param strategy is the specified strategy where investment is to be made,
     * @param token is the denomination in which the investment is to be made,
     * @param amount is the amount of token to be invested in the strategy by the depositor
     * @dev The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
     * @dev Cannot be called by an address that is 'frozen' (this function will revert if the `msg.sender` is frozen).
     */
    function depositIntoStrategy(IInvestmentStrategy strategy, IERC20 token, uint256 amount)
        external
        returns (uint256);




    /**
     * @notice Used for investing an asset into the specified strategy with the resultant shared created to `staker`,
     * who must sign off on the action
     * @param strategy is the specified strategy where investment is to be made,
     * @param token is the denomination in which the investment is to be made,
     * @param amount is the amount of token to be invested in the strategy by the depositor
     * @param staker the staker that the assets will be deposited on behalf of
     * @param expiry the timestamp at which the signature expires
     * @param r and @param vs are the elements of the ECDSA signature
     * @dev The `msg.sender` must have previously approved this contract to transfer at least `amount` of `token` on their behalf.
     * @dev A signature is required for this function to eliminate the possibility of griefing attacks, specifically those
     * targetting stakers who may be attempting to undelegate.
     * @dev Cannot be called on behalf of a staker that is 'frozen' (this function will revert if the `staker` is frozen).
     */
    function depositIntoStrategyOnBehalfOf(
        IInvestmentStrategy strategy,
        IERC20 token,
        uint256 amount,
        address staker,
        uint256 expiry,
        bytes32 r,
        bytes32 vs
    )
        external
        returns (uint256 shares);

    /// @notice Returns the current shares of `user` in `strategy`
    function investorStratShares(address user, IInvestmentStrategy strategy) external view returns (uint256 shares);

    /**
     * @notice Get all details on the depositor's investments and corresponding shares
     * @return (depositor's strategies, shares in these strategies)
     */
    function getDeposits(address depositor) external view returns (IInvestmentStrategy[] memory, uint256[] memory);

    /// @notice Simple getter function that returns `investorStrats[staker].length`.
    function investorStratsLength(address staker) external view returns (uint256);

    /// @notice Returns the single, central Delegation contract of EigenLayer
    function delegation() external view returns (IEigenLayrDelegation);

}