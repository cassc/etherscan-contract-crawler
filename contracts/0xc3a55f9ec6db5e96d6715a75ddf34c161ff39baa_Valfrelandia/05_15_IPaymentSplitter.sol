// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

interface IPaymentSplitter {
    event AgreementCreated(string name);
    event Withdraw(address to, uint256 amount);
    event Deposit(string name, uint256 amount);

    struct Beneficiary {
        address payee;
        uint256 basisPoints;
    }

    function createAgreement(string memory name, Beneficiary[] memory beneficiaries) external;

    function deleteAgreement(string memory name) external;

    function deposit(string memory agreementName) external payable;

    function withdraw(address to, uint256 amount) external;

    function emergencyWithdrawal() external;
}