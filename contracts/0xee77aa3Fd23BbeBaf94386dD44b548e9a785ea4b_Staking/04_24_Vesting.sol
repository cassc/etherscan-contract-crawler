// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vesting {
    address public immutable STAKING_CONTRACT;
    address public immutable REWARD_TOKEN;

    constructor(address _stakingContract, address _rewardToken) {
        // addresses can't be 0x0
        require(
            _stakingContract != address(0) && _rewardToken != address(0),
            "Invalid address"
        );
        STAKING_CONTRACT = _stakingContract;
        REWARD_TOKEN = _rewardToken;
    }

    /**
        @notice retrieve _amount of rewardToken that's held in vesting contract
        @param _amount uint256
        @param _staker address
     */
    function retrieve(address _staker, uint256 _amount) external {
        // must be called from staking contract
        require(
            msg.sender == STAKING_CONTRACT,
            "Not called from staking contract"
        );
        IERC20(REWARD_TOKEN).transfer(_staker, _amount);
    }
}