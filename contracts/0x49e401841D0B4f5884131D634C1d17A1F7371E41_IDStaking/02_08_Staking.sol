//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public token;

    mapping(uint256 => mapping(address => uint256)) public stakes;

    // stake
    function _stake(uint256 roundId, uint256 amount) internal {
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "unable to stake amount"
        );

        stakes[roundId][msg.sender] += amount;
    }

    // unstake
    function _unstake(uint256 roundId, uint256 amount) internal {
        stakes[roundId][msg.sender] -= amount;

        require(token.transfer(msg.sender, amount), "unable to unstake amount");
    }

    function _getUserStakeForRound(uint256 roundId, address user)
        internal
        view
        returns (uint256)
    {
        return stakes[roundId][user];
    }
}