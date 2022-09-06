// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IFeeDistro {
    function claim() external;

    function token() external view returns (address);
}