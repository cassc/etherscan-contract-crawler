//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ILido {
    function submit(address _referral) external payable returns (uint256);
}