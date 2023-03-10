// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract TAILSHIBARIUM is ERC20 {
    using SafeMath for uint256;
    using SafeMath for uint8;

    ISwapRouter constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    address public shareReceiver;
    address public executor;
    uint256 public shareThreshold;
    uint256 public treasuryShare = 2;
    uint256 public shareTokens;

    mapping(address => bool) public lpPool;

    uint256 public totalStaked;
    uint256 public totalClaimed;

    bool public stakingEnabled = false;

    struct Pool {
        uint8 id;
        uint8 apr;
        uint256 lock;
        uint256 volume;
        uint256 staked;
        uint256 claimed;
    }

    struct Staker {
        address staker;
        uint256 start;
        uint256 unlock;
        uint256 staked;
        uint256 compounded;
        uint256 earned;
    }

    mapping(uint8 => Pool) public pools;

    mapping(address => mapping(uint8  => Staker)) public stakers;

    event Stake(address indexed staker, uint8 pool, uint256 amount);
    event Claim(address indexed staker, uint256 amount);
    event PoolCreated(uint8 id);


    modifier onlyTreasury() {
        require(shareReceiver == _msgSender(), "Caller is not the shareReceiver.");
        _;
    }

    modifier isStakingEnabled() {
        require(stakingEnabled, "Staking is currently not enabled.");
        _;
    }
    
    modifier poolExists(uint8 pool) {
        require(pools[pool].apr != 0, "This pool does not exist.");
        _;
    }

    constructor(address execAddr) ERC20("TAIL SHIBARIUM", "TAIL") {
        uint256 totalSupply = 69696969 * 1e18;

        shareThreshold = totalSupply.mul(75).div(10000);
        shareReceiver = _msgSender();
        executor = execAddr;

        _mint(_msgSender(), totalSupply);
    }

    /**
    * @dev Update wallet that receives swapped share
    */
    function setShareReceiver(address receiver) external onlyTreasury {
        shareReceiver = receiver;
    }

    /**
    * @dev Update executor wallet
    */
    function setExecutor(address addr) external onlyTreasury {
        executor = addr;
    }

    /**
    * @dev Updates the threshold of how many tokens that must be in the contract calculation for share to be taken
    */
    function setThreshold(uint256 threshold) external onlyTreasury {
  	    require(
            threshold >= totalSupply().mul(1).div(100000) && 
            threshold <= totalSupply().mul(1).div(100), 
        "Max threshold exceeded (0.001% - 1%)");
        
  	    shareThreshold = threshold;
  	}

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (lpPool[from] || lpPool[to])
            shareTokens += amount.mul(treasuryShare).div(100);

        super._transfer(from, to, amount);
    }

    function swapShare(address tokenOut, uint24 poolFee) external returns (uint amountOut) {
        require(msg.sender == executor, "Only the executor can call this function.");

        uint256 share = shareTokens;
        require(share >= shareThreshold, "Not enough shares collceted yet.");

        if (share > shareThreshold) share = shareThreshold;

        _mint(address(this), share);
        _approve(address(this), address(swapRouter), share);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: shareReceiver,
                deadline: block.timestamp,
                amountIn: share,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        shareTokens -= share;
        amountOut = swapRouter.exactInputSingle(params);
    }

    /**
    * @dev To enable shares on certain liquidity pools only
    */
    function setLPPool(address pool, bool state) external onlyTreasury {
        lpPool[pool] = state;
    }

    /**
    * @dev Checks if holder is staking
    */
    function isStaking(address addr, uint8 pool) public view returns (bool) {
        return stakers[addr][pool].staker == addr;
    }

    /**
    * @dev Returns how much staker is staking
    */
    function userStaked(address staker, uint8 pool) public view returns (uint256) {
        return stakers[staker][pool].staked;
    }

    function _userEarned(address staker, uint8 poolId) private view returns (uint256) {
        require(isStaking(staker, poolId), "You are not staked in this pool.");

        uint256 staked = userStaked(staker, poolId);
        staked += stakers[staker][poolId].compounded;
        
        uint256 startInSec = stakers[staker][poolId].start.div(1 seconds);
        uint256 timestampInSec = block.timestamp.div(1 seconds);
        uint256 secsStaked = timestampInSec.sub(startInSec);

        Pool memory pool = pools[poolId];
        uint256 reward = staked.mul(pool.apr).div(100);
        uint256 rewardPerSec = reward.div(365).div(24).div(60).div(60);
        uint256 earned = rewardPerSec.mul(secsStaked);

        return earned;
    }

    /**
    * @dev Returns how much staker has earned
    */
    function userEarned(address staker, uint8 pool) public view returns (uint256) {
        uint256 earned = _userEarned(staker, pool);
        uint256 previouslyEarned = stakers[msg.sender][pool].earned;

        if (previouslyEarned > 0)
            earned += previouslyEarned;

        return earned;
    }
 
    /**
    * @dev Stakes tokens in a specified pool
    */
    function stake(uint256 amount, uint8 poolId) external isStakingEnabled poolExists(poolId) {
        Pool memory pool = pools[poolId];

        if (isStaking(msg.sender, poolId)) {
            stakers[msg.sender][poolId].earned += _userEarned(msg.sender, poolId);
            stakers[msg.sender][poolId].staked += amount;
            stakers[msg.sender][poolId].start = block.timestamp;
        } else {
            stakers[msg.sender][poolId] = Staker({
                staker: msg.sender,
                start: block.timestamp,
                unlock: block.timestamp.add(pool.lock),
                staked: amount,
                compounded: 0,
                earned: 0
            });
        }

        totalStaked += amount;
        pools[poolId].staked += amount;
        transferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, poolId, amount);
    }
    
    /**
    * @dev Compounds rewards in pool
    */
    function compound(uint8 pool) external isStakingEnabled poolExists(pool) {
        require(isStaking(msg.sender, pool), "You are not staked in this pool.");

        uint256 reward = userEarned(msg.sender, pool);
        stakers[msg.sender][pool].compounded += reward;
        stakers[msg.sender][pool].earned = 0;
        stakers[msg.sender][pool].start = block.timestamp;
    }

    /**
    * @dev Claim earned tokens from pool
    */
    function claim(uint8 pool) external isStakingEnabled poolExists(pool) {
        require(isStaking(msg.sender, pool), "You are not staked in this pool.");

        uint256 reward = userEarned(msg.sender, pool);

        totalClaimed += reward;
        pools[pool].claimed += reward;

        _mint(msg.sender, reward);

        stakers[msg.sender][pool].start = block.timestamp;
        stakers[msg.sender][pool].earned = 0;
    }

    /**
    * @dev Unstakes initially staked tokens and rewards from pool
    */
    function unstake(uint8 pool) external poolExists(pool) {
        require(isStaking(msg.sender, pool), "You are not staked in this pool.");

        uint256 reward = userEarned(msg.sender, pool);
        uint256 staked = userStaked(msg.sender, pool);

        if (stakingEnabled) {
            require(block.timestamp >= stakers[msg.sender][pool].unlock, "You cannot unsake a locked position.");

            totalClaimed += reward;
            pools[pool].claimed += reward;

            _mint(msg.sender, reward);
            transfer(msg.sender, staked);
        } else {
            transfer(msg.sender, staked);
        }

        totalStaked -= staked;
        pools[pool].staked -= staked;

        delete stakers[msg.sender][pool];
    }

    function createPool(uint8 apr, uint8 lock) external onlyTreasury {
        require(pools[lock].staked == 0, "A pool of this lock time already exists and has stakes in it.");
        require(apr > 0, "You cannot make a pool with an APR of 0%");

        Pool memory pool = Pool({
            id: lock,
            apr: apr,
            lock: lock.mul(1 days),
            volume: 0,
            staked: 0,
            claimed: 0
        });

        pools[lock] = pool;

        emit PoolCreated(lock);
    }

    function updatePoolAPR(uint8 apr, uint8 pool) external onlyTreasury {
        pools[pool].apr = apr;
    }

    /**
    * @dev Enables/disables staking
    */
    function setStakingState(bool state) external onlyTreasury {
        stakingEnabled = state;
    }

    receive() external payable {}
}