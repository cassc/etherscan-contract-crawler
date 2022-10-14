pragma solidity >=0.8.0 <0.9.0;
// SPDX-License-Identifier: MIT

import "./interfaces/ITellerV2.sol";

import "./interfaces/ITellerV2Autopay.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Helper contract to autopay loans
 */
contract TellerV2Autopay is
    Initializable,
    ContextUpgradeable,
    ITellerV2Autopay
{
    using SafeERC20 for ERC20;

    ITellerV2 public immutable tellerV2;

    //bidId => enabled
    mapping(uint256 => bool) public loanAutoPayEnabled;

    /**
     * @notice This event is emitted when a loan is autopaid.
     * @param bidId The id of the bid/loan which was repaid.
     * @param msgsender The account that called the method
     */
    event AutoPaidLoanMinimum(uint256 indexed bidId, address indexed msgsender);

    /**
     * @notice This event is emitted when loan autopayments are enabled or disabled.
     * @param bidId The id of the bid/loan.
     * @param enabled Whether the autopayments are enabled or disabled
     */
    event AutoPayEnabled(uint256 indexed bidId, bool enabled);

    constructor(address _protocolAddress) {
        tellerV2 = ITellerV2(_protocolAddress);
    }

    /**
     * @notice Function for a borrower to enable or disable autopayments
     * @param _bidId The id of the bid to cancel.
     * @param _autoPayEnabled boolean for allowing autopay on a loan
     */
    function setAutoPayEnabled(uint256 _bidId, bool _autoPayEnabled) external {
        require(
            _msgSender() == tellerV2.getLoanBorrower(_bidId),
            "Only the borrower can set autopay"
        );

        loanAutoPayEnabled[_bidId] = _autoPayEnabled;

        emit AutoPayEnabled(_bidId, _autoPayEnabled);
    }

    /**
     * @notice Function for a minimum autopayment to be performed on a loan
     * @param _bidId The id of the bid to repay.
     */
    function autoPayLoanMinimum(uint256 _bidId) external {
        require(
            loanAutoPayEnabled[_bidId],
            "Autopay is not enabled for that loan"
        );

        address lendingToken = ITellerV2(tellerV2).getLoanLendingToken(_bidId);
        address borrower = ITellerV2(tellerV2).getLoanBorrower(_bidId);

        uint256 amountToRepayMinimum = getEstimatedMinimumPayment(_bidId);

        //pull lendingToken in from the borrower to this smart contract
        ERC20(lendingToken).safeTransferFrom(
            borrower,
            address(this),
            amountToRepayMinimum
        );

        //approve the lendingToken to tellerV2
        ERC20(lendingToken).approve(address(tellerV2), amountToRepayMinimum);

        //use that lendingToken to repay the loan
        tellerV2.repayLoan(_bidId, amountToRepayMinimum);

        emit AutoPaidLoanMinimum(_bidId, msg.sender);
    }

    function getEstimatedMinimumPayment(uint256 _bidId)
        public
        virtual
        returns (uint256 _amount)
    {
        TellerV2Storage.Payment memory estimatedPayment = tellerV2
            .calculateAmountDue(_bidId);

        _amount = estimatedPayment.principal + estimatedPayment.interest;
    }
}