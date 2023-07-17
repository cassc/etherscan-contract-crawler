// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';



contract Mint is  Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;


    struct Invite {
        address addr;
        uint256 datetime;
    }

    address public rewardToken;
    uint256 public price;
    address public dev;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 immutable public duration = 25920000; // 300 day
    uint256 immutable public percent = 200;
    uint256 public totalAccumulatedReward = 0;


    uint256 public starttime;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public totalCirculation;


    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public receiveReward;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => Invite[]) public inviterAddress;
    mapping(address => uint256) public inviterSize;
    mapping(address => address) public inviter;


    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event DevFundRewardPaid(address indexed user, uint256 reward);

    modifier checkStart() {
        require(block.timestamp >= starttime, 'not start');
        _;
    }

    modifier updateReward(address account) {
        //
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }


    constructor(
        uint256 _price,
        address _owner,
        address _rewardToken,
        uint256 _starttime
    ) {
        price = _price;
        dev = _owner;
        rewardToken = _rewardToken;
        starttime = _starttime;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRate)
            .mul(1e18)
            .div(totalSupply())
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }
    function stake(address from)
    public payable
    updateReward(msg.sender)
    checkStart
    {
        require(msg.sender == tx.origin, "Only external accounts can call this function");
        require(!isContract(msg.sender), "Only external accounts can call this function");
        require(balanceOf(msg.sender) <= 0, "repeat start");
        require(msg.value >= price, "insufficient funds");
        // Inviter
        bool shouldSetInviter = balanceOf(msg.sender) == 0 && inviter[msg.sender] == address(0) &&
        from != address(0) && msg.sender != from;
        if (shouldSetInviter) {
            inviter[msg.sender] = from;
            Invite memory invite = Invite(msg.sender,block.timestamp);
            inviterAddress[from].push(invite);
            inviterSize[from] = inviterAddress[from].length;
        }
        uint256 amount = 1e18;
        uint256 newDeposit = deposits[msg.sender].add(amount);
        deposits[msg.sender] = newDeposit;
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lastStakeTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
        payable(dev).transfer(msg.value);
    }


    function getReward() public updateReward(msg.sender) checkStart {

        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 devPaid = reward.mul(percent).div(1000);
            address inviterAdd =  inviter[msg.sender];
            // If there is no inviter, it will be destroyed
            if(inviterAdd == address(0)){
                inviterAdd = 0x000000000000000000000000000000000000dEaD;
            }
            if(devPaid > 0){
                receiveReward[inviterAdd] = receiveReward[inviterAdd].add(devPaid);
                IERC20(rewardToken).safeTransfer(inviterAdd, devPaid);
                emit DevFundRewardPaid(inviterAdd, devPaid);
            }


            IERC20(rewardToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
            totalCirculation += (devPaid + reward);
        }
    }


    function setConfig(address _fund, uint256 _price) external {
        require(dev == _msgSender(), "error");
        dev = _fund;
        price = _price;
    }

    function notifyRewardAmount(uint256 reward)
    external
    onlyOwner
    updateReward(address(0))
    {

        if (block.timestamp > starttime){
            if (block.timestamp >= periodFinish) {
                uint256 period = block.timestamp.sub(starttime).div(duration).add(1);
                periodFinish = starttime.add(period.mul(duration));
                rewardRate = reward.div(periodFinish.sub(block.timestamp));
            } else {
                uint256 remaining = periodFinish.sub(block.timestamp);
                uint256 leftover = remaining.mul(rewardRate);
                rewardRate = reward.add(leftover).div(remaining);
            }
            lastUpdateTime = block.timestamp;
            emit RewardAdded(reward);
        }else {
            rewardRate = reward.div(duration);
            periodFinish = starttime.add(duration);
            lastUpdateTime = starttime;
            emit RewardAdded(reward);
        }

        totalAccumulatedReward = totalAccumulatedReward.add(reward);
        _checkRewardRate();
    }

    function _checkRewardRate() internal view returns (uint256) {
        return duration.mul(rewardRate).mul(1e18);
    }


    function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    function getLastInvites(address _address, uint256 count) public view returns (Invite[] memory) {
        Invite[] memory invites = inviterAddress[_address];
        uint256 length = invites.length;
        if (count > length) {
            count = length;
        }
        Invite[] memory lastInvites = new Invite[](count);
        for (uint256 i = length - count; i < length; i++) {
            lastInvites[i - (length - count)] = invites[i];
        }
        return lastInvites;
    }

    function withdraw() onlyOwner external {
        payable(msg.sender).transfer(address(this).balance);
    }

}