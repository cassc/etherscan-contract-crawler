// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title Pulsinator Farm-Bonds Smart Contract 
/// @author @m3tamorphTECH
/// @dev version 1.2

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

contract PulsinatorFarmBonds is ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    /* ========== STATE VARIABLES ========== */

    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address Pulsinator_WBNB_LP = 0xa26B7Cc2d1C18Ec9cB1d57b3F7d74a06E5df4740;
    address Pulsinator = 0xaEc98d2e60CD5FDf577cEc7A62f92580B1F89Ae6;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public acceptableSlippage = 500; 
    uint public PulsinatorPerBnb; 
    bool public PulsinatorBondBonusActive = false;
    uint public PulsinatorBondBonus = 500; 
    uint public PulsinatorForBondsSupply;
    uint public beansFromSoldPulsinator;
    uint public totalBeansOwed; 
    uint public totalPulsinatorOwed; 
    uint public totalLPTokensOwed;
    struct UserInfo {
        uint PulsinatorBalance;
        uint bnbBalance;
        uint PulsinatorBonds;
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
    event PulsinatorBondPurchased(address indexed user, uint PulsinatorAmount, uint wbnbAmount, uint lpAmount);
    event PulsinatorBondSold(address indexed user, uint PulsinatorAmount, uint wbnbAmount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken, address _router, address _Pulsinator, address _wbnb, address _PulsinatorWbnbLp) {
        OWNER = payable(msg.sender);
        teamWallet = payable(0xA15DDAdA6872B6c5948eED4E6Cac267962FdBEd1);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        ROUTER = _router;
        Pulsinator = _Pulsinator;
        WETH = _wbnb;
        Pulsinator_WBNB_LP = _PulsinatorWbnbLp;
        IERC20(WETH).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(Pulsinator).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(Pulsinator_WBNB_LP).safeApprove(ROUTER, 10000000000 * 10 ** 18);
        IERC20(Pulsinator).safeApprove(OWNER, 10000000000 * 10 ** 18);
    }

    receive() external payable {}
    
   /* ========== Pulsinator Bond FUNCTIONS ========== */

    function purchasePulsinatorBond() external payable nonReentrant {
        uint totalBeans = msg.value; 
        if(totalBeans <= 0) revert InvalidAmount();

        uint beanHalfOfBond = totalBeans / 2; 
        uint beanHalfToPulsinator = totalBeans - beanHalfOfBond; 
        uint PulsinatorHalfOfBond = _beanToPulsinator(beanHalfToPulsinator); 
        beansFromSoldPulsinator += beanHalfToPulsinator;

        uint PulsinatorMin = _calSlippage(PulsinatorHalfOfBond);
        uint beanMin = _calSlippage(beanHalfOfBond);

        (uint _amountA, uint _amountB, uint _liquidity) = IPancakeRouter01(ROUTER).addLiquidityETH{value: beanHalfOfBond}(
            Pulsinator,
            PulsinatorHalfOfBond,
            PulsinatorMin,
            beanMin,
            address(this),
            block.timestamp + 500  
        );

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.PulsinatorBalance += PulsinatorHalfOfBond;
        userInfo.bnbBalance += beanHalfOfBond;
        userInfo.PulsinatorBonds += _liquidity;

        totalPulsinatorOwed += PulsinatorHalfOfBond;
        totalBeansOwed += beanHalfOfBond;
        totalLPTokensOwed += _liquidity;

        addressToUserInfo[msg.sender] = userInfo;
        emit PulsinatorBondPurchased(msg.sender, _amountA, _amountB, _liquidity);
        _stake(_liquidity);

    }

    function redeemPulsinatorBond() external nonReentrant {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint PulsinatorOwed = userInfo.PulsinatorBalance;
        uint PulsinatorBonds = userInfo.PulsinatorBonds;
        if(PulsinatorBonds <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.PulsinatorBalance = 0;
        userInfo.PulsinatorBonds = 0;
      
        _unstake(PulsinatorBonds);

        uint PulsinatorMin = _calSlippage(PulsinatorOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            Pulsinator,
            WETH,
            PulsinatorBonds,
            PulsinatorMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalPulsinatorOwed -= PulsinatorOwed;
        totalLPTokensOwed -= PulsinatorBonds;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        payable(msg.sender).transfer(bnbOwed);
        IERC20(Pulsinator).safeTransfer(msg.sender, PulsinatorOwed);

        emit PulsinatorBondSold(msg.sender, _amountA, _amountB);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _beanToPulsinator(uint _amount) internal returns (uint) {
        uint PulsinatorJuice; 
        uint PulsinatorJuiceBonus;

        (uint PulsinatorReserves, uint bnbReserves,) = IPancakePair(Pulsinator_WBNB_LP).getReserves();
        PulsinatorPerBnb = PulsinatorReserves / bnbReserves;

        if(PulsinatorBondBonusActive) {
            PulsinatorJuiceBonus = PulsinatorPerBnb * PulsinatorBondBonus / 10000;
            uint PulsinatorPerBnbDiscounted = PulsinatorPerBnb + PulsinatorJuiceBonus;
            PulsinatorJuice = _amount * PulsinatorPerBnbDiscounted;
        } else PulsinatorJuice = _amount * PulsinatorPerBnb;

        if(PulsinatorJuice > PulsinatorForBondsSupply) revert InvalidAmount();
        PulsinatorForBondsSupply -= PulsinatorJuice;

        return PulsinatorJuice;
    }

    function fundPulsinatorBonds(uint _amount) external onlyOwner { 
        if(_amount <= 0) revert InvalidAmount();
        PulsinatorForBondsSupply += _amount;
        IERC20(Pulsinator).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundPulsinatorBonds(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        PulsinatorForBondsSupply -= _amount;
        IERC20(Pulsinator).safeTransfer(msg.sender, _amount);
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
        uint PulsinatorOwed = userInfo.PulsinatorBalance;
        uint PulsinatorBonds = userInfo.PulsinatorBonds;
        if(PulsinatorBonds <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.PulsinatorBalance = 0;
        userInfo.PulsinatorBonds = 0;
        
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;

        uint fee = amount * earlyUnstakeFee / 10000;
        uint PulsinatorBondsAfterFee = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);

        uint PulsinatorMin = _calSlippage(PulsinatorOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(ROUTER).removeLiquidity(
            Pulsinator,
            WETH,
            PulsinatorBondsAfterFee,
            PulsinatorMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        totalBeansOwed -= bnbOwed;
        totalPulsinatorOwed -= PulsinatorOwed;
        totalLPTokensOwed -= PulsinatorBonds;

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        uint bnbOwedAfterFee = bnbOwed - (bnbOwed * earlyUnstakeFee / 10000);
        uint PulsinatorOwedAfterFee = PulsinatorOwed - (PulsinatorOwed * earlyUnstakeFee / 10000);
       
        payable(msg.sender).transfer(bnbOwedAfterFee);
        IERC20(Pulsinator).safeTransfer(msg.sender, PulsinatorOwedAfterFee);

        emit Unstaked(msg.sender, amount);
        emit PulsinatorBondSold(msg.sender, _amountA, _amountB);
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

    function setPulsinatorBondBonus(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        PulsinatorBondBonus = _amount;
    }

    function setPulsinatorBondBonusActive(bool _status) external onlyOwner {
        PulsinatorBondBonusActive = _status;
    }

    function withdrawBeansFromSoldPulsinator() external onlyOwner {
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

    function setAddresses(address _router, address _PulsinatorWbnbLp, address _Pulsinator,  address _wbnb) external onlyOwner {
        if(_router == address(0)) revert InvalidAddress();
        if(_PulsinatorWbnbLp == address(0)) revert InvalidAddress();
        if(_Pulsinator == address(0)) revert InvalidAddress();
        if(_wbnb == address(0)) revert InvalidAddress();
        ROUTER = _router;
        Pulsinator_WBNB_LP = _PulsinatorWbnbLp;
        Pulsinator = _Pulsinator;
        WETH = _wbnb;
        setApprovaleForNewRouter();
    }

    function setApprovaleForNewRouter() internal {
        IERC20(WETH).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(Pulsinator).safeApprove(ROUTER, 1000000000 * 10 ** 18);
        IERC20(Pulsinator_WBNB_LP).safeApprove(ROUTER, 1000000000 * 10 ** 18);
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
            uint availRecoverAmount = _token.balanceOf(address(this)) - PulsinatorForStakingRewards();
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

    function PulsinatorForStakingRewards() public view returns (uint) {
       return rewardToken.balanceOf(address(this)) - PulsinatorForBondsSupply;
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }
}