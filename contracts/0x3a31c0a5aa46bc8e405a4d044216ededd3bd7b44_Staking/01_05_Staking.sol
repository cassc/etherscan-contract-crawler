// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract Staking is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router public uniswapRouter;
    IERC20 public token;
    uint256 public stakingDuration = 15 days;
    uint256 public withdrawalCooldown = 1 days; // Cooldown period for Ethereum withdrawals
    uint256 public dailyWithdrawalLimitPercentage = 2; // 2% daily withdrawal limit;
    address public penaltyWallet;

    mapping(address => uint256) public stakes;
    mapping(address => uint256) public ethValueOfStakes;
    mapping(address => uint256) public lastDepositTime;
    mapping(address => uint256) public lastETHWithdrawTime;
    mapping(address => uint256) public totalETHWithdrawn;

    event rewardWithdrawn(address indexed _user ,uint256 _amount, uint256 _claimDays);
    event tokensStaked(address indexed _user ,uint256 _amount);
    event tokensUnstaked(address indexed _user ,uint256 _amount);
    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier onlyToken() {
        assert(msg.sender == address(token));
        _;
	}

    constructor() {
        uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function updateStakingDuration(uint256 _duration) external onlyOwner {
        stakingDuration = _duration;
    }

    function updateWithdrawalCooldown(uint256 _cooldown) external onlyOwner {
        withdrawalCooldown = _cooldown;
    }

    function setDailyWithdrawalLimit(uint256 _percentage) external onlyOwner {
        require(_percentage <= 20, "Percentage must be less than 20%");
        dailyWithdrawalLimitPercentage = _percentage;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid address");
        token = IERC20(_tokenAddress);
        penaltyWallet = _tokenAddress;
    }

    function stakeTokens(address _user, uint _amount) external onlyToken {
        require(_amount > 0, "Amount must be greater than 0");

        uint256 ethValue = calculateTokenValueInETH(_amount);

        // Update user's stake and ethValueOfStakes
        stakes[_user] = stakes[_user].add(_amount);
        ethValueOfStakes[_user] = ethValueOfStakes[_user].add(ethValue);

        // Update last withdrawal time
        lastDepositTime[_user] = block.timestamp;        
        emit tokensStaked(_user,_amount);
        
        if (lastETHWithdrawTime[_user] == 0){
            lastETHWithdrawTime[_user] = block.timestamp;
        }
    }

    function calculateTokenValueInETH(uint256 _amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = uniswapRouter.WETH();

        uint256[] memory amounts = uniswapRouter.getAmountsOut(_amount, path);
        return amounts[1];
    }

    function calculateDailyWithdrawalLimit(address _user) internal view returns (uint256 total, uint256 daysSinceLastWithdrawal) {
        uint256 ethValue = ethValueOfStakes[_user];
        daysSinceLastWithdrawal = (block.timestamp.sub(lastETHWithdrawTime[_user])).div(withdrawalCooldown);
        uint256 dailyLimit = ethValue.mul(dailyWithdrawalLimitPercentage).div(100);
        total = dailyLimit.mul(daysSinceLastWithdrawal);
    }

    function withdrawReward() external {
        require(stakes[msg.sender] > 0, "No tokens staked");

        uint256 currentTime = block.timestamp;
        require(currentTime >= lastETHWithdrawTime[msg.sender].add(withdrawalCooldown), "Cooldown period not passed");

        (uint256 dailyWithdrawalAmount, uint256 claimDays) = calculateDailyWithdrawalLimit(msg.sender);
        require(dailyWithdrawalAmount > 0, "No withdrawable amount available");

        lastETHWithdrawTime[msg.sender] = currentTime;
        totalETHWithdrawn[msg.sender] = totalETHWithdrawn[msg.sender].add(dailyWithdrawalAmount);
        payable(msg.sender).transfer(dailyWithdrawalAmount);
        emit rewardWithdrawn(msg.sender, dailyWithdrawalAmount, claimDays);
    }

    function unstakeTokens() external {
        require(stakes[msg.sender] > 0, "No tokens staked");
        uint256 withdrawTokens = 0;

        uint256 stakedAmount = stakes[msg.sender];

        if(block.timestamp <= lastDepositTime[msg.sender].add(stakingDuration)){
            uint256 penalty = stakedAmount.mul(20).div(100); // 20% penalty
            withdrawTokens = stakedAmount.sub(penalty);
            token.transfer(penaltyWallet, penalty);
        }
        else{
            withdrawTokens = stakedAmount;
        }

        stakes[msg.sender] = 0;
        ethValueOfStakes[msg.sender] = 0;
        token.transfer(msg.sender, withdrawTokens);
        emit tokensUnstaked(msg.sender, withdrawTokens);
    }

    function getUserStake(address _user) external view returns (uint256 totalStakedTokens, uint256 totalrewardwithdrawn, uint256 ethValueOfStake, uint256 remainingDays) {
        totalStakedTokens = stakes[_user];
        ethValueOfStake = ethValueOfStakes[_user];
        uint256 currentTime = block.timestamp;
        totalrewardwithdrawn = totalETHWithdrawn[_user];
        if (currentTime < lastDepositTime[_user].add(stakingDuration)) {
            remainingDays = (lastDepositTime[_user].add(stakingDuration).sub(currentTime)).div(1 days);
        } else {
            remainingDays = 0;
        }
    }

    function emergencyWithdrawERC20(IERC20 erc20) external onlyOwner {
		uint256 balanceToken = erc20.balanceOf(address(this));
		erc20.transfer(owner(), balanceToken);
	}

	function emergencyWithdrawETH() external onlyOwner {
		uint256 balanceETH = address(this).balance;
		payable(msg.sender).transfer(balanceETH);
	}
}