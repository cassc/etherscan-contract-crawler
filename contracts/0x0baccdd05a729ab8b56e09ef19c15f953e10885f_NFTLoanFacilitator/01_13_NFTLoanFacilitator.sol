// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib, ERC20} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC1820Registry} from "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

import {INFTLoanFacilitator} from './interfaces/INFTLoanFacilitator.sol';
import {IERC721Mintable} from './interfaces/IERC721Mintable.sol';
import {ILendTicket} from './interfaces/ILendTicket.sol';

contract NFTLoanFacilitator is Ownable, INFTLoanFacilitator, IERC777Recipient {
    using SafeTransferLib for ERC20;

    // ==== constants ====

    /** 
     * See {INFTLoanFacilitator-INTEREST_RATE_DECIMALS}.     
     * @dev lowest non-zero APR possible = (1/10^3) = 0.001 = 0.1%
     */
    uint8 public constant override INTEREST_RATE_DECIMALS = 3;

    /// See {INFTLoanFacilitator-SCALAR}.
    uint256 public constant override SCALAR = 10 ** INTEREST_RATE_DECIMALS;

    
    // ==== state variables ====

    /// See {INFTLoanFacilitator-originationFeeRate}.
    /// @dev starts at 1%
    uint256 public override originationFeeRate = 10 ** (INTEREST_RATE_DECIMALS - 2);

    /// See {INFTLoanFacilitator-requiredImprovementRate}.
    /// @dev starts at 10%
    uint256 public override requiredImprovementRate = 10 ** (INTEREST_RATE_DECIMALS - 1);

    /// See {INFTLoanFacilitator-lendTicketContract}.
    address public override lendTicketContract;

    /// See {INFTLoanFacilitator-borrowTicketContract}.
    address public override borrowTicketContract;

    /// See {INFTLoanFacilitator-loanInfo}.
    mapping(uint256 => Loan) public loanInfo;

    /// @dev tracks loan count
    uint256 private _nonce = 1;

    
    // ==== modifiers ====

    modifier notClosed(uint256 loanId) { 
        require(!loanInfo[loanId].closed, "loan closed");
        _; 
    }


    // ==== constructor ====

    constructor(address _manager) {
        transferOwnership(_manager);

        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(
            address(this),
            keccak256("ERC777TokensRecipient"),
            address(this)
        );
    }

    
    // ==== state changing external functions ====

    /// See {INFTLoanFacilitator-createLoan}.
    function createLoan(
        uint256 collateralTokenId,
        address collateralContractAddress,
        uint16 maxPerAnnumInterest,
        bool allowLoanAmountIncrease,
        uint128 minLoanAmount,
        address loanAssetContractAddress,
        uint32 minDurationSeconds,
        address mintBorrowTicketTo
    )
        external
        override
        returns (uint256 id) 
    {
        require(minDurationSeconds != 0, '0 duration');
        require(minLoanAmount != 0, '0 loan amount');
        require(collateralContractAddress != lendTicketContract,
        'lend ticket collateral');
        require(collateralContractAddress != borrowTicketContract, 
        'borrow ticket collateral');
        
        IERC721(collateralContractAddress).transferFrom(msg.sender, address(this), collateralTokenId);

        unchecked {
            id = _nonce++;
        }

        Loan storage loan = loanInfo[id];
        loan.allowLoanAmountIncrease = allowLoanAmountIncrease;
        loan.originationFeeRate = uint88(originationFeeRate);
        loan.loanAssetContractAddress = loanAssetContractAddress;
        loan.loanAmount = minLoanAmount;
        loan.collateralTokenId = collateralTokenId;
        loan.collateralContractAddress = collateralContractAddress;
        loan.perAnnumInterestRate = maxPerAnnumInterest;
        loan.durationSeconds = minDurationSeconds;
        
        IERC721Mintable(borrowTicketContract).mint(mintBorrowTicketTo, id);
        emit CreateLoan(
            id,
            msg.sender,
            collateralTokenId,
            collateralContractAddress,
            maxPerAnnumInterest,
            loanAssetContractAddress,
            allowLoanAmountIncrease,
            minLoanAmount,
            minDurationSeconds
        );
    }

    /// See {INFTLoanFacilitator-closeLoan}.
    function closeLoan(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
        require(IERC721(borrowTicketContract).ownerOf(loanId) == msg.sender,
        "borrow ticket holder only");

        Loan storage loan = loanInfo[loanId];
        require(loan.lastAccumulatedTimestamp == 0, "has lender");
        
        loan.closed = true;
        IERC721(loan.collateralContractAddress).transferFrom(address(this), sendCollateralTo, loan.collateralTokenId);
        emit Close(loanId);
    }

    /// See {INFTLoanFacilitator-lend}.
    function lend(
        uint256 loanId,
        uint16 interestRate,
        uint128 amount,
        uint32 durationSeconds,
        address sendLendTicketTo
    )
        external
        override
        notClosed(loanId)
    {
        Loan storage loan = loanInfo[loanId];
        
        if (loan.lastAccumulatedTimestamp == 0) {
            address loanAssetContractAddress = loan.loanAssetContractAddress;
            require(loanAssetContractAddress.code.length != 0, "invalid loan");

            require(interestRate <= loan.perAnnumInterestRate, 'rate too high');

            require(durationSeconds >= loan.durationSeconds, 'duration too low');

            if (loan.allowLoanAmountIncrease) {
                require(amount >= loan.loanAmount, 'amount too low');
            } else {
                require(amount == loan.loanAmount, 'invalid amount');
            }
        
            loan.perAnnumInterestRate = interestRate;
            loan.lastAccumulatedTimestamp = uint40(block.timestamp);
            loan.durationSeconds = durationSeconds;
            loan.loanAmount = amount;
            
            uint256 facilitatorTake = amount * uint256(loan.originationFeeRate) / SCALAR;
            ERC20(loanAssetContractAddress).safeTransferFrom(msg.sender, address(this), facilitatorTake);
            ERC20(loanAssetContractAddress).safeTransferFrom(
                msg.sender,
                IERC721(borrowTicketContract).ownerOf(loanId),
                amount - facilitatorTake
            );
            IERC721Mintable(lendTicketContract).mint(sendLendTicketTo, loanId);
        } else {
            uint256 previousLoanAmount = loan.loanAmount;
            // implicitly checks that amount >= loan.loanAmount
            // will underflow if amount < previousAmount
            uint256 amountIncrease = amount - previousLoanAmount;
            if (!loan.allowLoanAmountIncrease) {
                require(amountIncrease == 0, 'amount increase not allowed');
            }

            uint256 accumulatedInterest;

            {
                uint256 previousInterestRate = loan.perAnnumInterestRate;
                uint256 previousDurationSeconds = loan.durationSeconds;

                require(interestRate <= previousInterestRate, 'rate too high');

                require(durationSeconds >= previousDurationSeconds, 'duration too low');

                require(
                    Math.ceilDiv(previousLoanAmount * requiredImprovementRate, SCALAR) <= amountIncrease
                    || previousDurationSeconds + Math.ceilDiv(previousDurationSeconds * requiredImprovementRate, SCALAR) <= durationSeconds 
                    || (previousInterestRate != 0 // do not allow rate improvement if rate already 0
                        && previousInterestRate - Math.ceilDiv(previousInterestRate * requiredImprovementRate, SCALAR) >= interestRate), 
                    "insufficient improvement"
                );

                 accumulatedInterest = _interestOwed(
                    previousLoanAmount,
                    loan.lastAccumulatedTimestamp,
                    previousInterestRate,
                    loan.accumulatedInterest
                );
            }

            require(accumulatedInterest < 1 << 128, 
            "interest exceeds uint128");

            loan.perAnnumInterestRate = interestRate;
            loan.lastAccumulatedTimestamp = uint40(block.timestamp);
            loan.durationSeconds = durationSeconds;
            loan.loanAmount = amount;
            loan.accumulatedInterest = uint128(accumulatedInterest);

            address currentLoanOwner = IERC721(lendTicketContract).ownerOf(loanId);
            ILendTicket(lendTicketContract).loanFacilitatorTransfer(currentLoanOwner, sendLendTicketTo, loanId);
            
            if(amountIncrease > 0){
                handleAmountIncreaseBuyoutPayments(
                    loanId, 
                    loan.loanAssetContractAddress,
                    amountIncrease,
                    loan.originationFeeRate,
                    currentLoanOwner,
                    accumulatedInterest,
                    previousLoanAmount
                );
            } else {
                ERC20(loan.loanAssetContractAddress).safeTransferFrom(
                    msg.sender,
                    currentLoanOwner,
                    accumulatedInterest + previousLoanAmount
                );
            }
            
            emit BuyoutLender(loanId, msg.sender, currentLoanOwner, accumulatedInterest, previousLoanAmount);
        }

        emit Lend(loanId, msg.sender, interestRate, amount, durationSeconds);
    }

    /// See {INFTLoanFacilitator-repayAndCloseLoan}.
    function repayAndCloseLoan(uint256 loanId) external override notClosed(loanId) {
        Loan storage loan = loanInfo[loanId];

        uint256 loanAmount = loan.loanAmount;
        uint256 interest = _interestOwed(
            loanAmount,
            loan.lastAccumulatedTimestamp,
            loan.perAnnumInterestRate,
            loan.accumulatedInterest
        );
        address lender = IERC721(lendTicketContract).ownerOf(loanId);
        loan.closed = true;
        ERC20(loan.loanAssetContractAddress).safeTransferFrom(msg.sender, lender, interest + loanAmount);
        IERC721(loan.collateralContractAddress).transferFrom(
            address(this),
            IERC721(borrowTicketContract).ownerOf(loanId),
            loan.collateralTokenId
        );

        emit Repay(loanId, msg.sender, lender, interest, loanAmount);
        emit Close(loanId);
    }

    /// See {INFTLoanFacilitator-seizeCollateral}.
    function seizeCollateral(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
        require(IERC721(lendTicketContract).ownerOf(loanId) == msg.sender, 
        "lend ticket holder only");

        Loan storage loan = loanInfo[loanId];
        require(block.timestamp > loan.durationSeconds + loan.lastAccumulatedTimestamp,
        "payment is not late");

        loan.closed = true;
        IERC721(loan.collateralContractAddress).transferFrom(
            address(this),
            sendCollateralTo,
            loan.collateralTokenId
        );

        emit SeizeCollateral(loanId);
        emit Close(loanId);
    }

    /// @dev If we allowed ERC777 tokens, 
    /// a malicious lender could revert in 
    /// tokensReceived and block buyouts or repayment.
    /// So we do not support ERC777 tokens.
    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        revert('ERC777 unsupported');
    }

    
    // === owner state changing ===

    /**
     * @notice Sets lendTicketContract to _contract
     * @dev cannot be set if lendTicketContract is already set
     */
    function setLendTicketContract(address _contract) external onlyOwner {
        require(lendTicketContract == address(0), 'already set');

        lendTicketContract = _contract;
    }

    /**
     * @notice Sets borrowTicketContract to _contract
     * @dev cannot be set if borrowTicketContract is already set
     */
    function setBorrowTicketContract(address _contract) external onlyOwner {
        require(borrowTicketContract == address(0), 'already set');

        borrowTicketContract = _contract;
    }

    /// @notice Transfers `amount` of loan origination fees for `asset` to `to`
    function withdrawOriginationFees(address asset, uint256 amount, address to) external onlyOwner {
        ERC20(asset).safeTransfer(to, amount);

        emit WithdrawOriginationFees(asset, amount, to);
    }

    /**
     * @notice Updates originationFeeRate the facilitator keeps of each loan amount
     * @dev Cannot be set higher than 5%
     */
    function updateOriginationFeeRate(uint32 _originationFeeRate) external onlyOwner {
        require(_originationFeeRate <= 5 * (10 ** (INTEREST_RATE_DECIMALS - 2)), "max fee 5%");
        
        originationFeeRate = _originationFeeRate;

        emit UpdateOriginationFeeRate(_originationFeeRate);
    }

    /**
     * @notice updates the percent improvement required of at least one loan term when buying out lender 
     * a loan that already has a lender. E.g. setting this value to 100 means duration or amount
     * must be 10% higher or interest rate must be 10% lower. 
     * @dev Cannot be 0.
     */
    function updateRequiredImprovementRate(uint256 _improvementRate) external onlyOwner {
        require(_improvementRate != 0, '0 improvement rate');

        requiredImprovementRate = _improvementRate;

        emit UpdateRequiredImprovementRate(_improvementRate);
    }

    
    // ==== external view ====

    /// See {INFTLoanFacilitator-loanInfoStruct}.
    function loanInfoStruct(uint256 loanId) external view override returns (Loan memory) {
        return loanInfo[loanId];
    }

    /// See {INFTLoanFacilitator-totalOwed}.
    function totalOwed(uint256 loanId) external view override returns (uint256) {
        Loan storage loan = loanInfo[loanId];
        uint256 lastAccumulated = loan.lastAccumulatedTimestamp;
        if (loan.closed || lastAccumulated == 0) return 0;

        return loanInfo[loanId].loanAmount + _interestOwed(
            loan.loanAmount,
            lastAccumulated,
            loan.perAnnumInterestRate,
            loan.accumulatedInterest
        );
    }

    /// See {INFTLoanFacilitator-interestOwed}.
    function interestOwed(uint256 loanId) external view override returns (uint256) {
        Loan storage loan = loanInfo[loanId];
        uint256 lastAccumulated = loan.lastAccumulatedTimestamp;
        if (loan.closed || lastAccumulated == 0) return 0;

        return _interestOwed(
            loan.loanAmount,
            lastAccumulated,
            loan.perAnnumInterestRate,
            loan.accumulatedInterest
        );
    }

    /// See {INFTLoanFacilitator-loanEndSeconds}.
    function loanEndSeconds(uint256 loanId) external view override returns (uint256) {
        Loan storage loan = loanInfo[loanId];
        uint256 lastAccumulated;
        require((lastAccumulated = loan.lastAccumulatedTimestamp) != 0, 'loan has no lender');
        
        return loan.durationSeconds + lastAccumulated;
    }

    
    // === internal & private ===

    /// @dev Returns the total interest owed on loan
    function _interestOwed(
        uint256 loanAmount,
        uint256 lastAccumulatedTimestamp,
        uint256 perAnnumInterestRate,
        uint256 accumulatedInterest
    ) 
        internal 
        view 
        returns (uint256) 
    {
        return loanAmount
            * (block.timestamp - lastAccumulatedTimestamp)
            * (perAnnumInterestRate * 1e18 / 365 days)
            / 1e21 // SCALAR * 1e18
            + accumulatedInterest;
    }

    /// @dev handles erc20 payments in case of lender buyout
    /// with increased loan amount
    function handleAmountIncreaseBuyoutPayments(
        uint256 loanId,
        address loanAssetContractAddress,
        uint256 amountIncrease,
        uint256 loanOriginationFeeRate,
        address currentLoanOwner,
        uint256 accumulatedInterest,
        uint256 previousLoanAmount
    ) 
        private 
    {
        uint256 facilitatorTake = (amountIncrease * loanOriginationFeeRate / SCALAR);

        ERC20(loanAssetContractAddress).safeTransferFrom(msg.sender, address(this), facilitatorTake);

        ERC20(loanAssetContractAddress).safeTransferFrom(
            msg.sender,
            currentLoanOwner,
            accumulatedInterest + previousLoanAmount
        );

        ERC20(loanAssetContractAddress).safeTransferFrom(
            msg.sender,
            IERC721(borrowTicketContract).ownerOf(loanId),
            amountIncrease - facilitatorTake
        );
    }
}