// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IVault {
    /**
     * @dev Emitted on new deposit.
     * @param sender address.
     * @param amount deposited.
     * @param tokensToMint on new deposit.
     **/
    event Deposit(
        address indexed sender,
        uint256 amount,
        uint256 tokensToMint,
        uint256 previousDepositBlockNr
    );

    /**
     * @dev Emitted on withdraw.
     * @param sender address to withdraw to.
     * @param amount of eTokens burned.
     * @param stakedTokensToTransfer to address.
     **/
    event Withdraw(address indexed sender, uint256 amount, uint256 stakedTokensToTransfer);

    /**
     * @dev Emitted on setMaxCapacity.
     * @param moderator address
     * @param amount of max capacity
     **/
    event SetMaxCapacity(address moderator, uint256 amount);

    /**
     * @dev Emitted on setMinAmountForFlash.
     * @param moderator address
     * @param amount for min flash loan
     **/
    event SetMinAmountForFlash(address moderator, uint256 amount);

     /**
     * @dev Emitted on pauseVault.
     * @param moderator address
     **/
    event VaultPaused(address moderator);

     /**
     * @dev Emitted on unpauseVault.
     * @param moderator address
     **/
    event VaultResumed(address moderator);

    /**
     * @dev Emitted on unpauseVault.
     * @param treasuryAddress address
     * @param amount uint256
     **/
    event SplitFees(address treasuryAddress, uint256 amount);

    /**
     * @dev Emitted on initialize.
     * @param treasuryAddress address of treasury where part of flash loan fee is sent.
     * @param flashLoanProvider provider of flash loans.
     * @param maxCapacity max capacity for a vault
     **/
    function initialize(
        address treasuryAddress,
        address flashLoanProvider,
        uint256 maxCapacity
    ) external;


}