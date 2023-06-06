// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.6;

interface IApiCaller {
    function callBackend(address owner_)
        external
        payable
        returns (bytes32 requestId);
}