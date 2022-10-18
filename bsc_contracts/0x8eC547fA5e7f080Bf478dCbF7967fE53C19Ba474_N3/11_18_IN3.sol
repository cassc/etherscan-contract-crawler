// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IN3 {
    function balanceOf(address _user) external view returns (uint256);

    function taxReferral() external view returns (uint256);

    function transferNoTax(address _to, uint256 _amount) external;

    function getPrice() external view returns (uint256);

    function getLpPrice() external view returns (uint256);

    function getLpAddress() external view returns (address);

}