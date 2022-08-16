// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "../library/TokenLoanData.sol";

interface ILiquidator {
    /// @dev using this function externally in the Token, Network Loan and NFT Loan Market Smart Contract
    function isLiquidateAccess(address liquidator) external view returns (bool);

    function liquidateLoan(
        uint256 _loanId,
        bytes[] calldata _swapData
    ) external;

    // function liquidateLoan(uint256 _loanId) external;

    function getLtv(uint256 _loanId) external view returns (uint256);

    function isLiquidationPending(uint256 _loanId) external view returns (bool);

    function payback(uint256 _loanId, uint256 _paybackAmount) external;

    function addPlatformFee(address _stable, uint256 _platformFee) external;
}