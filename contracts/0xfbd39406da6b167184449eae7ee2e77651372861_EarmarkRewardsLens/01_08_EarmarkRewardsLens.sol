// SPDX-License-Identifier: MITrewardTokens
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "./Interfaces.sol";
import "./WombexLensUI.sol";

contract EarmarkRewardsLens {
    uint256 public constant MAX_UINT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 public constant DENOMINATOR = 10000;

    IStaker public voterProxy;
    WombexLensUI public wombexLensUI;
    IBooster public booster;
    IBoosterEarmark public boosterEarmark;
    address public crv;
    uint256 public maxPidsToExecute;

    struct PendingReward {
        address token;
        string symbol;
        uint8 decimals;
        uint256 totalAmount;
        uint256 earmarkAmount;
        uint256 usdPrice;
    }

    struct Pool {
        address lpToken;
        string symbol;
        uint256 pid;
    }

    constructor(IStaker _voterProxy, WombexLensUI _wombexLensUI, uint256 _maxPidsToExecute) {
        voterProxy = _voterProxy;
        wombexLensUI = _wombexLensUI;
        maxPidsToExecute = _maxPidsToExecute;
        updateBooster();
    }

    function updateBooster() public {
        booster = IBooster(voterProxy.operator());
        boosterEarmark = IBoosterEarmark(booster.earmarkDelegate());
        crv = booster.crv();
    }

    function getRewards() public view returns(
        address[] memory tokens,
        string[] memory tokensSymbols,
        uint256[] memory boosterPendingRewards,
        uint256[] memory wombatPendingRewards,
        uint256[] memory availableBalances,
        int256[] memory diffBalances
    ) {
        tokens = boosterEarmark.distributionTokenList();
        tokensSymbols = new string[](tokens.length);
        boosterPendingRewards = new uint256[](tokens.length);
        wombatPendingRewards = new uint256[](tokens.length);
        availableBalances = new uint256[](tokens.length);
        diffBalances = new int256[](tokens.length);

        uint256 poolLen = booster.poolLength();

        for (uint256 i = 0; i < tokens.length; i++) {
            try ERC20(tokens[i]).symbol() returns (string memory symbol) {
                tokensSymbols[i] = symbol;
            } catch {

            }
            for (uint256 j = 0; j < poolLen; j++) {
                IBooster.PoolInfo memory poolInfo = booster.poolInfo(j);
                boosterPendingRewards[i] += booster.lpPendingRewards(poolInfo.lptoken, tokens[i]);

                uint256 wmPid = voterProxy.lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
                (
                    uint256 pendingRewards,
                    IERC20[] memory bonusTokenAddresses,
                    ,
                    uint256[] memory pendingBonusRewards
                ) = IMasterWombatV2(poolInfo.gauge).pendingTokens(wmPid, address(voterProxy));

                if (tokens[i] == crv) {
                    wombatPendingRewards[i] += pendingRewards;
                }

                for (uint256 k = 0; k < bonusTokenAddresses.length; k++) {
                    if (address(bonusTokenAddresses[k]) == tokens[i]) {
                        wombatPendingRewards[i] += pendingBonusRewards[k];
                    }
                }
            }
            availableBalances[i] = IERC20(tokens[i]).balanceOf(address(booster)) + IERC20(tokens[i]).balanceOf(address(voterProxy));

            diffBalances[i] = int256(wombatPendingRewards[i]) + int256(availableBalances[i]) - int256(boosterPendingRewards[i]);
        }
    }

    function getEarmarkablePools() public view returns(bool[] memory earmarkablePools, uint256 poolsCount) {
        uint256 earmarkPeriod = boosterEarmark.earmarkPeriod();
        uint256 poolLen = booster.poolLength();
        earmarkablePools = new bool[](poolLen);

        for (uint256 i = 0; i < poolLen; i++) {
            IBooster.PoolInfo memory p = booster.poolInfo(i);
            if (p.shutdown || !boosterEarmark.isEarmarkPoolAvailable(i, p)) {
                continue;
            }
            earmarkablePools[i] = poolRewardsAvailableByPoolOn(i, p, earmarkPeriod) < block.timestamp;
            if (earmarkablePools[i]) {
                poolsCount++;
            }
        }
    }

    function isPoolRewardsAvailable(uint256 _pid) public view returns(bool) {
        return poolRewardsAvailableByPoolOn(_pid, booster.poolInfo(_pid), boosterEarmark.earmarkPeriod()) < block.timestamp;
    }

    function poolRewardsAvailableByPoolOn(uint256 _pid, IBooster.PoolInfo memory _p, uint256 _earmarkPeriod) public view returns (uint256) {
        (address token , uint256 periodFinish, , , , , , , bool paused) = IRewards(_p.crvRewards).tokenRewards(crv);
//        if (token == crv && periodFinish < block.timestamp && IERC20(crv).balanceOf(p.crvRewards) > 1000 ether) {
//            return true;
//        }

        (uint256 pendingRewards, IERC20[] memory bonusTokenAddresses, , uint256[] memory pendingBonusRewards) = IMasterWombatV2(_p.gauge).pendingTokens(
            voterProxy.lpTokenToPid(_p.gauge, _p.lptoken),
            address(voterProxy)
        );
        uint256 nextEarmarkOn = boosterEarmark.lastEarmarkAt(_pid) + _earmarkPeriod;
        bool readyToExecute = nextEarmarkOn < block.timestamp;
        if (pendingRewards != 0 && !paused) {
            return periodFinish > nextEarmarkOn ? nextEarmarkOn : periodFinish;
        }
        for (uint256 i = 0; i < pendingBonusRewards.length; i++) {
            ( , periodFinish, , , , , , , paused) = IRewards(_p.crvRewards).tokenRewards(address(bonusTokenAddresses[i]));
            if (pendingBonusRewards[i] != 0 && !paused) {
                return periodFinish > nextEarmarkOn ? nextEarmarkOn : periodFinish;
            }
        }
        return MAX_UINT;
    }

    function getPidsToEarmark(bool _useMaxPidsCount) public view returns(uint256[] memory pids) {
        (bool[] memory earmarkablePools, uint256 poolsCount) = getEarmarkablePools();
        if (_useMaxPidsCount) {
            poolsCount = poolsCount > maxPidsToExecute ? maxPidsToExecute : poolsCount;
        }
        pids = new uint256[](poolsCount);
        uint256 curIndex = 0;
        for (uint256 i = 0; i < earmarkablePools.length; i++) {
            if (earmarkablePools[i]) {
                pids[curIndex] = i;
                curIndex++;
                if (_useMaxPidsCount && curIndex == maxPidsToExecute) {
                    break;
                }
            }
        }
    }

    function earmarkResolver() public view returns(bool execute, bytes memory data) {
        uint256[] memory pidsToExecute = getPidsToEarmark(true);
        return (
            pidsToExecute.length > 0,
            abi.encodeWithSelector(IBoosterEarmark.earmarkRewards.selector, pidsToExecute)
        );
    }

    function getPoolsQueue() public view returns(uint256[] memory pidsNextExecuteOn) {
        uint256 earmarkPeriod = boosterEarmark.earmarkPeriod();
        uint256 poolLen = booster.poolLength();
        pidsNextExecuteOn = new uint256[](poolLen);
        for (uint256 i = 0; i < poolLen; i++) {
            pidsNextExecuteOn[i] = poolRewardsAvailableByPoolOn(i, booster.poolInfo(i), earmarkPeriod);
        }
    }

    function getPoolPendingRewards(uint256 _pid) public returns(uint256 earmarkIncentive, uint256 executeOn, PendingReward[] memory rewards) {
        executeOn = boosterEarmark.getEarmarkPoolExecuteOn(_pid);
        earmarkIncentive = IBoosterEarmark(booster.earmarkDelegate()).earmarkIncentive();
        IBooster.PoolInfo memory poolInfo = booster.poolInfo(_pid);

        uint256 crvIndex = MAX_UINT;
        uint256 womPendingRewards;
        IERC20[] memory bonusTokenAddresses;
        uint256[] memory pendingBonusRewards;
        {
            uint256 wmPid = voterProxy.lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
            (womPendingRewards, bonusTokenAddresses, , pendingBonusRewards) = IMasterWombatV2(poolInfo.gauge).pendingTokens(wmPid, address(voterProxy));
        }

        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            if (address(bonusTokenAddresses[i]) == crv) {
                crvIndex = i;
                pendingBonusRewards[i] += womPendingRewards;
            }
        }

        rewards = new PendingReward[](crvIndex == MAX_UINT ? bonusTokenAddresses.length + 1 : bonusTokenAddresses.length);
        uint256 curIndex = 0;
        {
            uint256 womPrice = wombexLensUI.estimateInBUSDEther(crv, 1 ether, 18);
            if (crvIndex == MAX_UINT) {
                uint256 rewardsAmount = womPendingRewards + booster.lpPendingRewards(poolInfo.lptoken, crv);
                rewards[curIndex] = PendingReward(crv, "WOM", uint8(18), womPendingRewards, womPendingRewards * earmarkIncentive / DENOMINATOR, womPrice);
                curIndex++;
            }
        }

        for (uint256 i = 0; i < bonusTokenAddresses.length; i++) {
            string memory symbol;
            try ERC20(address(bonusTokenAddresses[i])).symbol() returns (string memory _symbol) {
                symbol = _symbol;
            } catch { }

            uint256 rewardsAmount = pendingBonusRewards[i] + booster.lpPendingRewards(poolInfo.lptoken, address(bonusTokenAddresses[i]));
            uint8 decimals = getTokenDecimals(address(bonusTokenAddresses[i]));
            rewards[curIndex] = PendingReward(
                address(bonusTokenAddresses[i]),
                symbol,
                decimals,
                rewardsAmount,
                rewardsAmount * earmarkIncentive / DENOMINATOR,
                wombexLensUI.estimateInBUSDEther(address(bonusTokenAddresses[i]), 10 ** decimals, decimals)
            );
            curIndex++;
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8 decimals) {
        try ERC20(_token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
        } catch {
            decimals = uint8(18);
        }
    }

    function getRewardsToExecute() public returns (uint256 earmarkIncentive, PendingReward[] memory rewards, Pool[] memory pools) {
        earmarkIncentive = IBoosterEarmark(booster.earmarkDelegate()).earmarkIncentive();

        address[] memory tokens = boosterEarmark.distributionTokenList();
        rewards = new PendingReward[](tokens.length);

        uint256[] memory pidsToExecute = getPidsToEarmark(true);
        pools = new Pool[](pidsToExecute.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            rewards[i].token = tokens[i];
            try ERC20(tokens[i]).symbol() returns (string memory _symbol) {
                rewards[i].symbol = _symbol;
            } catch { }
            for (uint256 j = 0; j < pidsToExecute.length; j++) {
                IBooster.PoolInfo memory poolInfo = booster.poolInfo(pidsToExecute[j]);
                if (i == 0) {
                    pools[j].lpToken = poolInfo.lptoken;
                    pools[j].pid = pidsToExecute[j];
                    try ERC20(pools[j].lpToken).symbol() returns (string memory _symbol) {
                        pools[j].symbol = _symbol;
                    } catch { }
                }

                uint256 wmPid = voterProxy.lpTokenToPid(poolInfo.gauge, poolInfo.lptoken);
                (
                    uint256 pendingRewards,
                    IERC20[] memory bonusTokenAddresses,
                    ,
                    uint256[] memory pendingBonusRewards
                ) = IMasterWombatV2(poolInfo.gauge).pendingTokens(wmPid, address(voterProxy));

                if (tokens[i] == crv) {
                    rewards[i].totalAmount += pendingRewards;
                }

                for (uint256 k = 0; k < bonusTokenAddresses.length; k++) {
                    if (address(bonusTokenAddresses[k]) == tokens[i]) {
                        rewards[i].totalAmount += pendingBonusRewards[k];
                    }
                }
            }
            rewards[i].earmarkAmount = rewards[i].totalAmount * earmarkIncentive / DENOMINATOR;
            rewards[i].decimals = getTokenDecimals(tokens[i]);
            rewards[i].usdPrice = wombexLensUI.estimateInBUSDEther(tokens[i], 10 ** rewards[i].decimals, rewards[i].decimals);
        }
    }
}