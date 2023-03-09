//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract IERC20Staking is ReentrancyGuard, Ownable {

    struct Plan {
        uint256 overallStaked;
        uint256 stakesCount;
        uint256 apr;
        uint256 stakeDuration;
        uint256 depositDeduction;
        uint256 withdrawDeduction;
        uint256 earlyPenalty;
        bool conclude;
    }
    
    struct Staking {
        uint256 amount;
        uint256 stakeAt;
        uint256 endstakeAt;
    }

    mapping(uint256 => mapping(address => Staking[])) public stakes;
    address public stakingToken;
    mapping(uint256 => Plan) public plans;

    constructor(address _stakingToken) {
        stakingToken = _stakingToken;
    }

    function stake(uint256 _stakingId, uint256 _amount) public virtual;
    function canWithdrawAmount(uint256 _stakingId, address account) public virtual view returns (uint256, uint256);
    function unstake(uint256 _stakingId, uint256 _amount) public virtual;
    function earnedToken(uint256 _stakingId, address account) public virtual view returns (uint256, uint256);
    function stakeData(uint256 _stakingId, address account) public virtual view returns (Staking[] memory);
    function claimEarned(uint256 _stakingId) public virtual;
    function getStakedPlans(address _account) public virtual view returns (bool[] memory);
}

contract GBankAPYStaking is IERC20Staking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public periodicTime = 365 days;
    uint256 planLimit = 3;
    uint256 LEVELS = 12;
    uint256[] public refRate;

    struct UserReferral {
        bool status;
        address referredBy;
        uint256 totalRef;
        uint256 totalEarning;
        uint256 claimableEarning;
    }

    mapping(address => UserReferral) public userRef;

    constructor(
        address _stakingToken
    ) IERC20Staking(_stakingToken) {
        plans[0].apr = 60;
        plans[0].stakeDuration = 180 days;
        plans[0].earlyPenalty = 30;

        plans[1].apr = 180;
        plans[1].stakeDuration = 365 days;
        plans[1].earlyPenalty = 30;

        plans[2].apr = 266;
        plans[2].stakeDuration = 450 days;
        plans[2].earlyPenalty = 30; 
        
        //LV 1 - 12
        refRate = [1000, 300, 200, 100, 100, 50, 50, 25, 25, 25, 25, 25]; //1000 = 10%     
    }

    function referralStake(uint256 _stakingId, uint256 _amount, address _referrer) public {  
        if ((_referrer != msg.sender) && (_referrer != address(0))) {
            if(userRef[msg.sender].status == false){
                require(_referrer != msg.sender, "You cannot refer yourself");
                userRef[msg.sender].referredBy = _referrer;
                userRef[msg.sender].status = true;

                address currentUpline0 = _referrer; 
                for (uint i = 0; i < LEVELS; i++) {
                    userRef[currentUpline0].totalRef += 1;
                    currentUpline0 = userRef[currentUpline0].referredBy; // Move to next referrer
                }               
            }                      
        }
        stake(_stakingId, _amount);
        address currentUpline1 = _referrer; 
        for (uint i = 0; i < LEVELS; i++) {
            uint bonus = _amount.mul(refRate[i]).div(10000);
            userRef[currentUpline1].totalEarning = userRef[currentUpline1].totalEarning.add(bonus);
            userRef[currentUpline1].claimableEarning = userRef[currentUpline1].claimableEarning.add(bonus);  
            currentUpline1 = userRef[currentUpline1].referredBy; // Move to next referrer
        } 
    }

    function stake(uint256 _stakingId, uint256 _amount) public nonReentrant override {
        require(_amount > 0, "Staking Amount cannot be zero");
        require(IERC20(stakingToken).balanceOf(msg.sender) >= _amount,"Balance is not enough");
        require(_stakingId < planLimit, "Staking is unavailable");
        
        Plan storage plan = plans[_stakingId];
        require(!plan.conclude, "Staking in this pool is concluded");

        uint256 beforeBalance = IERC20(stakingToken).balanceOf(address(this));
        IERC20(stakingToken).transferFrom(msg.sender, address(this), _amount);
        uint256 afterBalance = IERC20(stakingToken).balanceOf(address(this));
        uint256 amount = afterBalance - beforeBalance;
        
        uint256 deductionAmount = amount.mul(plan.depositDeduction).div(1000);
        if(deductionAmount > 0) {
            IERC20(stakingToken).transfer(stakingToken, deductionAmount);
        }
        
        uint256 stakelength = stakes[_stakingId][msg.sender].length;
        if(stakelength == 0) {
            plan.stakesCount += 1;
        }

        stakes[_stakingId][msg.sender].push();
        Staking storage _staking = stakes[_stakingId][msg.sender][stakelength];
        _staking.amount = amount.sub(deductionAmount);
        _staking.stakeAt = block.timestamp;
        _staking.endstakeAt = block.timestamp + plan.stakeDuration;
        
        plan.overallStaked = plan.overallStaked.add(
            amount.sub(deductionAmount)
        );
        emit Stake(msg.sender, amount);
    }

    function canWithdrawAmount(uint256 _stakingId, address _account) public override view returns (uint256, uint256) {
        uint256 _stakedAmount = 0;
        uint256 _canWithdraw = 0;
        for (uint256 i = 0; i < stakes[_stakingId][_account].length; i++) {
            Staking storage _staking = stakes[_stakingId][_account][i];
            _stakedAmount = _stakedAmount.add(_staking.amount);
            _canWithdraw = _canWithdraw.add(_staking.amount);
        }
        return (_stakedAmount, _canWithdraw);
    }

    function stakeData(uint256 _stakingId, address _account) public override view returns (Staking[] memory) {
        Staking[] memory _stakeDatas = new Staking[](stakes[_stakingId][_account].length);
        for (uint256 i = 0; i < stakes[_stakingId][_account].length; i++) {
            Staking storage _staking = stakes[_stakingId][_account][i];
            _stakeDatas[i] = _staking;
        }
        return (_stakeDatas);
    }

    function earnedToken(uint256 _stakingId, address _account) public override view returns (uint256, uint256) {
        uint256 _canClaim = 0;
        uint256 _earned = 0;
        Plan storage plan = plans[_stakingId];
        for (uint256 i = 0; i < stakes[_stakingId][_account].length; i++) {
            Staking storage _staking = stakes[_stakingId][_account][i];
            _canClaim = _canClaim.add(
                _staking.amount
                    .mul(block.timestamp - _staking.stakeAt)
                    .mul(plan.apr)
                    .div(100)
                    .div(periodicTime)
            );
            _earned = _earned.add(
                _staking.amount
                    .mul(block.timestamp - _staking.stakeAt)
                    .mul(plan.apr)
                    .div(100)
                    .div(periodicTime)
            );
        }
        return (_earned, _canClaim);
    }

    function unstake(uint256 _stakingId, uint256 _amount) public nonReentrant override {
        uint256 _stakedAmount;
        uint256 _canWithdraw;
        Plan storage plan = plans[_stakingId];
        (_stakedAmount, _canWithdraw) = canWithdrawAmount(_stakingId, msg.sender);
        require(_canWithdraw >= _amount, "Withdraw Amount is not enough");
        uint256 deductionAmount = _amount.mul(plans[_stakingId].withdrawDeduction).div(1000);
        uint256 tamount = _amount - deductionAmount;
        uint256 amount = _amount;
        uint256 _earned = 0;
        uint256 _penalty = 0;
        for (uint256 i = stakes[_stakingId][msg.sender].length; i > 0; i--) {
            Staking storage _staking = stakes[_stakingId][msg.sender][i-1];
            if (amount >= _staking.amount) {
                if (block.timestamp >= _staking.endstakeAt) {
                    _earned = _earned.add(
                        _staking.amount
                            .mul(block.timestamp - _staking.stakeAt)
                            .mul(plan.apr)
                            .div(100)
                            .div(periodicTime)
                    );
                } else {
                    _penalty = _penalty.add(
                        _staking.amount
                        .mul(plan.earlyPenalty)
                        .div(100)
                    );
                }
                amount = amount.sub(_staking.amount);
                _staking.amount = 0;
            } else {
                if (block.timestamp >= _staking.endstakeAt) {
                    _earned = _earned.add(
                        amount
                            .mul(block.timestamp - _staking.stakeAt)
                            .mul(plan.apr)
                            .div(100)
                            .div(periodicTime)
                    );
                } else {
                    _penalty = _penalty.add(
                        amount
                        .mul(plan.earlyPenalty)
                        .div(100)
                    );
                }
                _staking.amount = _staking.amount.sub(amount);
                amount = 0;
                break;
            }
            _staking.stakeAt = block.timestamp;
        }

        if(deductionAmount > 0) {
            IERC20(stakingToken).transfer(stakingToken, deductionAmount);
        }
        if(tamount > 0) {
            IERC20(stakingToken).transfer(msg.sender, tamount - _penalty);
        }
        if(_earned > 0) {
            IERC20(stakingToken).transfer(msg.sender, _earned);
        }
        plans[_stakingId].overallStaked = plans[_stakingId].overallStaked.sub(_amount);
        emit unStake(msg.sender, amount);
    }

    function claimEarned(uint256 _stakingId) public nonReentrant override {
        uint256 _earned = 0;
        Plan storage plan = plans[_stakingId];
        for (uint256 i = 0; i < stakes[_stakingId][msg.sender].length; i++) {
            Staking storage _staking = stakes[_stakingId][msg.sender][i];
            _earned = _earned.add(
                _staking
                    .amount
                    .mul(plan.apr)
                    .mul(block.timestamp.sub(_staking.stakeAt))
                    .div(periodicTime)
                    .div(100)
            );
            _staking.stakeAt = block.timestamp;
        }
        require(_earned > 0, "There is no amount to claim");
        IERC20(stakingToken).transfer(msg.sender, _earned);
    }

    function claimReferralEarnings(uint256 _ramount) public nonReentrant {
        uint256 _claimable = userRef[msg.sender].claimableEarning;
        require(_ramount > 0, "Cannot claim zero");
        require(_claimable > 0, "no amount to claim");
        require(_claimable >= _ramount, "input amount higher than claimable balance");
        if(_claimable > 0 && _claimable >= _ramount){
            userRef[msg.sender].claimableEarning = userRef[msg.sender].claimableEarning.sub(_ramount);
            IERC20(stakingToken).transfer(msg.sender, _ramount);
        }
    }

    function getStakedPlans(address _account) public override view returns (bool[] memory) {
        bool[] memory walletPlans = new bool[](planLimit);
        for (uint256 i = 0; i < planLimit; i++) {
            walletPlans[i] = stakes[i][_account].length == 0 ? false : true;
        }
        return walletPlans;
    }

    function setAPR(uint256 _stakingId, uint256 _percent) external onlyOwner {
        plans[_stakingId].apr = _percent;
    }

    function setReferralRewardRate(uint256 _refId, uint256 _percent) external onlyOwner {
        require(_percent <= 3000, "Cannot more than 30%");
        refRate[_refId] = _percent;
    }

    function setStakeDuration(uint256 _stakingId, uint256 _duration) external onlyOwner {
        plans[_stakingId].stakeDuration = _duration;
    }

    function setDepositDeduction(uint256 _stakingId, uint256 _deduction) external onlyOwner {
        require(_deduction <= 300, "Cannot more than 30%");
        plans[_stakingId].depositDeduction = _deduction;
    }

    function setWithdrawDeduction(uint256 _stakingId, uint256 _deduction) external onlyOwner {
        require(_deduction <= 300, "Cannot more than 30%");
        plans[_stakingId].withdrawDeduction = _deduction;
    }

    function setEarlyPenalty(uint256 _stakingId, uint256 _penalty) external onlyOwner {
        require(_penalty <= 30, "Cannot more than 30%");
        plans[_stakingId].earlyPenalty = _penalty;
    }

    function setStakeConclude(uint256 _stakingId, bool _conclude) external onlyOwner {
        plans[_stakingId].conclude = _conclude;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner{
        require(stakingToken != tokenAddress, "Cannot recover stakingToken");
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }

    event Stake(address indexed user, uint256 amount);
    event unStake(address indexed user, uint256 amount);    
}