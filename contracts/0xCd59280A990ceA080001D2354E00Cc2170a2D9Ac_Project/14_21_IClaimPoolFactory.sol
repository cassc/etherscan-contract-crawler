// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IClaimPoolFactory {
    function create(address _project, address _paymentToken) external returns (address);
}