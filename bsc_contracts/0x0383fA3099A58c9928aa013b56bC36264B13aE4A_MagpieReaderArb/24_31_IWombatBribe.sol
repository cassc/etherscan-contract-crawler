// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IMultiRewarder.sol';

interface IWombatBribe is IMultiRewarder {

    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

}