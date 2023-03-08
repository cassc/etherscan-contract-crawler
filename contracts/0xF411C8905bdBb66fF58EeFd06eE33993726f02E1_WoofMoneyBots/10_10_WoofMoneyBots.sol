// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract WoofMoneyBots is Ownable {

    struct PoolTemplate {
        uint amountEth;
        uint coolDownPeriod;
    }

    PoolTemplate [] private poolTemplates;
    mapping(uint => uint) private lastRewardTimestamps;

    struct PoolStake {
        address stakeholder;
        uint poolType;
        uint amountEth;
        uint amountTokens;
        uint lastRewardTimestamp;
        uint startBlockTimestamp;
        uint rewards;
    }

    PoolStake [] public pools;
    mapping(uint => uint[]) public poolIdsByType;
    mapping(address => uint[]) public poolIdsByStakeholder;

    enum StakeStage {
        Unstaked,
        Staked,
        CoolDown
    }

    struct StakeState {
        StakeStage stage;
        uint coolDownEndTimestamp;
    }

    mapping(address => mapping(uint => StakeState)) public stakeStates;

    ERC20 public token;
    ERC20 public lpToken;

    constructor(ERC20 _token, ERC20 _lpToken) {
        token = _token;
        lpToken = _lpToken;

        addPoolTemplate(1 ether, 86400);
        addPoolTemplate(0.8 ether, 129600);
        addPoolTemplate(0.4 ether, 172800);
        addPoolTemplate(0.2 ether, 259200);
    }

    function stake(uint poolType) public payable {
        require(poolTemplates[poolType].amountEth != 0, "Wrong pool type");

        address stakeholder = msg.sender;
        uint amountEth = poolTemplates[poolType].amountEth;

        (uint tokenInPool, uint ethInPool) = getTokenReserves();
        uint tokens = (msg.value * tokenInPool) / ethInPool;

        require(msg.value >= amountEth, "Insufficient funds for this type of pool");
        require(stakeStates[stakeholder][poolType].stage != StakeStage.CoolDown);

        token.transferFrom(stakeholder, address(this), tokens);

        if (msg.value - amountEth > 0) {
            payable(stakeholder).transfer(msg.value - amountEth);
        }

        PoolStake memory pool = PoolStake({
        stakeholder : stakeholder,
        poolType : poolType,
        amountEth : amountEth,
        amountTokens : tokens,
        startBlockTimestamp : block.timestamp,
        lastRewardTimestamp : block.timestamp,
        rewards : 0
        });

        uint id = pools.length;
        poolIdsByStakeholder[stakeholder].push(id);
        poolIdsByType[poolType].push(id);
        stakeStates[stakeholder][poolType].stage = StakeStage.Staked;

        pools.push(pool);
    }

    function getStakeState(uint poolType) public view returns (StakeState memory) {
        return stakeStates[msg.sender][poolType];
    }

    function getPools() public view returns (PoolStake [] memory) {
        PoolStake [] memory stakeholderPools = new PoolStake[](poolIdsByStakeholder[msg.sender].length);
        for (uint i = 0; i < poolIdsByStakeholder[msg.sender].length; i++) {
            PoolStake memory pool = pools[poolIdsByStakeholder[msg.sender][i]];
            stakeholderPools[i] = pool;
        }
        return stakeholderPools;
    }

    function distributeReward(uint poolType) public payable onlyOwner {
        require(msg.value > 0);
        require(block.timestamp != lastRewardTimestamps[poolType]);

        uint amount = msg.value;
        uint period = block.timestamp - lastRewardTimestamps[poolType];
        uint sumPeriodStake = 0;

        for (uint i = 0; i < poolIdsByType[poolType].length; i++) {
            PoolStake memory pool = pools[poolIdsByType[poolType][i]];
            if (pool.stakeholder != address(0) && stakeStates[pool.stakeholder][poolType].stage != StakeStage.CoolDown) {
                sumPeriodStake += block.timestamp - pool.lastRewardTimestamp;
            }
        }

        for (uint i = 0; i < poolIdsByType[poolType].length; i++) {
            uint idx = poolIdsByType[poolType][i];
            if (pools[idx].stakeholder != address(0) && stakeStates[pools[idx].stakeholder][poolType].stage != StakeStage.CoolDown) {
                pools[idx].rewards += (block.timestamp - pools[idx].lastRewardTimestamp) * amount / sumPeriodStake;
                pools[idx].lastRewardTimestamp = block.timestamp;
            }
        }

        lastRewardTimestamps[poolType] = block.timestamp;
    }

    function claim(uint poolType) public {
        uint rewards = 0;
        for (uint i = 0; i < poolIdsByType[poolType].length; i++) {
            uint idx = poolIdsByType[poolType][i];
            if (pools[idx].stakeholder == msg.sender) {
                rewards += pools[idx].rewards;
                pools[idx].rewards = 0;
            }
        }
        if (rewards > 0) {
            payable(msg.sender).transfer(rewards);
        }
    }

    function unstake(uint poolType) public {
        claim(poolType);

        require(stakeStates[msg.sender][poolType].stage != StakeStage.Unstaked, "Already unstaked");
        if (stakeStates[msg.sender][poolType].stage == StakeStage.Staked) {
            stakeStates[msg.sender][poolType].stage = StakeStage.CoolDown;
            stakeStates[msg.sender][poolType].coolDownEndTimestamp = block.timestamp + poolTemplates[poolType].coolDownPeriod;
            return;
        }

        if (stakeStates[msg.sender][poolType].stage == StakeStage.CoolDown) {
            require(block.timestamp >= stakeStates[msg.sender][poolType].coolDownEndTimestamp, "Must wait for cooldown to finish");

            uint amountEth = 0;
            uint amountTokens = 0;

            for (uint i = 0; i < poolIdsByType[poolType].length; i++) {
                if (pools[poolIdsByType[poolType][i]].stakeholder == msg.sender) {
                    amountEth += pools[poolIdsByType[poolType][i]].amountEth;
                    amountTokens += pools[poolIdsByType[poolType][i]].amountTokens;

                    delete pools[poolIdsByType[poolType][i]];
                }
            }

            if (amountEth > 0) {
                payable(msg.sender).transfer(amountEth);
            }

            if (amountTokens > 0) {
                token.transfer(msg.sender, amountTokens);
            }

            stakeStates[msg.sender][poolType].stage = StakeStage.Unstaked;
            stakeStates[msg.sender][poolType].coolDownEndTimestamp = 0;
        }
    }

    function getTokenReserves() internal view returns (uint256, uint256) {
        IERC20Metadata token0 = IERC20Metadata(IUniswapV2Pair(address(lpToken)).token0());
        IERC20Metadata token1 = IERC20Metadata(IUniswapV2Pair(address(lpToken)).token1());
        (uint112 Res0, uint112 Res1,) = IUniswapV2Pair(address(lpToken)).getReserves();
        return (uint256(Res0), uint256(Res1));
    }

    function getPoolTemplates() public view returns (PoolTemplate[] memory) {
        PoolTemplate [] memory templates = new PoolTemplate[](poolTemplates.length);
        for (uint i = 0; i < poolTemplates.length; i++) {
            templates[i] = poolTemplates[i];
        }
        return templates;
    }

    function addPoolTemplate(uint amountEth, uint coolDownPeriod) public onlyOwner {
        lastRewardTimestamps[poolTemplates.length] = block.timestamp;

        poolTemplates.push(PoolTemplate({
        amountEth : amountEth,
        coolDownPeriod : coolDownPeriod
        }));
    }

    function editPoolTemplate(uint idx, uint amountEth, uint coolDownPeriod) public onlyOwner {
        poolTemplates[idx].amountEth = amountEth;
        poolTemplates[idx].coolDownPeriod = coolDownPeriod;
    }

    function setToken(ERC20 _token) public onlyOwner {
        token = _token;
    }

    function setLpToken(ERC20 _lpToken) public onlyOwner {
        lpToken = _lpToken;
    }

}