// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "contracts/interfaces/INoteAdapter.sol";

/**************************************************************************/
/* NFTfiV2 Interfaces (subset) */
/**************************************************************************/

interface IDirectLoan {
    function LOAN_TYPE() external view returns (bytes32);

    function loanIdToLoan(uint32)
        external
        view
        returns (
            uint256, /* loanPrincipalAmount */
            uint256, /* maximumRepaymentAmount */
            uint256, /* nftCollateralId */
            address, /* loanERC20Denomination */
            uint32, /* loanDuration */
            uint16, /* loanInterestRateForDurationInBasisPoints */
            uint16, /* loanAdminFeeInBasisPoints */
            address, /* nftCollateralWrapper */
            uint64, /* loanStartTime */
            address, /* nftCollateralContract */
            address /* borrower */
        );
}

interface IDirectLoanCoordinator {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    struct Loan {
        address loanContract;
        uint64 smartNftId;
        StatusType status;
    }

    function promissoryNoteToken() external view returns (address);

    function getLoanData(uint32 _loanId) external view returns (Loan memory);

    function getContractFromType(bytes32 _loanType) external view returns (address);
}

interface ISmartNft {
    function loans(uint256 _tokenId)
        external
        view
        returns (
            address, /* loanCoordinator */
            uint256 /* loanId */
        );

    function exists(uint256 _tokenId) external view returns (bool);
}

/**************************************************************************/
/* Note Adapter Implementation */
/**************************************************************************/

/**
 * @title NFTfiV2 Note Adapter
 */
contract NFTfiV2NoteAdapter is INoteAdapter {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.3";

    /**
     * @notice Supported loan type
     */
    bytes32 public constant SUPPORTED_LOAN_TYPE1 = bytes32("DIRECT_LOAN_FIXED_REDEPLOY");
    bytes32 public constant SUPPORTED_LOAN_TYPE2 = bytes32("DIRECT_LOAN_FIXED_COLLECTION");

    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    IDirectLoanCoordinator private immutable _directLoanCoordinator;
    ISmartNft private immutable _noteToken;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice NFTfiV2NoteAdapter constructor
     * @param directLoanCoordinator Direct loan coordinator contract
     */
    constructor(IDirectLoanCoordinator directLoanCoordinator) {
        _directLoanCoordinator = directLoanCoordinator;
        _noteToken = ISmartNft(directLoanCoordinator.promissoryNoteToken());
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc INoteAdapter
     */
    function name() external pure returns (string memory) {
        return "NFTfi v2 Note Adapter";
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function noteToken() external view returns (IERC721) {
        return IERC721(address(_noteToken));
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isSupported(uint256 noteTokenId, address currencyToken) external view returns (bool) {
        /* Lookup loan coordinator and loan id */
        (address loanCoordinator, uint256 loanId) = _noteToken.loans(noteTokenId);

        /* Validate loan coordinator matches */
        if (loanCoordinator != address(_directLoanCoordinator)) return false;

        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Validate loan is active */
        if (loanData.status != IDirectLoanCoordinator.StatusType.NEW) return false;

        /* Get loan contract */
        IDirectLoan loanContract = IDirectLoan(loanData.loanContract);

        /* Validate loan type matches */
        bytes32 loanType = loanContract.LOAN_TYPE();
        if (loanType != SUPPORTED_LOAN_TYPE1 && loanType != SUPPORTED_LOAN_TYPE2) return false;

        /* Lookup loan currency token */
        (, , , address loanERC20Denomination, , , , , , , ) = loanContract.loanIdToLoan(uint32(loanId));

        /* Validate loan currency token matches */
        if (loanERC20Denomination != currencyToken) return false;

        return true;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanInfo(uint256 noteTokenId) external view returns (LoanInfo memory) {
        /* Lookup loan id */
        (, uint256 loanId) = _noteToken.loans(noteTokenId);

        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Get loan contract */
        IDirectLoan loanContract = IDirectLoan(loanData.loanContract);

        /* Lookup loan terms */
        (
            uint256 loanPrincipalAmount,
            uint256 maximumRepaymentAmount,
            uint256 nftCollateralId,
            address loanERC20Denomination,
            uint32 loanDuration,
            ,
            uint16 loanAdminFeeInBasisPoints,
            ,
            uint64 loanStartTime,
            address nftCollateralContract,
            address borrower
        ) = loanContract.loanIdToLoan(uint32(loanId));

        /* Calculate admin fee */
        uint256 adminFee = ((maximumRepaymentAmount - loanPrincipalAmount) * uint256(loanAdminFeeInBasisPoints)) /
            10000;

        /* Arrange into LoanInfo structure */
        LoanInfo memory loanInfo = LoanInfo({
            loanId: loanId,
            borrower: borrower,
            principal: loanPrincipalAmount,
            repayment: maximumRepaymentAmount - adminFee,
            maturity: loanStartTime + loanDuration,
            duration: loanDuration,
            currencyToken: loanERC20Denomination,
            collateralToken: nftCollateralContract,
            collateralTokenId: nftCollateralId
        });

        return loanInfo;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanAssets(uint256 noteTokenId) external view returns (AssetInfo[] memory) {
        /* Lookup loan id */
        (, uint256 loanId) = _noteToken.loans(noteTokenId);

        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Get loan contract */
        IDirectLoan loanContract = IDirectLoan(loanData.loanContract);

        /* Lookup loan terms */
        (, , uint256 nftCollateralId, , , , , , , address nftCollateralContract, ) = loanContract.loanIdToLoan(
            uint32(loanId)
        );

        /* Collect collateral assets */
        AssetInfo[] memory collateralAssets = new AssetInfo[](1);
        collateralAssets[0].token = nftCollateralContract;
        collateralAssets[0].tokenId = nftCollateralId;

        return collateralAssets;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLiquidateCalldata(uint256 loanId) external view returns (address, bytes memory) {
        /* Lookup loan data for loan contract */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        return (loanData.loanContract, abi.encodeWithSignature("liquidateOverdueLoan(uint32)", uint32(loanId)));
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
        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* No way to differentiate a repaid loan from a liquidated loan from just loanId */
        return loanData.status == IDirectLoanCoordinator.StatusType.RESOLVED;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isLiquidated(uint256 loanId) external view returns (bool) {
        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* No way to differentiate a repaid loan from a liquidated loan from just loanId */
        return loanData.status == IDirectLoanCoordinator.StatusType.RESOLVED;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isExpired(uint256 loanId) external view returns (bool) {
        /* Lookup loan data for loan contract */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Lookup loan terms */
        (, , , , uint32 loanDuration, , , , uint64 loanStartTime, , ) = IDirectLoan(loanData.loanContract).loanIdToLoan(
            uint32(loanId)
        );

        return
            loanData.status == IDirectLoanCoordinator.StatusType.NEW && block.timestamp > loanStartTime + loanDuration;
    }
}