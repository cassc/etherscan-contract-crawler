// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";

/**
 * @title   Manages vault slippage limits
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-08-16
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(nexus)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - VaultManagerRole._initialize(_vaultManager)
 * - AbstractSlippage._initialize(_slippageData)
 */
abstract contract AbstractSlippage is VaultManagerRole {
    // Initial slippage limits in basis points. i.e. 1% = 100
    struct SlippageData {
        uint256 redeem;
        uint256 deposit;
        uint256 withdraw;
        uint256 mint;
    }

    // Events for slippage change
    event RedeemSlippageChange(address indexed sender, uint256 slippage);
    event DepositSlippageChange(address indexed sender, uint256 slippage);
    event WithdrawSlippageChange(address indexed sender, uint256 slippage);
    event MintSlippageChange(address indexed sender, uint256 slippage);

    /// @notice Basis points calculation scale. 100% = 10000. 1% = 100
    uint256 public constant BASIS_SCALE = 1e4;

    /// @notice Redeem slippage in basis points i.e. 1% = 100
    uint256 public redeemSlippage;
    /// @notice Deposit slippage in basis points i.e. 1% = 100
    uint256 public depositSlippage;
    /// @notice Withdraw slippage in basis points i.e. 1% = 100
    uint256 public withdrawSlippage;
    /// @notice Mint slippage in basis points i.e. 1% = 100
    uint256 public mintSlippage;

    /// @param _slippageData Initial slippage limits of type `SlippageData`.
    function _initialize(SlippageData memory _slippageData) internal {
        _setRedeemSlippage(_slippageData.redeem);
        _setDepositSlippage(_slippageData.deposit);
        _setWithdrawSlippage(_slippageData.withdraw);
        _setMintSlippage(_slippageData.mint);
    }

    /***************************************
            Internal slippage functions
    ****************************************/

    /// @param _slippage Redeem slippage to apply as basis points i.e. 1% = 100
    function _setRedeemSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid redeem slippage");
        redeemSlippage = _slippage;

        emit RedeemSlippageChange(msg.sender, _slippage);
    }

    /// @param _slippage Deposit slippage to apply as basis points i.e. 1% = 100
    function _setDepositSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid deposit Slippage");
        depositSlippage = _slippage;

        emit DepositSlippageChange(msg.sender, _slippage);
    }

    /// @param _slippage Withdraw slippage to apply as basis points i.e. 1% = 100
    function _setWithdrawSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid withdraw Slippage");
        withdrawSlippage = _slippage;

        emit WithdrawSlippageChange(msg.sender, _slippage);
    }

    /// @param _slippage Mint slippage to apply as basis points i.e. 1% = 100
    function _setMintSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid mint slippage");
        mintSlippage = _slippage;

        emit MintSlippageChange(msg.sender, _slippage);
    }

    /***************************************
            External slippage functions
    ****************************************/

    /// @notice Governor function to set redeem slippage.
    /// @param _slippage Redeem slippage to apply as basis points i.e. 1% = 100
    function setRedeemSlippage(uint256 _slippage) external onlyGovernor {
        _setRedeemSlippage(_slippage);
    }

    /// @notice Governor function to set deposit slippage.
    /// @param _slippage Deposit slippage to apply as basis points i.e. 1% = 100
    function setDepositSlippage(uint256 _slippage) external onlyGovernor {
        _setDepositSlippage(_slippage);
    }

    /// @notice Governor function to set withdraw slippage.
    /// @param _slippage Withdraw slippage to apply as basis points i.e. 1% = 100
    function setWithdrawSlippage(uint256 _slippage) external onlyGovernor {
        _setWithdrawSlippage(_slippage);
    }

    /// @notice Governor function to set mint slippage.
    /// @param _slippage Mint slippage to apply as basis points i.e. 1% = 100
    function setMintSlippage(uint256 _slippage) external onlyGovernor {
        _setMintSlippage(_slippage);
    }
}