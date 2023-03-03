// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "./Interfaces.sol";

interface IUniswapV2Router01 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IWmx {
    function getFactAmounMint(uint256) external view returns (uint256);
}

interface IWomAsset {
    function pool() external view returns (address);
    function underlyingToken() external view returns (address);
}

interface IWomPool {
    function quotePotentialWithdraw(address _token, uint256 _liquidity) external view returns (uint256);
    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);
}

interface IBaseRewardPool4626 {
    struct RewardState {
        address token;
        uint256 periodFinish;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 currentRewards;
        uint256 historicalRewards;
        bool paused;
    }
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (RewardState memory);
    function claimableRewards(address _account)
        external view returns (address[] memory tokens, uint256[] memory amounts);
}

contract WombexLensUI {
    // STABLECOIN POOLS
    address internal constant WOM_STABLE_MAIN_POOL = 0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0;
    address internal constant WOM_STABLE_SIDE_POOL = 0x0520451B19AD0bb00eD35ef391086A692CFC74B2;
    address internal constant WOM_INNOVATION_POOL = 0x48f6A8a0158031BaF8ce3e45344518f1e69f2A14;
    address internal constant WOM_IUSD_POOL = 0x277E777F7687239B092c8845D4d2cd083a33C903;
    address internal constant WOM_CUSD_POOL = 0x4dFa92842d05a790252A7f374323b9C86D7b7E12;
    address internal constant WOM_AXLUSDC_POOL = 0x8ad47d7ab304272322513eE63665906b64a49dA2;
    address internal constant WOM_USDD_POOL = 0x05f727876d7C123B9Bb41507251E2Afd81EAD09A;

    // BNB POOLS
    address internal constant WOM_BNB_POOL = 0x0029b7e8e9eD8001c868AA09c74A1ac6269D4183;
    address internal constant WOM_BNBx_POOL = 0x8df1126de13bcfef999556899F469d64021adBae;
    address internal constant WOM_STKBNB_POOL = 0xB0219A90EF6A24a237bC038f7B7a6eAc5e01edB0;

    // OTHER POOLS
    address internal constant WOM_WMX_POOL = 0xeEB5a751E0F5231Fc21c7415c4A4c6764f67ce2e;

    // STABLE TOKENS
    address internal constant BUSD_TOKEN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address internal constant USDT_TOKEN = 0x55d398326f99059fF775485246999027B3197955;
    address internal constant USDC_TOKEN = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address internal constant DAI_TOKEN = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
    address internal constant HAY_TOKEN = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;
    address internal constant FRAX_TOKEN = 0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40;
    address internal constant TUSD_TOKEN = 0x14016E85a25aeb13065688cAFB43044C2ef86784;
    address internal constant axlUSDC_TOKEN = 0x4268B8F0B87b6Eae5d897996E6b845ddbD99Adf3;
    address internal constant CUSD_TOKEN = 0xFa4BA88Cf97e282c505BEa095297786c16070129;
    address internal constant iUSD_TOKEN = 0x0A3BB08b3a15A19b4De82F8AcFc862606FB69A2D;
    address internal constant USDD_TOKEN = 0xd17479997F34dd9156Deef8F95A52D81D265be9c;

    // OTHER UNDERLYING TOKENS
    address internal constant WOM_TOKEN = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;
    address internal constant WMX_TOKEN = 0xa75d9ca2a0a1D547409D82e1B06618EC284A2CeD;
    address internal constant WBNB_TOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant WMX_WOM_TOKEN = 0x0415023846Ff1C6016c4d9621de12b24B2402979;

    // REWARD TOKENS TOKENS
    address internal constant SD_TOKEN = 0x3BC5AC0dFdC871B365d159f728dd1B9A0B5481E8;
    address internal constant PSTAKE_TOKEN = 0x4C882ec256823eE773B25b414d36F92ef58a7c0C;
    address internal constant ANKR_TOKEN = 0xf307910A4c7bbc79691fD374889b36d8531B08e3;

    // ROUTERS
    address internal constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address internal constant APE_ROUTER = 0xcF0feBd3f17CEf5b47b0cD257aCf6025c5BFf3b7;

    struct PoolValues {
        string symbol;
        uint256 pid;
        uint256 lpTokenPrice;
        uint256 lpTokenBalance;
        uint256 tvl;
        uint256 wmxApr;
        uint256 totalApr;
        address rewardPool;
        PoolValuesTokenApr[] tokenAprs;
    }

    struct PoolValuesTokenApr {
        address token;
        uint256 apr;
    }

    struct PoolRewardRate {
        address[] rewardTokens;
        uint256[] rewardRates;
    }

    struct RewardContractData {
        uint256 balance;
        uint256 usdOut;
        address[] rewardTokens;
        uint256[] rewards;
    }

    function _isUsdStableToken(address _token) internal pure returns (bool) {
        if (_token == BUSD_TOKEN || _token == USDT_TOKEN || _token == USDC_TOKEN || _token == DAI_TOKEN ||
        _token == HAY_TOKEN || _token == FRAX_TOKEN || _token == TUSD_TOKEN || _token == axlUSDC_TOKEN ||
        _token == CUSD_TOKEN || _token == iUSD_TOKEN || _token == USDD_TOKEN) {
            return true;
        }
        return false;
    }

    function _isUsdStablePoolWithBUSD(address _womPool) internal pure returns (bool) {
        if (_womPool == WOM_STABLE_MAIN_POOL || _womPool == WOM_STABLE_SIDE_POOL || _womPool == WOM_INNOVATION_POOL ||
        _womPool == WOM_AXLUSDC_POOL || _womPool == WOM_IUSD_POOL) {
            return true;
        }
        return false;
    }

    function _isUsdStablePool(address _womPool) internal pure returns (bool) {
        if (_isUsdStablePoolWithBUSD(_womPool) || _womPool == WOM_USDD_POOL || _womPool == WOM_CUSD_POOL) {
            return true;
        }
        return false;
    }

    function getRewardRates(
        IBooster _booster
    ) public view returns(PoolRewardRate[] memory result, uint256 mintRatio) {
        uint256 len = _booster.poolLength();

        result = new PoolRewardRate[](len);
        mintRatio = _booster.mintRatio();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            IBaseRewardPool4626 crvRewards = IBaseRewardPool4626(poolInfo.crvRewards);
            address[] memory rewardTokens = crvRewards.rewardTokensList();
            uint256[] memory rewardRates = new uint256[](rewardTokens.length);
            for (uint256 j = 0; j < rewardTokens.length; j++) {
                address token = rewardTokens[j];
                rewardRates[j] = crvRewards.tokenRewards(token).rewardRate;
            }
            result[i].rewardTokens = rewardTokens;
            result[i].rewardRates = rewardRates;
        }
    }

    function getApys1(
        IBooster _booster
    ) public view returns(PoolValues[] memory) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();
        PoolValues[] memory result = new PoolValues[](len);
        uint256 wmxUsdPrice = estimateInBUSD(WMX_TOKEN, 1 ether);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            IBaseRewardPool4626 crvRewards = IBaseRewardPool4626(poolInfo.crvRewards);
            address pool = IWomAsset(poolInfo.lptoken).pool();

            PoolValues memory pValues;

            pValues.pid = i;
            pValues.symbol = ERC20(poolInfo.lptoken).symbol();
            pValues.rewardPool = poolInfo.crvRewards;

            // 1. Calculate Tvl
            pValues.lpTokenPrice = getLpUsdOut(pool, 1 ether);
            pValues.lpTokenBalance = ERC20(poolInfo.crvRewards).totalSupply();
            pValues.tvl = pValues.lpTokenBalance * pValues.lpTokenPrice / 1 ether;

            // 2. Calculate APYs
            if (pValues.tvl > 10) {
                _setApys(crvRewards, wmxUsdPrice, mintRatio, pValues.tvl, pValues);
            }

            result[i] = pValues;
        }

        return result;
    }

    function _setApys(IBaseRewardPool4626 crvRewards, uint256 wmxUsdPrice, uint256 mintRatio, uint256 poolTvl, PoolValues memory pValues) internal view {
        address[] memory rewardTokens = crvRewards.rewardTokensList();
        uint256 len = rewardTokens.length;
        PoolValuesTokenApr[] memory aprs = new PoolValuesTokenApr[](len);
        uint256 aprTotal;
        uint256 wmxApr;

        for (uint256 i = 0; i < len; i++) {
            address token = rewardTokens[i];
            IBaseRewardPool4626.RewardState memory rewardState = crvRewards.tokenRewards(token);

            if (token == WOM_TOKEN) {
                uint256 factAmountMint = IWmx(WMX_TOKEN).getFactAmounMint(rewardState.rewardRate * 365 days);
                uint256 wmxRate = factAmountMint;
                if (mintRatio > 0) {
                    wmxRate = factAmountMint * mintRatio / 10_000;
                }

                wmxApr = wmxRate * wmxUsdPrice * 100 / poolTvl / 1e16;
            }

            uint256 usdPrice = estimateInBUSD(token, 1 ether);
            uint256 apr = rewardState.rewardRate * 365 days * usdPrice * 100 / poolTvl / 1e16;
            aprTotal += apr;

            aprs[i].token = token;
            aprs[i].apr = apr;
        }

        aprTotal += wmxApr;

        pValues.tokenAprs = aprs;
        pValues.totalApr = aprTotal;
        pValues.wmxApr = wmxApr;
    }

    function getLpUsdOut(
        address _womPool,
        uint256 _lpTokenAmountIn
    ) public view returns (uint256) {
        if (_isUsdStablePoolWithBUSD(_womPool)) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, BUSD_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_WMX_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, WOM_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_CUSD_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, HAY_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_USDD_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, USDC_TOKEN, _lpTokenAmountIn);
        } else if (_womPool == WOM_BNBx_POOL || _womPool == WOM_STKBNB_POOL) {
            return _quotePotentialWithdrawalTokenToBUSD(_womPool, WBNB_TOKEN, _lpTokenAmountIn);
        } else {
            revert("unsupported pool");
        }
    }

    function _quotePotentialWithdrawalTokenToBUSD(address _womPool, address _tokenOut, uint256 _lpTokenAmountIn) internal view returns (uint256) {
        try IWomPool(_womPool).quotePotentialWithdraw(_tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut) {
            return estimateInBUSD(_tokenOut, tokenAmountOut);
        } catch {
        }
        return 0;
    }

    // Estimates a token equivalent in USD (BUSD) using a Uniswap-compatible router
    function estimateInBUSD(address _token, uint256 _amountIn) public view returns (uint256) {
        // 1. All the USD stable tokens are roughly estimated as $1.
        if (_isUsdStableToken(_token)) {
            return _amountIn;
        }

        address router = PANCAKE_ROUTER;
        bool throughBnb = false;

        if (_token == SD_TOKEN) {
            router = APE_ROUTER;
        }
        if (_token == ANKR_TOKEN) {
            throughBnb = true;
        }

        address[] memory path;
        if (throughBnb) {
            path = new address[](3);
            path[0] = _token;
            path[1] = WBNB_TOKEN;
            path[2] = BUSD_TOKEN;
        } else {
            path = new address[](2);
            path[0] = _token;
            path[1] = BUSD_TOKEN;
        }
        uint256[] memory amountsOut = IUniswapV2Router01(router).getAmountsOut(_amountIn, path);
        return amountsOut[amountsOut.length - 1];
    }

    /*** USER DETAILS ***/

    function getUserBalancesDefault(
        IBooster _booster,
        address _user
    ) public view returns(
        uint256[] memory lpTokenBalances,
        uint256[] memory underlyingBalances,
        uint256[] memory usdOuts,
        address[][] memory rewardTokens,
        uint256[][] memory earnedRewardsUSD,
        RewardContractData memory wmxWom,
        RewardContractData memory locker
    ) {
        (lpTokenBalances, underlyingBalances, usdOuts, rewardTokens, earnedRewardsUSD) = getUserBalances(
            _booster, _user, allBoosterPoolIds(_booster)
        );
        wmxWom = getUserWmxWom(IBooster(_booster).crvLockRewards(), _user);
        locker = getUserLocker(IBooster(_booster).cvxLocker(), _user);
    }

    function allBoosterPoolIds(IBooster _booster) public view returns (uint256[] memory) {
        uint256 len = _booster.poolLength();
        uint256[] memory poolIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            poolIds[i] = i;
        }
        return poolIds;
    }

    function getUserWmxWom(
        address _crvLockRewards,
        address _user
    ) public view returns (RewardContractData memory data) {
        (address[] memory wmxWomRewardTokens, , uint256[] memory wmxWomRewardsUSD) = getUserPendingRewards(_crvLockRewards, _user);
        data = RewardContractData(ERC20(_crvLockRewards).balanceOf(_user), 0, wmxWomRewardTokens, wmxWomRewardsUSD);
        if (data.balance > 0) {
            (uint256 womAmountOut,) = IWomPool(WOM_WMX_POOL)
                .quotePotentialSwap(WMX_WOM_TOKEN, WOM_TOKEN, int256(data.balance));

            if (womAmountOut > 0) {
                address[] memory path = new address[](2);

                path[0] = WOM_TOKEN;
                path[1] = BUSD_TOKEN;
                uint256[] memory amountsOut = IUniswapV2Router01(PANCAKE_ROUTER).getAmountsOut(womAmountOut, path);
                data.usdOut = amountsOut[1];
            }
        }
    }

    function getUserLocker(
        address _locker,
        address _user
    ) public view returns (RewardContractData memory data) {
        (address[] memory rewardTokens, , uint256[] memory rewardsUSD) = getUserLockerPendingRewards(_locker, _user);
        (uint256 balance, , , ) = IWmxLocker(_locker).lockedBalances(_user);
        data = RewardContractData(balance, 0, rewardTokens, rewardsUSD);
        if (data.balance > 0) {
            address[] memory path = new address[](2);
            path[0] = WMX_TOKEN;
            path[1] = BUSD_TOKEN;
            uint256[] memory amountsOut = IUniswapV2Router01(PANCAKE_ROUTER).getAmountsOut(data.balance, path);
            data.usdOut = amountsOut[1];
        }
    }

    function getUserBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public view returns(
        uint256[] memory lpTokenBalances,
        uint256[] memory underlyingBalances,
        uint256[] memory usdOuts,
        address[][] memory rewardTokens,
        uint256[][] memory earnedRewardsUSD
    ) {
        uint256 len = _poolIds.length;
        lpTokenBalances = new uint256[](len);
        underlyingBalances = new uint256[](len);
        usdOuts = new uint256[](len);
        rewardTokens = new address[][](len);
        earnedRewardsUSD = new uint256[][](len);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(_poolIds[i]);

            // 1. Earned rewards
            (rewardTokens[i],,earnedRewardsUSD[i]) = getUserPendingRewards(poolInfo.crvRewards, _user);

            // 2. LP token balance
            uint256 womLpTokenBalance = ERC20(poolInfo.crvRewards).balanceOf(_user);
            lpTokenBalances[i] = womLpTokenBalance;
            if (womLpTokenBalance == 0) {
                continue;
            }

            // 3. Underlying balance
            address womPool = IWomAsset(poolInfo.lptoken).pool();
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();
            try IWomPool(womPool).quotePotentialWithdraw(underlyingToken, womLpTokenBalance) returns (uint256 underlyingBalance) {
                underlyingBalances[i] = underlyingBalance;

                // 4. Usd outs
                if (_isUsdStablePool(womPool)) {
                    usdOuts[i] = underlyingBalance;
                } else {
                    usdOuts[i] = getLpUsdOut(womPool, womLpTokenBalance);
                }
            } catch {}
        }
    }

    function getUserPendingRewards(address _rewardsPool, address _user)
        public view returns (
            address[] memory rewardTokens,
            uint256[] memory earnedRewards,
            uint256[] memory earnedRewardsUSD
    ) {
        (rewardTokens, earnedRewards) = IBaseRewardPool4626(_rewardsPool)
            .claimableRewards(_user);

        earnedRewardsUSD = new uint256[](rewardTokens.length);
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            if (earnedRewards[i] > 0) {
                earnedRewardsUSD[i] = estimateInBUSD(rewardTokens[i], earnedRewards[i]);
            }
        }
    }

    function getUserLockerPendingRewards(address _locker, address _user) public view
        returns (
            address[] memory rewardTokens,
            uint256[] memory earnedRewards,
            uint256[] memory earnedRewardsUSD
        )
    {
        IWmxLocker.EarnedData[] memory userRewards = IWmxLocker(_locker).claimableRewards(_user);

        rewardTokens = new address[](userRewards.length);
        earnedRewards = new uint256[](userRewards.length);
        earnedRewardsUSD = new uint256[](userRewards.length);
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            rewardTokens[i] = userRewards[i].token;
            earnedRewards[i] = userRewards[i].amount;
            if (earnedRewards[i] > 0) {
                earnedRewardsUSD[i] = estimateInBUSD(rewardTokens[i], earnedRewards[i]);
            }
        }
    }

    function getWomLpBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public view returns(uint256[] memory balances) {
        uint256 len = _poolIds.length;
        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            balances[i] = ERC20(poolInfo.crvRewards).balanceOf(_user);
        }
    }

    /*** ESTIMATIONS ***/

    function quoteUnderlyingAmountOut(
        address _lpToken,
        uint256 _lpTokenAmountIn
    ) public view returns(uint256) {
        address pool = IWomAsset(_lpToken).pool();
        address underlyingToken = IWomAsset(_lpToken).underlyingToken();
        return IWomPool(pool).quotePotentialWithdraw(underlyingToken, _lpTokenAmountIn);
    }
}