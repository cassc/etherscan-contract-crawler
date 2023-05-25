pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiSuperNodeFeePool {
    function withdrawEther(address _to, uint256 _amount) external;
}