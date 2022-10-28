// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";

contract StakingHelper {

    address public immutable staking;
    address public immutable PSI;

    constructor (address _staking, address _PSI) {
        require(_staking != address(0));
        staking = _staking;
        require(_PSI != address(0));
        PSI = _PSI;
    }

    function stake(uint _amount) external {
        IERC20(PSI).transferFrom(msg.sender, address(this), _amount);
        IERC20(PSI).approve(staking, _amount);
        IStaking(staking).stake(_amount, msg.sender);
        IStaking(staking).claim(msg.sender);
    }
}