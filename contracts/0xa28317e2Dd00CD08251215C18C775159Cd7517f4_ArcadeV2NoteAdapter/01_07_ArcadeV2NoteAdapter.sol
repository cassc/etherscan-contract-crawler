// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "contracts/interfaces/INoteAdapter.sol";

import "./LoanLibrary.sol";
import "./IVaultFactory.sol";
import "./IVaultInventoryReporter.sol";

/**************************************************************************/
/* ArcadeV2 Interfaces (subset) */
/**************************************************************************/

interface ILoanCore {
    function getLoan(uint256 loanId) external view returns (LoanLibrary.LoanData calldata loanData);

    function borrowerNote() external returns (IERC721);

    function lenderNote() external returns (IERC721);
}

interface IVaultDepositRouter {
    function factory() external returns (address);

    function reporter() external returns (IVaultInventoryReporter);
}

interface IRepaymentController {
    function claim(uint256 loanId) external;
}

/**************************************************************************/
/* Note Adapter Implementation */
/**************************************************************************/

/**
 * @title ArcadeV2 Note Adapter
 */
contract ArcadeV2NoteAdapter is INoteAdapter {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.1";

    /**
     * @notice Interest rate denominator used for calculating repayment
     */
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;

    /**
     * @notice Basis points denominator used for calculating repayment
     */
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10_000;

    /**************************************************************************/
    /* Errors */
    /**************************************************************************/

    /**
     * @notice Unsupported collateral item
     */
    error UnsupportedCollateralItem();

    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    ILoanCore private immutable _loanCore;
    IERC721 private immutable _borrowerNote;
    IERC721 private immutable _lenderNote;
    IRepaymentController private immutable _repaymentController;
    IVaultFactory private immutable _vaultFactory;
    IVaultInventoryReporter private immutable _vaultInventoryReporter;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice ArcadeV2NoteAdapter constructor
     * @param loanCore Loan core contract
     */
    constructor(
        ILoanCore loanCore,
        IRepaymentController repaymentController,
        IVaultDepositRouter vaultDepositRouter
    ) {
        _loanCore = loanCore;
        _borrowerNote = loanCore.borrowerNote();
        _lenderNote = loanCore.lenderNote();
        _repaymentController = repaymentController;
        _vaultFactory = IVaultFactory(vaultDepositRouter.factory());
        _vaultInventoryReporter = vaultDepositRouter.reporter();
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc INoteAdapter
     */
    function name() external pure returns (string memory) {
        return "Arcade v2 Note Adapter";
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function noteToken() external view returns (IERC721) {
        return IERC721(address(_lenderNote));
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isSupported(uint256 noteTokenId, address currencyToken) external view returns (bool) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(noteTokenId);

        /* Vadiate loan state is active */
        if (loanData.state != LoanLibrary.LoanState.Active) return false;

        /* Validate loan is a single installment */
        if (loanData.terms.numInstallments != 0) return false;

        /* Validate loan currency token matches */
        if (loanData.terms.payableCurrency != currencyToken) return false;

        return true;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanInfo(uint256 noteTokenId) external view returns (LoanInfo memory) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(noteTokenId);

        /* Calculate repayment */
        uint256 principal = loanData.terms.principal;
        uint256 repayment = principal +
            (principal * loanData.terms.interestRate) /
            INTEREST_RATE_DENOMINATOR /
            BASIS_POINTS_DENOMINATOR;

        /* Arrange into LoanInfo structure */
        LoanInfo memory loanInfo = LoanInfo({
            loanId: noteTokenId,
            borrower: _borrowerNote.ownerOf(noteTokenId),
            principal: principal,
            repayment: repayment,
            maturity: uint64(loanData.startDate + loanData.terms.durationSecs),
            duration: uint64(loanData.terms.durationSecs),
            currencyToken: loanData.terms.payableCurrency,
            collateralToken: loanData.terms.collateralAddress,
            collateralTokenId: loanData.terms.collateralId
        });

        return loanInfo;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanAssets(uint256 noteTokenId) external view returns (AssetInfo[] memory) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(noteTokenId);

        /* Collect collateral assets */
        AssetInfo[] memory collateralAssets;
        if (
            loanData.terms.collateralAddress == address(_vaultFactory) &&
            _vaultFactory.isInstance(address(uint160(loanData.terms.collateralId)))
        ) {
            /* Enumerate vault inventory */
            IVaultInventoryReporter.Item[] memory items = _vaultInventoryReporter.enumerateOrFail(
                address(uint160(loanData.terms.collateralId))
            );

            /* Translate vault inventory to asset infos */
            collateralAssets = new AssetInfo[](items.length);
            for (uint256 i; i < items.length; i++) {
                if (items[i].itemType != IVaultInventoryReporter.ItemType.ERC_721) revert UnsupportedCollateralItem();
                collateralAssets[i] = AssetInfo({token: items[i].tokenAddress, tokenId: items[i].tokenId});
            }
        } else {
            collateralAssets = new AssetInfo[](1);
            collateralAssets[0].token = loanData.terms.collateralAddress;
            collateralAssets[0].tokenId = loanData.terms.collateralId;
        }

        return collateralAssets;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLiquidateCalldata(uint256 loanId) external view returns (address, bytes memory) {
        return (address(_repaymentController), abi.encodeWithSignature("claim(uint256)", loanId));
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getUnwrapCalldata(uint256) external pure returns (address, bytes memory) {
        return (address(0), "");
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isRepaid(uint256 loanId) external view returns (bool) {
        return _loanCore.getLoan(loanId).state == LoanLibrary.LoanState.Repaid;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isLiquidated(uint256 loanId) external view returns (bool) {
        return _loanCore.getLoan(loanId).state == LoanLibrary.LoanState.Defaulted;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isExpired(uint256 loanId) external view returns (bool) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(loanId);

        return
            loanData.state == LoanLibrary.LoanState.Active &&
            block.timestamp > loanData.startDate + loanData.terms.durationSecs;
    }
}