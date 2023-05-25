// SPDX-License-Identifier: BSD

pragma solidity ^0.8.0;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import {IStakeFor} from './IStakeFor.sol';

contract RewardDistributorV3 is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant SIGNER_ROLE = keccak256('SIGNER_ROLE');
    bytes32 public constant OPERATOR = keccak256('OPERATOR');
    bytes32 public constant DELAYED_OPERATOR = keccak256('DELAYED_OPERATOR');

    uint256 public totalRewardDistributed;

    IStakeFor public stakingPool;
    IERC20 public immutable x2y2Token;

    mapping(address => uint256) public userClaimedTotal;

    event Reward(address user, uint256 amount);
    event StakingPoolUpdate(address pool);

    constructor(
        IERC20 _x2y2Token,
        IStakeFor _stakingPool,
        address _signer,
        address _operator,
        address _delayedOperator,
        address _admin
    ) {
        x2y2Token = _x2y2Token;
        stakingPool = _stakingPool;

        if (_admin == address(0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        } else {
            _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        }

        if (_operator != address(0)) {
            _grantRole(OPERATOR, _operator);
        }

        if (_delayedOperator != address(0)) {
            _grantRole(DELAYED_OPERATOR, _delayedOperator);
        }

        if (_signer != address(0)) {
            _grantRole(SIGNER_ROLE, _signer);
        }
    }

    function pause() external onlyRole(OPERATOR) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR) {
        _unpause();
    }

    function operatorWithdraw(
        IERC20 token,
        uint256 amount,
        address to
    ) external onlyRole(DELAYED_OPERATOR) {
        require(to != address(0), 'Caller: to is 0x0');
        token.safeTransfer(to, amount);
    }

    function updateStakingPool(IStakeFor pool_) external onlyRole(OPERATOR) {
        stakingPool = pool_;
        emit StakingPoolUpdate(address(pool_));
    }

    function claim(
        uint256 deadline,
        uint256 rewards,
        bool staking,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused {
        require(rewards > 0, 'Caller: reward > 0');
        require(deadline > block.timestamp, 'Caller: deadline reached');

        address signer = ECDSA.recover(
            keccak256(abi.encode(rewards, msg.sender, deadline)),
            v,
            r,
            s
        );
        require(hasRole(SIGNER_ROLE, signer), 'Caller: invalid signature');

        uint256 amount = rewards - userClaimedTotal[msg.sender];
        require(amount > 0, 'Caller: no reward to claim');

        userClaimedTotal[msg.sender] = rewards;
        totalRewardDistributed += amount;
        emit Reward(msg.sender, amount);

        if (staking && address(stakingPool) != address(0)) {
            x2y2Token.approve(address(stakingPool), amount);
            stakingPool.depositFor(msg.sender, amount);
        } else {
            x2y2Token.safeTransfer(msg.sender, amount);
        }
    }
}