// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface ILoanStatus {
    /**
     * @dev loan status
     */
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }
    
    /**
     * @dev load status record structure
     */
    struct LoanState {
        uint64 xy3NftId;
        StatusType status;
    }

    /**
     * @dev get load status
     * @param _loanId load ID
     */
    function getLoanState(uint32 _loanId)
        external
        view
        returns (LoanState memory);
}