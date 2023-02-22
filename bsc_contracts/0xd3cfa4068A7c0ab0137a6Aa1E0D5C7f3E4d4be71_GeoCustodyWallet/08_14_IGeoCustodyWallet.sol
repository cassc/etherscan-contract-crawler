// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGeoCustodyWallet {
    function initialize(address, address) external;

    function version() external pure returns (uint32);

    function beneficiary() external view returns (address);

    function released() external view returns (uint256);

    function released(address) external view returns (uint256);

    function release() external returns (uint256);

    function release(address) external returns (uint256);
}