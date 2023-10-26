// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract SpiritStaking {

    using SafeERC20 for ERC20;

    uint constant _baseProportion = 10000;
    uint immutable _bonusProportion;
    
    uint public lockCycle;
    uint public total;
    uint public payed;
    ERC20 public input;
    ERC20 public output;
    uint256 public rewardPerTokenStored;
    string public name;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping (address => uint) public balance;
    mapping(address => uint) public userPayed;
    

    event Stake(address indexed account, uint amount, uint lockTime);
    event Withdraw(address indexed account, uint amount);
    event GetReward(address indexed account, uint amount);
    event AddBonus(address indexed account, uint amount);

    struct LockLog {
        uint unLockTime;
        uint amount;
    }
    mapping(address => LockLog[]) public _locklogs;

    modifier updateReward(address account) {
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    constructor(string memory name_, address input_, address output_, uint bonusProportion_, uint lockCycle_) {
        name = name_;
        _bonusProportion = bonusProportion_;
        lockCycle = lockCycle_;
        input = ERC20(input_);
        output = ERC20(output_);
    }

    function earned(address account) public view returns (uint256) {
        return balance[account] * (rewardPerTokenStored - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }


    function stake(uint amount) external updateReward(msg.sender) {
        require(amount > 0);
        input.safeTransferFrom(msg.sender, address(this), amount);
        total += amount;
        balance[msg.sender] += amount;
        _locklogs[msg.sender].push(LockLog(block.timestamp + lockCycle, amount));
        emit Stake(msg.sender, amount, block.timestamp + lockCycle);
    }

    function unfreezeTotal(address account) public view returns (uint unfreeze) {
        uint length = _locklogs[account].length;
        for (uint i; i < length; i++) {
            if (_locklogs[account][i].unLockTime <= block.timestamp) {
                unfreeze += _locklogs[account][i].amount;
            }
        }
    }

    function withdrawByUnfreeze() external updateReward(msg.sender) {
        uint length = _locklogs[msg.sender].length;
        for (uint i = length - 1 ; i >= 0; i--) {
            if (_locklogs[msg.sender][i].unLockTime <= block.timestamp) {
                withdraw(i);
            }
            if (i == 0) {
                return;
            }
        }
    }

    function withdrawByIndex(uint index) external updateReward(msg.sender) {
        withdraw(index);
    }

    function withdraw(uint index) internal{
        LockLog memory log = _locklogs[msg.sender][index];
        require(log.amount > 0 && log.unLockTime < block.timestamp, "withdraw error");
        input.safeTransfer(msg.sender, log.amount);
        uint length = _locklogs[msg.sender].length;
        total -= log.amount;
        balance[msg.sender] -= log.amount;
        if (length - 1 != index) {
            _locklogs[msg.sender][index] = _locklogs[msg.sender][length - 1];
            _locklogs[msg.sender][length - 1] = log;
        }
        _locklogs[msg.sender].pop();
        emit Withdraw(msg.sender, log.amount);
    }

    function getReward() public updateReward(msg.sender) {
        require(rewards[msg.sender] > 0,"not enough");
        output.safeTransfer(msg.sender, rewards[msg.sender]);
        payed += rewards[msg.sender];
        userPayed[msg.sender] += rewards[msg.sender];
        emit GetReward(msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function addBonus(uint amount) external {
        require(total != 0);
        require(amount * 1e18 * _bonusProportion / _baseProportion / total > 0 , "amount error");
        rewardPerTokenStored += amount * 1e18 * _bonusProportion / _baseProportion / total;
        output.safeTransferFrom(msg.sender, address(this), amount * _bonusProportion / _baseProportion);
        emit AddBonus(msg.sender, amount);
    }

    struct HomeView {
        uint PROPORTIONOFDIVIDENDPOOL;
        string STAKINGTOKEN;
        uint STAKINGLOCKUPTIME;
        bool APY;
        uint CUMULATIVEDIVIDENDSAVAILABLE;
        bool THETIMEUNTILTHENEXTDIVIDEND;
        uint TOTALSTAKEDPOOL;
        uint YOURCURRENTPROPORTION;
        uint YOURTOTALDIVIDEND;
        uint NOTBEENCLAIMED;
        uint YOUHAVESTAKED;
        uint REDEEMABLEUPINMATURITY;
    }

    function homeView(address account) external view returns (HomeView memory){
        return HomeView ( 
            _bonusProportion,
            name,
            lockCycle,
            false,
            payed,
            false,
            total,
            total == 0 ? 0 : balance[account] * _baseProportion / total,
            userPayed[account] + earned(account),
            earned(account),
            balance[account],
            unfreezeTotal(account)
        );
    }
    
}