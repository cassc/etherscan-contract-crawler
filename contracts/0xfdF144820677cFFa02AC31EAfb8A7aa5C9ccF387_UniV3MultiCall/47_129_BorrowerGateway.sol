// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Constants} from "../Constants.sol";
import {DataTypesPeerToPeer} from "./DataTypesPeerToPeer.sol";
import {Errors} from "../Errors.sol";
import {IAddressRegistry} from "./interfaces/IAddressRegistry.sol";
import {IBaseCompartment} from "./interfaces/compartments/IBaseCompartment.sol";
import {IBorrowerGateway} from "./interfaces/IBorrowerGateway.sol";
import {ILenderVaultImpl} from "./interfaces/ILenderVaultImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";
import {IQuoteHandler} from "./interfaces/IQuoteHandler.sol";
import {IVaultCallback} from "./interfaces/IVaultCallback.sol";

contract BorrowerGateway is ReentrancyGuard, IBorrowerGateway {
    using SafeERC20 for IERC20Metadata;

    // putting fee info in borrow gateway since borrower always pays this upfront
    address public immutable addressRegistry;
    // index 0: base protocol fee is paid even for swap (no tenor)
    // index 1: protocol fee slope scales protocol fee with tenor
    uint128[2] internal protocolFeeParams;

    constructor(address _addressRegistry) {
        if (_addressRegistry == address(0)) {
            revert Errors.InvalidAddress();
        }
        addressRegistry = _addressRegistry;
    }

    function borrowWithOffChainQuote(
        address lenderVault,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.OffChainQuote calldata offChainQuote,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple,
        bytes32[] calldata proof
    ) external nonReentrant returns (DataTypesPeerToPeer.Loan memory) {
        _checkDeadlineAndRegisteredVault(
            borrowInstructions.deadline,
            lenderVault
        );
        {
            address quoteHandler = IAddressRegistry(addressRegistry)
                .quoteHandler();
            IQuoteHandler(quoteHandler).checkAndRegisterOffChainQuote(
                msg.sender,
                lenderVault,
                offChainQuote,
                quoteTuple,
                proof
            );
        }

        (
            DataTypesPeerToPeer.Loan memory loan,
            uint256 loanId,
            uint256 upfrontFee
        ) = _processBorrowTransaction(
                borrowInstructions,
                offChainQuote.generalQuoteInfo,
                quoteTuple,
                lenderVault
            );

        emit Borrowed(
            lenderVault,
            loan.borrower,
            loan,
            upfrontFee,
            loanId,
            borrowInstructions.callbackAddr,
            borrowInstructions.callbackData
        );
        return loan;
    }

    function borrowWithOnChainQuote(
        address lenderVault,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.OnChainQuote calldata onChainQuote,
        uint256 quoteTupleIdx
    ) external nonReentrant returns (DataTypesPeerToPeer.Loan memory) {
        // borrow gateway just forwards data to respective vault and orchestrates transfers
        // borrow gateway is oblivious towards and specific borrow details, and only fwds info
        // vaults needs to check details of given quote and whether it's valid
        // all lenderVaults need to approve BorrowGateway

        // 1. BorrowGateway "optimistically" pulls loanToken from lender vault: either transfers directly to (a) borrower or (b) callbacker for further processing
        // 2. BorrowGateway then pulls collToken from borrower to lender vault
        // 3. Finally, BorrowGateway updates lender vault storage state

        _checkDeadlineAndRegisteredVault(
            borrowInstructions.deadline,
            lenderVault
        );
        {
            address quoteHandler = IAddressRegistry(addressRegistry)
                .quoteHandler();
            IQuoteHandler(quoteHandler).checkAndRegisterOnChainQuote(
                msg.sender,
                lenderVault,
                quoteTupleIdx,
                onChainQuote
            );
        }
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple = onChainQuote
            .quoteTuples[quoteTupleIdx];

        (
            DataTypesPeerToPeer.Loan memory loan,
            uint256 loanId,
            uint256 upfrontFee
        ) = _processBorrowTransaction(
                borrowInstructions,
                onChainQuote.generalQuoteInfo,
                quoteTuple,
                lenderVault
            );

        emit Borrowed(
            lenderVault,
            loan.borrower,
            loan,
            upfrontFee,
            loanId,
            borrowInstructions.callbackAddr,
            borrowInstructions.callbackData
        );
        return loan;
    }

    function repay(
        DataTypesPeerToPeer.LoanRepayInstructions
            calldata loanRepayInstructions,
        address vaultAddr
    ) external nonReentrant {
        _checkDeadlineAndRegisteredVault(
            loanRepayInstructions.deadline,
            vaultAddr
        );
        if (
            loanRepayInstructions.callbackAddr != address(0) &&
            IAddressRegistry(addressRegistry).whitelistState(
                loanRepayInstructions.callbackAddr
            ) !=
            DataTypesPeerToPeer.WhitelistState.CALLBACK
        ) {
            revert Errors.NonWhitelistedCallback();
        }
        ILenderVaultImpl lenderVault = ILenderVaultImpl(vaultAddr);
        DataTypesPeerToPeer.Loan memory loan = lenderVault.loan(
            loanRepayInstructions.targetLoanId
        );
        if (msg.sender != loan.borrower) {
            revert Errors.InvalidBorrower();
        }
        if (
            block.timestamp < loan.earliestRepay ||
            block.timestamp >= loan.expiry
        ) {
            revert Errors.OutsideValidRepayWindow();
        }
        // checks repayAmount <= remaining loan balance
        if (
            loanRepayInstructions.targetRepayAmount == 0 ||
            loanRepayInstructions.targetRepayAmount + loan.amountRepaidSoFar >
            loan.initRepayAmount
        ) {
            revert Errors.InvalidRepayAmount();
        }
        bool noCompartment = loan.collTokenCompartmentAddr == address(0);
        // @dev: amountReclaimedSoFar cannot exceed initCollAmount for non-compartmentalized assets
        uint256 maxReclaimableCollAmount = noCompartment
            ? loan.initCollAmount - loan.amountReclaimedSoFar
            : IBaseCompartment(loan.collTokenCompartmentAddr)
                .getReclaimableBalance(loan.collToken);

        // @dev: amountRepaidSoFar cannot exceed initRepayAmount
        uint128 leftRepaymentAmount = loan.initRepayAmount -
            loan.amountRepaidSoFar;
        uint128 reclaimCollAmount = SafeCast.toUint128(
            (maxReclaimableCollAmount *
                uint256(loanRepayInstructions.targetRepayAmount)) /
                uint256(leftRepaymentAmount)
        );
        if (reclaimCollAmount == 0) {
            revert Errors.ReclaimAmountIsZero();
        }

        lenderVault.updateLoanInfo(
            loanRepayInstructions.targetRepayAmount,
            loanRepayInstructions.targetLoanId,
            reclaimCollAmount,
            noCompartment,
            loan.collToken
        );

        _processRepayTransfers(
            vaultAddr,
            loanRepayInstructions,
            loan,
            leftRepaymentAmount,
            reclaimCollAmount,
            noCompartment
        );

        emit Repaid(
            vaultAddr,
            loanRepayInstructions.targetLoanId,
            loanRepayInstructions.targetRepayAmount
        );
    }

    /**
     * @notice Protocol fee is allowed to be zero, so no min fee checks, only max fee checks
     */
    function setProtocolFeeParams(uint128[2] calldata _newFeeParams) external {
        if (msg.sender != IAddressRegistry(addressRegistry).owner()) {
            revert Errors.InvalidSender();
        }
        if (
            _newFeeParams[0] > Constants.MAX_SWAP_PROTOCOL_FEE ||
            _newFeeParams[1] > Constants.MAX_FEE_PER_ANNUM ||
            (_newFeeParams[0] == protocolFeeParams[0] &&
                _newFeeParams[1] == protocolFeeParams[1])
        ) {
            revert Errors.InvalidFee();
        }
        protocolFeeParams = _newFeeParams;
        emit ProtocolFeeSet(_newFeeParams);
    }

    function getProtocolFeeParams() external view returns (uint128[2] memory) {
        return protocolFeeParams;
    }

    function _processBorrowTransaction(
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.GeneralQuoteInfo calldata generalQuoteInfo,
        DataTypesPeerToPeer.QuoteTuple calldata quoteTuple,
        address lenderVault
    ) internal returns (DataTypesPeerToPeer.Loan memory, uint256, uint256) {
        (
            DataTypesPeerToPeer.Loan memory loan,
            uint256 loanId,
            DataTypesPeerToPeer.TransferInstructions memory transferInstructions
        ) = ILenderVaultImpl(lenderVault).processQuote(
                msg.sender,
                borrowInstructions,
                generalQuoteInfo,
                quoteTuple
            );

        _processTransfers(
            lenderVault,
            borrowInstructions,
            loan,
            transferInstructions
        );
        return (loan, loanId, transferInstructions.upfrontFee);
    }

    // solhint-disable code-complexity
    function _processTransfers(
        address lenderVault,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan memory loan,
        DataTypesPeerToPeer.TransferInstructions memory transferInstructions
    ) internal {
        if (
            borrowInstructions.callbackAddr != address(0) &&
            IAddressRegistry(addressRegistry).whitelistState(
                borrowInstructions.callbackAddr
            ) !=
            DataTypesPeerToPeer.WhitelistState.CALLBACK
        ) {
            revert Errors.NonWhitelistedCallback();
        }
        ILenderVaultImpl(lenderVault).transferTo(
            loan.loanToken,
            borrowInstructions.callbackAddr == address(0)
                ? loan.borrower
                : borrowInstructions.callbackAddr,
            loan.initLoanAmount
        );
        if (borrowInstructions.callbackAddr != address(0)) {
            IVaultCallback(borrowInstructions.callbackAddr).borrowCallback(
                loan,
                borrowInstructions.callbackData
            );
        }

        uint128[2] memory currProtocolFeeParams = protocolFeeParams;
        uint128[2] memory applicableProtocolFeeParams = currProtocolFeeParams;

        address mysoTokenManager = IAddressRegistry(addressRegistry)
            .mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            applicableProtocolFeeParams = IMysoTokenManager(mysoTokenManager)
                .processP2PBorrow(
                    applicableProtocolFeeParams,
                    borrowInstructions,
                    loan,
                    lenderVault
                );
            for (uint256 i; i < 2; ) {
                if (applicableProtocolFeeParams[i] > currProtocolFeeParams[i]) {
                    revert Errors.InvalidFee();
                }
                unchecked {
                    ++i;
                }
            }
        }

        // Note: Collateral and fees flow and breakdown is as follows:
        //
        // collSendAmount ("collSendAmount")
        // |
        // |-- protocolFeeAmount ("protocolFeeAmount")
        // |
        // |-- gross pledge amount
        //     |
        //     |-- gross upfront fee
        //     |   |
        //     |   |-- net upfront fee ("upfrontFee")
        //     |   |
        //     |   |-- transfer fee 1
        //     |
        //     |-- gross reclaimable collateral
        //         |
        //         |-- net reclaimable collateral ("initCollAmount")
        //         |
        //         |-- transfer fee 2 ("expectedCompartmentTransferFee")
        //
        // where expectedProtocolAndVaultTransferFee = protocolFeeAmount + transfer fee 1

        uint256 protocolFeeAmount = _calculateProtocolFeeAmount(
            applicableProtocolFeeParams,
            borrowInstructions.collSendAmount,
            loan.initCollAmount == 0 ? 0 : loan.expiry - block.timestamp
        );

        // check protocolFeeAmount <= expectedProtocolAndVaultTransferFee
        if (
            protocolFeeAmount >
            borrowInstructions.expectedProtocolAndVaultTransferFee
        ) {
            revert Errors.InsufficientSendAmount();
        }

        if (protocolFeeAmount != 0) {
            // note: if coll token has a transfer fee, then protocolFeeAmount received by the protocol will be less than
            // protocolFeeAmount; this is by design to not tax borrowers or lenders for transfer fees on protocol fees
            IERC20Metadata(loan.collToken).safeTransferFrom(
                loan.borrower,
                IAddressRegistry(addressRegistry).owner(),
                protocolFeeAmount
            );
        }
        // determine any transfer fee for sending collateral to vault
        uint256 collTransferFeeForSendingToVault = borrowInstructions
            .expectedProtocolAndVaultTransferFee - protocolFeeAmount;
        // Note: initialize the coll amount that is sent to vault in case there's no compartment
        uint256 grossCollTransferAmountToVault = loan.initCollAmount +
            transferInstructions.upfrontFee +
            collTransferFeeForSendingToVault;
        // Note: initialize the vault's expected coll balance increase in case there's no compartment
        uint256 expVaultCollBalIncrease = loan.initCollAmount +
            transferInstructions.upfrontFee;
        if (transferInstructions.collReceiver != lenderVault) {
            // Note: if there's a compartment then adjust the coll amount that is sent to vault by deducting the amount
            // that goes to the compartment, i.e., the borrower's reclaimable coll amount and any associated transfer fees
            grossCollTransferAmountToVault -= loan.initCollAmount;
            // Note: similarly, adjust the vault's expected coll balance diff by deducting the reclaimable coll amount that
            // goes to the compartment
            expVaultCollBalIncrease -= loan.initCollAmount;

            uint256 collReceiverPreBal = IERC20Metadata(loan.collToken)
                .balanceOf(transferInstructions.collReceiver);
            IERC20Metadata(loan.collToken).safeTransferFrom(
                loan.borrower,
                transferInstructions.collReceiver,
                loan.initCollAmount +
                    borrowInstructions.expectedCompartmentTransferFee
            );
            // check that compartment balance increase matches the intended reclaimable collateral amount
            if (
                IERC20Metadata(loan.collToken).balanceOf(
                    transferInstructions.collReceiver
                ) != loan.initCollAmount + collReceiverPreBal
            ) {
                revert Errors.InvalidSendAmount();
            }
        }

        if (grossCollTransferAmountToVault > 0) {
            // @dev: grossCollTransferAmountToVault can be zero in case no upfront fee and compartment is used
            if (expVaultCollBalIncrease == 0) {
                revert Errors.InconsistentExpVaultBalIncrease();
            }
            uint256 vaultPreBal = IERC20Metadata(loan.collToken).balanceOf(
                lenderVault
            );
            IERC20Metadata(loan.collToken).safeTransferFrom(
                loan.borrower,
                lenderVault,
                grossCollTransferAmountToVault
            );
            if (
                IERC20Metadata(loan.collToken).balanceOf(lenderVault) !=
                vaultPreBal + expVaultCollBalIncrease
            ) {
                revert Errors.InvalidSendAmount();
            }
        }
    }

    function _processRepayTransfers(
        address lenderVault,
        DataTypesPeerToPeer.LoanRepayInstructions memory loanRepayInstructions,
        DataTypesPeerToPeer.Loan memory loan,
        uint128 leftRepaymentAmount,
        uint128 reclaimCollAmount,
        bool noCompartment
    ) internal {
        noCompartment
            ? ILenderVaultImpl(lenderVault).transferTo(
                loan.collToken,
                loanRepayInstructions.callbackAddr == address(0)
                    ? loan.borrower
                    : loanRepayInstructions.callbackAddr,
                reclaimCollAmount
            )
            : ILenderVaultImpl(lenderVault).transferCollFromCompartment(
                loanRepayInstructions.targetRepayAmount,
                leftRepaymentAmount,
                reclaimCollAmount,
                loan.borrower,
                loan.collToken,
                loanRepayInstructions.callbackAddr,
                loan.collTokenCompartmentAddr
            );
        if (loanRepayInstructions.callbackAddr != address(0)) {
            IVaultCallback(loanRepayInstructions.callbackAddr).repayCallback(
                loan,
                loanRepayInstructions.callbackData
            );
        }
        uint256 loanTokenReceived = IERC20Metadata(loan.loanToken).balanceOf(
            lenderVault
        );

        IERC20Metadata(loan.loanToken).safeTransferFrom(
            loan.borrower,
            lenderVault,
            loanRepayInstructions.targetRepayAmount +
                loanRepayInstructions.expectedTransferFee
        );

        loanTokenReceived =
            IERC20Metadata(loan.loanToken).balanceOf(lenderVault) -
            loanTokenReceived;
        if (loanTokenReceived != loanRepayInstructions.targetRepayAmount) {
            revert Errors.InvalidSendAmount();
        }
    }

    function _checkDeadlineAndRegisteredVault(
        uint256 deadline,
        address lenderVault
    ) internal view {
        if (block.timestamp > deadline) {
            revert Errors.DeadlinePassed();
        }
        if (!IAddressRegistry(addressRegistry).isRegisteredVault(lenderVault)) {
            revert Errors.UnregisteredVault();
        }
    }

    function _calculateProtocolFeeAmount(
        uint128[2] memory _protocolFeeParams,
        uint256 collSendAmount,
        uint256 borrowDuration
    ) internal pure returns (uint256 protocolFeeAmount) {
        bool useMaxProtocolFee = _protocolFeeParams[0] +
            ((_protocolFeeParams[1] * borrowDuration) /
                Constants.YEAR_IN_SECONDS) >
            Constants.MAX_TOTAL_PROTOCOL_FEE;
        protocolFeeAmount = useMaxProtocolFee
            ? (collSendAmount * Constants.MAX_TOTAL_PROTOCOL_FEE) /
                Constants.BASE
            : ((_protocolFeeParams[0] * collSendAmount) / Constants.BASE) +
                ((collSendAmount * _protocolFeeParams[1] * borrowDuration) /
                    (Constants.YEAR_IN_SECONDS * Constants.BASE));
    }
}