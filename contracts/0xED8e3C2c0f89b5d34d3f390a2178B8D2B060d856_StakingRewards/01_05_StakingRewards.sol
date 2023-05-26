// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract StakingRewards is Ownable {
    IERC721 stakingToken;

    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(uint => address) public stakes;

    uint public _totalSupply;
    mapping(address => uint) public _balances;

    uint public endTime;

    event Staked(address indexed user, uint id);
    event Unstaked(address indexed user, uint id);

    constructor(address _stakingToken, uint _rewardRate) {
        stakingToken = IERC721(_stakingToken);
        rewardRate = _rewardRate;

        endTime = block.timestamp + 90 days;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }

        if (endTime < block.timestamp) {
            return rewardPerTokenStored + (((endTime - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
        } else {
            return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
        }
    }

    function earned(address account) public view returns (uint) {
        return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function updateReward(address account) internal returns(bool) {
        rewardPerTokenStored = rewardPerToken();

        if (endTime < block.timestamp) {
            lastUpdateTime = endTime;
        } else {
            lastUpdateTime = block.timestamp;
        }

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;

        return true;
    }

    function stake(uint[] calldata ids) external returns(bool) {
        updateReward(msg.sender);

        for (uint i = 0; i < ids.length; i++) {
            stakingToken.transferFrom(msg.sender, address(this), ids[i]);

            stakes[ids[i]] = msg.sender;

            emit Staked(msg.sender, ids[i]);
        }

        _balances[msg.sender] += ids.length;
        _totalSupply += ids.length;

        return true;
    }

    function unstake(uint[] calldata ids) external returns(bool) {
        updateReward(msg.sender);

        for (uint i = 0; i < ids.length; i++) {
            require(msg.sender == stakes[ids[i]], 'Staking::unstake: msg.sender is not token owner');

            delete stakes[ids[i]];

            stakingToken.transferFrom(address(this), msg.sender, ids[i]);

            emit Unstaked(msg.sender, ids[i]);
        }

        _balances[msg.sender] -= ids.length;
        _totalSupply -= ids.length;

        return true;
    }

    function _setRewardRate(uint _rewardRate)
        external
        onlyOwner
        returns(bool)
    {
        rewardRate = _rewardRate;

        return true;
    }

    function _setEndTime(uint _endTime)
        external
        onlyOwner
        returns(bool)
    {
        require(_endTime > block.timestamp, "StakingRewards::_setEndTime: time is not correct");

        endTime = _endTime;

        return true;
    }

    function _returnTokens(address[] calldata users, uint[] calldata ids) public onlyOwner returns (bool) {
        require(users.length == ids.length, "StakingRewards::_returnTokens: length is not correct");
        for (uint i = 0; i < ids.length; i++) {
            stakingToken.transferFrom(address(this), users[i], ids[i]);
        }

        return true;
    }
}