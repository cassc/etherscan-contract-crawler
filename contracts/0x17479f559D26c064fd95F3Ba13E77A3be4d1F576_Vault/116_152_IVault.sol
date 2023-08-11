// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

//  libraries
import { DataTypes } from "../../libraries/types/DataTypes.sol";

/**
 * @title Interface for opty.fi's interest bearing vault
 * @author opty.fi
 * @notice Contains mix of permissioned and permissionless vault methods
 */
interface IVault {
    /**
     * @notice Set maximum standard deviation of vault value in a single block
     * @dev the maximum vault value jump is in percentage basis points set by governance
     * @param _maxVaultValueJump the standard deviation from a vault value in basis points
     */
    function setMaxVaultValueJump(uint256 _maxVaultValueJump) external;

    /**
     * @notice Calculate the value of a vault share in underlying token
     * @dev It should only be called if the current strategy's last step is Curve
     * @return the underlying token worth a vault share is
     */
    function getPricePerFullShareWrite() external returns (uint256);

    /**
     * @notice Withdraw the underying asset of vault from previous strategy if any,
     *         claims and swaps the reward tokens for the underlying token
     *         performs batch minting of shares for users deposited previously without rebalance,
     *         deposits the assets into the new strategy if any or holds the same in the vault
     * @dev the vault will be charged to compensate gas fees if operator calls this function
     */
    function rebalance() external;

    /**
     * @notice Claim the rewards if any strategy have it and swap for underlying token
     * @param _investStrategyHash vault invest strategy hash
     */
    function harvest(bytes32 _investStrategyHash) external;

    /**
     * @notice A cheap function to deposit whole underlying token's balance
     * @dev this function does not rebalance, hence vault shares will be minted on the next rebalance
     */
    function userDepositAll() external;

    /**
     * @notice A cheap function to deposit _amount of underlying token to the vault
     * @dev the user will receive vault shares on next rebalance
     * @param _amount the amount of the underlying token to be deposited
     */
    function userDeposit(uint256 _amount) external;

    /**
     * @notice Deposit full balance in underlying token of the caller and rebalance
     * @dev the vault shares are minted right away
     */
    function userDepositAllRebalance() external;

    /**
     * @notice Deposit amount of underlying token of caller and rebalance
     * @dev the vault shares are minted right away
     * @param _amount the amount of the underlying token
     */
    function userDepositRebalance(uint256 _amount) external;

    /**
     * @notice Redeem full balance of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault
     */
    function userWithdrawAllRebalance() external;

    /**
     * @notice Redeem the amount of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault
     * @param _redeemAmount the vault shares to redeem
     */
    function userWithdrawRebalance(uint256 _redeemAmount) external;

    /**
     * @notice A cheap function to deposit whole underlying token's balance of caller
     * @dev the gas fees are paid in $CHI tokens and vault shares are minted on next rebalance
     */
    function userDepositAllWithCHI() external;

    /**
     * @notice A cheap function to deposit amount of underlying token's balance of caller
     * @dev the gas fees are paid in $CHI tokens and vault shares are minted on next rebalance
     * @param _amount the amount of underlying tokens to be deposited
     */
    function userDepositWithCHI(uint256 _amount) external;

    /**
     * @notice Deposit full balance in underlying token of the caller and rebalance
     * @dev the vault shares are minted right away and gas fees are paid in $CHI tokens
     */
    function userDepositAllRebalanceWithCHI() external;

    /**
     * @notice Deposit amount of underlying token of caller and rebalance
     * @dev the vault shares are minted right away and gas fees are paid in $CHI tokens
     * @param _amount the amount of the underlying token
     */
    function userDepositRebalanceWithCHI(uint256 _amount) external;

    /**
     * @notice Redeem full balance of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault and gas fees are paid in $CHI tokens
     */
    function userWithdrawAllRebalanceWithCHI() external;

    /**
     * @notice Redeem the amount of vault shares for getting yield optimized underlying tokens
     * @dev this function rebalances the vault and gas fees are paid in $CHI tokens
     * @param _redeemAmount the amount of vault shares
     */
    function userWithdrawRebalanceWithCHI(uint256 _redeemAmount) external;

    /**
     * @notice Recall vault investments from current strategy, restricts deposits
     *         and allows redemption of the shares
     * @dev this function can be invoked by governance via registry
     */
    function discontinue() external;

    /**
     * @notice This function can temporarily restrict user from depositing
     *         or withdrawing assets to and from the vault
     * @dev this function can be invoked by governance via registry
     * @param _unpaused for invoking/revoking pause over the vault
     */
    function setUnpaused(bool _unpaused) external;

    /**
     * @notice Retrieve underlying token balance in the vault
     * @return The balance of underlying token in the vault
     */
    function balance() external view returns (uint256);

    /**
     * @notice Calculate the value of a vault share in underlying token
     * @return The underlying token worth a vault share is
     */
    function getPricePerFullShare() external view returns (uint256);

    /**
     * @notice Assign a risk profile name
     * @dev name of the risk profile should be approved by governance
     * @param _riskProfileCode code of the risk profile
     */
    function setRiskProfileCode(uint256 _riskProfileCode) external;

    /**
     * @notice Assign the address of the underlying asset of the vault
     * @dev the underlying asset should be approved by the governance
     * @param _underlyingToken the address of the underlying asset
     */
    function setToken(address _underlyingToken) external;

    /**
     * @dev A helper function to validate the vault value will not be deviated from max vault value
     *      within the same block
     * @param _diff absolute difference between minimum and maximum vault value within a block
     * @param _currentVaultValue the underlying token balance of the vault
     * @return bool returns true if vault value jump is within permissible limits
     */
    function isMaxVaultValueJumpAllowed(uint256 _diff, uint256 _currentVaultValue) external view returns (bool);

    /**
     * @notice A function to be called in case vault needs to claim and harvest tokens in case a strategy
     *         provides multiple reward tokens
     * @param _codes Array of encoded data in bytes which acts as code to execute
     */
    function adminCall(bytes[] memory _codes) external;

    /**
     * @notice A function to get deposit queue
     * @return return queue
     */
    function getDepositQueue() external view returns (DataTypes.UserDepositOperation[] memory);
}