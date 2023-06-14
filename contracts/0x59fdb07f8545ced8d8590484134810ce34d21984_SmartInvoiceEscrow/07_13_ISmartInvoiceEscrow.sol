// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ISmartInvoice.sol";

interface ISmartInvoiceEscrow is ISmartInvoice {
    function release() external;

    function release(uint256 _milestone) external;

    function releaseTokens(address _token) external;

    function withdraw() external;

    function withdrawTokens(address _token) external;

    function lock(bytes32 _details) external payable;

    function resolve(
        uint256 _clientAward,
        uint256 _providerAward,
        bytes32 _details
    ) external;
}