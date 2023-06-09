// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IERC20WithDecimals} from "IERC20WithDecimals.sol";
import {IProtocolConfig} from "IProtocolConfig.sol";
import {IPortfolio} from "IPortfolio.sol";
import {IBulletLoans} from "IBulletLoans.sol";
import {ILenderVerifier} from "ILenderVerifier.sol";

enum ManagedPortfolioStatus {
    Open,
    Frozen,
    Closed
}

interface IManagedPortfolio is IPortfolio {
    function initialize(
        string memory __name,
        string memory __symbol,
        address _manager,
        IERC20WithDecimals _underlyingToken,
        IBulletLoans _bulletLoans,
        IProtocolConfig _protocolConfig,
        ILenderVerifier _lenderVerifier,
        uint256 _duration,
        uint256 _maxSize,
        uint256 _managerFee
    ) external;

    function managerFee() external view returns (uint256);

    function maxSize() external view returns (uint256);

    function createBulletLoan(
        uint256 loanDuration,
        address borrower,
        uint256 principalAmount,
        uint256 repaymentAmount
    ) external;

    function setEndDate(uint256 newEndDate) external;

    function markLoanAsDefaulted(uint256 instrumentId) external;

    function getStatus() external view returns (ManagedPortfolioStatus);

    function getOpenLoanIds() external view returns (uint256[] memory);
}