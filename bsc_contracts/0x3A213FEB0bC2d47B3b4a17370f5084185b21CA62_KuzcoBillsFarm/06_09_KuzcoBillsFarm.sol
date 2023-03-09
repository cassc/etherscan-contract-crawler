// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title Kuzco LP farm Smart Contract 
/// @author @m3tamorphTECH
/// @dev version 1.3 - 9 decimal compatibility

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter01.sol";
import "../interfaces/IWETH.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

contract KuzcoBillsFarm is ReentrancyGuard { 
    using SafeERC20 for IERC20;
    
    /* ========== STATE VARIABLES ========== */

    address ROUTER = 0x0Fa0544003C3Ad35806d22774ee64B7F6b56589b; 
    address Kuzco_WBNB_LP = 0x7868Da09d75472f0279CC175D9870e4cd7105A07;
    address Kuzco = 0x7dF332d3183DB400b69B71d4b6bcD0354293cdD9;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public acceptableSlippage = 1500; 
    uint public KuzcoPerBnb; 
    bool public KuzcoBillBonusActive = false;
    uint public KuzcoBillBonus = 500; 
    uint public KuzcoForBillsSupply;
    uint public beansFromSoldKuzco;
    uint public totalBeansOwed; 
    uint public totalKuzcoOwed; 
    uint public totalLPTokensOwed;
    struct UserInfo {
        uint KuzcoBalance;
        uint bnbBalance;
        uint KuzcoBills;
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
    event KuzcoBillPurchased(address indexed user, uint KuzcoAmount, uint wbnbAmount, uint lpAmount);
    event KuzcoBillsold(address indexed user, uint KuzcoAmount, uint wbnbAmount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken, address _router, address _Kuzco, address _wbnb, address _KuzcoWbnbLp) {
        OWNER = payable(msg.sender);
        teamWallet = payable(msg.sender);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        ROUTER = _router;
        Kuzco = _Kuzco;
        WETH = _wbnb;
        Kuzco_WBNB_LP = _KuzcoWbnbLp;
        IERC20(WETH).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(Kuzco).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(Kuzco_WBNB_LP).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(Kuzco).safeApprove(OWNER, 10000000000 * 10 ** 18);
    }

    receive() external payable {}
    
   /* ========== Kuzco Bill FUNCTIONS ========== */

    function purchaseKuzcoBill() external payable nonReentrant {
        uint totalBeans = msg.value; 
        if(totalBeans <= 0) revert InvalidAmount();

        uint beanHalfOfBill = totalBeans / 2; 
        uint beanHalfToKuzco = totalBeans - beanHalfOfBill; 
        uint KuzcoHalfOfBill = _beanToKuzco(beanHalfToKuzco); 
        beansFromSoldKuzco += beanHalfToKuzco;

        uint KuzcoMin = _calSlippage(KuzcoHalfOfBill);
        uint beanMin = _calSlippage(beanHalfOfBill);

        (uint _amountA, uint _amountB, uint _liquidity) = IPancakeRouter01(ROUTER).addLiquidityETH{value: beanHalfOfBill}(
            Kuzco,
            KuzcoHalfOfBill,
            KuzcoMin,
            beanMin,
            address(this),
            block.timestamp + 500  
        );

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.KuzcoBalance += KuzcoHalfOfBill;
        userInfo.bnbBalance += beanHalfOfBill;
        userInfo.KuzcoBills += _liquidity;

        totalKuzcoOwed += KuzcoHalfOfBill;
        totalBeansOwed += beanHalfOfBill;
        totalLPTokensOwed += _liquidity;

        addressToUserInfo[msg.sender] = userInfo;
        emit KuzcoBillPurchased(msg.sender, _amountA, _amountB, _liquidity);
        _stake(_liquidity);

    }

    function redeemKuzcoBill() external nonReentrant {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint KuzcoOwed = userInfo.KuzcoBalance;
        uint KuzcoBills = userInfo.KuzcoBills;
        if(KuzcoBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.KuzcoBalance = 0;
        userInfo.KuzcoBills = 0;
      
        _unstake(KuzcoBills);

        uint KuzcoMin = _calSlippage(KuzcoOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            Kuzco,
            WETH,
            KuzcoBills,
            KuzcoMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalKuzcoOwed -= KuzcoOwed;
        totalLPTokensOwed -= KuzcoBills;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        payable(msg.sender).transfer(bnbOwed);
        IERC20(Kuzco).safeTransfer(msg.sender, KuzcoOwed);

        emit KuzcoBillsold(msg.sender, _amountA, _amountB);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _beanToKuzco(uint _amount) internal returns (uint) {
        uint KuzcoJuice; 
        uint KuzcoJuiceBonus;

        (uint KuzcoReserves, uint bnbReserves,) = IPancakePair(Kuzco_WBNB_LP).getReserves();
        KuzcoReserves = KuzcoReserves / 10 ** 9;
        bnbReserves = bnbReserves / 10 ** 18;
        KuzcoPerBnb = KuzcoReserves / bnbReserves;

        if(KuzcoBillBonusActive) {
            KuzcoJuiceBonus = KuzcoPerBnb * KuzcoBillBonus / 10000;
            uint KuzcoPerBnbDiscounted = KuzcoPerBnb + KuzcoJuiceBonus;
            KuzcoJuice = _amount * KuzcoPerBnbDiscounted / 10 ** 9;
        } 
        
        else KuzcoJuice = _amount * KuzcoPerBnb / 10 ** 9;

        if(KuzcoJuice > KuzcoForBillsSupply) revert InvalidAmount();
        KuzcoForBillsSupply -= KuzcoJuice;

        return KuzcoJuice;
    }

    function fundKuzcoBills(uint _amount) external onlyOwner { 
        if(_amount <= 0) revert InvalidAmount();
        KuzcoForBillsSupply += _amount;
        IERC20(Kuzco).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundKuzcoBills(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        KuzcoForBillsSupply -= _amount;
        IERC20(Kuzco).safeTransfer(msg.sender, _amount);
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

    function emergencyUnstake() external nonReentrant updateReward(msg.sender) {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint KuzcoOwed = userInfo.KuzcoBalance;
        uint KuzcoBills = userInfo.KuzcoBills;
        if(KuzcoBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.KuzcoBalance = 0;
        userInfo.KuzcoBills = 0;
        
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;

        uint fee = amount * earlyUnstakeFee / 10000;
        uint KuzcoBillsAfterFee = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);

        uint KuzcoMin = _calSlippage(KuzcoOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            Kuzco,
            WETH,
            KuzcoBillsAfterFee,
            KuzcoMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalKuzcoOwed -= KuzcoOwed;
        totalLPTokensOwed -= KuzcoBills;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        uint bnbOwedAfterFee = bnbOwed - (bnbOwed * earlyUnstakeFee / 10000);
        uint KuzcoOwedAfterFee = KuzcoOwed - (KuzcoOwed * earlyUnstakeFee / 10000);
       
        payable(msg.sender).transfer(bnbOwedAfterFee);
        IERC20(Kuzco).safeTransfer(msg.sender, KuzcoOwedAfterFee);

        emit Unstaked(msg.sender, amount);
        emit KuzcoBillsold(msg.sender, _amountA, _amountB);
    }    

    function claimRewards() public nonReentrant updateReward(msg.sender) {
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

    function setKuzcoBillBonus(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        KuzcoBillBonus = _amount;
    }

    function setKuzcoBillBonusActive(bool _status) external onlyOwner {
        KuzcoBillBonusActive = _status;
    }

    function withdrawBeansFromSoldKuzco() external onlyOwner {
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
        if(_teamWallet == address(0)) revert InvalidAddress();
        teamWallet = _teamWallet;
    }

    function setAddresses(address _router, address _KuzcoWbnbLp, address _Kuzco,  address _wbnb) external onlyOwner {
        if(_router == address(0)) revert InvalidAddress();
        if(_KuzcoWbnbLp == address(0)) revert InvalidAddress();
        if(_Kuzco == address(0)) revert InvalidAddress();
        if(_wbnb == address(0)) revert InvalidAddress();
        ROUTER = _router;
        Kuzco_WBNB_LP = _KuzcoWbnbLp;
        Kuzco = _Kuzco;
        WETH = _wbnb;
        setApprovaleForNewRouter();
    }

    function setApprovaleForNewRouter() internal {
        IERC20(WETH).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(Kuzco).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(Kuzco_WBNB_LP).safeApprove(ROUTER, 1000000000 * 10 ** 18);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if(_newOwner == address(0)) revert InvalidAddress();
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
            uint availRecoverAmount = _token.balanceOf(address(this)) - KuzcoForStakingRewards();
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

    function KuzcoForStakingRewards() public view returns (uint) {
       return rewardToken.balanceOf(address(this)) - KuzcoForBillsSupply;
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }
}