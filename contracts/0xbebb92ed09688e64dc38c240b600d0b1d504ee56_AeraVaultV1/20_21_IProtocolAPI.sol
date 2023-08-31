// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IBMerkleOrchard.sol";

/// @title Interface for protocol that owns treasury.
interface IProtocolAPI {
    // Use struct parameter to prevent human error.
    // token: Token address.
    // value: Amount of weight of token.
    struct TokenValue {
        IERC20 token;
        uint256 value;
    }

    /// @notice Initialize Vault with first deposit.
    /// @dev Initial deposit must be performed before
    ///      calling withdraw() or deposit() functions.
    ///      It enables trading, so weights and balances should be in line
    ///      with market spot prices, otherwise there is a significant risk
    ///      of arbitrage.
    ///      This is checked by Balancer in internal transactions:
    ///       If token amount is not zero when join pool.
    /// @param tokenWithAmount Deposit tokens with amount.
    function initialDeposit(TokenValue[] memory tokenWithAmount) external;

    /// @notice Deposit tokens into vault.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    /// @param tokenWithAmount Deposit tokens with amount.
    function deposit(TokenValue[] memory tokenWithAmount) external;

    /// @notice Deposit tokens into vault.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    ///      It reverts if balances were updated in the current block.
    /// @param tokenWithAmount Deposit token with amount.
    function depositIfBalanceUnchanged(TokenValue[] memory tokenWithAmount)
        external;

    /// @notice Withdraw tokens up to requested amounts.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    /// @param tokenWithAmount Requested tokens with amount.
    function withdraw(TokenValue[] memory tokenWithAmount) external;

    /// @notice Withdraw tokens up to requested amounts.
    /// @dev It calls updateWeights() function
    ///      which cancels current active weights change schedule.
    ///      It reverts if balances were updated in the current block.
    /// @param tokenWithAmount Requested tokens with amount.
    function withdrawIfBalanceUnchanged(TokenValue[] memory tokenWithAmount)
        external;

    /// @notice Initiate vault destruction and return all funds to treasury owner.
    function initiateFinalization() external;

    /// @notice Destroy vault and returns all funds to treasury owner.
    function finalize() external;

    /// @notice Change guardian.
    function setGuardian(address newGuardian) external;

    /// @notice Withdraw any tokens accidentally sent to vault.
    function sweep(address token, uint256 amount) external;

    /// @notice Enable swap with current weights.
    function enableTradingRiskingArbitrage() external;

    /// @notice Enable swap with updating weights.
    /// @dev These are checked by Balancer in internal transactions:
    ///       If weight length and token length match.
    ///       If total sum of weights is one.
    ///       If weight is greater than minimum.
    /// @param tokenWithWeight Tokens with new weights.
    function enableTradingWithWeights(TokenValue[] memory tokenWithWeight)
        external;

    /// @notice Disable swap.
    function disableTrading() external;

    /// @notice Claim Balancer rewards.
    /// @dev It calls claimDistributions() function of Balancer MerkleOrchard.
    ///      Once this function is called, the tokens will be transferred to
    ///      the Vault and it can be distributed via sweep function.
    /// @param claims An array of claims provided as a claim struct.
    ///        See https://docs.balancer.fi/products/merkle-orchard/claiming-tokens#claiming-from-the-contract-directly.
    /// @param tokens An array consisting of tokens to be claimed.
    function claimRewards(
        IBMerkleOrchard.Claim[] memory claims,
        IERC20[] memory tokens
    ) external;

    /// @notice Offer ownership to another address
    /// @dev It disables immediate transfer of ownership
    function transferOwnership(address newOwner) external;

    /// @notice Cancel current pending ownership transfer
    function cancelOwnershipTransfer() external;
}