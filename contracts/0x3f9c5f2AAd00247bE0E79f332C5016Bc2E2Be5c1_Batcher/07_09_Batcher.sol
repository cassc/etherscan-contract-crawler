/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBatcher.sol";
import "./interfaces/IVault.sol";

/// @title Batcher
/// @author 0xAd1, Bapireddy
/// @notice Used to batch user deposits and withdrawals until the next rebalance
contract Batcher is IBatcher, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Vault parameters for the batcher
    VaultInfo public vaultInfo;

    /// @notice Creates a new Batcher strictly linked to a vault
    /// @param vaultAddress Address of the vault which will be used to deposit and withdraw want tokens
    constructor(address vaultAddress) {
        require(vaultAddress != address(0), "NULL_ADDRESS");
        vaultInfo = VaultInfo({
            vaultAddress: vaultAddress,
            tokenAddress: IVault(vaultAddress).wantToken()
        });

        IERC20(vaultInfo.tokenAddress).approve(vaultAddress, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                       USER DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Ledger to maintain addresses and their amounts to be withdrawn from vault
    mapping(address => uint256) public withdrawLedger;

    /// @notice Amount of LP tokens pending to be exchanged back to want token
    uint256 public pendingWithdrawal;

    /**
     * @notice User deposits vault LP tokens to be withdrawn. Stores the deposits for future batching via periphery
     * @param amountIn Value of token to be deposited
     */

    function initiateWithdrawal(uint256 amountIn)
        external
        override
        nonReentrant
    {
        require(amountIn > 0, "AMOUNT_IN_ZERO");

        IERC20(vaultInfo.vaultAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        withdrawLedger[msg.sender] = withdrawLedger[msg.sender] + (amountIn);

        pendingWithdrawal = pendingWithdrawal + amountIn;

        emit WithdrawRequest(msg.sender, vaultInfo.vaultAddress, amountIn);
    }

    /**
     * @notice Allows user to collect want token back after successfull batch withdrawal
     * @param amountOut Amount of token to be withdrawn
     */
    function completeWithdrawal(uint256 amountOut, address recipient)
        external
        override
        nonReentrant
    {
        require(amountOut != 0, "INVALID_AMOUNTOUT");
        // Will revert if not enough balance
        userWantTokens[recipient] = userWantTokens[recipient] - amountOut;
        IERC20(vaultInfo.tokenAddress).safeTransfer(recipient, amountOut);
        emit WithdrawComplete(recipient, vaultInfo.vaultAddress, amountOut);
    }

    /**
     * @notice Allows user to collect want token back after successfull batch withdrawal
     * @param amountOut Amount of token to be withdrawn
     */
    function completeWithdrawalWithZap(uint256 amountOut, address recipient)
        external
        override
        nonReentrant
    {
        onlyZapper();
        require(amountOut != 0, "INVALID_AMOUNTOUT");
        // Will revert if not enough balance
        userWantTokens[recipient] = userWantTokens[recipient] - amountOut;
        IERC20(vaultInfo.tokenAddress).safeTransfer(zapper(), amountOut);
        emit WithdrawComplete(recipient, vaultInfo.vaultAddress, amountOut);
    }

    /**
     * @notice User deposits vault LP tokens to be withdrawn. Stores the deposits for future batching via periphery
     * @param cancellationAmount Value of token to be cancelled for withdrawal
     */
    function cancelWithdrawal(uint256 cancellationAmount)
        external
        override
        nonReentrant
    {
        require(cancellationAmount > 0, "AMOUNT_IN_ZERO");

        require(
            withdrawLedger[msg.sender] >= cancellationAmount,
            "NO_WITHDRAWAL_PENDING"
        );

        withdrawLedger[msg.sender] =
            withdrawLedger[msg.sender] -
            cancellationAmount;

        pendingWithdrawal = pendingWithdrawal - cancellationAmount;

        IERC20(vaultInfo.vaultAddress).safeTransfer(
            msg.sender,
            cancellationAmount
        );

        emit WithdrawRescinded(
            msg.sender,
            vaultInfo.vaultAddress,
            cancellationAmount
        );
    }

    /// @notice Ledger to maintain addresses and vault want tokens which batcher owes them
    mapping(address => uint256) public userWantTokens;

    /**
     * @notice Performs withdraws on the periphery for the supplied users in batch
     * @param users array of users whose deposits must be resolved
     */
    function batchWithdraw(address[] memory users)
        external
        override
        nonReentrant
    {
        onlyKeeper();
        IVault vault = IVault(vaultInfo.vaultAddress);

        IERC20 token = IERC20(vaultInfo.tokenAddress);

        uint256 amountToWithdraw = 0;
        uint256 oldWantBalance = token.balanceOf(address(this));

        // Temprorary array to hold user withdrawal info and check for duplicate addresses
        uint256[] memory withdrawValues = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            uint256 userWithdraw = withdrawLedger[users[i]];
            amountToWithdraw = amountToWithdraw + userWithdraw;
            withdrawValues[i] = userWithdraw;

            // Withdrawal ledger for that address is set to zero
            // Incase of duplicate address sent, new withdrawal amount used for same user will be 0
            withdrawLedger[users[i]] = 0;
        }

        require(amountToWithdraw > 0, "NO_WITHDRAWS");

        uint256 wantTokensReportedByVault = vault.withdraw(
            amountToWithdraw,
            address(this)
        );

        uint256 wantTokensReceived = token.balanceOf(address(this)) -
            (oldWantBalance);

        assert(wantTokensReceived == wantTokensReportedByVault);

        uint256 totalUsersProcessed = 0;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 userAmount = withdrawValues[i];

            // Checks if userAmount is not 0, only then proceed to allocate want tokens
            if (userAmount > 0) {
                uint256 userShare = (userAmount * wantTokensReceived) /
                    amountToWithdraw;

                // Allocating want tokens to user. Can be claimed by the user by calling completeWithdrawal
                userWantTokens[users[i]] = userWantTokens[users[i]] + userShare;
                ++totalUsersProcessed;
            }
        }

        pendingWithdrawal = pendingWithdrawal - amountToWithdraw;

        emit BatchWithdrawSuccessful(wantTokensReceived, totalUsersProcessed);
    }

    /*///////////////////////////////////////////////////////////////
                    MAINTAINANCE ACTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Function to sweep funds out in case of emergency, can only be called by governance
    /// @param _token Address of token to sweep
    function sweep(address _token) external nonReentrant {
        onlyGovernance();
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    ACCESS MODIFERS
  //////////////////////////////////////////////////////////////*/

    /// @notice Helper to get Governance address from Vault contract
    /// @return Governance address
    function governance() public view returns (address) {
        return IVault(vaultInfo.vaultAddress).governance();
    }

    /// @notice Helper to get Keeper address from Vault contract
    /// @return Keeper address
    function keeper() public view returns (address) {
        return IVault(vaultInfo.vaultAddress).keeper();
    }

    /// @notice Helper to get Keeper address from Vault contract
    /// @return Keeper address
    function zapper() public view returns (address) {
        return IVault(vaultInfo.vaultAddress).zapper();
    }

    /// @notice Helper to assert msg.sender as keeper address
    function onlyKeeper() internal view {
        require(msg.sender == keeper(), "ONLY_KEEPER");
    }

    /// @notice Helper to assert msg.sender as keeper address
    function onlyZapper() internal view {
        require(msg.sender == zapper(), "ONLY_ZAPPER");
    }

    /// @notice Helper to asset msg.sender as governance address
    function onlyGovernance() internal view {
        require(governance() == msg.sender, "ONLY_GOV");
    }
}