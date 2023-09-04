// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;

interface IUnwrapTokenV1 {
    function requestWithdraw(address _recipient, uint256 _wbethAmount, uint256 _ethAmount) external;

    function moveFromWrapContract() payable external;

    function moveFromWrapContract(uint256 _ethAmount) external;
}