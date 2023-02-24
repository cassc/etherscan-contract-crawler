// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title DefiBear-Bills LP farm Smart Contract 
/// @author @m3tamorphTECH
/// @dev version 1.0

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IPancakeRouter01.sol";
import "../interfaces/IPancakeRouter02.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

contract DefiBearsFarm {
    using SafeERC20 for IERC20;
    
    /* ========== STATE VARIABLES ========== */

    address APE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 
    address KIWI_WBNB_LP = 0xb0494c303871c28f38Fa07f7A052C02C449Cbb47;
    address KIWI = 0xAF049b4B059201E0167863aeCc28C43cdaD3c521;
    address WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    uint public acceptableSlippage = 500; 
    uint public kiwiPerBnb; 
    bool public kiwiBillBonusActive = false;
    uint public kiwiBillBonus = 1000; // 10% bonus
    uint public kiwiForBillsSupply;
    uint public beansFromSoldKiwi;
    struct UserInfo {
        uint kiwiBalance;
        uint bnbBalance;
        uint kiwiBills;
    }
    mapping(address => UserInfo) public addressToUserInfo;

    address payable public OWNER;
    address payable public teamWallet;
    IERC20 public immutable stakedToken;
    IERC20 public immutable rewardToken;
    uint public earlyUnstakeFee = 2000;  // 20% fee
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
    event KiwiBillPurchased(address indexed user, uint kiwiAmount, uint wbnbAmount, uint lpAmount);
    event KiwiBillSold(address indexed user, uint kiwiAmount, uint wbnbAmount);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakedToken, address _rewardToken, address _router, address _kiwi, address _wbnb, address _kiwiWbnbLp) {
        OWNER = payable(msg.sender);
        teamWallet = payable(0x832faEe88b4C5B444F08FdB1dC30A48883e9d329);
        stakedToken = IERC20(_stakedToken);
        rewardToken = IERC20(_rewardToken);
        APE_ROUTER = _router;
        KIWI = _kiwi;
        WETH = _wbnb;
        KIWI_WBNB_LP = _kiwiWbnbLp;
        IERC20(WETH).safeApprove(APE_ROUTER, 10000000000 * 10 ** 18);
        IERC20(KIWI).safeApprove(APE_ROUTER, 10000000000 * 10 ** 18);
        IERC20(KIWI_WBNB_LP).safeApprove(APE_ROUTER, 10000000000 * 10 ** 18);
        IERC20(KIWI).safeApprove(OWNER, 10000000000 * 10 ** 18);
    }

    receive() external payable {}
    
   /* ========== KIWI BILL FUNCTIONS ========== */

    function purchaseKiwiBill() external payable {
        uint totalBeans = msg.value; 
        if(totalBeans <= 0) revert InvalidAmount();

        uint beanHalfOfBill = totalBeans / 2; 
        uint beanHalfToKiwi = totalBeans - beanHalfOfBill; 
        uint kiwiHalfOfBill = _beanToKiwi(beanHalfToKiwi); 
        beansFromSoldKiwi += beanHalfToKiwi;

        uint kiwiMin = _calSlippage(kiwiHalfOfBill);
        uint beanMin = _calSlippage(beanHalfOfBill);

        (uint _amountA, uint _amountB, uint _liquidity) = IPancakeRouter01(APE_ROUTER).addLiquidityETH{value: beanHalfOfBill}(
            KIWI,
            kiwiHalfOfBill,
            kiwiMin,
            beanMin,
            address(this),
            block.timestamp + 500  
        );

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.kiwiBalance += kiwiHalfOfBill;
        userInfo.bnbBalance += beanHalfOfBill;
        userInfo.kiwiBills += _liquidity;

        addressToUserInfo[msg.sender] = userInfo;
        emit KiwiBillPurchased(msg.sender, _amountA, _amountB, _liquidity);
        _stake(_liquidity);

    }

    function redeemKiwiBill() external {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint bnbOwed = userInfo.bnbBalance;
        uint kiwiOwed = userInfo.kiwiBalance;
        uint kiwiBills = userInfo.kiwiBills;
        if(kiwiBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.kiwiBalance = 0;
        userInfo.kiwiBills = 0;
      
        _unstake(kiwiBills);

        uint kiwiMin = _calSlippage(kiwiOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(APE_ROUTER).removeLiquidity(
            KIWI,
            WETH,
            kiwiBills,
            kiwiMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        // (uint _amountA, uint _amountB) = IPancakeRouter01(APE_ROUTER).removeLiquidityETH(
        //     KIWI,
        //     kiwiBills,
        //     kiwiMin,
        //     beanMin, 
        //     address(this),
        //     block.timestamp + 500 
        // );

        payable(msg.sender).transfer(bnbOwed);
        IERC20(KIWI).safeTransfer(msg.sender, kiwiOwed);

        emit KiwiBillSold(msg.sender, _amountA, _amountB);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _beanToKiwi(uint _amount) public returns (uint) {
        uint kiwiJuice; 
        uint kiwiJuiceBonus;

        //confirm token0 & token1 in LP contract
        (uint kiwiReserves, uint bnbReserves,) = IPancakePair(KIWI_WBNB_LP).getReserves();
        kiwiPerBnb = kiwiReserves / bnbReserves;

        if(kiwiBillBonusActive) {
            kiwiJuiceBonus = kiwiPerBnb * kiwiBillBonus / 10000;
            uint kiwiPerBnbDiscounted = kiwiPerBnb + kiwiJuiceBonus;
            kiwiJuice = _amount * kiwiPerBnbDiscounted;
        } else kiwiJuice = _amount * kiwiPerBnb;

        if(kiwiJuice > kiwiForBillsSupply) revert InvalidAmount();
        kiwiForBillsSupply -= kiwiJuice;

        return kiwiJuice;
    }

    function fundKiwiBills(uint _amount) external { 
        if(_amount <= 0) revert InvalidAmount();
        kiwiForBillsSupply += _amount;
        IERC20(KIWI).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundKiwiBills(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        kiwiForBillsSupply -= _amount;
        IERC20(KIWI).safeTransfer(msg.sender, _amount);
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
        uint kiwiOwed = userInfo.kiwiBalance;
        uint kiwiBills = userInfo.kiwiBills;
        if(kiwiBills <= 0) revert InvalidAmount();
        userInfo.bnbBalance = 0;
        userInfo.kiwiBalance = 0;
        userInfo.kiwiBills = 0;
        
        uint amount = userStakedBalance[msg.sender];
        if(amount <= 0) revert InvalidAmount();
        userStakedBalance[msg.sender] = 0;
        _totalStaked -= amount;

        uint fee = amount * earlyUnstakeFee / 10000;
        uint kiwiBillsAfterFee = amount - fee;
        stakedToken.safeTransfer(teamWallet, fee);

        uint kiwiMin = _calSlippage(kiwiOwed);
        uint beanMin = _calSlippage(bnbOwed);

        (uint _amountA, uint _amountB) = IPancakeRouter01(APE_ROUTER).removeLiquidity(
            KIWI,
            WETH,
            kiwiBillsAfterFee,
            kiwiMin,
            beanMin, 
            address(this),
            block.timestamp + 500 
        );

        // (uint _amountA, uint _amountB) = IPancakeRouter01(APE_ROUTER).removeLiquidityETH(
        //     KIWI,
        //     kiwiBillsAfterFee, 
        //     kiwiMin, 
        //     beanMin, 
        //     address(this),
        //     block.timestamp + 500 
        // );

        uint bnbOwedAfterFee = bnbOwed - (bnbOwed * earlyUnstakeFee / 10000);
        uint kiwiOwedAfterFee = kiwiOwed - (kiwiOwed * earlyUnstakeFee / 10000);
       
        payable(msg.sender).transfer(bnbOwedAfterFee);
        IERC20(KIWI).safeTransfer(msg.sender, kiwiOwedAfterFee);

        emit Unstaked(msg.sender, amount);
        emit KiwiBillSold(msg.sender, _amountA, _amountB);
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

    function setKiwiBillBonus(uint _amount) external onlyOwner {
        if(_amount > 2000) revert InvalidAmount(); // can't set above 20%
        kiwiBillBonus = _amount;
    }

    function setKiwiBillBonusActive(bool _status) external onlyOwner {
        kiwiBillBonusActive = _status;
    }

    function withdrawBeansFromSoldKiwi() external onlyOwner {
        uint beans = beansFromSoldKiwi;
        beansFromSoldKiwi = 0;
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
        require(rewardRate > 0, "reward rate = 0");
        updatedAt = block.timestamp;
    } 

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function setAddresses(address _router, address _kiwiWbnbLp, address _kiwi,  address _wbnb) external onlyOwner {
        APE_ROUTER = _router;
        KIWI_WBNB_LP = _kiwiWbnbLp;
        KIWI = _kiwi;
        WETH = _wbnb;
        setApprovaleForNewRouter();
    }

    function setApprovaleForNewRouter() internal {
        IERC20(WETH).safeApprove(APE_ROUTER, 1000000000 * 10 ** 18);
        IERC20(KIWI).safeApprove(APE_ROUTER, 1000000000 * 10 ** 18);
        IERC20(KIWI_WBNB_LP).safeApprove(APE_ROUTER, 1000000000 * 10 ** 18);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        OWNER = payable(_newOwner);
    }

    function setEarlyUnstakeFee(uint _earlyUnstakeFee) external onlyOwner {
        require(_earlyUnstakeFee <= 2500, "the amount of fee is too damn high");
        earlyUnstakeFee = _earlyUnstakeFee;
    }

    function emergencyRecoverBeans() public onlyOwner {
        uint balance = address(this).balance;
        uint recoverAmount = balance - beansFromSoldKiwi;
        (bool success, ) = msg.sender.call{value: recoverAmount}("");
        require(success, "Transfer failed.");
    }

    function emergencyRecoverBEP20(IERC20 _token, uint _amount) public onlyOwner {
        if(_token == stakedToken) {
            uint recoverAmount = _token.balanceOf(address(this)) - _totalStaked;
            _token.safeTransfer(msg.sender, recoverAmount);
        }
        else if(_token == rewardToken) {
            uint availRecoverAmount = _token.balanceOf(address(this)) - kiwiForStakingRewards();
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

    function kiwiForStakingRewards() public view returns (uint) {
       return rewardToken.balanceOf(address(this)) - kiwiForBillsSupply;
    }

    function balanceOf(address _account) external view returns (uint) {
        return userStakedBalance[_account];
    }

    function totalStaked() external view returns (uint) {
        return _totalStaked;
    }
}