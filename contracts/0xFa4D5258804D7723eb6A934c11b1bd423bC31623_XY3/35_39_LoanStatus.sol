// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./Xy3Nft.sol";
import "./interfaces/ILoanStatus.sol";
import "./interfaces/IConfig.sol";

/**
 * @title  LoanStatus
 * @author XY3
 */
contract LoanStatus is ILoanStatus {

    event UpdateStatus(
        uint32 indexed loanId,
        uint64 indexed xy3NftId,
        StatusType newStatus
    );

    uint32 public totalNumLoans = 10000;
    mapping(uint32 => LoanState) private loanStatus;

    /**
     * @dev XY3 mint a NFT to the lender as a ticket for collateral
     * @param _lender Lender address
     * @param _borrower Borrower address
     */
    function createLoan(address _lender, address _borrower) internal returns (uint32) {
        // skip 0, loanIds start from 1
        totalNumLoans += 1;

        uint64 xy3NftId = uint64(
            uint256(keccak256(abi.encodePacked(address(this), totalNumLoans)))
        );

        LoanState memory newLoan = LoanState({
            status: StatusType.NEW,
            xy3NftId: xy3NftId
        });

        (Xy3Nft borrowerNote, Xy3Nft lenderNote) = getNotes();
        // Mint an ERC721 to the lender as the ticket for the collateral
        lenderNote.mint(
            _lender,
            xy3NftId,
            abi.encode(totalNumLoans)
        );

        // Mint an ERC721 to the borrower as the ticket for the collateral
        borrowerNote.mint(
            _borrower,
            xy3NftId,
            abi.encode(totalNumLoans)
        );

        loanStatus[totalNumLoans] = newLoan;
        emit UpdateStatus(totalNumLoans, xy3NftId, StatusType.NEW);

        return totalNumLoans;
    }

    /**
     * @dev XY3 close the loan when load paid
     * Update the loan status to be RESOLVED and burns Xy3Nft token.
     * @param _loanId - Id of loan
     */
    function resolveLoan(uint32 _loanId) internal {
        LoanState storage loan = loanStatus[_loanId];
        require(loan.status == StatusType.NEW, "Loan is not a new one");

        loan.status = StatusType.RESOLVED;
        (Xy3Nft borrowerNote, Xy3Nft lenderNote) = getNotes();
        lenderNote.burn(loan.xy3NftId);
        borrowerNote.burn(loan.xy3NftId);

        emit UpdateStatus(_loanId, loan.xy3NftId, StatusType.RESOLVED);
        delete loanStatus[_loanId];
    }

    /**
     * @dev Get loan state for a given id.
     * @param _loanId The given load Id.
     */
    function getLoanState(uint32 _loanId)
        public
        view
        override
        returns (LoanState memory)
    {
        return loanStatus[_loanId];
    }

    function getNotes() private view returns(Xy3Nft borrowerNote, Xy3Nft lenderNote) {
        IAddressProvider addressProvider = IConfig(address(this)).getAddressProvider();
        borrowerNote = Xy3Nft(addressProvider.getBorrowerNote());
        lenderNote = Xy3Nft(addressProvider.getLenderNote());
    }
}