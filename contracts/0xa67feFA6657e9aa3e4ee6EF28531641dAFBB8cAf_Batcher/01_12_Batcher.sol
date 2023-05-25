/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBatcher.sol";
import "../../interfaces/IVault.sol";
import "./EIP712.sol";

/// @title Batcher
/// @author 0xAd1, Bapireddy
/// @notice Used to batch user deposits and withdrawals until the next rebalance
contract Batcher is IBatcher, EIP712, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Vault parameters for the batcher
    VaultInfo public vaultInfo;

    /// @notice Enforces signature checking on deposits
    bool public checkValidDepositSignature;

    /// @notice Creates a new Batcher strictly linked to a vault
    /// @param _verificationAuthority Address of the verification authority which allows users to deposit
    /// @param vaultAddress Address of the vault which will be used to deposit and withdraw want tokens
    /// @param maxAmount Maximum amount of tokens that can be deposited in the vault
    constructor(
        address _verificationAuthority,
        address vaultAddress,
        uint256 maxAmount
    ) {
        verificationAuthority = _verificationAuthority;
        checkValidDepositSignature = true;

        require(vaultAddress != address(0), "NULL_ADDRESS");
        vaultInfo = VaultInfo({
            vaultAddress: vaultAddress,
            tokenAddress: IVault(vaultAddress).wantToken(),
            maxAmount: maxAmount
        });

        IERC20(vaultInfo.tokenAddress).approve(vaultAddress, type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                       USER DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Ledger to maintain addresses and their amounts to be deposited into vault
    mapping(address => uint256) public depositLedger;

    /// @notice Ledger to maintain addresses and their amounts to be withdrawn from vault
    mapping(address => uint256) public withdrawLedger;

    /// @notice Address which authorises users to deposit into Batcher
    address public verificationAuthority;

    /// @notice Amount of want tokens pending to be deposited
    uint256 public pendingDeposit;

    /// @notice Amount of LP tokens pending to be exchanged back to want token
    uint256 public pendingWithdrawal;

    /**
     * @notice Stores the deposits for future batching via periphery
     * @param amountIn Value of token to be deposited. It will be ignored if txn is sent with native ETH
     * @param signature signature verifying that recipient has enough karma and is authorized to deposit by brahma
     * @param recipient address receiving the shares issued by vault
     */
    function depositFunds(
        uint256 amountIn,
        bytes memory signature,
        address recipient,
        PermitParams memory permit
    ) external override nonReentrant {
        validDeposit(recipient, signature);

        if (permit.value != 0) {
            IERC20Permit(vaultInfo.tokenAddress).permit(
                msg.sender,
                address(this),
                permit.value,
                permit.deadline,
                permit.v,
                permit.r,
                permit.s
            );
        }

        uint256 wantBalanceBeforeTransfer = IERC20(vaultInfo.tokenAddress)
            .balanceOf(address(this));

        IERC20(vaultInfo.tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amountIn
        );

        uint256 wantBalanceAfterTransfer = IERC20(vaultInfo.tokenAddress)
            .balanceOf(address(this));

        /// Check in both cases for want balance increase to be correct
        assert(
            wantBalanceAfterTransfer - wantBalanceBeforeTransfer == amountIn
        );

        require(
            IERC20(vaultInfo.vaultAddress).totalSupply() +
                pendingDeposit -
                pendingWithdrawal +
                amountIn <=
                vaultInfo.maxAmount,
            "MAX_LIMIT_EXCEEDED"
        );

        depositLedger[recipient] = depositLedger[recipient] + (amountIn);
        pendingDeposit = pendingDeposit + amountIn;

        emit DepositRequest(recipient, vaultInfo.vaultAddress, amountIn);
    }

    /**
     * @notice User deposits vault LP tokens to be withdrawn. Stores the deposits for future batching via periphery
     * @param amountIn Value of token to be deposited
     */
    function initiateWithdrawal(uint256 amountIn)
        external
        override
        nonReentrant
    {
        require(depositLedger[msg.sender] == 0, "DEPOSIT_PENDING");

        require(amountIn > 0, "AMOUNT_IN_ZERO");

        if (amountIn > userLPTokens[msg.sender]) {
            IERC20(vaultInfo.vaultAddress).safeTransferFrom(
                msg.sender,
                address(this),
                amountIn - userLPTokens[msg.sender]
            );
            userLPTokens[msg.sender] = 0;
        } else {
            userLPTokens[msg.sender] = userLPTokens[msg.sender] - amountIn;
        }

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

        userLPTokens[msg.sender] =
            userLPTokens[msg.sender] +
            (cancellationAmount);

        pendingWithdrawal = pendingWithdrawal - cancellationAmount;

        emit WithdrawRescinded(
            msg.sender,
            vaultInfo.vaultAddress,
            cancellationAmount
        );
    }

    /**
     * @notice Can be used to send LP tokens owed to the recipient
     * @param amount Amount of LP tokens to withdraw
     * @param recipient Address to receive the LP tokens
     */
    function claimTokens(uint256 amount, address recipient)
        public
        override
        nonReentrant
    {
        require(userLPTokens[recipient] >= amount, "NO_FUNDS");
        userLPTokens[recipient] = userLPTokens[recipient] - amount;
        IERC20(vaultInfo.vaultAddress).safeTransfer(recipient, amount);
    }

    /*///////////////////////////////////////////////////////////////
                    VAULT DEPOSIT/WITHDRAWAL LOGIC
  //////////////////////////////////////////////////////////////*/

    /// @notice Ledger to maintain addresses and vault LP tokens which batcher owes them
    mapping(address => uint256) public userLPTokens;

    /// @notice Ledger to maintain addresses and vault want tokens which batcher owes them
    mapping(address => uint256) public userWantTokens;

    /**
     * @notice Performs deposits on the periphery for the supplied users in batch
     * @param users array of users whose deposits must be resolved
     */
    function batchDeposit(address[] memory users)
        external
        override
        nonReentrant
    {
        onlyKeeper();
        IVault vault = IVault(vaultInfo.vaultAddress);

        uint256 amountToDeposit = 0;
        uint256 oldLPBalance = IERC20(address(vault)).balanceOf(address(this));

        // Temprorary array to hold user deposit info and check for duplicate addresses
        uint256[] memory depositValues = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            // Copies deposit value from ledger to temporary array
            uint256 userDeposit = depositLedger[users[i]];
            amountToDeposit = amountToDeposit + userDeposit;
            depositValues[i] = userDeposit;

            // deposit ledger for that address is set to zero
            // Incase of duplicate address sent, new deposit amount used for same user will be 0
            depositLedger[users[i]] = 0;
        }

        require(amountToDeposit > 0, "NO_DEPOSITS");

        uint256 lpTokensReportedByVault = vault.deposit(
            amountToDeposit,
            address(this)
        );

        uint256 lpTokensReceived = IERC20(address(vault)).balanceOf(
            address(this)
        ) - (oldLPBalance);

        assert(lpTokensReceived == lpTokensReportedByVault);

        uint256 totalUsersProcessed = 0;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 userAmount = depositValues[i];

            // Checks if userAmount is not 0, only then proceed to allocate LP tokens
            if (userAmount > 0) {
                uint256 userShare = (userAmount * (lpTokensReceived)) /
                    (amountToDeposit);

                // Allocating LP tokens to user, can be calimed by the user later by calling claimTokens
                userLPTokens[users[i]] = userLPTokens[users[i]] + userShare;
                ++totalUsersProcessed;
            }
        }

        pendingDeposit = pendingDeposit - amountToDeposit;

        emit BatchDepositSuccessful(lpTokensReceived, totalUsersProcessed);
    }

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
                    INTERNAL HELPERS
  //////////////////////////////////////////////////////////////*/

    /// @notice Helper to verify signature against verification authority
    /// @param signature Should be generated by verificationAuthority. Should contain msg.sender
    function validDeposit(address recipient, bytes memory signature)
        internal
        view
    {
        if (checkValidDepositSignature) {
            require(
                verifySignatureAgainstAuthority(
                    recipient,
                    signature,
                    verificationAuthority
                ),
                "INVALID_SIGNATURE"
            );
        }

        require(withdrawLedger[recipient] == 0, "WITHDRAW_PENDING");
    }

    /*///////////////////////////////////////////////////////////////
                    MAINTAINANCE ACTIONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Function to set authority address
    /// @param authority New authority address
    function setAuthority(address authority) public {
        onlyGovernance();

        // Logging old and new verification authority
        emit VerificationAuthorityUpdated(verificationAuthority, authority);
        verificationAuthority = authority;
    }

    /// @inheritdoc IBatcher
    function setVaultLimit(uint256 maxAmount) external override {
        onlyGovernance();
        emit VaultLimitUpdated(
            vaultInfo.vaultAddress,
            vaultInfo.maxAmount,
            maxAmount
        );
        vaultInfo.maxAmount = maxAmount;
    }

    /// @notice Function to enable/disable deposit signature check
    function setDepositSignatureCheck(bool enabled) public {
        onlyGovernance();
        checkValidDepositSignature = enabled;
    }

    /// @notice Function to sweep funds out in case of emergency, can only be called by governance
    /// @param _token Address of token to sweep
    function sweep(address _token) public nonReentrant {
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

    /// @notice Helper to assert msg.sender as keeper address
    function onlyKeeper() internal view {
        require(msg.sender == keeper(), "ONLY_KEEPER");
    }

    /// @notice Helper to asset msg.sender as governance address
    function onlyGovernance() internal view {
        require(governance() == msg.sender, "ONLY_GOV");
    }
}