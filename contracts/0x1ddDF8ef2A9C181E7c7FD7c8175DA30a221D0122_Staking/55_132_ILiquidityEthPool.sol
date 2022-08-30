// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "../interfaces/IWETH.sol";
import "../interfaces/IManager.sol";

/// @title Interface for Pool
/// @notice Allows users to deposit Eth to be deployed to market makers.
/// @notice Mints 1:1 tAsset on deposit, represeting an IOU for the undelrying token that is freely transferable.
/// @notice Holders of tAsset earn rewards based on duration their tokens were deployed and the demand for that asset.
/// @notice Holders of tAsset can redeem for underlying asset after issuing requestWithdrawal and waiting for the next cycle.
interface ILiquidityEthPool {
    struct WithdrawalInfo {
        uint256 minCycle;
        uint256 amount;
    }

    event WithdrawalRequested(address requestor, uint256 amount);
    event BurnerRegistered(address burner, bool allowed);
    event Burned(address indexed account, address indexed burner, uint256 amount);

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the msg.sender.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function deposit(uint256 amount) external payable;

    /// @notice Transfers amount of underlying token from user to this pool and mints fToken to the account.
    /// @notice Depositor must have previously granted transfer approval to the pool via underlying token contract.
    /// @notice Liquidity deposited is deployed on the next cycle - unless a withdrawal request is submitted, in which case the liquidity will be withheld.
    function depositFor(address account, uint256 amount) external payable;

    /// @notice Requests that the manager prepare funds for withdrawal next cycle
    /// @notice Invoking this function when sender already has a currently pending request will overwrite that requested amount and reset the cycle timer
    /// @param amount Amount of fTokens requested to be redeemed
    function requestWithdrawal(uint256 amount) external;

    function approveManager(uint256 amount) external;

    /// @notice Sender must first invoke requestWithdrawal in a previous cycle
    /// @notice This function will burn the fAsset and transfers underlying asset back to sender
    /// @notice Will execute a partial withdrawal if either available liquidity or previously requested amount is insufficient
    /// @param amount Amount of fTokens to redeem, value can be in excess of available tokens, operation will be reduced to maximum permissible
    function withdraw(uint256 amount, bool asEth) external;

    /// @return Reference to the underlying ERC-20 contract
    function weth() external view returns (IWETH);

    /// @return Reference to the underlying ERC-20 contract
    function underlyer() external view returns (address);

    /// @return Amount of liquidity that should not be deployed for market making (this liquidity will be used for completing requested withdrawals)
    function withheldLiquidity() external view returns (uint256);

    /// @notice Get withdraw requests for an account
    /// @param account User account to check
    /// @return minCycle Cycle - block number - that must be active before withdraw is allowed, amount Token amount requested
    function requestedWithdrawals(address account) external view returns (uint256, uint256);

    /// @notice Pause deposits on the pool. Withdraws still allowed
    function pause() external;

    /// @notice Unpause deposits on the pool.
    function unpause() external;

    ///@notice Registers address that is allowed or not allowed to burn 
    ///@dev Address registered as 'true' will be able to burn tAssets in its possession or that it has an allowance to
    ///@param burner Address that will be able / not able to burn tAssets
    ///@param allowedBurner Boolean that will register burner address as able to burn or not
    function registerBurner(address burner, bool allowedBurner) external;

    ///@notice Function allows address to burn tAssets in its posession
    ///@dev Address can burn all tAssets in its posession
    ///@dev Overages are prevented by interited functionality from _burn()
    ///@param amount Amount of tAsset to be burned
    ///@param account Address to be burned from
    function controlledBurn(uint256 amount, address account) external;
}