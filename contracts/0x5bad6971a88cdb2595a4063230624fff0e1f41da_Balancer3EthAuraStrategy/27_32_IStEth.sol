//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IStEth {
    function submit(address _referral) external payable returns (uint256);
}