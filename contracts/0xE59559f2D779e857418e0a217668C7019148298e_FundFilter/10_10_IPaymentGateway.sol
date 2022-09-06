// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

interface IPaymentGateway {
    function weth9() external view returns (address);
}