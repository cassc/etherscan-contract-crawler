// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IOctusCallback {
    function onNativeWithdrawal(bytes memory payload) external;
    function onAlienWithdrawal(bytes memory payload) external;
    function onAlienWithdrawalPendingCreated(bytes memory payload) external;
}