// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;


interface IFactory {
    function signerAddress() external view returns(address);
    function platformAddress() external view returns(address);
    function platformCommission() external view returns(uint8);
}