// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IParticipantsERC20Tokens {
    function getRoyaltyERC20Tokens() external view returns (address[] memory);
}