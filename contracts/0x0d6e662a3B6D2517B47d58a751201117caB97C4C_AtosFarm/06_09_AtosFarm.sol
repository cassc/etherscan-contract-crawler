// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
/// @title Single Staking Pool/Farm Rewards Smart Contract 
/// @author @m3tamorphTECH
/// @notice Designed based on the OG Synthetix staking rewards contract

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IWETH.sol";

    /* ========== CUSTOM ERRORS ========== */

error InvalidAmount();
error InvalidAddress();
error TokensLocked();

contract AtosFarm is ReentrancyGuard {
    using SafeERC20 for IERC20;
   
    /* ========== STATE VARIABLES ========== */

    address public owner;
    address payable public teamWallet;
    IERC20 public stakedToken;
    IERC20 public rewardToken;
    address internal atos = 0xF0a3a52Eef1eBE77Bb2743F53035b5813aFe721F;
    address internal pair = 0x8A6Fc18e27338876810E1770F9158a1A271F90aB;
    address internal router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint public YIELD_RATE = 3000;
    uint public LOCK_TIME = 30 days;
    uint public EARLY_UNSTAKE_FEE = 1000;
    uint public stakingRewardsSupply;
    
    /* ========== Farm Variables ========== */

    uint public acceptableSlippage = 500; 
    uint public atosPerEth;
    uint public atosForBillsSupply;
    uint public totalEthOwed; 
    uint public totalAtosOwed; 
    struct UserInfo {
        uint atosBalance; 
        uint ethBalance; 
        uint lpBalance;
        uint stakedTimeStamp;
        uint unlockTimeStamp;
        uint rewardAmount; 
    }
    mapping(address => UserInfo) public addressToUserInfo;

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        if(msg.sender != owner) revert InvalidAddress();
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event Log(uint fullRewards, uint timeStaked, uint timeLocked, uint fractionStaked, uint owedRewards);
   
    /* ========== CONSTRUCTOR ========== */

    constructor(address _atos, address _pair, address _router, address _weth) payable {
        owner = msg.sender;
        teamWallet = payable(0xE00C59db165B84Fee2be6C3E115DFF11552C1D1c);
        atos = _atos;
        stakedToken = IERC20(atos);
        rewardToken = IERC20(atos);
        pair = _pair;
        router = _router;
        WETH = _weth;
        IERC20(WETH).approve(router, 1000000000000 * 10 ** 18);
        IERC20(pair).approve(router, 1000000000000 * 10 ** 18);
        IERC20(atos).approve(router, 1000000000000 * 10 ** 18);
    }

    receive() external payable {}
    
/* ========== MUTATIVE FUNCTIONS ========== */

    function purchaseAtosBill() external payable nonReentrant {
        uint totalEth = msg.value; 
        if(totalEth <= 0) revert InvalidAmount();

        uint ethHalfOfBill = totalEth / 2; 
        uint ethHalfToAtos = totalEth - ethHalfOfBill; 
        uint atosHalfOfBill = _ethToAtos(ethHalfToAtos);
        if(atosHalfOfBill <= 0) revert InvalidAmount();

        uint atosMin = _calSlippage(atosHalfOfBill);
        uint ethMin = _calSlippage(ethHalfOfBill);

        (uint _amountA, uint _amountB, uint _liquidity) = IUniswapV2Router02(router).addLiquidityETH{value: ethHalfOfBill}(
            atos,
            atosHalfOfBill,
            atosMin,
            ethMin,
            address(this),
            block.timestamp + 900  
        );

        uint rewardAmount = _calculateRewards(atosHalfOfBill);

        UserInfo memory userInfo = addressToUserInfo[msg.sender];
        userInfo.atosBalance += atosHalfOfBill; // _amountA
        userInfo.ethBalance += ethHalfOfBill; // _amountB
        userInfo.lpBalance += _liquidity;
        userInfo.stakedTimeStamp = block.timestamp;
        userInfo.unlockTimeStamp = block.timestamp + LOCK_TIME;
        userInfo.rewardAmount += rewardAmount; 
        
        addressToUserInfo[msg.sender] = userInfo;

        totalAtosOwed += atosHalfOfBill;
        totalEthOwed += ethHalfOfBill;
        

        emit Staked(msg.sender, atosHalfOfBill);
    }

    function redeemAtosBill() external nonReentrant {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint atosOwed = userInfo.atosBalance;
        uint ethOwed = userInfo.ethBalance;
        uint atosBills = userInfo.lpBalance;
        uint rewardAmount = userInfo.rewardAmount;

        if(atosBills <= 0) revert InvalidAmount();
        if(atosOwed <= 0) revert InvalidAmount();

        userInfo.atosBalance = 0;
        userInfo.ethBalance = 0;
        userInfo.lpBalance = 0;
        userInfo.rewardAmount = 0;
      
        uint atosMin = _calSlippage(atosOwed);
        uint ethMin = _calSlippage(ethOwed);

        (uint _amountA, uint _amountB) = IUniswapV2Router02(router).removeLiquidity(
            atos,
            WETH,
            atosBills,
            atosMin,
            ethMin, 
            address(this),
            block.timestamp + 500 
        );

        uint balance = address(this).balance;
        IWETH(WETH).withdraw(_amountB);
        assert(address(this).balance == balance + _amountB);

        totalAtosOwed -= atosOwed;
        totalEthOwed -= ethOwed;
        stakingRewardsSupply -= rewardAmount;
        
        uint transferAmount = atosOwed + rewardAmount;

        payable(msg.sender).transfer(ethOwed);
        IERC20(atos).safeTransfer(msg.sender, transferAmount);

        emit Unstaked(msg.sender, atosOwed);
    }

    function _calSlippage(uint _amount) internal view returns (uint) {
        return _amount * acceptableSlippage / 10000;
    }

    function _ethToAtos(uint _amount) internal returns (uint) {
        uint totalAtos; 

        (uint ethReserves, uint AtosReserves,) = IUniswapV2Pair(pair).getReserves();
        AtosReserves = AtosReserves / 10 ** 9;
        ethReserves = ethReserves / 10 ** 18;
        atosPerEth = AtosReserves / ethReserves;
        
        totalAtos = _amount * atosPerEth / 10 ** 9;

        if(totalAtos > atosForBillsSupply) revert InvalidAmount();
        atosForBillsSupply -= totalAtos;

        return totalAtos;
    }

    function _calculateRewards(uint _amount) internal view returns(uint) {
        uint rewardAmount = _amount * YIELD_RATE / 10000;
        return rewardAmount;
    }

    function emergencyUnstake() external nonReentrant {
        UserInfo storage userInfo = addressToUserInfo[msg.sender];
        uint atosOwed = userInfo.atosBalance;
        uint ethOwed = userInfo.ethBalance;
        uint atosBills = userInfo.lpBalance;
        uint rewardAmount = userInfo.rewardAmount;
        uint stakedTimestamp = userInfo.stakedTimeStamp;

        if(atosBills <= 0) revert InvalidAmount();
        if(atosOwed <= 0) revert InvalidAmount();
        if(userInfo.unlockTimeStamp < block.timestamp) revert InvalidAmount();

        userInfo.atosBalance = 0;
        userInfo.ethBalance = 0;
        userInfo.lpBalance = 0;
        userInfo.rewardAmount = 0;

        totalAtosOwed -= atosOwed;
        totalEthOwed -= ethOwed;
        stakingRewardsSupply -= rewardAmount;

        uint rewardsOwed = _calculateRewardsEmerg(rewardAmount, stakedTimestamp);
        uint fee = atosOwed * EARLY_UNSTAKE_FEE / 10000;
        uint postFeeAmount = atosOwed - fee;
        uint amountDue = postFeeAmount + rewardsOwed;

        payable(msg.sender).transfer(ethOwed);        
        IERC20(atos).safeTransfer(teamWallet, fee);
        IERC20(atos).safeTransfer(msg.sender, amountDue);   

        emit Unstaked(msg.sender, atosOwed);
    }

    function _calculateRewardsEmerg(uint _rewardAmount, uint _stakedTimestamp) internal returns(uint) {
        uint fullRewards = _rewardAmount;
        uint owedRewards; 

        uint timeStaked = block.timestamp - _stakedTimestamp;
        uint timeLocked = LOCK_TIME;
        uint fractionStaked = timeStaked * 1e18 / timeLocked;

        owedRewards = fullRewards * fractionStaked / 1e18;
       
        emit Log(fullRewards, timeStaked, timeLocked, fractionStaked, owedRewards);
        return owedRewards;

    }

    /* ========== VIEW & GETTER FUNCTIONS ========== */

    function balanceOf(address _account) external view returns (uint) {
        UserInfo memory userInfo = addressToUserInfo[_account];
        return userInfo.atosBalance;
    }

    function totalStaked() external view returns (uint) {
        return totalAtosOwed;
    }

    /* ========== OWNER RESTRICTED FUNCTIONS ========== */

    function fundStakingRewards(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        stakingRewardsSupply += _amount;
        IERC20(atos).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function fundAtosBills(uint _amount) external onlyOwner { 
        if(_amount <= 0) revert InvalidAmount();
        atosForBillsSupply += _amount;
        IERC20(atos).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function defundAtosBills(uint _amount) external onlyOwner {
        if(_amount <= 0) revert InvalidAmount();
        atosForBillsSupply -= _amount;
        IERC20(atos).safeTransfer(msg.sender, _amount);
    }

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function updateYieldRate(uint _yieldRate) external onlyOwner {
        if(_yieldRate <= 0) revert InvalidAmount();
        YIELD_RATE = _yieldRate;
    }

    function updateLockTime(uint _lockTime) external onlyOwner {
        if(_lockTime <= 0) revert InvalidAmount();
        LOCK_TIME = _lockTime;
    }

    function updateEarlyUnstakeFee(uint _earlyUnstakeFee) external onlyOwner {
        if(_earlyUnstakeFee <= 0) revert InvalidAmount();
        if(_earlyUnstakeFee > 5000) revert InvalidAmount(); // can't set higher than 50%
        EARLY_UNSTAKE_FEE = _earlyUnstakeFee;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if(_newOwner == address(0)) revert InvalidAddress();
        owner = _newOwner;
    }

    function recoverEth() external onlyOwner {
        uint balance = address(this).balance;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function recoverErc20(IERC20 _token, uint _amount) external onlyOwner {
        _token.safeTransfer(msg.sender, _amount);
    }

}