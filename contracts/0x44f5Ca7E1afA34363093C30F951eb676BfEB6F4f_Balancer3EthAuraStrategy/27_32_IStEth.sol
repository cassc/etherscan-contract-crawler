//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IStEth {
    function submit(address _referral) external payable returns (uint256);
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);
}