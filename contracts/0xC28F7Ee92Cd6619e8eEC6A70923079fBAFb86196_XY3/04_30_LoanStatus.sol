pragma solidity 0.8.4;

import "./Xy3Nft.sol";
import "./ILoanStatus.sol";


contract LoanStatus is ILoanStatus {

    event UpdateStatus(
        uint32 indexed loanId,
        uint64 indexed xy3NftId,
        StatusType newStatus
    );

    uint32 public totalNumLoans = 0;
    mapping(uint32 => LoanState) private loanStatus;
    address public ticketToken;

    
    constructor(address _ticketToken) {
        require(
            _ticketToken != address(0),
            "invalid address"
        );
        ticketToken = _ticketToken;
    }

    
    function createLoan(address _lender) internal returns (uint32) {
        
        totalNumLoans += 1;

        uint64 xy3NftId = uint64(
            uint256(keccak256(abi.encodePacked(address(this), totalNumLoans)))
        );

        LoanState memory newLoan = LoanState({
            status: StatusType.NEW,
            xy3NftId: xy3NftId
        });

        
        Xy3Nft(ticketToken).mint(
            _lender,
            xy3NftId,
            abi.encode(totalNumLoans)
        );

        loanStatus[totalNumLoans] = newLoan;
        emit UpdateStatus(totalNumLoans, xy3NftId, StatusType.NEW);

        return totalNumLoans;
    }

    
    function resolveLoan(uint32 _loanId) internal {
        LoanState storage loan = loanStatus[_loanId];
        require(loan.status == StatusType.NEW, "Loan is not a new one");

        loan.status = StatusType.RESOLVED;
        Xy3Nft(ticketToken).burn(loan.xy3NftId);

        emit UpdateStatus(_loanId, loan.xy3NftId, StatusType.RESOLVED);
    }

    
    function getLoanState(uint32 _loanId)
        public
        view
        override
        returns (LoanState memory)
    {
        return loanStatus[_loanId];
    }
}