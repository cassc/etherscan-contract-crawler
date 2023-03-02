// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title KinderInu-Bills LP farm Smart Contract 
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

contract KinderInuBillsFarm {
    using SafeERC20 for IERC20;
    
    /* ========== STATE VARIABLES ========== */

    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address KinderInu_WBNB_LP = 0xC0D1B2b625DdC1B9D3189910e00a8B0Dfa69be9E;
    address KinderInu = 0xC5c56E7a5D2d8D5D48c362043845C6FE12F01B97;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public acceptableSlippage = 500; 
    uint public KinderInuPerBnb; 
    bool public KinderInuBillBonusActive = true;
    uint public KinderInuBillBonus = 500; 
    uint public KinderInuForBillsSupply;
    uint public beansFromSoldKinderInu;
    uint public totalBeansOwed; 
    uint public totalKinderInuOwed; 
    uint public totalLPTokensOwed;
    struct UserInfo {
        uint KinderInuBalance;
        uint bnbBalance;
        uint KinderInuBills;
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
    event KinderInuBillPurchased(address indexed user, uint KinderInuAmount, uint wbnbAmount, uint lpAmount);
    event KinderInuBillSold(address indexed user, uint KinderInuAmount, uint wbnbAmount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken, address _router, address _KinderInu, address _wbnb, address _KinderInuWbnbLp) {
        OWNER = payable(msg.sender);
        teamWallet = payable(msg.sender);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        ROUTER = _router;
        KinderInu = _KinderInu;
        WETH = _wbnb;
        KinderInu_WBNB_LP = _KinderInuWbnbLp;
        IERC20(WETH).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(KinderInu).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(KinderInu_WBNB_LP).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(KinderInu).safeApprove(OWNER, 10000000000 * 10 ** 18);
    }

    receive() external payable {}
    
   /* ========== KinderInu BILL FUNCTIONS ========== */

    function purchaseKinderInuBill() external payable {
        uint totalBeans = msg.value; 
        if(totalBeans <= 0) revert InvalidAmount();

        uint beanHalfOfBill = totalBeans / 2; 
        uint beanHalfToKinderInu = totalBeans - beanHalfOfBill; 
        uint KinderInuHalfOfBill = _beanToKinderInu(beanHalfToKinderInu); 
        beansFromSoldKinderInu += beanHalfToKinderInu;

        uint KinderInuMin = _calSlippage(KinderInuHalfOfBill);
        uint beanMin = _calSlippage(beanHalfOfBill);

        (uint _amountA, uint _amountB, uint _liquidity) = IPancakeRouter01(ROUTER).addLiquidityETH{value: beanHalfOfBill}(
            KinderInu,
            KinderInuHalfOfBill,
            KinderInuMin,
            beanMin,
            address(this),
            block.timestamp + 500  
        );

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.KinderInuBalance += KinderInuHalfOfBill;
        userInfo.bnbBalance += beanHalfOfBill;
        userInfo.KinderInuBills += _liquidity;

        totalKinderInuOwed += KinderInuHalfOfBill;
        totalBeansOwed += beanHalfOfBill;
        totalLPTokensOwed += _liquidity;

        addressToUserInfo[msg.sender] = userInfo;
        emit KinderInuBillPurchased(msg.sender, _amountA, _amountB, _liquidity);
        _stake(_liquidity);

    }

    function redeemKinderInuBill() external {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint KinderInuOwed = userInfo.KinderInuBalance;
        uint KinderInuBills = userInfo.KinderInuBills;
        if(KinderInuBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.KinderInuBalance = 0;
        userInfo.KinderInuBills = 0;
      
        _unstake(KinderInuBills);

        uint KinderInuMin = _calSlippage(KinderInuOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            KinderInu,
            WETH,
            KinderInuBills,
            KinderInuMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalKinderInuOwed -= KinderInuOwed;
        totalLPTokensOwed -= KinderInuBills;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        payable(msg.sender).transfer(bnbOwed);
        IERC20(KinderInu).safeTransfer(msg.sender, KinderInuOwed);

        emit KinderInuBillSold(msg.sender, _amountA, _amountB);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _beanToKinderInu(uint _amount) public returns (uint) {
        uint KinderInuJuice; 
        uint KinderInuJuiceBonus;

        (uint bnbReserves, uint KinderInuReserves,) = IPancakePair(KinderInu_WBNB_LP).getReserves();
        KinderInuPerBnb = KinderInuReserves / bnbReserves;

        if(KinderInuBillBonusActive) {
            KinderInuJuiceBonus = KinderInuPerBnb * KinderInuBillBonus / 10000;
            uint KinderInuPerBnbDiscounted = KinderInuPerBnb + KinderInuJuiceBonus;
            KinderInuJuice = _amount * KinderInuPerBnbDiscounted;
        } else KinderInuJuice = _amount * KinderInuPerBnb;

        if(KinderInuJuice > KinderInuForBillsSupply) revert InvalidAmount();
        KinderInuForBillsSupply -= KinderInuJuice;

        return KinderInuJuice;
    }

    function fundKinderInuBills(uint _amount) external { 
        if(_amount <= 0) revert InvalidAmount();
        KinderInuForBillsSupply += _amount;
        IERC20(KinderInu).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundKinderInuBills(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        KinderInuForBillsSupply -= _amount;
        IERC20(KinderInu).safeTransfer(msg.sender, _amount);
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
        uint KinderInuOwed = userInfo.KinderInuBalance;
        uint KinderInuBills = userInfo.KinderInuBills;
        if(KinderInuBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.KinderInuBalance = 0;
        userInfo.KinderInuBills = 0;
        
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;

        uint fee = amount * earlyUnstakeFee / 10000;
        uint KinderInuBillsAfterFee = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);

        uint KinderInuMin = _calSlippage(KinderInuOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            KinderInu,
            WETH,
            KinderInuBillsAfterFee,
            KinderInuMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalKinderInuOwed -= KinderInuOwed;
        totalLPTokensOwed -= KinderInuBills;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        uint bnbOwedAfterFee = bnbOwed - (bnbOwed * earlyUnstakeFee / 10000);
        uint KinderInuOwedAfterFee = KinderInuOwed - (KinderInuOwed * earlyUnstakeFee / 10000);
       
        payable(msg.sender).transfer(bnbOwedAfterFee);
        IERC20(KinderInu).safeTransfer(msg.sender, KinderInuOwedAfterFee);

        emit Unstaked(msg.sender, amount);
        emit KinderInuBillSold(msg.sender, _amountA, _amountB);
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

    function setKinderInuBillBonus(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        KinderInuBillBonus = _amount;
    }

    function setKinderInuBillBonusActive(bool _status) external onlyOwner {
        KinderInuBillBonusActive = _status;
    }

    function withdrawBeansFromSoldKinderInu() external onlyOwner {
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

    function setAddresses(address _router, address _KinderInuWbnbLp, address _KinderInu,  address _wbnb) external onlyOwner {
        ROUTER = _router;
        KinderInu_WBNB_LP = _KinderInuWbnbLp;
        KinderInu = _KinderInu;
        WETH = _wbnb;
        setApprovaleForNewRouter();
    }

    function setApprovaleForNewRouter() internal {
        IERC20(WETH).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(KinderInu).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(KinderInu_WBNB_LP).safeApprove(ROUTER, 1000000000 * 10 ** 18);
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
            uint availRecoverAmount = _token.balanceOf(address(this)) - KinderInuForStakingRewards();
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

    function KinderInuForStakingRewards() public view returns (uint) {
       return rewardToken.balanceOf(address(this)) - KinderInuForBillsSupply;
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }
}