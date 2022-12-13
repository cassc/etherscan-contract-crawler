//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

interface IStablzFeeHandler {

    function usdt() external view returns (address);

    function treasury() external view returns (address);

    function calculateFee(uint _amount) external view returns (uint);

}