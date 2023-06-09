// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20} from "IERC20.sol";
import {IDebtInstrument} from "IDebtInstrument.sol";

enum BulletLoanStatus {
    Issued,
    FullyRepaid,
    Defaulted,
    Resolved
}

interface IBulletLoans is IDebtInstrument {
    struct LoanMetadata {
        IERC20 underlyingToken;
        BulletLoanStatus status;
        uint256 principal;
        uint256 totalDebt;
        uint256 amountRepaid;
        uint256 duration;
        uint256 repaymentDate;
        address recipient;
    }

    function loans(uint256 id)
        external
        view
        returns (
            IERC20,
            BulletLoanStatus,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        );

    function createLoan(
        IERC20 _underlyingToken,
        uint256 principal,
        uint256 totalDebt,
        uint256 duration,
        address recipient
    ) external returns (uint256);

    function markLoanAsDefaulted(uint256 instrumentId) external;

    function markLoanAsResolved(uint256 instrumentId) external;

    function updateLoanParameters(
        uint256 instrumentId,
        uint256 newTotalDebt,
        uint256 newRepaymentDate
    ) external;

    function updateLoanParameters(
        uint256 instrumentId,
        uint256 newTotalDebt,
        uint256 newRepaymentDate,
        bytes memory borrowerSignature
    ) external;
}