// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.0;

interface IGeneralTaxDistributor {
    function distributeTax(address token, address origSender) external returns (uint256);
}