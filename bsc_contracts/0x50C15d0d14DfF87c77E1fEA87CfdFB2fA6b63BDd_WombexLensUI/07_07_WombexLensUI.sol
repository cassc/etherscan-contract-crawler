// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
import "./Interfaces.sol";

interface IUniswapV2Router01 {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface FraxRouter {
    function getAmountsOutWithTwamm(uint amountIn, address[] memory path) external returns (uint[] memory amounts);
}

interface QuoterV2 {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
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
    function getTokens() external view returns (address[] memory);
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
    function asset() external view returns (address);
    function rewardTokensList() external view returns (address[] memory);
    function tokenRewards(address _token) external view returns (RewardState memory);
    function claimableRewards(address _account)
        external view returns (address[] memory tokens, uint256[] memory amounts);
}

contract WombexLensUI is Ownable {
    address public UNISWAP_ROUTER;
    address public UNISWAP_V3_QUOTER;

    address public MAIN_STABLE_TOKEN;
    uint8 public MAIN_STABLE_TOKEN_DECIMALS;

    address public WOM_TOKEN;
    address public WMX_TOKEN;
    address public WMX_MINTER;
    address public WETH_TOKEN;
    address public WMX_WOM_TOKEN;

    address public WOM_WMX_POOL;

    mapping(address => bool) public isUsdStableToken;
    mapping(address => address) public poolToToken;
    mapping(address => address) public tokenToRouter;
    mapping(address => bool) public tokenUniV3;
    mapping(address => address) public tokenSwapThroughToken;
    mapping(address => address) public tokenSwapToTargetStable;

    struct PoolValues {
        string symbol;
        uint256 pid;
        uint256 lpTokenPrice;
        uint256 lpTokenBalance;
        uint256 tvl;
        uint256 wmxApr;
        uint256 itemApr;
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
        address poolAddress;
        uint128 lpBalance;
        uint128 underlyingBalance;
        uint128 usdBalance;
        uint8 decimals;
        RewardItem[] rewards;
    }

    struct RewardItem {
        address rewardToken;
        uint128 amount;
        uint128 usdAmount;
        uint8 decimals;
    }

    constructor(
        address _UNISWAP_ROUTER,
        address _UNISWAP_V3_ROUTER,
        address _MAIN_STABLE_TOKEN,
        address _WOM_TOKEN,
        address _WMX_TOKEN,
        address _WMX_MINTER,
        address _WETH_TOKEN,
        address _WMX_WOM_TOKEN,
        address _WOM_WMX_POOL
    ) {
        UNISWAP_ROUTER = _UNISWAP_ROUTER;
        UNISWAP_V3_QUOTER = _UNISWAP_V3_ROUTER;
        MAIN_STABLE_TOKEN = _MAIN_STABLE_TOKEN;
        MAIN_STABLE_TOKEN_DECIMALS = getTokenDecimals(_MAIN_STABLE_TOKEN);
        WOM_TOKEN = _WOM_TOKEN;
        WMX_TOKEN = _WMX_TOKEN;
        WMX_MINTER = _WMX_MINTER;
        WETH_TOKEN = _WETH_TOKEN;
        WMX_WOM_TOKEN = _WMX_WOM_TOKEN;
        WOM_WMX_POOL = _WOM_WMX_POOL;
    }

    function setUsdStableTokens(address[] memory _tokens, bool _isStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            isUsdStableToken[_tokens[i]] = _isStable;
        }
    }

    function setPoolsForToken(address[] memory _pools, address _token) external onlyOwner {
        for (uint256 i = 0; i < _pools.length; i++) {
            poolToToken[_pools[i]] = _token;
        }
    }

    function setTokensToRouter(address[] memory _tokens, address _router) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenToRouter[_tokens[i]] = _router;
        }
    }

    function setTokenUniV3(address[] memory _tokens, bool _tokenUniV3) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenUniV3[_tokens[i]] = _tokenUniV3;
        }
    }

    function setTokenSwapThroughToken(address[] memory _tokens, address _throughToken) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapThroughToken[_tokens[i]] = _throughToken;
        }
    }

    function setTokensTargetStable(address[] memory _tokens, address _targetStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapToTargetStable[_tokens[i]] = _targetStable;
        }
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
    ) public returns(PoolValues[] memory) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();
        PoolValues[] memory result = new PoolValues[](len);
        uint256 wmxUsdPrice = estimateInBUSD(WMX_TOKEN, 1 ether, uint8(18));

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
                (pValues.tokenAprs, pValues.totalApr, pValues.itemApr, pValues.wmxApr) = getRewardPoolApys(crvRewards, pValues.tvl, wmxUsdPrice, mintRatio);
            }

            result[i] = pValues;
        }

        return result;
    }

    function getRewardPoolApys(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(
        PoolValuesTokenApr[] memory aprs,
        uint256 aprTotal,
        uint256 aprItem,
        uint256 wmxApr
    ) {
        address[] memory rewardTokens = crvRewards.rewardTokensList();
        uint256 len = rewardTokens.length;
        aprs = new PoolValuesTokenApr[](len);

        for (uint256 i = 0; i < len; i++) {
            address token = rewardTokens[i];
            IBaseRewardPool4626.RewardState memory rewardState = crvRewards.tokenRewards(token);

            if (token == WOM_TOKEN) {
                uint256 factAmountMint = IWmx(WMX_MINTER).getFactAmounMint(rewardState.rewardRate * 365 days);
                uint256 wmxRate = factAmountMint;
                if (mintRatio > 0) {
                    wmxRate = factAmountMint * mintRatio / 10_000;
                }

                wmxApr = wmxRate * wmxUsdPrice * 100 / poolTvl / 1e16;
            }

            uint256 usdPrice = estimateInBUSD(token, 1 ether, getTokenDecimals(token));
            uint256 apr = rewardState.rewardRate * 365 days * usdPrice * 100 / poolTvl / 1e16;
            aprTotal += apr;
            aprItem += rewardState.rewardRate * 365 days * usdPrice / 1e16;

            aprs[i].token = token;
            aprs[i].apr = apr;
        }

        aprTotal += wmxApr;
    }

    function getRewardPoolTotalApr(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(uint256 aprItem, uint256 aprTotal) {
        (, aprTotal, aprItem, ) = getRewardPoolApys(crvRewards, poolTvl, wmxUsdPrice, mintRatio);
    }

    function getRewardPoolTotalApr128(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(uint128 aprItem128, uint128 aprTotal128) {
        (uint256 aprItem, uint256 aprTotal) = getRewardPoolTotalApr(crvRewards, poolTvl, wmxUsdPrice, mintRatio);
        aprTotal128 = uint128(aprTotal);
        aprItem128 = uint128(aprItem);
    }

    function getBribeApys(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(
        PoolValuesTokenApr[] memory aprs,
        uint256 aprItem,
        uint256 aprTotal
    ) {
        (, , , , , , address bribe) = bribesVoter.infos(lpToken);
        if (bribe == address(0)) {
            return (new PoolValuesTokenApr[](0), 0, 0);
        }
        (, uint128 voteWeight) = bribesVoter.weights(lpToken);
        uint256 userVotes = bribesVoter.getUserVotes(voterProxy, lpToken);
        if (userVotes == 0) {
            userVotes = 1 ether;
        }
        IERC20[] memory rewardTokens = IBribe(bribe).rewardTokens();
        aprs = new PoolValuesTokenApr[](rewardTokens.length);

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            aprs[i].token = address(rewardTokens[i]);

            (, uint96 tokenPerSec, , ) = IBribe(bribe).rewardInfo(i);
            uint256 usdPerSec = estimateInBUSD(aprs[i].token, tokenPerSec, getTokenDecimals(aprs[i].token));
            if (voteWeight / poolTvl > 0) {
                aprs[i].apr = usdPerSec * 365 days * 10e3 / (voteWeight * allPoolsTvl / veWomBalance);
                // 365 * 24 * 60 * 60 * rewardInfo.tokenPerSec * tokenUsdcPrice * userVotes / weight / (rewardPoolTotalSupply * wmxPrice) * 100,
                aprItem += usdPerSec * 365 days * userVotes * 100 / voteWeight;
            }
            aprTotal += aprs[i].apr;
        }
    }

    function getBribeTotalApr(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(uint256 aprItem, uint256 aprTotal) {
        (, aprItem, aprTotal) = getBribeApys(voterProxy, bribesVoter, lpToken, poolTvl, allPoolsTvl, veWomBalance);
    }

    function getBribeTotalApr128(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(uint128 aprItem128, uint128 aprTotal128) {
        (uint256 aprItem, uint256 aprTotal) = getBribeTotalApr(voterProxy, bribesVoter, lpToken, poolTvl, allPoolsTvl, veWomBalance);
        aprItem128 = uint128(aprItem);
        aprTotal128 = uint128(aprTotal);
    }

    function getTvl(IBooster _booster) public returns(uint256 tvlSum) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            address pool = IWomAsset(poolInfo.lptoken).pool();
            tvlSum += ERC20(poolInfo.crvRewards).totalSupply() * getLpUsdOut(pool, 1 ether) / 1 ether;
        }
        address voterProxy = _booster.voterProxy();
        tvlSum += estimateInBUSD(WOM_TOKEN, ERC20(IStaker(voterProxy).veWom()).balanceOf(voterProxy), 18);
        tvlSum += estimateInBUSD(WMX_TOKEN, ERC20(WMX_TOKEN).balanceOf(_booster.cvxLocker()), 18);
    }

    function getTotalRevenue(IBooster _booster, address[] memory _oldCrvRewards, uint256 _revenueRatio) public returns(uint256 totalRevenueSum, uint256 totalWomSum) {
        uint256 mintRatio = _booster.mintRatio();
        uint256 len = _booster.poolLength();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(i);
            (uint256 revenueSum, uint256 womSum) = getPoolRewardsInUsd(poolInfo.crvRewards);
            totalRevenueSum += revenueSum;
            totalWomSum += womSum;
        }
        for (uint256 i = 0; i < _oldCrvRewards.length; i++) {
            (uint256 revenueSum, uint256 womSum) = getPoolRewardsInUsd(_oldCrvRewards[i]);
            totalRevenueSum += revenueSum;
            totalWomSum += womSum;
        }
        (uint256 revenueSum, uint256 womSum) = getPoolRewardsInUsd(_booster.crvLockRewards());
        totalRevenueSum += revenueSum;
        totalWomSum += womSum;

        totalRevenueSum += totalRevenueSum * _revenueRatio / 1 ether; // due to locker inaccessible rewards
        totalWomSum += totalWomSum * _revenueRatio / 1 ether; // due to locker inaccessible rewards
    }

    function getPoolRewardsInUsd(address _crvRewards) public returns(uint256 revenueSum, uint256 womSum) {
        address[] memory rewardTokensList = IBaseRewardPool4626(_crvRewards).rewardTokensList();

        for (uint256 j = 0; j < rewardTokensList.length; j++) {
            address t = rewardTokensList[j];
            IBaseRewardPool4626.RewardState memory tRewards = IBaseRewardPool4626(_crvRewards).tokenRewards(t);
            revenueSum += estimateInBUSD(t, tRewards.historicalRewards + tRewards.queuedRewards, getTokenDecimals(t));
            if (t == WOM_TOKEN || t == WMX_WOM_TOKEN) {
                womSum += tRewards.historicalRewards + tRewards.queuedRewards;
            }
        }
    }

    function getProtocolStats(IBooster _booster, address[] memory _oldCrvRewards, uint256 _revenueRatio) public returns(uint256 tvl, uint256 totalRevenue, uint256 earnedWomSum, uint256 veWomShare) {
        tvl = getTvl(_booster);
        (totalRevenue, earnedWomSum) = getTotalRevenue(_booster, _oldCrvRewards, _revenueRatio);
        address voterProxy = _booster.voterProxy();
        ERC20 veWom = ERC20(IStaker(voterProxy).veWom());
        veWomShare = (veWom.balanceOf(voterProxy) * 1 ether) / veWom.totalSupply();
    }

    function getTokenToWithdrawFromPool(address _womPool) public view returns (address tokenOut) {
        tokenOut = poolToToken[_womPool];
        if (tokenOut == address(0)) {
            address[] memory tokens = IWomPool(_womPool).getTokens();
            for (uint256 i = 0; i < tokens.length; i++) {
                if (isUsdStableToken[tokens[i]]) {
                    tokenOut = tokens[i];
                    break;
                }
            }
            if (tokenOut == address(0)) {
                address[] memory tokens = IWomPool(_womPool).getTokens();
                for (uint256 i = 0; i < tokens.length; i++) {
                    if (tokens[i] == WOM_TOKEN || tokens[i] == WMX_TOKEN || tokens[i] == WETH_TOKEN) {
                        tokenOut = tokens[i];
                        break;
                    }
                }
            }
        }
    }

    function getLpUsdOut(
        address _womPool,
        uint256 _lpTokenAmountIn
    ) public returns (uint256 result) {
        address tokenOut = getTokenToWithdrawFromPool(_womPool);
        if (tokenOut == address(0)) {
            revert("stable not found for pool");
        }
        return quotePotentialWithdrawalTokenToBUSD(_womPool, tokenOut, _lpTokenAmountIn);
    }

    function quotePotentialWithdrawalTokenToBUSD(address _womPool, address _tokenOut, uint256 _lpTokenAmountIn) public returns (uint256) {
        try IWomPool(_womPool).quotePotentialWithdraw(_tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut) {
            uint8 decimals = getTokenDecimals(_tokenOut);
            uint256 result = estimateInBUSD(_tokenOut, tokenAmountOut, decimals);
            result *= 10 ** (18 - decimals);
            return result;
        } catch {
        }
        return 0;
    }

    function wmxWomToWom(uint256 wmxWomAmount) public view returns (uint256 womAmount) {
        if (wmxWomAmount == 0) {
            return 0;
        }
        try IWomPool(WOM_WMX_POOL).quotePotentialSwap(WMX_WOM_TOKEN, WOM_TOKEN, int256(1 ether)) returns (uint256 potentialOutcome, uint256 haircut) {
            womAmount = potentialOutcome * wmxWomAmount / 1 ether;
        } catch {
            womAmount = wmxWomAmount;
        }
    }

    // Estimates a token equivalent in USD (BUSD) using a Uniswap-compatible router
    function estimateInBUSD(address _token, uint256 _amountIn, uint256 _decimals) public returns (uint256 result) {
        if (_amountIn == 0) {
            return 0;
        }
        // 1. All the USD stable tokens are roughly estimated as $1.
        if (isUsdStableToken[_token]) {
            return _amountIn;
        }

        address router = UNISWAP_ROUTER;

        if (tokenToRouter[_token] != address(0)) {
            router = tokenToRouter[_token];
        }
        if (_token == WMX_WOM_TOKEN) {
            _amountIn = wmxWomToWom(_amountIn);
            _token = WOM_TOKEN;
        }

        address targetStable = MAIN_STABLE_TOKEN;
        uint8 targetStableDecimals = MAIN_STABLE_TOKEN_DECIMALS;
        if (tokenSwapToTargetStable[_token] != address(0)) {
            targetStable = tokenSwapToTargetStable[_token];
            targetStableDecimals = getTokenDecimals(targetStable);
        }

        address[] memory path;
        address throughToken = tokenSwapThroughToken[_token];
        if (throughToken != address(0)) {
            path = new address[](3);
            path[0] = _token;
            path[1] = throughToken;
            path[2] = targetStable;
        } else {
            path = new address[](2);
            path[0] = _token;
            path[1] = targetStable;
        }

        uint256 oneUnit = 10 ** _decimals;
        _amountIn = _amountIn * 10 ** (_decimals - targetStableDecimals);
        if (router == 0xCAAaB0A72f781B92bA63Af27477aA46aB8F653E7) { // frax router
            try FraxRouter(router).getAmountsOutWithTwamm(oneUnit, path) returns (uint256[] memory amountsOut) {
                result = _amountIn * amountsOut[amountsOut.length - 1] / oneUnit;
            } catch {
            }
        } else if (tokenUniV3[_token]) {
            QuoterV2.QuoteExactInputSingleParams memory params = QuoterV2.QuoteExactInputSingleParams(_token, targetStable, oneUnit, 3000, 0);
            try QuoterV2(UNISWAP_V3_QUOTER).quoteExactInputSingle(params) returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate) {
                result = _amountIn * amountOut / oneUnit;
            } catch {
            }
        } else {
            try IUniswapV2Router01(router).getAmountsOut(oneUnit, path) returns (uint256[] memory amountsOut) {
                result = _amountIn * amountsOut[amountsOut.length - 1] / oneUnit;
            } catch {
            }
        }
    }

    /*** USER DETAILS ***/

    function getUserBalancesDefault(
        IBooster _booster,
        address _user
    ) public returns(
        RewardContractData[] memory pools,
        RewardContractData memory wmxWom,
        RewardContractData memory locker
    ) {
        pools = getUserBalances(_booster, _user, allBoosterPoolIds(_booster));
        wmxWom = getUserWmxWom(_booster, _booster.crvLockRewards(), _user);
        locker = getUserLocker(_booster.cvxLocker(), _user);
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
        IBooster _booster,
        address _crvLockRewards,
        address _user
    ) public returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserPendingRewards(_booster.mintRatio(), _crvLockRewards, _user);
        uint256 wmxWomBalance = ERC20(_crvLockRewards).balanceOf(_user);
        data = RewardContractData(_crvLockRewards, uint128(wmxWomBalance), uint128(wmxWomToWom(wmxWomBalance)), uint128(0), uint8(18), rewards);
        data.usdBalance = uint128(estimateInBUSD(WMX_WOM_TOKEN, data.underlyingBalance, uint8(18)));
    }

    function getUserLocker(
        address _locker,
        address _user
    ) public returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserLockerPendingRewards(_locker, _user);
        (uint256 balance, , , ) = IWmxLocker(_locker).lockedBalances(_user);
        data = RewardContractData(_locker, uint128(balance), uint128(balance), uint128(0), uint8(18), rewards);
        data.usdBalance = uint128(estimateInBUSD(WMX_TOKEN, data.underlyingBalance, uint8(18)));
    }

    function getUserBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public returns(RewardContractData[] memory rewardContractData) {
        uint256 len = _poolIds.length;
        rewardContractData = new RewardContractData[](len);
        uint256 mintRatio = _booster.mintRatio();

        for (uint256 i = 0; i < len; i++) {
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(_poolIds[i]);

            // 1. Earned rewards
            RewardItem[] memory rewardTokens = getUserPendingRewards(
                getPoolMintRatio(_booster, _poolIds[i], mintRatio),
                poolInfo.crvRewards,
                _user
            );

            // 2. LP token balance
            uint256 lpTokenBalance = ERC20(poolInfo.crvRewards).balanceOf(_user);

            // 3. Underlying balance
            address womPool = IWomAsset(poolInfo.lptoken).pool();
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();

            rewardContractData[i] = RewardContractData(poolInfo.crvRewards, uint128(lpTokenBalance), uint128(0), uint128(0), getTokenDecimals(underlyingToken), rewardTokens);

            try IWomPool(womPool).quotePotentialWithdraw(underlyingToken, lpTokenBalance) returns (uint256 underlyingBalance) {
                rewardContractData[i].underlyingBalance = uint128(underlyingBalance);

                // 4. Usd outs
                if (isUsdStableToken[underlyingToken]) {
                    uint8 decimals = getTokenDecimals(underlyingToken);
                    underlyingBalance *= 10 ** (18 - decimals);
                    rewardContractData[i].usdBalance = uint128(underlyingBalance);
                } else {
                    rewardContractData[i].usdBalance = uint128(getLpUsdOut(womPool, lpTokenBalance));
                }
            } catch {}
        }
    }

    function getPoolMintRatio(IBooster _booster, uint256 pid, uint256 defaultMintRatio) public view returns (uint256 resMintRatio) {
        resMintRatio = defaultMintRatio;
        try _booster.customMintRatio(pid) returns (uint256 _customMintRatio) {
            resMintRatio = _customMintRatio == 0 ? defaultMintRatio : _customMintRatio;
        } catch {
        }
    }

    function getTokenDecimals(address _token) public view returns (uint8 decimals) {
        try ERC20(_token).decimals() returns (uint8 _decimals) {
            decimals = _decimals;
        } catch {
            decimals = uint8(18);
        }
    }

    function getUserPendingRewards(uint256 mintRatio, address _rewardsPool, address _user) public
        returns (RewardItem[] memory rewards)
    {
        (address[] memory rewardTokens, uint256[] memory earnedRewards) = IBaseRewardPool4626(_rewardsPool)
            .claimableRewards(_user);

        uint256 len = rewardTokens.length;
        rewards = new RewardItem[](len + 1);
        uint256 earnedWom;
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            if (rewardTokens[i] == WOM_TOKEN) {
                earnedWom = earnedRewards[i];
            }
            uint8 decimals = getTokenDecimals(rewardTokens[i]);
            rewards[i] = RewardItem(
                rewardTokens[i],
                uint128(earnedRewards[i]),
                uint128(estimateInBUSD(rewardTokens[i], earnedRewards[i], decimals)),
                decimals
            );
        }
        if (earnedWom > 0) {
            uint256 earned = ITokenMinter(WMX_MINTER).getFactAmounMint(earnedWom);
            earned = mintRatio > 0 ? earned * mintRatio / 10000 : earned;
            rewards[len] = RewardItem(WMX_TOKEN, uint128(earned), uint128(estimateInBUSD(WMX_TOKEN, earned, uint8(18))), uint8(18));
        }
    }

    function getUserLockerPendingRewards(address _locker, address _user) public
        returns (RewardItem[] memory rewards)
    {
        IWmxLocker.EarnedData[] memory userRewards = IWmxLocker(_locker).claimableRewards(_user);

        rewards = new RewardItem[](userRewards.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            uint8 decimals = getTokenDecimals(userRewards[i].token);
            rewards[i] = RewardItem(
                userRewards[i].token,
                uint128(userRewards[i].amount),
                uint128(estimateInBUSD(userRewards[i].token, userRewards[i].amount, decimals)),
                decimals
            );
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