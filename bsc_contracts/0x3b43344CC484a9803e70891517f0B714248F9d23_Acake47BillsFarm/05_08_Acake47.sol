// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title Bills LP farm Smart Contract 
/// @author @m3tamorphTECH
/// @dev version 1.1

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter01.sol";
import "../interfaces/IWETH.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

contract Acake47BillsFarm {
    using SafeERC20 for IERC20;
    
    /* ========== STATE VARIABLES ========== */

    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address LP_PAIR = 0xeF65bc4d2216FFF6211Ada51F04f8dbEd70Cf43C;
    address ACAKE47 = 0xD62389d1C9d1457E59d59d9cEBe038308dA2ed6D;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public acceptableSlippage = 500; 
    uint public ACAKE47PerBnb; 
    bool public ACAKE47BillBonusActive = false;
    uint public ACAKE47BillBonus = 500; 
    uint public ACAKE47ForBillsSupply;
    uint public beansFromSoldACAKE47;
    uint public totalBeansOwed; 
    uint public totalACAKE47Owed; 
    uint public totalLPTokensOwed;
    struct UserInfo {
        uint ACAKE47Balance;
        uint bnbBalance;
        uint ACAKE47Bills;
    }
    mapping(address => UserInfo) public addressToUserInfo;

    address payable public OWNER;
    address payable public teamWallet;
    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    uint public earlyUnstakeFee = 2000;
    uint public poolDuration;
    uint public poolStartTime;
    uint public poolEndTime;
    uint public updatedAt;
    uint public rewardRate; 
    uint public rewardPerTokenStored; 
    uint private _totalStaked;
    mapping(address => uint) public userStakedBalance;
    mapping(address => uint) public userPaidRewards;
    mapping(address => uint) userRewardPerTokenPaid;
    mapping(address => uint) userRewards; 
    
    /* ========== MODIFIERS ========== */

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();
        if (_account != address(0)) {
            userRewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyOwner() {
        if(msg.sender != OWNER) revert InvalidAddress();
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event ACAKE47BillPurchased(address indexed user, uint ACAKE47Amount, uint wbnbAmount, uint lpAmount);
    event ACAKE47BillSold(address indexed user, uint ACAKE47Amount, uint wbnbAmount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken, address _router, address _ACAKE47, address _wbnb, address _ACAKE47WbnbLp) {
        OWNER = payable(msg.sender);
        teamWallet = payable(msg.sender);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        ROUTER = _router;
        ACAKE47 = _ACAKE47;
        WETH = _wbnb;
        LP_PAIR = _ACAKE47WbnbLp;
        IERC20(WETH).safeApprove(ROUTER, 2**256-1);
        IERC20(ACAKE47).safeApprove(ROUTER, 2**256-1);
        IERC20(LP_PAIR).safeApprove(ROUTER, 2**256-1);
        IERC20(ACAKE47).safeApprove(OWNER, 2**256-1);
    }

    receive() external payable {}
    
   /* ========== ACAKE47 BILL FUNCTIONS ========== */

    function purchaseACAKE47Bill() external payable {
        uint totalBeans = msg.value; 
        if(totalBeans <= 0) revert InvalidAmount();

        uint beanHalfOfBill = totalBeans / 2; 
        uint beanHalfToACAKE47 = totalBeans - beanHalfOfBill; 
        uint ACAKE47HalfOfBill = _beanToACAKE47(beanHalfToACAKE47); 
        beansFromSoldACAKE47 += beanHalfToACAKE47;

        uint ACAKE47Min = _calSlippage(ACAKE47HalfOfBill);
        uint beanMin = _calSlippage(beanHalfOfBill);

        (uint _amountA, uint _amountB, uint _liquidity) = IPancakeRouter01(ROUTER).addLiquidityETH{value: beanHalfOfBill}(
            ACAKE47,
            ACAKE47HalfOfBill,
            ACAKE47Min,
            beanMin,
            address(this),
            block.timestamp + 500  
        );

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.ACAKE47Balance += ACAKE47HalfOfBill;
        userInfo.bnbBalance += beanHalfOfBill;
        userInfo.ACAKE47Bills += _liquidity;

        totalACAKE47Owed += ACAKE47HalfOfBill;
        totalBeansOwed += beanHalfOfBill;
        totalLPTokensOwed += _liquidity;
        
        addressToUserInfo[msg.sender] = userInfo;
        emit ACAKE47BillPurchased(msg.sender, _amountA, _amountB, _liquidity);
        _stake(_liquidity);

    }

    function redeemACAKE47Bill() external {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint ACAKE47Owed = userInfo.ACAKE47Balance;
        uint ACAKE47Bills = userInfo.ACAKE47Bills;
        if(ACAKE47Bills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.ACAKE47Balance = 0;
        userInfo.ACAKE47Bills = 0;
      
        _unstake(ACAKE47Bills);

        uint ACAKE47Min = _calSlippage(ACAKE47Owed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            ACAKE47,
            WETH,
            ACAKE47Bills,
            ACAKE47Min,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        totalBeansOwed -= bnbOwed;
        totalACAKE47Owed -= ACAKE47Owed;
        totalLPTokensOwed -= ACAKE47Bills;

        payable(msg.sender).transfer(bnbOwed);
        IERC20(ACAKE47).safeTransfer(msg.sender, ACAKE47Owed);

        emit ACAKE47BillSold(msg.sender, _amountA, _amountB);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _beanToACAKE47(uint _amount) public returns (uint) {
        uint ACAKE47Juice; 
        uint ACAKE47JuiceBonus;

        (uint bnbReserves, uint ACAKE47Reserves,) = IPancakePair(LP_PAIR).getReserves();
        ACAKE47PerBnb = ACAKE47Reserves / bnbReserves;

        if(ACAKE47BillBonusActive) {
            ACAKE47JuiceBonus = ACAKE47PerBnb * ACAKE47BillBonus / 10000;
            uint ACAKE47PerBnbDiscounted = ACAKE47PerBnb + ACAKE47JuiceBonus;
            ACAKE47Juice = _amount * ACAKE47PerBnbDiscounted;
        } else ACAKE47Juice = _amount * ACAKE47PerBnb;

        if(ACAKE47Juice > ACAKE47ForBillsSupply) revert InvalidAmount();
        ACAKE47ForBillsSupply -= ACAKE47Juice;

        return ACAKE47Juice;
    }

    function fundACAKE47Bills(uint _amount) external { 
        if(_amount <= 0) revert InvalidAmount();
        ACAKE47ForBillsSupply += _amount;
        IERC20(ACAKE47).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundACAKE47Bills(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        ACAKE47ForBillsSupply -= _amount;
        IERC20(ACAKE47).safeTransfer(msg.sender, _amount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _stake(uint _amount) internal updateReward(msg.sender) {
        if(_amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] += _amount;
        _totalStaked += _amount;
        emit Staked(msg.sender, _amount);
    }

    function _unstake(uint _amount) internal updateReward(msg.sender) {
        if(block.timestamp < poolEndTime) revert TokensLocked();
        if(_amount <= 0) revert InvalidAmount();
        if(_amount > userStakedBalance[msg.sender]) revert InvalidAmount();
        userStakedBalance[msg.sender] -= _amount;
        _totalStaked -= _amount;
        emit Unstaked(msg.sender, _amount);
    }

    function emergencyUnstake() external updateReward(msg.sender) {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint ACAKE47Owed = userInfo.ACAKE47Balance;
        uint ACAKE47Bills = userInfo.ACAKE47Bills;
        if(ACAKE47Bills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.ACAKE47Balance = 0;
        userInfo.ACAKE47Bills = 0;
        
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;

        uint fee = amount * earlyUnstakeFee / 10000;
        uint ACAKE47BillsAfterFee = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);

        uint ACAKE47Min = _calSlippage(ACAKE47Owed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            ACAKE47,
            WETH,
            ACAKE47BillsAfterFee,
            ACAKE47Min,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        totalBeansOwed -= bnbOwed;
        totalACAKE47Owed -= ACAKE47Owed;
        totalLPTokensOwed -= ACAKE47Bills;

        uint bnbOwedAfterFee = bnbOwed - (bnbOwed * earlyUnstakeFee / 10000);
        uint ACAKE47OwedAfterFee = ACAKE47Owed - (ACAKE47Owed * earlyUnstakeFee / 10000);
       
        payable(msg.sender).transfer(bnbOwedAfterFee);
        IERC20(ACAKE47).safeTransfer(msg.sender, ACAKE47OwedAfterFee);

        emit Unstaked(msg.sender, amount);
        emit ACAKE47BillSold(msg.sender, _amountA, _amountB);
    }    

    function claimRewards() public updateReward(msg.sender) {
        uint rewards = userRewards[msg.sender];
        if (rewards > 0) {
            userRewards[msg.sender] = 0;
            userPaidRewards[msg.sender] += rewards;
            rewardToken.safeTransfer(msg.sender, rewards);
            emit RewardPaid(msg.sender, rewards);
        }
    }

    /* ========== OWNER RESTRICTED FUNCTIONS ========== */

    function setAcceptableSlippage(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        acceptableSlippage = _amount;
    }

    function setACAKE47BillBonus(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        ACAKE47BillBonus = _amount;
    }

    function setACAKE47BillBonusActive(bool _status) external onlyOwner {
        ACAKE47BillBonusActive = _status;
    }

    function withdrawBeansFromSoldACAKE47() external onlyOwner {
        uint beans = beansFromSoldACAKE47;
        beansFromSoldACAKE47 = 0;
        (bool success, ) = msg.sender.call{value: beans}("");
        require(success, "Transfer failed.");
    }

    function setPoolDuration(uint _duration) external onlyOwner {
        require(poolEndTime < block.timestamp, "Pool still live");
        poolDuration = _duration;
    }

    function setPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        if (_amount <= 0) revert InvalidAmount();
        if (block.timestamp >= poolEndTime) {
            rewardRate = _amount / poolDuration;
        } else {
            uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / poolDuration;
        }
        if(rewardRate <= 0) revert InvalidAmount();
        poolStartTime = block.timestamp;
        poolEndTime = block.timestamp + poolDuration;
        updatedAt = block.timestamp;
    } 

    function topUpPoolRewards(uint _amount) external onlyOwner updateReward(address(0)) { 
        uint remainingRewards = (poolEndTime - block.timestamp) * rewardRate;
        rewardRate = (_amount + remainingRewards) / poolDuration;
        if(rewardRate <= 0) revert InvalidAmount();
        updatedAt = block.timestamp;
    } 

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function setAddresses(address _router, address _ACAKE47WbnbLp, address _ACAKE47,  address _wbnb) external onlyOwner {
        ROUTER = _router;
        LP_PAIR = _ACAKE47WbnbLp;
        ACAKE47 = _ACAKE47;
        WETH = _wbnb;
        setApprovaleForNewRouter();
    }

    function setApprovaleForNewRouter() internal {
        IERC20(WETH).safeApprove(ROUTER, 2**256-1);
        IERC20(ACAKE47).safeApprove(ROUTER, 2**256-1);
        IERC20(LP_PAIR).safeApprove(ROUTER, 2**256-1);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        OWNER = payable(_newOwner);
    }

    function setEarlyUnstakeFee(uint _earlyUnstakeFee) external onlyOwner {
        if(_earlyUnstakeFee > 2500) revert InvalidAmount();
        earlyUnstakeFee = _earlyUnstakeFee;
    }

    function emergencyRecoverBeans() public onlyOwner {
        uint recoverAmount = address(this).balance;
        (bool success, ) = msg.sender.call{value: recoverAmount}("");
        require(success, "Transfer failed.");
    }

    function emergencyRecoverBEP20(IERC20 _token, uint _amount) public onlyOwner {
        if(_token == stakedToken) {
            uint recoverAmount = _token.balanceOf(address(this)) - totalLPTokensOwed;
            _token.safeTransfer(msg.sender, recoverAmount);
        }
        else if(_token == rewardToken) {
            uint availRecoverAmount = _token.balanceOf(address(this)) - ACAKE47ForStakingRewards();
            if(_amount > availRecoverAmount) revert InvalidAmount();
            _token.safeTransfer(msg.sender, _amount);
        }
        else {
            _token.safeTransfer(msg.sender, _amount);
        }
    }

    /* ========== VIEW & GETTER FUNCTIONS ========== */

    function viewUserInfo(address _user) public view returns (UserInfo memory) {
        return addressToUserInfo[_user];
    }

    function earned(address _account) public view returns (uint) {
        return (userStakedBalance[_account] * 
            (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18
            + userRewards[_account];
    }

    function lastTimeRewardApplicable() internal view returns (uint) {
        return _min(block.timestamp, poolEndTime);
    }

    function rewardPerToken() internal view returns (uint) {
        if (_totalStaked == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) / _totalStaked;
    }

    function _min(uint x, uint y) internal pure returns (uint) {
        return x <= y ? x : y;
    }

    function ACAKE47ForStakingRewards() public view returns (uint) {
       return rewardToken.balanceOf(address(this)) - ACAKE47ForBillsSupply;
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }
}