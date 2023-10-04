// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Constants} from "../Constants.sol";
import {DataTypesPeerToPeer} from "./DataTypesPeerToPeer.sol";
import {Errors} from "../Errors.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {IBaseCompartment} from "./interfaces/compartments/IBaseCompartment.sol";
import {ILenderVaultImpl} from "./interfaces/ILenderVaultImpl.sol";
import {IOracle} from "./interfaces/IOracle.sol";

/**
 * @title LenderVaultImpl
 * @notice This contract implements the logic for the Lender Vault.
 * IMPORTANT: Security best practices dictate that the signers should always take care to
 * keep their private keys safe. Signing only trusted and human-readable public schema data is a good practice. Additionally,
 * the Myso team recommends that the signer should use a purpose-bound address for signing to reduce the chance
 * for a compromised private key to result in loss of funds. The Myso team also recommends that even vaults owned
 * by an EOA should have multiple signers to reduce chance of forged quotes. In the event that a signer is compromised,
 * the vault owner should immediately remove the compromised signer and if possible, add a new signer.
 */

contract LenderVaultImpl is
    Initializable,
    Ownable2Step,
    Pausable,
    ILenderVaultImpl
{
    using SafeERC20 for IERC20Metadata;

    address public addressRegistry;
    address[] public signers;
    address public circuitBreaker;
    address public reverseCircuitBreaker;
    address public onChainQuotingDelegate;
    uint256 public minNumOfSigners;
    mapping(address => bool) public isSigner;
    bool public withdrawEntered;

    mapping(address => uint256) public lockedAmounts;
    DataTypesPeerToPeer.Loan[] internal _loans;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _vaultOwner,
        address _addressRegistry
    ) external initializer {
        addressRegistry = _addressRegistry;
        minNumOfSigners = 1;
        if (_vaultOwner == address(0) || _addressRegistry == address(0)) {
            revert Errors.InvalidAddress();
        }
        super._transferOwnership(_vaultOwner);
    }

    function unlockCollateral(
        address collToken,
        uint256[] calldata _loanIds
    ) external {
        // only owner can call this function
        _checkOwner();
        // if empty array is passed, revert
        uint256 loanIdsLen = _loanIds.length;
        if (loanIdsLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        uint256 totalUnlockableColl;
        for (uint256 i; i < loanIdsLen; ) {
            DataTypesPeerToPeer.Loan storage _loan = _loans[_loanIds[i]];

            if (_loan.collToken != collToken) {
                revert Errors.InconsistentUnlockTokenAddresses();
            }
            if (_loan.collUnlocked || block.timestamp < _loan.expiry) {
                revert Errors.InvalidCollUnlock();
            }
            if (_loan.collTokenCompartmentAddr != address(0)) {
                IBaseCompartment(_loan.collTokenCompartmentAddr)
                    .unlockCollToVault(collToken);
            } else {
                totalUnlockableColl += (_loan.initCollAmount -
                    _loan.amountReclaimedSoFar);
            }
            _loan.collUnlocked = true;
            unchecked {
                ++i;
            }
        }

        lockedAmounts[collToken] -= totalUnlockableColl;

        emit CollateralUnlocked(
            owner(),
            collToken,
            _loanIds,
            totalUnlockableColl
        );
    }

    function updateLoanInfo(
        uint128 repayAmount,
        uint256 loanId,
        uint128 reclaimCollAmount,
        bool noCompartment,
        address collToken
    ) external {
        _senderCheckGateway();

        _loans[loanId].amountRepaidSoFar += repayAmount;
        _loans[loanId].amountReclaimedSoFar += reclaimCollAmount;

        // only update lockedAmounts when no compartment
        if (noCompartment) {
            lockedAmounts[collToken] -= reclaimCollAmount;
        }
    }

    function processQuote(
        address borrower,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple
    )
        external
        whenNotPaused
        returns (
            DataTypesPeerToPeer.Loan memory _loan,
            uint256 loanId,
            DataTypesPeerToPeer.TransferInstructions memory transferInstructions
        )
    {
        _senderCheckGateway();
        if (
            borrowInstructions.collSendAmount <
            borrowInstructions.expectedProtocolAndVaultTransferFee +
                borrowInstructions.expectedCompartmentTransferFee
        ) {
            revert Errors.InsufficientSendAmount();
        }
        // this check early in function removes need for other checks on sum of upfront plus transfer fees underflowing coll send amount
        if (quoteTuple.upfrontFeePctInBase > Constants.BASE) {
            revert Errors.InvalidUpfrontFee();
        }
        // determine the effective net pledge amount on which loan amount and upfront fee calculation is based
        uint256 netPledgeAmount = borrowInstructions.collSendAmount -
            borrowInstructions.expectedProtocolAndVaultTransferFee -
            borrowInstructions.expectedCompartmentTransferFee;
        transferInstructions.upfrontFee =
            (netPledgeAmount * quoteTuple.upfrontFeePctInBase) /
            Constants.BASE;
        (uint256 loanAmount, uint256 repayAmount) = _getLoanAndRepayAmount(
            netPledgeAmount,
            generalQuoteInfo,
            quoteTuple,
            quoteTuple.upfrontFeePctInBase
        );
        // checks to prevent griefing attacks (e.g. small unlocks that aren't worth it)
        if (
            loanAmount < generalQuoteInfo.minLoan ||
            loanAmount > generalQuoteInfo.maxLoan
        ) {
            revert Errors.InvalidSendAmount();
        }
        if (loanAmount < borrowInstructions.minLoanAmount || loanAmount == 0) {
            revert Errors.TooSmallLoanAmount();
        }
        transferInstructions.collReceiver = address(this);
        _loan.borrower = borrower;
        _loan.loanToken = generalQuoteInfo.loanToken;
        _loan.collToken = generalQuoteInfo.collToken;
        _loan.initLoanAmount = SafeCast.toUint128(loanAmount);
        _loan.initCollAmount = SafeCast.toUint128(
            netPledgeAmount - transferInstructions.upfrontFee
        );
        if (quoteTuple.upfrontFeePctInBase < Constants.BASE) {
            // note: if upfrontFee<100% this corresponds to a loan; check that tenor and earliest repay are consistent
            if (
                quoteTuple.tenor <
                SafeCast.toUint40(
                    generalQuoteInfo.earliestRepayTenor +
                        Constants.MIN_TIME_BETWEEN_EARLIEST_REPAY_AND_EXPIRY
                )
            ) {
                revert Errors.InvalidEarliestRepay();
            }
            _loan.expiry = SafeCast.toUint40(
                block.timestamp + quoteTuple.tenor
            );
            _loan.earliestRepay = SafeCast.toUint40(
                block.timestamp + generalQuoteInfo.earliestRepayTenor
            );
            if (_loan.initCollAmount == 0) {
                revert Errors.ReclaimableCollateralAmountZero();
            }
            loanId = _loans.length;
            if (
                generalQuoteInfo.borrowerCompartmentImplementation == address(0)
            ) {
                if (borrowInstructions.expectedCompartmentTransferFee > 0) {
                    revert Errors.InconsistentExpTransferFee();
                }
                lockedAmounts[_loan.collToken] += _loan.initCollAmount;
            } else {
                transferInstructions.collReceiver = _createCollCompartment(
                    generalQuoteInfo.borrowerCompartmentImplementation,
                    loanId
                );
                _loan.collTokenCompartmentAddr = transferInstructions
                    .collReceiver;
            }
            _loan.initRepayAmount = SafeCast.toUint128(repayAmount);
            _loans.push(_loan);
        } else {
            // note: only case left is upfrontFee = 100% and this corresponds to an outright swap;
            // check that tenor is zero and earliest repay is nonzero, and compartment is zero, with no compartment transfer fee
            if (
                _loan.initCollAmount != 0 ||
                quoteTuple.tenor + generalQuoteInfo.earliestRepayTenor != 0 ||
                generalQuoteInfo.borrowerCompartmentImplementation !=
                address(0) ||
                borrowInstructions.expectedCompartmentTransferFee != 0
            ) {
                revert Errors.InvalidSwap();
            }
        }
        emit QuoteProcessed(netPledgeAmount, transferInstructions);
    }

    function withdraw(address token, uint256 amount) external {
        if (withdrawEntered) {
            revert Errors.WithdrawEntered();
        }
        withdrawEntered = true;
        _checkOwner();
        uint256 vaultBalance = IERC20Metadata(token).balanceOf(address(this));
        if (amount == 0 || amount > vaultBalance - lockedAmounts[token]) {
            revert Errors.InvalidWithdrawAmount();
        }
        IERC20Metadata(token).safeTransfer(owner(), amount);
        withdrawEntered = false;
        emit Withdrew(token, amount);
    }

    function transferTo(
        address token,
        address recipient,
        uint256 amount
    ) external {
        _senderCheckGateway();
        if (
            amount >
            IERC20Metadata(token).balanceOf(address(this)) -
                lockedAmounts[token]
        ) {
            revert Errors.InsufficientVaultFunds();
        }
        IERC20Metadata(token).safeTransfer(recipient, amount);
    }

    function transferCollFromCompartment(
        uint256 repayAmount,
        uint256 repayAmountLeft,
        uint128 reclaimCollAmount,
        address borrowerAddr,
        address collTokenAddr,
        address callbackAddr,
        address collTokenCompartmentAddr
    ) external {
        _senderCheckGateway();
        IBaseCompartment(collTokenCompartmentAddr).transferCollFromCompartment(
            repayAmount,
            repayAmountLeft,
            reclaimCollAmount,
            borrowerAddr,
            collTokenAddr,
            callbackAddr
        );
    }

    function setMinNumOfSigners(uint256 _minNumOfSigners) external {
        _checkOwner();
        if (_minNumOfSigners == 0 || _minNumOfSigners == minNumOfSigners) {
            revert Errors.InvalidNewMinNumOfSigners();
        }
        minNumOfSigners = _minNumOfSigners;
        emit MinNumberOfSignersSet(_minNumOfSigners);
    }

    function addSigners(address[] calldata _signers) external {
        _checkOwner();
        uint256 signersLen = _signers.length;
        if (signersLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        address vaultOwner = owner();
        for (uint256 i; i < signersLen; ) {
            if (_signers[i] == address(0) || _signers[i] == vaultOwner) {
                revert Errors.InvalidAddress();
            }
            if (isSigner[_signers[i]]) {
                revert Errors.AlreadySigner();
            }
            isSigner[_signers[i]] = true;
            signers.push(_signers[i]);
            unchecked {
                ++i;
            }
        }
        emit AddedSigners(_signers);
    }

    function removeSigner(address signer, uint256 signerIdx) external {
        _checkOwner();
        uint256 signersLen = signers.length;
        if (signerIdx >= signersLen) {
            revert Errors.InvalidArrayIndex();
        }

        if (!isSigner[signer] || signer != signers[signerIdx]) {
            revert Errors.InvalidSignerRemoveInfo();
        }
        address signerWithSwappedPosition;
        if (signerIdx != signersLen - 1) {
            signerWithSwappedPosition = signers[signersLen - 1];
            signers[signerIdx] = signerWithSwappedPosition;
        }
        signers.pop();
        isSigner[signer] = false;
        emit RemovedSigner(signer, signerIdx, signerWithSwappedPosition);
    }

    function setCircuitBreaker(address newCircuitBreaker) external {
        _checkOwner();
        address oldCircuitBreaker = circuitBreaker;
        _checkCircuitBreaker(newCircuitBreaker, oldCircuitBreaker);
        circuitBreaker = newCircuitBreaker;
        emit CircuitBreakerUpdated(newCircuitBreaker, oldCircuitBreaker);
    }

    function setReverseCircuitBreaker(
        address newReverseCircuitBreaker
    ) external {
        _checkOwner();
        address oldReverseCircuitBreaker = reverseCircuitBreaker;
        _checkCircuitBreaker(
            newReverseCircuitBreaker,
            oldReverseCircuitBreaker
        );
        reverseCircuitBreaker = newReverseCircuitBreaker;
        emit ReverseCircuitBreakerUpdated(
            newReverseCircuitBreaker,
            oldReverseCircuitBreaker
        );
    }

    function setOnChainQuotingDelegate(
        address newOnChainQuotingDelegate
    ) external {
        _checkOwner();
        address oldOnChainQuotingDelegate = onChainQuotingDelegate;
        // delegate is allowed to be a signer, unlike owner, circuit breaker or reverse circuit breaker
        if (
            newOnChainQuotingDelegate == oldOnChainQuotingDelegate ||
            newOnChainQuotingDelegate == owner()
        ) {
            revert Errors.InvalidAddress();
        }
        onChainQuotingDelegate = newOnChainQuotingDelegate;
        emit OnChainQuotingDelegateUpdated(
            newOnChainQuotingDelegate,
            oldOnChainQuotingDelegate
        );
    }

    function pauseQuotes() external {
        if (msg.sender != circuitBreaker && msg.sender != owner()) {
            revert Errors.InvalidSender();
        }
        _pause();
    }

    function unpauseQuotes() external {
        if (msg.sender != reverseCircuitBreaker && msg.sender != owner()) {
            revert Errors.InvalidSender();
        }
        _unpause();
    }

    function loan(
        uint256 loanId
    ) external view returns (DataTypesPeerToPeer.Loan memory _loan) {
        uint256 loansLen = _loans.length;
        if (loanId >= loansLen) {
            revert Errors.InvalidArrayIndex();
        }
        _loan = _loans[loanId];
    }

    function totalNumLoans() external view returns (uint256) {
        return _loans.length;
    }

    function getTokenBalancesAndLockedAmounts(
        address[] calldata tokens
    )
        external
        view
        returns (uint256[] memory balances, uint256[] memory _lockedAmounts)
    {
        uint256 tokensLen = tokens.length;
        if (tokensLen == 0) {
            revert Errors.InvalidArrayLength();
        }
        balances = new uint256[](tokensLen);
        _lockedAmounts = new uint256[](tokensLen);
        for (uint256 i; i < tokensLen; ) {
            if (tokens[i] == address(0)) {
                revert Errors.InvalidAddress();
            }
            balances[i] = IERC20Metadata(tokens[i]).balanceOf(address(this));
            _lockedAmounts[i] = lockedAmounts[tokens[i]];
            unchecked {
                ++i;
            }
        }
    }

    function totalNumSigners() external view returns (uint256) {
        return signers.length;
    }

    function transferOwnership(
        address _newOwnerProposal
    ) public override(Ownable2Step, ILenderVaultImpl) {
        if (
            _newOwnerProposal == address(this) ||
            _newOwnerProposal == pendingOwner() ||
            _newOwnerProposal == owner() ||
            isSigner[_newOwnerProposal]
        ) {
            revert Errors.InvalidNewOwnerProposal();
        }
        // @dev: access control check via super.transferOwnership()
        super.transferOwnership(_newOwnerProposal);
    }

    function owner()
        public
        view
        override(Ownable, ILenderVaultImpl)
        returns (address)
    {
        return super.owner();
    }

    function pendingOwner()
        public
        view
        override(Ownable2Step, ILenderVaultImpl)
        returns (address)
    {
        return super.pendingOwner();
    }

    function renounceOwnership() public pure override {
        revert Errors.Disabled();
    }

    function _createCollCompartment(
        address borrowerCompartmentImplementation,
        uint256 loanId
    ) internal returns (address collCompartment) {
        collCompartment = Clones.clone(borrowerCompartmentImplementation);
        IBaseCompartment(collCompartment).initialize(address(this), loanId);
    }

    function _senderCheckGateway() internal view {
        if (msg.sender != IAddressRegistry(addressRegistry).borrowerGateway()) {
            revert Errors.UnregisteredGateway();
        }
    }

    function _getLoanAndRepayAmount(
        uint256 netPledgeAmount,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple,
        uint256 upfrontFeePctInBase
    ) internal view returns (uint256 loanAmount, uint256 repayAmount) {
        uint256 loanPerCollUnit;
        if (generalQuoteInfo.oracleAddr == address(0)) {
            loanPerCollUnit = quoteTuple.loanPerCollUnitOrLtv;
        } else {
            // arbitrage protection if LTV > 100% and no whitelist restriction
            if (
                quoteTuple.loanPerCollUnitOrLtv > Constants.BASE &&
                generalQuoteInfo.whitelistAddr == address(0)
            ) {
                revert Errors.LtvHigherThanMax();
            }
            (uint256 collTokenPriceRaw, uint256 loanTokenPriceRaw) = IOracle(
                generalQuoteInfo.oracleAddr
            ).getRawPrices(
                    generalQuoteInfo.collToken,
                    generalQuoteInfo.loanToken
                );
            loanPerCollUnit =
                Math.mulDiv(
                    quoteTuple.loanPerCollUnitOrLtv,
                    collTokenPriceRaw *
                        10 **
                            IERC20Metadata(generalQuoteInfo.loanToken)
                                .decimals(),
                    loanTokenPriceRaw
                ) /
                Constants.BASE;
        }
        uint256 unscaledLoanAmount = loanPerCollUnit * netPledgeAmount;
        uint256 collTokenDecimals = IERC20Metadata(generalQuoteInfo.collToken)
            .decimals();

        // calculate loan amount
        loanAmount = unscaledLoanAmount / (10 ** collTokenDecimals);

        // calculate repay amount and interest rate factor only for loans
        if (upfrontFeePctInBase < Constants.BASE) {
            // calculate interest rate factor
            // @dev: custom typecasting rather than safecasting to catch when interest rate factor = 0
            int256 _interestRateFactor = int256(Constants.BASE) +
                quoteTuple.interestRatePctInBase;
            if (_interestRateFactor <= 0) {
                revert Errors.InvalidInterestRateFactor();
            }
            uint256 interestRateFactor = uint256(_interestRateFactor);

            // calculate repay amount
            repayAmount =
                Math.mulDiv(
                    unscaledLoanAmount,
                    interestRateFactor,
                    Constants.BASE
                ) /
                (10 ** collTokenDecimals);
        }
    }

    function _checkCircuitBreaker(
        address newCircuitBreaker,
        address oldCircuitBreaker
    ) internal view {
        if (
            newCircuitBreaker == oldCircuitBreaker ||
            newCircuitBreaker == owner() ||
            isSigner[newCircuitBreaker]
        ) {
            revert Errors.InvalidAddress();
        }
    }
}