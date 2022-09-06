// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TokenVesting.sol";
import "../Staking/IStakingV2.sol";
/**
 * @title TokenVesting
 * @dev Vesting for BEP20 compatible token.
 */
contract TokenStakableVesting is Ownable, TokenVesting {
    using SafeERC20 for IERC20;

    mapping(address => bool) public allowedStakingInstances;

    event StakingInstancesChanged();

    constructor(uint128 _initTime, uint128 _stopTime, uint128 _startPercent, uint128 _maxPenalty)
    TokenVesting(_initTime, _stopTime, _startPercent, _maxPenalty) {}

    function addStakingInstances(address[] memory stakingInstances, bool status) public onlyOwner {
        require(status || !isLocked(), 'TokenVesting: cannot revoke participation after start');
        for (uint i=0; i<stakingInstances.length; ++i) {
            allowedStakingInstances[stakingInstances[i]] = status;
        }
        emit StakingInstancesChanged();
    }

    /**
     * @dev Sends specific amount of released tokens and send it to sender
     */
    function restake(uint256 pid, address addr, uint256 pocket, uint256 timerange) public {
        restake(pid, addr, pocket, currentBalance(msg.sender), timerange);
    }

    /**
     * @dev Sends specific amount of released tokens and send it to sender
     */
    function restake(uint256 pid, address addr, uint256 pocket, uint256 amount, uint256 timerange) public {
        require(allowedStakingInstances[addr], 'TokenVesting: stakingInstance not allowed');
        if (pocket > 0) {
            token.safeTransferFrom(address(msg.sender), address(this), pocket);
        }

        amount = _release(msg.sender, msg.sender, amount, 6);
        uint256 penalty = timeboundPenalty(block.timestamp + timerange);
        uint256 feeval;

        if (penalty > 0) {
            feeval = amount * penalty / 1000;
            amount = amount - feeval;
        }
        if (amount > 0) {
            emit Released(msg.sender, msg.sender, address(token), amount);
        }
        if (feeval > 0) {
            emit Released(msg.sender, vault, address(token), feeval);
            token.safeTransfer(vault, feeval);
        }

        token.approve(addr, pocket+amount);
        IStakingV2(addr).deposit(pid, msg.sender, pocket+amount, timerange);
    }
}