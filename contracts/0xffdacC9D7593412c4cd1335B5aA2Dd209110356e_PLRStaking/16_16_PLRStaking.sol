// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

import "./interfaces/ILPRewards.sol";
import "./interfaces/IStakingRewards.sol";
import "./interfaces/RewardsDistributionRecipient.sol";
import "./interfaces/IOlympus.sol";
import "./interfaces/IUniswapV2Router02.sol";


contract PLRStaking is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint8 private _ready;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    /* === configuration constants === */
    //TODO - Replace with mainnet addresses
    uint256 private constant MAX_INVESTMENT_PERCENT = 20;
    uint256 private constant STAKING_PERIOD = 90 days;
    uint256 private constant MINIMUM_GUARANTEED_REWARDS = 300000e18;
    

    /* === configuration variables === */
    address private ROUTER_CONTRACT_ADDRESS = address(0);
    address private OHM_STAKING_ADDRESS = address(0);
    address private PLR_TOKEN_ADDRESS = address(0);
    address private OHM_TOKEN_ADDRESS = address(0);
    address private DAI_TOKEN_ADDRESS = address(0);
    address private STAKED_OHM_TOKEN_ADDRESS = address(0);
    address private pillarDaoVault;
    address private lpVault; // Address of the LP staking contract 
    uint256 private maxWeeklyInvest = 80000e18;
    uint256 private maxStake = 1000000e18; // 1 million tokens  
    uint256 private stakingStart;  
    uint256 private totalStaked = 0;
    uint256 private totalInvested = 0;
    uint256 private lastInvestedTimestamp = 0;
    uint256 private _rewardsEarned = 0;
    mapping(address => uint256) private _balances;

    /* ====== Modifiers ====== */
    modifier whenInitialized() {
        require(_ready == 0, "PLRStaking: Contract not ready");
        _;
    }

    modifier whenReadyToStake() {
        require(_ready == 1, "PLRStaking: Not ready to stake");
        _;
    }

    modifier whenInvestable() {
        require(_ready == 2, "PLRStaking: Contract is not ready for investing");
        _;
    }

    modifier whenReadyToUnstake() {
        require(_ready == 3, "PLRStaking: Not ready to unstake");
        _;
    }

    modifier whenInvestableOrStakable() {
        require((_ready ==2 || _ready ==3),"PLRStaking: Not ready to unstake");
        _;
    }
    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _rewardsDistribution
    ) {
        rewardsDistribution = _rewardsDistribution;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_stakingToken);
        _ready = 0; //contract is initialised
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function getContractState() public view onlyOwner returns (uint8) {
        return _ready;
    }

    function setInitialized() public onlyOwner whenReadyToUnstake {
        _ready = 0;
    }

    function setStakeable() public onlyOwner whenInitialized {
        _ready = 1;
        if(stakingStart == 0) {
            stakingStart = block.timestamp;
        }
    }

    function setInvestable() public onlyOwner whenReadyToStake {
        require(IERC20(stakingToken).balanceOf(address(this)) > 0, "PLRStaking: Not enough balance");
        _ready = 2;
    }

    function setUnstakeable() public onlyOwner whenInvestableOrStakable{
        _ready = 3;
    }

    function notifyRewardAmount(uint256 _reward) override external onlyRewardsDistribution {
        require(_reward > 0, "PLRStaking: Invalid reward amount");
        _rewardsEarned = _rewardsEarned.add(_reward);
        RewardAdded(_reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakingToken), "PLRStaking: Cannot withdraw the staking token");
        IERC20(_tokenAddress).safeTransfer(address(this), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function configure(
        address _routerContract, 
        address _olympusContract,
        address _plrToken,
        address _daiToken,
        address _ohmToken,
        address _sOhmToken) external onlyOwner whenInitialized {
        require(_routerContract != address(0), "PLRStaking: Invalid Router address");
        require(_olympusContract != address(0), "PLRStaking: Invalid Staking address");
        require(_plrToken != address(0), "PLRStaking: Invalid PLR token");
        require(_daiToken != address(0), "PLRStaking: Invalid DAI token");
        require(_ohmToken != address(0), "PLRStaking: Invalid OHM token");
        require(_sOhmToken != address(0), "PLRStaking: Invalid sOHM token");
        ROUTER_CONTRACT_ADDRESS = _routerContract;
        OHM_STAKING_ADDRESS = _olympusContract;
        PLR_TOKEN_ADDRESS = _plrToken;
        DAI_TOKEN_ADDRESS = _daiToken;
        OHM_TOKEN_ADDRESS = _ohmToken;
        STAKED_OHM_TOKEN_ADDRESS = _sOhmToken;
    }

    function setPillarDAOVault(address _daoWallet) external onlyOwner {
        require(_daoWallet != address(0), "PLRStaking: Invalid wallet");
        pillarDaoVault = _daoWallet;
    }

    function setLPVault(address _lpVault) external onlyOwner {
        require(_lpVault != address(0), "PLRStaking: Invalid LP Vault");
        lpVault = _lpVault;
    }

    function setMaxWeeklyInvestment(uint256 _amt) external onlyOwner whenInitialized {
        require(_amt != 0, "PLRStaking: Maximum stake cannot be zero");
        maxWeeklyInvest = _amt;
    }

    function setMaxStake(uint256 _amt) external onlyOwner whenInitialized {
        require(_amt != 0, "PLRStaking: Maximum stake cannot be zero");
        maxStake = _amt;
    }

    function startStakingPeriod() external onlyOwner whenInitialized {
        stakingStart = block.timestamp;
        setStakeable();
    }
    function endStakingPeriod() external onlyOwner whenInvestable {
        uint256 currentTimestamp = block.timestamp;
        uint256 timeLapsed = currentTimestamp.sub(stakingStart);
        require(timeLapsed > STAKING_PERIOD, "PLRStaking: Too early to end staking");
        setUnstakeable();
    }
    /* ========== VIEWS ========== */

    function totalSupply() override external view returns (uint256) {
        return totalStaked;
    }

    function balanceOf(address _account) override external view returns (uint256) {
        return _balances[_account];
    }

    function rewardsEarned() external view returns (uint256) {
        return _rewardsEarned;
    }

    function getMaxWeeklyInvestment() external view returns (uint256) {
        return maxWeeklyInvest;
    }

    function getMaxStake() external view returns (uint256) {
        return maxStake;
    }

    function getTotalInvested() external view returns (uint256) {
        return totalInvested;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function stake(uint256 _amount) override external nonReentrant whenReadyToStake {
        require(_amount > 0, "PLRStaking: Cannot stake 0");
        require(_amount <= maxStake, "PLRStaking: Cannot stake more than 1 million");
        totalStaked = totalStaked.add(_amount);
        _balances[msg.sender] = _balances[msg.sender].add(_amount);
        TransferHelper.safeTransferFrom(address(stakingToken),msg.sender,address(this),_amount);
        emit Staked(msg.sender, _amount);
    }

    function exit() override external nonReentrant whenReadyToUnstake {
        uint256 rewardsAvailable = MINIMUM_GUARANTEED_REWARDS;
        uint256 contributionSize = _balances[msg.sender].mul(100).div(totalStaked);
        if(_rewardsEarned > MINIMUM_GUARANTEED_REWARDS) {
            uint256 extra = _rewardsEarned.sub(rewardsAvailable).div(3);
            rewardsAvailable = rewardsAvailable.add(extra);
        }
        uint256 rewardsForUser = rewardsAvailable.mul(contributionSize).div(100);
        rewardsForUser = _balances[msg.sender].add(rewardsForUser);
        withdraw(rewardsForUser);
    }
    /* ======= ReInvesting Functions ========= */

    function invest(uint256 _deadline) override external onlyOwner whenInvestable {
        require(_deadline > block.timestamp, "PLRStaking: Invalid deadline");
        require(ROUTER_CONTRACT_ADDRESS != address(0), "PLRStaking: Invalid Router address");
        require(OHM_STAKING_ADDRESS != address(0), "PLRStaking: Invalid OHM address");
        uint256 timeLapse = block.timestamp - lastInvestedTimestamp;
        require(timeLapse > 1 weeks, "PLRStaking: Cannot invest now");
                
        uint256 amountIn = getTokensAvailableToInvest();
        uint256[] memory amounts = swapExactTokenForToken(PLR_TOKEN_ADDRESS,OHM_TOKEN_ADDRESS,amountIn,_deadline);
        //stake on Olympus DAO
        uint256 stakedBalance = stakeOHM(amounts[2]);
        emit Invested(amounts[2], stakedBalance);
        totalInvested = totalInvested.add(amountIn);
        lastInvestedTimestamp = block.timestamp;
    }

    function buyBack(uint256 _deadline) override external onlyOwner whenInvestable {
        require(_deadline > block.timestamp, "PLRStaking: Invalid deadline");
        require((block.timestamp - stakingStart) > 11 weeks, "PLRStaking: Too early");
        require(pillarDaoVault != address(0), "PLRStaking: DAO vault not configured.");
        require(lpVault != address(0), "PLRStaking: LP vault not configured.");
        //unstake from Olympus DAO
        uint256 stakedBalance = IERC20(STAKED_OHM_TOKEN_ADDRESS).balanceOf(address(this));
        uint256 daiBalance = IERC20(DAI_TOKEN_ADDRESS).balanceOf(address(this));
        uint256 buyBackAmt = 0;
        if(stakedBalance > 0) {
            uint256 ohmBalance = unstakeOHM(stakedBalance);
            //if OHM balance is > 0 swap OHM for PLR
            if(ohmBalance > 0) {
                uint256[] memory amounts = swapExactTokenForToken(OHM_TOKEN_ADDRESS, PLR_TOKEN_ADDRESS, ohmBalance,_deadline);
                buyBackAmt = amounts[2];
            }
        }
        //If DAI balance is > 0 then swap DAI for PLR
        if(daiBalance > 0) {
            uint256[] memory amounts = swapExactTokenForToken(DAI_TOKEN_ADDRESS, PLR_TOKEN_ADDRESS, daiBalance,_deadline);
            buyBackAmt = buyBackAmt.add(amounts[2]);
        }

        if(buyBackAmt > totalInvested) {
            _rewardsEarned = buyBackAmt.sub(totalInvested);
            if(_rewardsEarned < MINIMUM_GUARANTEED_REWARDS) {
                _rewardsEarned = MINIMUM_GUARANTEED_REWARDS; 
            } else {
                uint256 extra = _rewardsEarned.sub(MINIMUM_GUARANTEED_REWARDS);
                extra = extra.div(3);

                //transfer 1/3 of the earnings to lpVault
                TransferHelper.safeTransferFrom(address(stakingToken),address(this),lpVault,extra);
                ILPRewards(lpVault).notifyRewardAmount(extra);
                //transfer 1/3 to the DAO vault
                TransferHelper.safeTransferFrom(address(stakingToken),address(this),pillarDaoVault,extra);
            }
        } else {
            _rewardsEarned = MINIMUM_GUARANTEED_REWARDS;
        }
        emit BuyBack(buyBackAmt,_rewardsEarned);
    }

    function hedgeToStable(uint256 _deadline) override external whenInvestable onlyOwner {
        require(_deadline > block.timestamp, "PLRStaking: Invalid deadline");
        uint256 stakedBalance = IERC20(STAKED_OHM_TOKEN_ADDRESS).balanceOf(address(this));
        if(stakedBalance > 0) {
            uint256 ohmBalance = unstakeOHM(stakedBalance);
            if(ohmBalance > 0) {
                uint256[] memory amounts = swapExactTokenForToken(OHM_TOKEN_ADDRESS,DAI_TOKEN_ADDRESS,ohmBalance,_deadline);
                emit Hedged(amounts[2]);
            }            
        }
    }

    /* ======= Internal functions ======= */

    function getTokensAvailableToInvest() internal view returns (uint256) {
        uint256 plrBalance = totalStaked;
        uint256 amountAvailable = plrBalance.mul(MAX_INVESTMENT_PERCENT).div(100);
        amountAvailable = amountAvailable.sub(totalInvested);
        if(amountAvailable > maxWeeklyInvest) {
            amountAvailable = maxWeeklyInvest;
        }

        return amountAvailable;
    }

    function unstakeOHM(uint256 _balance) internal returns ( uint256 ) {
        uint256 amount = 0;
        if(_balance > 0) {
            IOlympus(OHM_STAKING_ADDRESS).unstake(_balance,false);
            amount = IERC20(OHM_TOKEN_ADDRESS).balanceOf(address(this));
        }
        return amount;
    }

    function stakeOHM(uint256 _amount) internal returns ( uint256 ) {
        require(_amount > 0, "PLRStaking: Cannot stake 0");
        IERC20 token = IERC20(OHM_TOKEN_ADDRESS);
        if(token.allowance(address(this),OHM_STAKING_ADDRESS) < _amount) {
            token.safeIncreaseAllowance(OHM_STAKING_ADDRESS,_amount);
        }
        IOlympus(OHM_STAKING_ADDRESS).stake(_amount,address(this));
        return IERC20(STAKED_OHM_TOKEN_ADDRESS).balanceOf(address(this));
    }

    function swapExactTokenForToken(address _from, address _to, uint256 _amount,uint256 _deadline) internal returns ( uint256[] memory ) {
        require(ROUTER_CONTRACT_ADDRESS != address(0), "PLRStaking: Invalid Router Address");
        require(_amount > 0, "PLRStaking: Invalid Amount");
        require(_from != address(0), "PLRStaking: Invalid Token Address");
        require(_to != address(0), "PLRStaking: Invalid Token Address");

        IUniswapV2Router02 router = IUniswapV2Router02(ROUTER_CONTRACT_ADDRESS);
        
        IERC20 token = IERC20(_from);
        if(token.allowance(address(this),ROUTER_CONTRACT_ADDRESS) < _amount) {
            token.safeIncreaseAllowance(ROUTER_CONTRACT_ADDRESS,_amount);
        }

        address[] memory path = new address[](3);
        path[0] = _from;
        path[1] = router.WETH();
        path[2] = _to;

        return router.swapExactTokensForTokens(
            _amount,
            0, // amountOutMin: we can skip computing this number because the math is tested
            path,
            address(this),
            _deadline
        );
    }

    function withdraw(uint256 _amount) internal  {
        require(_amount > 0, "PLRStaking: Cannot withdraw 0");
        IERC20 token = IERC20(stakingToken);
        require(token.balanceOf(address(this)) >= _amount,"PLRStaking: Not enough balance");
        _balances[msg.sender] = 0;
        TransferHelper.safeTransferFrom(address(stakingToken),address(this),msg.sender,_amount);
        emit Withdrawn(msg.sender, _amount);
    }
    /* ========== EVENTS ========== */

    event RewardAdded(uint256 _reward);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event Recovered(address _token, uint256 _amount);
    
    /* ====== Fallback functions ======== */
    receive() external payable {
    }
}