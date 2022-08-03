// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./external/interfaces/ILendingPool.sol";
import "./interfaces/IFlashRollover.sol";
import "./interfaces/ILoanCore.sol";
import "./interfaces/IOriginationController.sol";
import "./interfaces/IRepaymentController.sol";
import "./interfaces/IFeeController.sol";

import "./v1/ILoanCoreV1.sol";
import "./v1/IAssetWrapperV1.sol";
import "./v1/LoanLibraryV1.sol";

/**
 * @title FlashRolloverV1toV2
 * @author Non-Fungible Technologies, Inc.
 *
 * Based off Arcade.xyz's V1 lending FlashRollover.
 * Uses AAVE flash loan liquidity to repay a loan
 * on the V1 protocol, and open a new loan on V2
 * (with lender's signature).
 */
contract FlashRolloverV1toV2 is IFlashRollover, ReentrancyGuard, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    struct ERC20Holding {
        address tokenAddress;
        uint256 amount;
    }

    struct ERC721Holding {
        address tokenAddress;
        uint256 tokenId;
    }

    struct ERC1155Holding {
        address tokenAddress;
        uint256 tokenId;
        uint256 amount;
    }

    /* solhint-disable var-name-mixedcase */
    // AAVE Contracts
    // Variable names are in upper case to fulfill IFlashLoanReceiver interface
    ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
    ILendingPool public immutable override LENDING_POOL;

    /* solhint-enable var-name-mixedcase */

    address private owner;

    constructor(ILendingPoolAddressesProvider _addressesProvider) {
        ADDRESSES_PROVIDER = _addressesProvider;
        LENDING_POOL = ILendingPool(_addressesProvider.getLendingPool());

        owner = msg.sender;
    }

    function rolloverLoan(
        RolloverContractParams calldata contracts,
        uint256 loanId,
        LoanLibrary.LoanTerms calldata newLoanTerms,
        address lender,
        uint160 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        LoanLibraryV1.LoanTerms memory loanTerms = contracts.sourceLoanCore.getLoan(loanId).terms;

        {
            _validateRollover(contracts.sourceLoanCore, contracts.targetVaultFactory, loanTerms, newLoanTerms, contracts.sourceLoanCore.getLoan(loanId).borrowerNoteId);
        }

        {
            address[] memory assets = new address[](1);
            assets[0] = loanTerms.payableCurrency;

            uint256[] memory amounts = new uint256[](1);
            amounts[0] = loanTerms.principal + loanTerms.interest;

            uint256[] memory modes = new uint256[](1);
            modes[0] = 0;

            bytes memory params = abi.encode(
                OperationData({ contracts: contracts, loanId: loanId, newLoanTerms: newLoanTerms, lender: lender, nonce: nonce, v: v, r: r, s: s })
            );

            // Flash loan based on principal + interest
            LENDING_POOL.flashLoan(address(this), assets, amounts, modes, address(this), params, 0);
        }
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override nonReentrant returns (bool) {
        require(msg.sender == address(LENDING_POOL), "unknown callback sender");
        require(initiator == address(this), "not initiator");

        return _executeOperation(assets, amounts, premiums, abi.decode(params, (OperationData)));
    }

    function _executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        OperationData memory opData
    ) internal returns (bool) {
        OperationContracts memory opContracts = _getContracts(opData.contracts);

        // Get loan details
        LoanLibraryV1.LoanData memory loanData = opContracts.loanCore.getLoan(opData.loanId);

        address borrower = opContracts.borrowerNote.ownerOf(loanData.borrowerNoteId);

        // Do accounting to figure out amount each party needs to receive
        (uint256 flashAmountDue, uint256 needFromBorrower, uint256 leftoverPrincipal) = _ensureFunds(
            amounts[0],
            premiums[0],
            opContracts.feeController.getOriginationFee(),
            opData.newLoanTerms.principal
        );

        IERC20 asset = IERC20(assets[0]);

        if (needFromBorrower > 0) {
            require(asset.balanceOf(borrower) >= needFromBorrower, "borrower cannot pay");
            require(asset.allowance(borrower, address(this)) >= needFromBorrower, "lacks borrower approval");
        }

        _repayLoan(opContracts, loanData, borrower);

        {
            _recreateBundle(opContracts, loanData, opData.newLoanTerms.collateralId);

            uint256 newLoanId = _initializeNewLoan(
                opContracts,
                borrower,
                opData.lender,
                opData
            );

            emit Rollover(
                opContracts.lenderNote.ownerOf(loanData.lenderNoteId),
                borrower,
                loanData.terms.collateralTokenId,
                newLoanId
            );

            if (address(opData.contracts.sourceLoanCore) != address(opData.contracts.targetLoanCore)) {
                emit Migration(address(opContracts.loanCore), address(opContracts.targetLoanCore), newLoanId);
            }
        }

        if (leftoverPrincipal > 0) {
            asset.safeTransfer(borrower, leftoverPrincipal);
        } else if (needFromBorrower > 0) {
            asset.safeTransferFrom(borrower, address(this), needFromBorrower);
        }

        // Approve all amounts for flash loan repayment
        asset.approve(address(LENDING_POOL), flashAmountDue);

        return true;
    }

    function _ensureFunds(
        uint256 amount,
        uint256 premium,
        uint256 originationFee,
        uint256 newPrincipal
    )
        internal
        pure
        returns (
            uint256 flashAmountDue,
            uint256 needFromBorrower,
            uint256 leftoverPrincipal
        )
    {
        // Make sure new loan, minus pawn fees, can be repaid
        flashAmountDue = amount + premium;
        uint256 willReceive = newPrincipal - ((newPrincipal * originationFee) / 10_000);

        if (flashAmountDue > willReceive) {
            // Not enough - have borrower pay the difference
            needFromBorrower = flashAmountDue - willReceive;
        } else if (willReceive > flashAmountDue) {
            // Too much - will send extra to borrower
            leftoverPrincipal = willReceive - flashAmountDue;
        }

        // Either leftoverPrincipal or needFromBorrower should be 0
        require(leftoverPrincipal == 0 || needFromBorrower == 0, "funds conflict");
    }

    function _repayLoan(
        OperationContracts memory contracts,
        LoanLibraryV1.LoanData memory loanData,
        address borrower
    ) internal {
        // Take BorrowerNote from borrower
        // Must be approved for withdrawal
        contracts.borrowerNote.transferFrom(borrower, address(this), loanData.borrowerNoteId);

        // Approve repayment
        IERC20(loanData.terms.payableCurrency).approve(
            address(contracts.repaymentController),
            loanData.terms.principal + loanData.terms.interest
        );

        // Repay loan
        contracts.repaymentController.repay(loanData.borrowerNoteId);

        // contract now has asset wrapper but has lost funds
        require(
            contracts.sourceAssetWrapper.ownerOf(loanData.terms.collateralTokenId) == address(this),
            "collateral ownership"
        );
    }

    function _initializeNewLoan(
        OperationContracts memory contracts,
        address borrower,
        address lender,
        OperationData memory opData
    ) internal returns (uint256) {
        uint256 collateralId = opData.newLoanTerms.collateralId;

        // Withdraw vault token
        IERC721(address(contracts.targetVaultFactory)).safeTransferFrom(borrower, address(this), collateralId);

        // approve originationController
        IERC721(address(contracts.targetVaultFactory)).approve(address(contracts.originationController), collateralId);

        // start new loan
        // stand in for borrower to meet OriginationController's requirements
        uint256 newLoanId = contracts.originationController.initializeLoan(
            opData.newLoanTerms,
            address(this),
            lender,
            IOriginationController.Signature({
                v: opData.v,
                r: opData.r,
                s: opData.s
            }),
            opData.nonce
        );

        contracts.targetBorrowerNote.safeTransferFrom(address(this), borrower, newLoanId);

        return newLoanId;
    }

    function _recreateBundle(
        OperationContracts memory contracts,
        LoanLibraryV1.LoanData memory loanData,
        uint256 vaultId
    ) internal {
        uint256 oldBundleId = loanData.terms.collateralTokenId;
        IAssetWrapper sourceAssetWrapper = IAssetWrapper(address(contracts.sourceAssetWrapper));

        /**
         * @dev Only ERC721 and ERC1155 bundle holdings supported (ERC20 and ETH
         *      holdings will be ignored and get stuck). Only 20 of each supported
         *      (any extras will get stuck).
         */
        ERC721Holding[] memory bundleERC721Holdings = new ERC721Holding[](20);
        ERC1155Holding[] memory bundleERC1155Holdings = new ERC1155Holding[](20);

        for (uint256 i = 0; i < bundleERC721Holdings.length; i++) {
            try sourceAssetWrapper.bundleERC721Holdings(oldBundleId, i) returns (address tokenAddr, uint256 tokenId) {
                bundleERC721Holdings[i] = ERC721Holding(tokenAddr, tokenId);
            } catch { break; }
        }

        for (uint256 i = 0; i < bundleERC1155Holdings.length; i++) {
            try sourceAssetWrapper.bundleERC1155Holdings(oldBundleId, i) returns (address tokenAddr, uint256 tokenId, uint256 amount) {
                bundleERC1155Holdings[i] = ERC1155Holding(tokenAddr, tokenId, amount);
            } catch { break; }
        }

        sourceAssetWrapper.withdraw(oldBundleId);

        // Create new asset vault
        address vault = address(uint160(vaultId));

        for (uint256 i = 0; i < bundleERC721Holdings.length; i++) {
            ERC721Holding memory h = bundleERC721Holdings[i];

            if (h.tokenAddress == address(0)) {
                break;
            }

            IERC721(h.tokenAddress).safeTransferFrom(address(this), vault, h.tokenId);
        }

        for (uint256 i = 0; i < bundleERC1155Holdings.length; i++) {
            ERC1155Holding memory h = bundleERC1155Holdings[i];

            if (h.tokenAddress == address(0)) {
                break;
            }

            IERC1155(h.tokenAddress).safeTransferFrom(address(this), vault, h.tokenId, h.amount, bytes(""));
        }
    }

    function _getContracts(RolloverContractParams memory contracts) internal returns (OperationContracts memory) {
        return
            OperationContracts({
                loanCore: contracts.sourceLoanCore,
                borrowerNote: contracts.sourceLoanCore.borrowerNote(),
                lenderNote: contracts.sourceLoanCore.lenderNote(),
                feeController: contracts.targetLoanCore.feeController(),
                sourceAssetWrapper: contracts.sourceLoanCore.collateralToken(),
                targetVaultFactory: contracts.targetVaultFactory,
                repaymentController: contracts.sourceRepaymentController,
                originationController: contracts.targetOriginationController,
                targetLoanCore: contracts.targetLoanCore,
                targetBorrowerNote: contracts.targetLoanCore.borrowerNote()
            });
    }

    function _validateRollover(
        ILoanCoreV1 sourceLoanCore,
        IVaultFactory targetVaultFactory,
        LoanLibraryV1.LoanTerms memory sourceLoanTerms,
        LoanLibrary.LoanTerms calldata newLoanTerms,
        uint256 borrowerNoteId
    ) internal {
        require(sourceLoanCore.borrowerNote().ownerOf(borrowerNoteId) == msg.sender, "caller not borrower");
        require(newLoanTerms.payableCurrency == sourceLoanTerms.payableCurrency, "currency mismatch");
        require(newLoanTerms.collateralAddress == address(targetVaultFactory), "must use vault");
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner, "not owner");

        owner = _owner;

        emit SetOwner(owner);
    }

    function flushToken(IERC20 token, address to) external override {
        require(msg.sender == owner, "not owner");

        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "no balance");

        token.transfer(to, balance);
    }

    receive() external payable {}
}