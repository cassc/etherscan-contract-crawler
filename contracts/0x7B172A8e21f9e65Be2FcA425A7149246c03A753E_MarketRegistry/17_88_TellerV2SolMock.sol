// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../TellerV2.sol";
import "../interfaces/ITellerV2.sol";
import "../TellerV2Context.sol";

/*
This is only used for sol test so its named specifically to avoid being used for the typescript tests.
*/
contract TellerV2SolMock is ITellerV2, TellerV2Storage {
    function setMarketRegistry(address _marketRegistry) public {
        marketRegistry = IMarketRegistry(_marketRegistry);
    }

    function submitBid(
        address _lendingToken,
        uint256 _marketId,
        uint256 _principal,
        uint32 _duration,
        uint16,
        string calldata,
        address _receiver
    ) public returns (uint256 bidId_) {
        bidId_ = bidId;

        Bid storage bid = bids[bidId];
        bid.borrower = msg.sender;
        bid.receiver = _receiver != address(0) ? _receiver : bid.borrower;
        bid.marketplaceId = _marketId;
        bid.loanDetails.lendingToken = ERC20(_lendingToken);
        bid.loanDetails.principal = _principal;
        bid.loanDetails.loanDuration = _duration;
        bid.loanDetails.timestamp = uint32(block.timestamp);

        bidId++;
    }

    function repayLoanMinimum(uint256 _bidId) external {}

    function repayLoanFull(uint256 _bidId) external {}

    function repayLoan(uint256 _bidId, uint256 _amount) public {
        Bid storage bid = bids[_bidId];

        IERC20(bid.loanDetails.lendingToken).transferFrom(
            msg.sender,
            address(this),
            _amount
        );
    }

    /*
     * @notice Calculates the minimum payment amount due for a loan.
     * @param _bidId The id of the loan bid to get the payment amount for.
     */
    function calculateAmountDue(uint256 _bidId)
        public
        view
        returns (Payment memory due)
    {
        if (bids[_bidId].state != BidState.ACCEPTED) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bids[_bidId], block.timestamp);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    /**
     * @notice Calculates the minimum payment amount due for a loan at a specific timestamp.
     * @param _bidId The id of the loan bid to get the payment amount for.
     * @param _timestamp The timestamp at which to get the due payment at.
     */
    function calculateAmountDue(uint256 _bidId, uint256 _timestamp)
        public
        view
        returns (Payment memory due)
    {
        Bid storage bid = bids[_bidId];
        if (
            bids[_bidId].state != BidState.ACCEPTED ||
            bid.loanDetails.acceptedTimestamp >= _timestamp
        ) return due;

        (, uint256 duePrincipal, uint256 interest) = V2Calculations
            .calculateAmountOwed(bid, _timestamp);
        due.principal = duePrincipal;
        due.interest = interest;
    }

    function lenderAcceptBid(uint256 _bidId)
        public
        returns (
            uint256 amountToProtocol,
            uint256 amountToMarketplace,
            uint256 amountToBorrower
        )
    {
        Bid storage bid = bids[_bidId];

        bid.lender = msg.sender;

        //send tokens to caller
        IERC20(bid.loanDetails.lendingToken).transferFrom(
            bid.lender,
            bid.receiver,
            bid.loanDetails.principal
        );
        //for the reciever

        return (0, bid.loanDetails.principal, 0);
    }

    function getBidState(uint256 _bidId)
        public
        view
        returns (TellerV2Storage.BidState)
    {
        return bids[_bidId].state;
    }

    function getLoanDetails(uint256 _bidId)
        public
        view
        returns (TellerV2Storage.LoanDetails memory)
    {
        return bids[_bidId].loanDetails;
    }

    function getBorrowerActiveLoanIds(address _borrower)
        public
        view
        returns (uint256[] memory)
    {}

    function isLoanDefaulted(uint256 _bidId) public view returns (bool) {}

    function isPaymentLate(uint256 _bidId) public view returns (bool) {}

    function getLoanBorrower(uint256 _bidId)
        external
        view
        returns (address borrower_)
    {
        borrower_ = bids[_bidId].borrower;
    }

    function getLoanLender(uint256 _bidId)
        external
        view
        returns (address lender_)
    {
        lender_ = bids[_bidId].lender;
    }

    function getLoanLendingToken(uint256 _bidId)
        external
        view
        returns (address token_)
    {
        token_ = address(bids[_bidId].loanDetails.lendingToken);
    }

    function setLastRepaidTimestamp(uint256 _bidId, uint32 _timestamp) public {
        bids[_bidId].loanDetails.lastRepaidTimestamp = _timestamp;
    }
}