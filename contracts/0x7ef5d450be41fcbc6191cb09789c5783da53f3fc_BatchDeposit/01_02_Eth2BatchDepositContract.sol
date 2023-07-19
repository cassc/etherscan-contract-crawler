// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.9;

import {IDepositContract} from "./IEth2ConsensusDepositContract.sol";

interface IBatchDeposit {
    function batchDeposit(bytes calldata args) external payable;
}

contract BatchDeposit is IBatchDeposit {
    IDepositContract public immutable depositContract;

    uint constant private pubkeyLength = 48;
    uint constant private withdrawalCredentialsLength = 32;
    uint constant private signatureLength = 96;
    uint constant private depositDataRootLength = 32;
    uint constant private depositArgsLength =
        pubkeyLength +
        withdrawalCredentialsLength +
        signatureLength +
        depositDataRootLength;

    constructor(IDepositContract _depositContract) {
        require(address(_depositContract) != address(0),
                "Please specify the correct deposit contract");
        depositContract = _depositContract;
    }

    function batchDeposit(bytes calldata args) external payable {
        require(
            args.length % depositArgsLength == 0,
            "Input data length must be multiple of depositArgsLength"
        );
        uint count = args.length / depositArgsLength;
        require(msg.value % 32 ether == 0, "msg.value must be multiple of 32 ETH");
        require(msg.value / 32 ether == count, "msg.value must be 32 ETH * count");

        uint withdrawalCredentialsStart;
        uint signatureStart;
        uint depositDataRootStart;

        for (uint pubkeyStart = 0; pubkeyStart < args.length; ) {
            unchecked
            {
                withdrawalCredentialsStart = pubkeyStart + pubkeyLength;
                signatureStart = withdrawalCredentialsStart + withdrawalCredentialsLength;
                depositDataRootStart = signatureStart + signatureLength;
            }

            uint depositDataRootEnd;
            unchecked { depositDataRootEnd = depositDataRootStart + depositDataRootLength; }
            bytes32 depositDataRoot = bytes32(args[depositDataRootStart : depositDataRootEnd]);

            depositContract.deposit{value: 32 ether}(
                args[pubkeyStart : withdrawalCredentialsStart],
                args[withdrawalCredentialsStart : signatureStart],
                args[signatureStart : depositDataRootStart],
                depositDataRoot
            );
            pubkeyStart = depositDataRootEnd;
        }
    }
}