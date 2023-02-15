// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;

interface IstETH {
    function submit(address _referral) external payable returns (uint256);
}