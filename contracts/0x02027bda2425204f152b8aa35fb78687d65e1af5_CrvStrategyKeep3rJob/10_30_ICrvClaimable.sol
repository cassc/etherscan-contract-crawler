// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ICrvClaimable {
    function claimable_tokens(address _address) external returns (uint256 _amount);
}