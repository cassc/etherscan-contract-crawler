// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Staking is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_DENOMINATOR = 100;
    uint256 public constant HARVEST_PERIOD = 2592000;
    uint256 public constant PRECISION_FACTOR = 1000000000000000000000000;

    IUniswapV2Router01 public immutable ROUTER;
    IERC20 public immutable DKUMA;
    IERC20 public immutable USDC;

    address[] public PATH;

    uint256 public poolEndTime;
    uint256 public rewardPerSecond;
    uint256 public totalStaked;
    uint256 public accTokenPerShare;
    uint256 public lastActionTime;
    uint256 public leftovers;

    mapping (address => UserInfo) public stakeInfo;

    struct UserInfo {
        uint256 amount;
        uint256 enteredAt;
        uint256 rewardTaken;
        uint256 rewardTakenActual;
        uint256 bag;
    }

    constructor(IUniswapV2Router01 _router, address _dkuma, address _usdc) {
        IUniswapV2Factory factory = IUniswapV2Factory(_router.factory());
        require(factory.getPair(_dkuma, _router.WETH()) != address(0) && factory.getPair(_router.WETH(), _usdc) != address(0), "Cannot find pairs");
        ROUTER = _router;
        DKUMA = IERC20(_dkuma);
        USDC = IERC20(_usdc);
        PATH.push(_dkuma);
        PATH.push(_router.WETH());
        PATH.push(_usdc);
    }

    function pendingReward(address account) external view returns(uint256) {
        UserInfo storage stake = stakeInfo[account];
        if (stake.amount > 0) {
            uint256 rightBound;
            if (block.timestamp > poolEndTime) {
                rightBound = poolEndTime;
            }
            else {
                rightBound = block.timestamp;
            }
            uint256 adjustedTokenPerShare = accTokenPerShare;
            if (rightBound > lastActionTime) {
                adjustedTokenPerShare += (((rightBound - lastActionTime) * rewardPerSecond) * PRECISION_FACTOR) / totalStaked;
            }
            return ((stake.amount * adjustedTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
        }
        return 0;
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake zero");
        UserInfo storage stake = stakeInfo[_msgSender()];
        _updatePool();
        DKUMA.safeTransferFrom(_msgSender(), address(this), amount);
        amount = _takeFee(amount, 3);
        require(amount > 0, "Too low amount to deposit");
        uint256 reward = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
        if (reward > 0) {
            stake.bag += reward;
        }
        totalStaked += amount;
        stake.amount += amount;
        stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
        if (stake.enteredAt == 0) {
            stake.enteredAt = block.timestamp;
        }
    }

    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot unstake zero");
        UserInfo storage stake = stakeInfo[_msgSender()];
        require(stake.amount >= amount, "Cannot withdraw this much");
        _updatePool();
        uint256 reward = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken;
        stake.bag += reward;
        totalStaked -= amount;
        stake.amount -= amount;
        stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
        amount = _takeFee(amount, 5);
        require(amount > 0, "Too low amount to withdraw");
        DKUMA.safeTransfer(_msgSender(), amount);
        if (stake.amount == 0) {
            stake.rewardTakenActual += stake.bag;
            if (stake.bag > USDC.balanceOf(address(this))) {
                USDC.safeTransfer(_msgSender(), USDC.balanceOf(address(this)));
            }
            else {
                USDC.safeTransfer(_msgSender(), stake.bag);
            }
            stake.bag = 0;
            stake.enteredAt = 0;
        }
    }

    function harvest() external nonReentrant {
        UserInfo storage stake = stakeInfo[_msgSender()];
        require(stake.enteredAt > 0 && stake.enteredAt + HARVEST_PERIOD <= block.timestamp, "Cannot harvest yet");
        stake.enteredAt = block.timestamp;
        _updatePool();
        uint256 toTransfer = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR) - stake.rewardTaken + stake.bag;
        stake.bag = 0;
        stake.rewardTaken = ((stake.amount * accTokenPerShare) / PRECISION_FACTOR);
        stake.rewardTakenActual += toTransfer;
        if (toTransfer > USDC.balanceOf(address(this)) - leftovers) {
            USDC.safeTransfer(_msgSender(), USDC.balanceOf(address(this)));
        }
        else {
            USDC.safeTransfer(_msgSender(), toTransfer);
        }
    }

    function extend(uint256 _endTime, bool swapDkuma) external onlyOwner {
        require(_endTime > poolEndTime && _endTime > block.timestamp, "Invalid end time");
        _updatePool();
        uint256 amount = USDC.balanceOf(address(this));
        if (swapDkuma) {
            DKUMA.safeTransferFrom(_msgSender(), address(this), DKUMA.balanceOf(_msgSender()));
            uint256 swapAmount = DKUMA.balanceOf(address(this)) - totalStaked;
            DKUMA.safeApprove(address(ROUTER), swapAmount);
            ROUTER.swapExactTokensForTokens(swapAmount, 0, PATH, address(this), block.timestamp);
        }
        USDC.safeTransferFrom(_msgSender(), address(this), USDC.balanceOf(_msgSender()));
        if (poolEndTime == 0) {
            lastActionTime = block.timestamp;
        }
        else if (block.timestamp < poolEndTime) {
            leftovers += (poolEndTime - block.timestamp) * rewardPerSecond;
        }
        amount = (USDC.balanceOf(address(this)) - amount) + leftovers;
        poolEndTime = _endTime;
        rewardPerSecond = amount / (_endTime - block.timestamp);
        require(rewardPerSecond > 0, "Reward per second too low");
        leftovers = amount % (_endTime - block.timestamp);
    }

    function extractInvalidToken(IERC20 token) external onlyOwner {
        require(token != DKUMA && token != USDC, "Cannot extract DKUMA or USDC");
        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_msgSender()).transfer(address(this).balance);
        }
        else {
            token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
        }
    }

    function _updatePool() private {
        if (block.timestamp <= lastActionTime || poolEndTime == 0) {
            return;
        }
        if (totalStaked == 0) {
            lastActionTime = block.timestamp;
            return;
        }
        uint256 rightBound;
        if (block.timestamp > poolEndTime) {
            rightBound = poolEndTime;
        }
        else {
            rightBound = block.timestamp;
        }
        if (rightBound > lastActionTime) {
            uint256 reward = ((rightBound - lastActionTime) * rewardPerSecond);
            accTokenPerShare += (reward * PRECISION_FACTOR) / totalStaked;
        }
        lastActionTime = block.timestamp;
    }

    function _takeFee(uint256 amount, uint256 fee) private returns(uint256) {
        uint256 toReturn = (amount * (FEE_DENOMINATOR - fee)) / FEE_DENOMINATOR;
        DKUMA.safeTransfer(owner(), amount - toReturn);
        return toReturn;
    }
}