// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {
    function token() external view returns (address);
    function getPricePerFullShare() external view returns (uint256);
}