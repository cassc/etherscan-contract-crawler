// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract PHXStake is Ownable {
    
    using SafeMath for uint256;
    // Info of each user.

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CAKEs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * accPhxPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPhxPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // // Info of each pool.
    // struct PoolInfo {
    //     IERC20 lpToken;           // Address of LP token contract.
    //     uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
    //     uint256 lastRewardBlock;  // Last block number that CAKEs distribution occurs.
    //     uint256 accPhxPerShare; // Accumulated CAKEs per share, times 1e12. See below.
    // }
    // The PHX TOKEN!

    IERC20 public phx;
    //The lpToken TOKEN!
    IERC20 public lpToken;
    // PHX tokens created per block.
    uint256 public phxPerBlock;
    // Bonus muliplier for early cake makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when PHX mining starts.
    uint256 public startBlock;
    // How many allocation points assigned to pool.
    uint256 public allocPoint;
    // Accumulated PHX per share, times 1e12.
    uint256 public accPhxPerShare;
    //Last block number that CAKEs distribution occurs.
    uint256 public lastRewardBlock; 

    event Deposit(
        address indexed user, 
        uint256 amount
        );

    event Withdraw(
        address indexed user, 
        uint256 amount
        );

    event EmergencyWithdraw(
        address indexed user, 
        uint256 amount
        );

    constructor(
        IERC20 _phx,
        IERC20 _lpToken,
        uint256 _phxPerBlock
  
    ) public {
        phx = _phx;
        lpToken = _lpToken;
        phxPerBlock = _phxPerBlock;
        startBlock = block.number;
        allocPoint = 1000;
        lastRewardBlock = startBlock;
        accPhxPerShare= 0;
        totalAllocPoint = 1000;
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }
    function setPhxPerBlock(uint256 _phxPerBlock) external onlyOwner{
        phxPerBlock = _phxPerBlock;
    }

    // Update the pool's allocation point. Can only be called by the owner.
    function set(uint256 _allocPoint) public onlyOwner {
        uint256 prevAllocPoint = allocPoint;
        allocPoint = _allocPoint;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            updatePool();
        }
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending pheonix on frontend.
    function pendingPHX(address _user) 
        external 
        view 
        returns (uint256) 
        {
        UserInfo storage user = userInfo[_user];
        uint256 lpSupply = lpToken.balanceOf(address(this));
        uint256 accPhx = accPhxPerShare;
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
            
            uint256 phxReward = multiplier.mul(phxPerBlock).mul(allocPoint).div(totalAllocPoint);
            accPhx = accPhx.add(phxReward.mul(1e12).div(lpSupply));
        }
        return (user.amount.mul(accPhx).div(1e12).sub(user.rewardDebt));
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint256 lpSupply = lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
        uint256 phxReward = multiplier.mul(phxPerBlock).mul(allocPoint).div(totalAllocPoint);
        accPhxPerShare = accPhxPerShare.add(phxReward.mul(1e12).div(lpSupply));
        lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit( uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accPhxPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                phx.transfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(accPhxPerShare).div(1e12);
        emit Deposit(msg.sender, _amount);
    }
    function lpTokenSupply() public view returns(uint256){
        return lpToken.balanceOf(address(this));
    }
    // function acc() public view returns(uint256){
    //     return accPhxPerShare;
    // }
    // function userInf() public view returns(uint256,uint256){
    //     return (userInfo[msg.sender].amount,userInfo[msg.sender].rewardDebt);
    // }
    // function utils() public view returns(uint256){
    //     return (block.number);
    // }
    // function getPhx() public view returns(uint256){
    //     uint256 multiplier = getMultiplier(lastRewardBlock, block.number);
    //     uint256 phxReward = multiplier.mul(phxPerBlock).mul(allocPoint).div(totalAllocPoint);
    //     return phxReward;
    // }
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _amount) public {

        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool();
        uint256 pending = user.amount.mul(accPhxPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
           phx.transfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            lpToken.transfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(accPhxPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }
     // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        // hi
        UserInfo storage user = userInfo[msg.sender];
        lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }
}