// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DataTypesPeerToPeer} from "../DataTypesPeerToPeer.sol";

interface ILenderVaultImpl {
    event AddedSigners(address[] _signers);

    event MinNumberOfSignersSet(uint256 minNumSigners);

    event RemovedSigner(
        address signerRemoved,
        uint256 signerIdx,
        address signerMovedFromEnd
    );

    event CollateralUnlocked(
        address indexed vaultOwner,
        address indexed collToken,
        uint256[] loanIds,
        uint256 amountUnlocked
    );

    event QuoteProcessed(
        uint256 netPledgeAmount,
        DataTypesPeerToPeer.TransferInstructions transferInstructions
    );

    event Withdrew(address indexed tokenAddr, uint256 withdrawAmount);

    event CircuitBreakerUpdated(
        address indexed newCircuitBreaker,
        address indexed oldCircuitBreaker
    );

    event ReverseCircuitBreakerUpdated(
        address indexed newReverseCircuitBreaker,
        address indexed oldReverseCircuitBreaker
    );

    event OnChainQuotingDelegateUpdated(
        address indexed newOnChainQuotingDelegate,
        address indexed oldOnChainQuotingDelegate
    );

    /**
     * @notice function to initialize lender vault
     * @dev factory creates clone and then initializes the vault
     * @param vaultOwner address of vault owner
     * @param addressRegistry registry address
     */
    function initialize(address vaultOwner, address addressRegistry) external;

    /**
     * @notice function to unlock defaulted collateral
     * @dev only loans with same collateral token can be unlocked in one call
     * function will revert if mismatch in coll token to a loan.collToken.
     * @param collToken address of the collateral token
     * @param _loanIds array of indices of the loans to unlock
     */
    function unlockCollateral(
        address collToken,
        uint256[] calldata _loanIds
    ) external;

    /**
     * @notice function to update loan info on a reoay
     * @dev only borrower gateway can call this function
     * loanId is needed by vault to store updated loan info
     * @param repayAmount amount of loan repaid
     * @param loanId index of loan in loans array
     * @param collAmount amount of collateral to unlock
     * @param noCompartment boolean flag indicating whether loan has no compartment
     * @param collToken address of the collateral token
     */
    function updateLoanInfo(
        uint128 repayAmount,
        uint256 loanId,
        uint128 collAmount,
        bool noCompartment,
        address collToken
    ) external;

    /**
     * @notice function to processQuote on a borrow
     * @dev only borrower gateway can call this function
     * @param borrower address of the borrower
     * @param borrowInstructions struct containing all info for borrow (see DataTypesPeerToPeer.sol notes)
     * @param generalQuoteInfo struct containing quote info (see Datatypes.sol notes)
     * @param quoteTuple struct containing specific quote tuple info (see DataTypesPeerToPeer.sol notes)
     * @return loan loan information after processing the quote
     * @return loanId index of loans in the loans array
     * @return transferInstructions struct containing transfer instruction info (see DataTypesPeerToPeer.sol notes)
     */
    function processQuote(
        address borrower,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple
    )
        external
        returns (
            DataTypesPeerToPeer.Loan calldata loan,
            uint256 loanId,
            DataTypesPeerToPeer.TransferInstructions memory transferInstructions
        );

    /**
     * @notice function to withdraw a token from a vault
     * @dev only vault owner can withdraw
     * @param token address of the token to withdraw
     * @param amount amount of token to withdraw
     */
    function withdraw(address token, uint256 amount) external;

    /**
     * @notice function to transfer token from vault
     * @dev only borrow gateway can call this function
     * @param token address of the token to transfer
     * @param recipient address which receives the tokens
     * @param amount amount of token to transfer
     */
    function transferTo(
        address token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice function to transfer token from a compartment
     * @dev only borrow gateway can call this function, if callbackAddr, then
     * the collateral will be transferred to the callback address
     * @param repayAmount amount of loan token to be repaid
     * @param repayAmountLeft amount of loan token still outstanding
     * @param reclaimCollAmount amount of collateral to be reclaimed
     * @param borrowerAddr address of the borrower
     * @param collTokenAddr address of the coll token to transfer to compartment
     * @param callbackAddr address of callback
     * @param collTokenCompartmentAddr address of the coll token compartment
     */
    function transferCollFromCompartment(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr,
        address collTokenCompartmentAddr
    ) external;

    /**
     * @notice function to set minimum number of signers required for an offchain quote
     * @dev this function allows a multi-sig quorum to sign a quote offchain
     * @param _minNumOfSigners minimum number of signatures borrower needs to provide
     */
    function setMinNumOfSigners(uint256 _minNumOfSigners) external;

    /**
     * @notice function to add a signer
     * @dev this function only can be called by vault owner
     * @param _signers array of signers to add
     */
    function addSigners(address[] calldata _signers) external;

    /**
     * @notice function to remove a signer
     * @dev this function only can be called by vault owner
     * @param signer address of signer to be removed
     * @param signerIdx index of the signers array at which signer resides
     */
    function removeSigner(address signer, uint256 signerIdx) external;

    /**
     * @notice function to set a circuit breaker
     * @dev the circuit breaker (and vault owner) can pause all loan offers;
     * note: circuit breaker and reverse circuit breaker can be the same account
     * @param circuitBreaker address of the circuit breaker
     */
    function setCircuitBreaker(address circuitBreaker) external;

    /**
     * @notice function to set a reverse circuit breaker
     * @dev the reverse circuit breaker (and vault owner) can unpause all loan offers;
     * note: circuit breaker and reverse circuit breaker can be the same account
     * @param reverseCircuitBreaker address of the reverse circuit breaker
     */
    function setReverseCircuitBreaker(address reverseCircuitBreaker) external;

    /**
     * @notice function to set a delegate for on chain quoting
     * @dev the quote handler (and vault owner) can add, delete and update on chain quotes
     * @param onChainQuotingDelegate address of the delegate
     */
    function setOnChainQuotingDelegate(address onChainQuotingDelegate) external;

    /**
     * @notice function to pause all quotes from lendervault
     * @dev only vault owner and circuit breaker can pause quotes
     */
    function pauseQuotes() external;

    /**
     * @notice function to unpause all quotes from lendervault
     * @dev only vault owner and reverse circuit breaker can unpause quotes again
     */
    function unpauseQuotes() external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice function to retrieve loan from loans array in vault
     * @dev this function reverts on invalid index
     * @param index index of loan
     * @return loan loan stored at that index in vault
     */
    function loan(
        uint256 index
    ) external view returns (DataTypesPeerToPeer.Loan memory loan);

    /**
     * @notice function to return owner address
     * @return owner address
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice function to return the total number of signers
     * @return number of signers
     */
    function totalNumSigners() external view returns (uint256);

    /**
     * @notice function to return unlocked token balances
     * @param tokens array of token addresses
     * @return balances the vault balances of the token addresses
     * @return _lockedAmounts the vault locked amounts of the token addresses
     */
    function getTokenBalancesAndLockedAmounts(
        address[] calldata tokens
    )
        external
        view
        returns (uint256[] memory balances, uint256[] memory _lockedAmounts);

    /**
     * @notice function to return address of registry
     * @return registry address
     */
    function addressRegistry() external view returns (address);

    /**
     * @notice function to return address of the circuit breaker
     * @return circuit breaker address
     */
    function circuitBreaker() external view returns (address);

    /**
     * @notice function to return address of the reverse circuit breaker
     * @return reverse circuit breaker address
     */
    function reverseCircuitBreaker() external view returns (address);

    /**
     * @notice function to return address of the delegate for on chain quoting
     * @return approved delegate address
     */
    function onChainQuotingDelegate() external view returns (address);

    /**
     * @notice function returns signer at given index
     * @param index of the signers array
     * @return signer address
     */
    function signers(uint256 index) external view returns (address);

    /**
     * @notice function returns minimum number of signers
     * @return minimum number of signers
     */
    function minNumOfSigners() external view returns (uint256);

    /**
     * @notice function returns if address is a signer
     * @return true, if a signer, else false
     */
    function isSigner(address signer) external view returns (bool);

    /**
     * @notice function returns if withdraw mutex is activated
     * @return true, if withdraw already called, else false
     */
    function withdrawEntered() external view returns (bool);

    /**
     * @notice function returns current locked amounts of given token
     * @param token address of the token
     * @return amount of token locked
     */
    function lockedAmounts(address token) external view returns (uint256);

    /**
     * @notice function returns total number of loans
     * @return total number of loans
     */
    function totalNumLoans() external view returns (uint256);
}