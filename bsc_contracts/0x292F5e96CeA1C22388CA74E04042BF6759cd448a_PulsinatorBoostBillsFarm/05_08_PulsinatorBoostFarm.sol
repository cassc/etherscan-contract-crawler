// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title PulsinatorBoost-Bills LP farm Smart Contract 
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

contract PulsinatorBoostBillsFarm {
    using SafeERC20 for IERC20;
    
    /* ========== STATE VARIABLES ========== */

    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address PulsinatorBoost_WBNB_LP = 0x7EA21EdFD1c3BBC9304c2Baf365768a65Eb52260;
    address PulsinatorBoost = 0x872e002bb606DFD6990Dd54461ad513009C1777f;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public acceptableSlippage = 500; 
    uint public PulsinatorBoostPerBnb; 
    bool public PulsinatorBoostBillBonusActive = true;
    uint public PulsinatorBoostBillBonus = 500; 
    uint public PulsinatorBoostForBillsSupply;
    uint public beansFromSoldPulsinatorBoost;
    uint public totalBeansOwed; 
    uint public totalPulsinatorBoostOwed; 
    uint public totalLPTokensOwed;
    struct UserInfo {
        uint PulsinatorBoostBalance;
        uint bnbBalance;
        uint PulsinatorBoostBills;
    }
    mapping(address => UserInfo) public addressToUserInfo;

    address payable public OWNER;
    address payable public teamWallet;
    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    uint public earlyUnstakeFee = 2500; 
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
    event PulsinatorBoostBillPurchased(address indexed user, uint PulsinatorBoostAmount, uint wbnbAmount, uint lpAmount);
    event PulsinatorBoostBillSold(address indexed user, uint PulsinatorBoostAmount, uint wbnbAmount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken, address _router, address _PulsinatorBoost, address _wbnb, address _PulsinatorBoostWbnbLp) {
        OWNER = payable(msg.sender);
        teamWallet = payable(msg.sender);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        ROUTER = _router;
        PulsinatorBoost = _PulsinatorBoost;
        WETH = _wbnb;
        PulsinatorBoost_WBNB_LP = _PulsinatorBoostWbnbLp;
        IERC20(WETH).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(PulsinatorBoost).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(PulsinatorBoost_WBNB_LP).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(PulsinatorBoost).safeApprove(OWNER, 10000000000 * 10 ** 18);
    }

    receive() external payable {}
    
   /* ========== PulsinatorBoost BILL FUNCTIONS ========== */

    function purchasePulsinatorBoostBill() external payable {
        uint totalBeans = msg.value; 
        if(totalBeans <= 0) revert InvalidAmount();

        uint beanHalfOfBill = totalBeans / 2; 
        uint beanHalfToPulsinatorBoost = totalBeans - beanHalfOfBill; 
        uint PulsinatorBoostHalfOfBill = _beanToPulsinatorBoost(beanHalfToPulsinatorBoost); 
        beansFromSoldPulsinatorBoost += beanHalfToPulsinatorBoost;

        uint PulsinatorBoostMin = _calSlippage(PulsinatorBoostHalfOfBill);
        uint beanMin = _calSlippage(beanHalfOfBill);

        (uint _amountA, uint _amountB, uint _liquidity) = IPancakeRouter01(ROUTER).addLiquidityETH{value: beanHalfOfBill}(
            PulsinatorBoost,
            PulsinatorBoostHalfOfBill,
            PulsinatorBoostMin,
            beanMin,
            address(this),
            block.timestamp + 500  
        );

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.PulsinatorBoostBalance += PulsinatorBoostHalfOfBill;
        userInfo.bnbBalance += beanHalfOfBill;
        userInfo.PulsinatorBoostBills += _liquidity;

        totalPulsinatorBoostOwed += PulsinatorBoostHalfOfBill;
        totalBeansOwed += beanHalfOfBill;
        totalLPTokensOwed += _liquidity;

        addressToUserInfo[msg.sender] = userInfo;
        emit PulsinatorBoostBillPurchased(msg.sender, _amountA, _amountB, _liquidity);
        _stake(_liquidity);

    }

    function redeemPulsinatorBoostBill() external {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint PulsinatorBoostOwed = userInfo.PulsinatorBoostBalance;
        uint PulsinatorBoostBills = userInfo.PulsinatorBoostBills;
        if(PulsinatorBoostBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.PulsinatorBoostBalance = 0;
        userInfo.PulsinatorBoostBills = 0;
      
        _unstake(PulsinatorBoostBills);

        uint PulsinatorBoostMin = _calSlippage(PulsinatorBoostOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            PulsinatorBoost,
            WETH,
            PulsinatorBoostBills,
            PulsinatorBoostMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalPulsinatorBoostOwed -= PulsinatorBoostOwed;
        totalLPTokensOwed -= PulsinatorBoostBills;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        payable(msg.sender).transfer(bnbOwed);
        IERC20(PulsinatorBoost).safeTransfer(msg.sender, PulsinatorBoostOwed);

        emit PulsinatorBoostBillSold(msg.sender, _amountA, _amountB);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _beanToPulsinatorBoost(uint _amount) public returns (uint) {
        uint PulsinatorBoostJuice; 
        uint PulsinatorBoostJuiceBonus;

        (uint PulsinatorBoostReserves, uint bnbReserves,) = IPancakePair(PulsinatorBoost_WBNB_LP).getReserves();
        PulsinatorBoostPerBnb = PulsinatorBoostReserves / bnbReserves;

        if(PulsinatorBoostBillBonusActive) {
            PulsinatorBoostJuiceBonus = PulsinatorBoostPerBnb * PulsinatorBoostBillBonus / 10000;
            uint PulsinatorBoostPerBnbDiscounted = PulsinatorBoostPerBnb + PulsinatorBoostJuiceBonus;
            PulsinatorBoostJuice = _amount * PulsinatorBoostPerBnbDiscounted;
        } else PulsinatorBoostJuice = _amount * PulsinatorBoostPerBnb;

        if(PulsinatorBoostJuice > PulsinatorBoostForBillsSupply) revert InvalidAmount();
        PulsinatorBoostForBillsSupply -= PulsinatorBoostJuice;

        return PulsinatorBoostJuice;
    }

    function fundPulsinatorBoostBills(uint _amount) external { 
        if(_amount <= 0) revert InvalidAmount();
        PulsinatorBoostForBillsSupply += _amount;
        IERC20(PulsinatorBoost).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundPulsinatorBoostBills(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        PulsinatorBoostForBillsSupply -= _amount;
        IERC20(PulsinatorBoost).safeTransfer(msg.sender, _amount);
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
        uint PulsinatorBoostOwed = userInfo.PulsinatorBoostBalance;
        uint PulsinatorBoostBills = userInfo.PulsinatorBoostBills;
        if(PulsinatorBoostBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.PulsinatorBoostBalance = 0;
        userInfo.PulsinatorBoostBills = 0;
        
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;

        uint fee = amount * earlyUnstakeFee / 10000;
        uint PulsinatorBoostBillsAfterFee = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);

        uint PulsinatorBoostMin = _calSlippage(PulsinatorBoostOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            PulsinatorBoost,
            WETH,
            PulsinatorBoostBillsAfterFee,
            PulsinatorBoostMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalPulsinatorBoostOwed -= PulsinatorBoostOwed;
        totalLPTokensOwed -= PulsinatorBoostBills;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        uint bnbOwedAfterFee = bnbOwed - (bnbOwed * earlyUnstakeFee / 10000);
        uint PulsinatorBoostOwedAfterFee = PulsinatorBoostOwed - (PulsinatorBoostOwed * earlyUnstakeFee / 10000);
       
        payable(msg.sender).transfer(bnbOwedAfterFee);
        IERC20(PulsinatorBoost).safeTransfer(msg.sender, PulsinatorBoostOwedAfterFee);

        emit Unstaked(msg.sender, amount);
        emit PulsinatorBoostBillSold(msg.sender, _amountA, _amountB);
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

    function setPulsinatorBoostBillBonus(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        PulsinatorBoostBillBonus = _amount;
    }

    function setPulsinatorBoostBillBonusActive(bool _status) external onlyOwner {
        PulsinatorBoostBillBonusActive = _status;
    }

    function withdrawBeansFromSoldPulsinatorBoost() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
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
        require(rewardRate > 0, "reward rate = 0");
        updatedAt = block.timestamp;
    } 

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function setAddresses(address _router, address _PulsinatorBoostWbnbLp, address _PulsinatorBoost,  address _wbnb) external onlyOwner {
        ROUTER = _router;
        PulsinatorBoost_WBNB_LP = _PulsinatorBoostWbnbLp;
        PulsinatorBoost = _PulsinatorBoost;
        WETH = _wbnb;
        setApprovaleForNewRouter();
    }

    function setApprovaleForNewRouter() internal {
        IERC20(WETH).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(PulsinatorBoost).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(PulsinatorBoost_WBNB_LP).safeApprove(ROUTER, 1000000000 * 10 ** 18);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        OWNER = payable(_newOwner);
    }

    function setEarlyUnstakeFee(uint _earlyUnstakeFee) external onlyOwner {
        require(_earlyUnstakeFee <= 2500, "the amount of fee is too damn high");
        earlyUnstakeFee = _earlyUnstakeFee;
    }

    function emergencyRecoverBEP20(IERC20 _token, uint _amount) public onlyOwner {
        if(_token == stakedToken) {
            uint recoverAmount = _token.balanceOf(address(this)) - _totalStaked;
            _token.safeTransfer(msg.sender, recoverAmount);
        }
        else if(_token == rewardToken) {
            uint availRecoverAmount = _token.balanceOf(address(this)) - PulsinatorBoostForStakingRewards();
            require(_amount <= availRecoverAmount, "amount too high");
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

    function PulsinatorBoostForStakingRewards() public view returns (uint) {
       return rewardToken.balanceOf(address(this)) - PulsinatorBoostForBillsSupply;
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }
}