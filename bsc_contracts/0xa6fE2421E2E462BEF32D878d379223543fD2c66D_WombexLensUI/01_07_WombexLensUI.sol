// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts-0.8/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-0.8/access/Ownable.sol";
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

contract WombexLensUI is Ownable {
    // STABLECOIN POOLS
    address internal constant WOM_CUSD_POOL = 0x4dFa92842d05a790252A7f374323b9C86D7b7E12;
    address internal constant WOM_USDD_POOL = 0x05f727876d7C123B9Bb41507251E2Afd81EAD09A;

    // BNB POOLS
    address internal constant WOM_BNBx_POOL = 0x8df1126de13bcfef999556899F469d64021adBae;
    address internal constant WOM_STKBNB_POOL = 0xB0219A90EF6A24a237bC038f7B7a6eAc5e01edB0;

    // OTHER POOLS
    address internal constant WOM_WMX_POOL = 0xeEB5a751E0F5231Fc21c7415c4A4c6764f67ce2e;

    // STABLE TOKENS
    address internal constant BUSD_TOKEN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address internal constant USDC_TOKEN = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address internal constant HAY_TOKEN = 0x0782b6d8c4551B9760e74c0545a9bCD90bdc41E5;

    // OTHER UNDERLYING TOKENS
    address internal constant WOM_TOKEN = 0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1;
    address internal constant WMX_TOKEN = 0xa75d9ca2a0a1D547409D82e1B06618EC284A2CeD;
    address internal constant WBNB_TOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant WMX_WOM_TOKEN = 0x0415023846Ff1C6016c4d9621de12b24B2402979;

    // ROUTERS
    address internal constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    mapping(address => bool) public isUsdStableToken;
    mapping(address => address) public stablePoolToStableToken;
    mapping(address => address) public tokenToRouter;
    mapping(address => bool) public tokenSwapThroughBnb;

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
        address poolAddress;
        uint256 lpBalance;
        uint256 underlyingBalance;
        uint256 usdBalance;
        RewardItem[] rewards;
    }

    struct RewardItem {
        address rewardToken;
        uint256 amount;
        uint256 usdAmount;
    }

    function setUsdStableTokens(address[] memory _tokens, bool _isStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            isUsdStableToken[_tokens[i]] = _isStable;
        }
    }

    function setUsdStablePoolsForToken(address[] memory _pools, address _token) external onlyOwner {
        for (uint256 i = 0; i < _pools.length; i++) {
            stablePoolToStableToken[_pools[i]] = _token;
        }
    }

    function setTokensToRouter(address[] memory _tokens, address _router) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenToRouter[_tokens[i]] = _router;
        }
    }

    function setTokenSwapThroughBnb(address[] memory _tokens, bool _throughBnb) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapThroughBnb[_tokens[i]] = _throughBnb;
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
        if (stablePoolToStableToken[_womPool] == BUSD_TOKEN) {
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

    function wmxWomToWom(uint256 wmxWomAmount) public view returns (uint256 womAmount) {
        if (wmxWomAmount == 0) {
            return 0;
        }
        (womAmount, ) = IWomPool(WOM_WMX_POOL).quotePotentialSwap(WMX_WOM_TOKEN, WOM_TOKEN, int256(wmxWomAmount));
    }

    // Estimates a token equivalent in USD (BUSD) using a Uniswap-compatible router
    function estimateInBUSD(address _token, uint256 _amountIn) public view returns (uint256 result) {
        if (_amountIn == 0) {
            return 0;
        }
        // 1. All the USD stable tokens are roughly estimated as $1.
        if (isUsdStableToken[_token]) {
            return _amountIn;
        }

        address router = PANCAKE_ROUTER;
        bool throughBnb = tokenSwapThroughBnb[_token];

        if (tokenToRouter[_token] != address(0)) {
            router = tokenToRouter[_token];
        }
        if (_token == WMX_WOM_TOKEN) {
            _amountIn = wmxWomToWom(_amountIn);
            _token = WOM_TOKEN;
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

        try IUniswapV2Router01(router).getAmountsOut(_amountIn, path) returns (uint256[] memory amountsOut) {
            result = amountsOut[amountsOut.length - 1];
        } catch {
        }
    }

    /*** USER DETAILS ***/

    function getUserBalancesDefault(
        IBooster _booster,
        address _user
    ) public view returns(
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
    ) public view returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserPendingRewards(_booster.mintRatio(), _crvLockRewards, _user);
        uint256 wmxWomBalance = ERC20(_crvLockRewards).balanceOf(_user);
        data = RewardContractData(_crvLockRewards, wmxWomBalance, wmxWomToWom(wmxWomBalance), 0, rewards);
        data.usdBalance = estimateInBUSD(WMX_WOM_TOKEN, data.underlyingBalance);
    }

    function getUserLocker(
        address _locker,
        address _user
    ) public view returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserLockerPendingRewards(_locker, _user);
        (uint256 balance, , , ) = IWmxLocker(_locker).lockedBalances(_user);
        data = RewardContractData(_locker, balance, balance, 0, rewards);
        data.usdBalance = estimateInBUSD(WMX_TOKEN, data.underlyingBalance);
    }

    function getUserBalances(
        IBooster _booster,
        address _user,
        uint256[] memory _poolIds
    ) public view returns(RewardContractData[] memory rewardContractData) {
        uint256 len = _poolIds.length;
        rewardContractData = new RewardContractData[](len);
        uint256 mintRatio = _booster.mintRatio();

        for (uint256 i = 0; i < len; i++) {
            uint256 customMintRatio = _booster.customMintRatio(_poolIds[i]);
            IBooster.PoolInfo memory poolInfo = _booster.poolInfo(_poolIds[i]);

            // 1. Earned rewards
            RewardItem[] memory rewardTokens = getUserPendingRewards(customMintRatio == 0 ? mintRatio : customMintRatio, poolInfo.crvRewards, _user);

            // 2. LP token balance
            uint256 lpTokenBalance = ERC20(poolInfo.crvRewards).balanceOf(_user);
            rewardContractData[i] = RewardContractData(poolInfo.crvRewards, lpTokenBalance, 0, 0, rewardTokens);

            // 3. Underlying balance
            address womPool = IWomAsset(poolInfo.lptoken).pool();
            address underlyingToken = IWomAsset(poolInfo.lptoken).underlyingToken();
            try IWomPool(womPool).quotePotentialWithdraw(underlyingToken, lpTokenBalance) returns (uint256 underlyingBalance) {
                rewardContractData[i].underlyingBalance = underlyingBalance;

                // 4. Usd outs
                if (stablePoolToStableToken[womPool] != address(0)) {
                    rewardContractData[i].usdBalance = underlyingBalance;
                } else {
                    rewardContractData[i].usdBalance = getLpUsdOut(womPool, lpTokenBalance);
                }
            } catch {}
        }
    }

    function getUserPendingRewards(uint256 mintRatio, address _rewardsPool, address _user) public view
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
            rewards[i] = RewardItem(
                rewardTokens[i],
                earnedRewards[i],
                estimateInBUSD(rewardTokens[i], earnedRewards[i])
            );
        }
        if (earnedWom > 0) {
            uint256 earned = ITokenMinter(WMX_TOKEN).getFactAmounMint(earnedWom);
            earned = mintRatio > 0 ? earned * mintRatio / 10000 : earned;
            rewards[len] = RewardItem(WMX_TOKEN, earned, estimateInBUSD(WMX_TOKEN, earned));
        }
    }

    function getUserLockerPendingRewards(address _locker, address _user) public view
        returns (RewardItem[] memory rewards)
    {
        IWmxLocker.EarnedData[] memory userRewards = IWmxLocker(_locker).claimableRewards(_user);

        rewards = new RewardItem[](userRewards.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            rewards[i] = RewardItem(
                userRewards[i].token,
                userRewards[i].amount,
                estimateInBUSD(userRewards[i].token, userRewards[i].amount)
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