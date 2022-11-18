// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBeneficiaryBase {
    function burn(uint256 _amountOutMin) external;

    function rescue(address _token) external;

    function tokenWhitelist(address _addr) external view returns (bool);
}