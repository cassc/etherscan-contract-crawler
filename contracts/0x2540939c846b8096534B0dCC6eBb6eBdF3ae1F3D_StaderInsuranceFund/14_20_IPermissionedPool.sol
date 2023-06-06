// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IPermissionedPool {
    function receiveInsuranceFund() external payable;

    function transferETHOfDefectiveKeysToSSPM(uint256 _defectiveKeyCount) external payable;

    function fullDepositOnBeaconChain(bytes[] calldata _pubkey) external;
}