// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ILoansPeripheral {
    struct Collateral {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct Calldata {
        uint256 amount;
        uint256 interest;
        uint256 maturity;
        Collateral[] collaterals;
        bool delegations;
        uint256 deadline;
        uint256 nonce;
        uint256 genesisToken;
        uint256 v;
        uint256 r;
        uint256 s;
    }

    function reserveEth(
        uint256 _amount,
        uint256 _interest,
        uint256 _maturity,
        Collateral[] calldata _collaterals,
        bool _delegations,
        uint256 _deadline,
        uint256 _nonce,
        uint256 _genesisToken,
        uint256 _v,
        uint256 _r,
        uint256 _s
    ) external returns (uint256);

    function pay(uint256 _loanId) external payable;

    function getLoanPayableAmount(
        address _borrower,
        uint256 _loanId,
        uint256 _timestamp
    ) external view returns (uint256);
}