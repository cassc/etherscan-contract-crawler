// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISmartInvoice {
    function init(
        address _recipient,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;
}