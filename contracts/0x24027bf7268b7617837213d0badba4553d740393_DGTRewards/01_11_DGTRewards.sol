// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./dMath.sol";
import "./oracle/libraries/FullMath.sol";

import "./interfaces/VatLike.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/PipLike.sol";

/*
   "Distribute Dgt Tokens to Borrowers".
   Borrowers of Davos token against collaterals are incentivized 
   to get Dgt Tokens.
*/

contract DGTRewards is IRewards, Initializable {
    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Rewards/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "Rewards/not-live"); wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1, "Rewards/not-authorized"); _; }

    // --- State Vars/Constants ---
    uint256 constant YEAR = 31556952; //seconds in year (365.2425 * 24 * 3600)
    uint256 constant RAY = 10 ** 27;  

    struct Ilk {
        uint256 rewardRate;  // Collateral, per-second reward rate [ray]
        uint256 rho;         // Pool init time
        bytes32 ilk;
    }
    struct Pile {
        uint256 amount;
        uint256 ts;
    }

    uint256 public live;

    mapping (address => mapping(address => Pile)) public piles;  // usr > collateral > Pile
    mapping (address => uint256) public claimedRewards;
    mapping (address => Ilk) public pools;
    address[] public poolsList;

    VatLike public vat;
    address public dgtToken;
    PipLike public oracle;

    uint256 public rewardsPool;  // <Unused>
    uint256 public poolLimit;
    uint256 public maxPools;

    // --- Modifiers ---
    modifier poolInit(address token) {
        require(pools[token].rho != 0, "Reward/pool-not-init");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_, uint256 poolLimit_, uint256 maxPools_) external initializer {
        live = 1;
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        poolLimit = poolLimit_;
        maxPools = maxPools_;
    }

    // --- Admin ---
    function initPool(address token, bytes32 ilk, uint256 rate) external auth {
        require(IERC20Upgradeable(dgtToken).balanceOf(address(this)) >= poolLimit, "Reward/not-enough-reward-token");
        require(pools[token].rho == 0, "Reward/pool-existed");
        require(token != address(0), "Reward/invalid-token");
        pools[token] = Ilk(rate, block.timestamp, ilk);
        poolsList.push(token);
        require(poolsList.length <= maxPools, "Reward/maxPools-exceeded");

        emit PoolInited(token, rate);
    }
    function setDgtToken(address dgtToken_) external auth {
        require(dgtToken_ != address(0), "Reward/invalid-token");
        dgtToken = dgtToken_;

        emit DgtTokenChanged(dgtToken);
    }
    function setRewardsMaxLimit(uint256 newLimit) external auth {
        require(IERC20Upgradeable(dgtToken).balanceOf(address(this)) >= newLimit, "Reward/not-enough-reward-token");
        poolLimit = newLimit;

        emit RewardsLimitChanged(poolLimit);
    }
    function setOracle(address oracle_) external auth {
        require(oracle_ != address(0), "Reward/invalid-oracle");
        oracle = PipLike(oracle_);

        emit DgtOracleChanged(address(oracle));
    }
    function setRate(address token, uint256 newRate) external auth {
        require(pools[token].rho == 0, "Reward/pool-existed");
        require(token != address(0), "Reward/invalid-token");
        require(newRate >= RAY, "Reward/negative-rate");
        require(newRate < 2 * RAY, "Reward/high-rate");
        Ilk storage pool = pools[token];
        pool.rewardRate = newRate;

        emit RateChanged(token, newRate);
    }
    function setMaxPools(uint256 newMaxPools) external auth {
        require(newMaxPools != 0, "Reward/invalid-maxPool");
        maxPools = newMaxPools;
    }

    // --- View ---
    function dgtPrice() public view returns(uint256) {
        // 1 DAVOS is dgtPrice() dgts
        (bytes32 price, bool has) = oracle.peek();
        if (has) {
            return uint256(price);
        } else {
            return 0;
        }
    }
    function rewardsRate(address token) public view returns(uint256) {
        return pools[token].rewardRate;
    }
    function distributionApy(address token) public view returns(uint256) {
        // Yearly api in percents with 18 decimals
        return (dMath.rpow(pools[token].rewardRate, YEAR, RAY) - RAY) / 10 ** 7;
    }
    function pendingRewards(address usr) public view returns(uint256) {
        uint256 i = 0;
        uint256 acc = 0;
        while (i < poolsList.length) {
            acc += claimable(poolsList[i], usr);
            i++;
        }
        return acc - claimedRewards[usr];
    }
    function claimable(address token, address usr) public poolInit(token) view returns (uint256) {
        return piles[usr][token].amount + unrealisedRewards(token, usr);
    }
    function unrealisedRewards(address token, address usr) public poolInit(token) view returns(uint256) {
        if (pools[token].rho == 0) {
            // No pool for this token
            return 0;
        }
        bytes32 poolIlk = pools[token].ilk;
        (, uint256 art) = vat.urns(poolIlk, usr);
        uint256 last = piles[usr][token].ts;
        if (last == 0) {
            return 0;
        }
        uint256 rate = dMath.rpow(pools[token].rewardRate, block.timestamp - last, RAY);
        uint256 rewards = FullMath.mulDiv(rate, art, 10 ** 27) - art;                     // $ amount
        return FullMath.mulDiv(rewards, dgtPrice(), 10 ** 18);                           // Dgt Tokens
    }

    // --- Externals ---
    function drop(address token, address usr) public {
        if (pools[token].rho == 0) {
            // No pool for this token
            return;
        }
        Pile storage pile = piles[usr][token];

        pile.amount += unrealisedRewards(token, usr);
        pile.ts = block.timestamp;
    }
    function claim(uint256 amount) external {
        require(amount <= pendingRewards(msg.sender), "Rewards/not-enough-rewards");
        require(poolLimit >= amount, "Rewards/rewards-limit-exceeded");
        uint256 i = 0;
        while (i < poolsList.length) {
            drop(poolsList[i], msg.sender);
            i++;
        }
        claimedRewards[msg.sender] += amount;
        poolLimit -= amount;
        
        IERC20Upgradeable(dgtToken).safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    // --- Locks ---
    function cage() public auth {
        live = 0;
        emit Cage(msg.sender);
    }
    function uncage() public auth {
        live = 1;
        emit Uncage(msg.sender);
    }
}