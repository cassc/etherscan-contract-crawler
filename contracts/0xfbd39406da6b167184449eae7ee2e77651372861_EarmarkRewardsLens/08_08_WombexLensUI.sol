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
    function quotePotentialWithdrawFromOtherAsset(address fromToken, address toToken, uint256 liquidity) external view virtual returns (uint256 amount, uint256 withdrewAmount);
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
    function totalSupply() external view returns (uint256);
    function asset() external view returns (address);
    function stakingToken() external view returns (address);
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

    address public WETH_TOKEN;
    address public WMX_WOM_TOKEN;
    address public WOM_TOKEN;
    address public WMX_TOKEN;
    address public WMX_MINTER;

    mapping(address => address) public swapTokenByPool;
    mapping(address => bool) public isUsdStableToken;
    mapping(address => address) public poolToToken;
    mapping(address => address) public tokenToRouter;
    mapping(address => uint24) public tokenUniV3Fee;
    mapping(address => address[]) public tokenSwapThroughTokens;
    mapping(address => address) public tokenSwapToTargetStable;

    struct PoolValuesTokenApr {
        address token;
        uint128 rewardRate;
        uint128 apr;
        bool isPeriodFinish;
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
        uint128 periodFinish;
    }

    constructor(
        address _UNISWAP_ROUTER,
        address _UNISWAP_V3_ROUTER,
        address _MAIN_STABLE_TOKEN,
        address _WOM_TOKEN,
        address _WMX_TOKEN,
        address _WMX_MINTER,
        address _WETH_TOKEN,
        address _WMX_WOM_TOKEN
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
    }

    function setUsdStableTokens(address[] memory _tokens, bool _isStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            isUsdStableToken[_tokens[i]] = _isStable;
        }
    }

    function setSwapTokenByPool(address[] memory _tokens, address _pool) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            swapTokenByPool[_tokens[i]] = _pool;
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

    function setTokenUniV3Fee(address[] memory _tokens, uint24 _tokenUniV3Fee) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenUniV3Fee[_tokens[i]] = _tokenUniV3Fee;
        }
    }

    function setTokenSwapThroughToken(address[] memory _tokens, address[] memory _throughTokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapThroughTokens[_tokens[i]] = _throughTokens;
        }
    }

    function setTokensTargetStable(address[] memory _tokens, address _targetStable) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenSwapToTargetStable[_tokens[i]] = _targetStable;
        }
    }

    struct RewardPoolInput {
        IBooster booster;
        uint256 poolId;
        address lpToken;
        address crvRewards;
        uint256[] rewardTokenPrices;
    }
    struct RewardPoolApyOutput {
        PoolValuesTokenApr[] aprs;
        uint256 aprTotal;
        uint256 aprItem;
        uint256 wmxApr;
        uint256 tvl;
    }

    function getRewardPoolApys(RewardPoolInput[] memory input) public returns (RewardPoolApyOutput[] memory output) {
        output = new RewardPoolApyOutput[](input.length);
        uint256 wmxPrice = estimateInBUSDEther(WMX_TOKEN, 1 ether, uint8(18));
        for (uint256 i = 0; i < input.length; i++) {
            output[i].tvl = IBaseRewardPool4626(input[i].crvRewards).totalSupply() * getLpUsdOut(IWomAsset(input[i].lpToken).pool(), IWomAsset(input[i].lpToken).underlyingToken(), 1 ether) / 1 ether;
            (output[i].aprs, output[i].aprTotal, output[i].aprItem, output[i].wmxApr) = getRewardPoolApys(
                IBaseRewardPool4626(input[i].crvRewards),
                output[i].tvl,
                address(input[i].booster) == address(0) ? 0 : wmxPrice,
                address(input[i].booster) == address(0) ? 0 : getPoolMintRatio(input[i].booster, input[i].poolId, input[i].booster.mintRatio()),
                input[i].rewardTokenPrices
            );
        }
    }

    function getRewardPoolApys(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio,
        uint256[] memory rewardTokenPrices
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
            aprs[i].token = rewardTokens[i];
            IBaseRewardPool4626.RewardState memory rewardState = crvRewards.tokenRewards(aprs[i].token);
            aprs[i].isPeriodFinish = rewardState.periodFinish < block.timestamp;
            if (aprs[i].isPeriodFinish) {
                continue;
            }

            if (aprs[i].token == WOM_TOKEN && poolTvl > 0) {
                uint256 factAmountMint = IWmx(WMX_MINTER).getFactAmounMint(rewardState.rewardRate * 365 days);
                uint256 wmxRate = factAmountMint;
                if (mintRatio > 0) {
                    wmxRate = factAmountMint * mintRatio / 10_000;
                }

                wmxApr += wmxRate * wmxUsdPrice * 100 / poolTvl / 1e16;
            }

            uint8 decimals = getTokenDecimals(aprs[i].token);
            uint256 usdPrice = rewardTokenPrices.length == 0 ? estimateInBUSDEther(aprs[i].token, 10 ** decimals, decimals) : rewardTokenPrices[i];
            aprs[i].rewardRate = uint128(rewardState.rewardRate * 10 ** (18 - decimals));
            aprs[i].apr = poolTvl == 0 ? 0 : uint128(uint256(aprs[i].rewardRate) * 365 days * usdPrice * 100 / poolTvl / 1e16);
            aprItem += uint256(aprs[i].rewardRate) * 365 days * usdPrice / 1e16;
            aprTotal += aprs[i].apr;
        }
        aprTotal += wmxApr;
    }

    function getRewardPoolTotalApr128(
        IBaseRewardPool4626 crvRewards,
        uint256 poolTvl,
        uint256 wmxUsdPrice,
        uint256 mintRatio
    ) public returns(uint128 aprItem128, uint128 aprTotal128) {
        uint256[] memory prices = new uint256[](0);
        (, uint256 aprTotal, uint256 aprItem, ) = getRewardPoolApys(crvRewards, poolTvl, wmxUsdPrice, mintRatio, prices);
        aprTotal128 = uint128(aprTotal);
        aprItem128 = uint128(aprItem);
    }

    function getBribeApys(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance,
        uint256[] memory rewardTokenPrices
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

            (, aprs[i].rewardRate, , ) = IBribe(bribe).rewardInfo(i);
            uint8 decimals = getTokenDecimals(aprs[i].token);
            uint256 price = rewardTokenPrices.length == 0 ? estimateInBUSDEther(aprs[i].token, 10 ** decimals, decimals) : rewardTokenPrices[i];
            uint256 usdPerSec = price * uint256(aprs[i].rewardRate) / (10 ** decimals);
            if (veWomBalance != 0 && poolTvl != 0 && voteWeight / poolTvl > 0) {
                aprs[i].apr = uint128(usdPerSec * 365 days * 10e3 / (voteWeight * allPoolsTvl / veWomBalance));
                // 365 * 24 * 60 * 60 * rewardInfo.tokenPerSec * tokenUsdcPrice * userVotes / weight / (rewardPoolTotalSupply * wmxPrice) * 100,
                aprItem += usdPerSec * 365 days * userVotes * 100 / voteWeight;
            }
            aprTotal += aprs[i].apr;
        }
    }

    function getBribeTotalApr128(
        address voterProxy,
        IBribeVoter bribesVoter,
        address lpToken,
        uint256 poolTvl,
        uint256 allPoolsTvl,
        uint256 veWomBalance
    ) public returns(uint128 aprItem128, uint128 aprTotal128, PoolValuesTokenApr[] memory aprs) {
        uint256[] memory prices = new uint256[](0);
        uint256 aprItem;
        uint256 aprTotal;
        (aprs, aprItem, aprTotal) = getBribeApys(voterProxy, bribesVoter, lpToken, poolTvl, allPoolsTvl, veWomBalance, prices);
        aprItem128 = uint128(aprItem);
        aprTotal128 = uint128(aprTotal);
    }


    function getTokenToWithdrawFromPool(address _womPool) public view returns (address tokenOut) {
        tokenOut = poolToToken[_womPool];
        if (tokenOut == address(0)) {
            address[] memory tokens;
            try IWomPool(_womPool).getTokens() returns (address[] memory _tokens) {
                tokens = _tokens;
            } catch {
                return address(0);
            }
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
        address _fromToken,
        uint256 _lpTokenAmountIn
    ) public returns (uint256 result) {
        address tokenOut = getTokenToWithdrawFromPool(_womPool);
        if (tokenOut == address(0)) {
            return 0;
        }
        return quotePotentialWithdrawalTokenToBUSD(_womPool, _fromToken, tokenOut, _lpTokenAmountIn);
    }

    function getTokensPrices(address[] memory _tokens) public returns (uint256[] memory prices) {
        uint256 len = _tokens.length;
        prices = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            address underlyingToken = getTokenUnderlying(_tokens[i]);
            if (underlyingToken == address(0)) {
                uint8 decimals = getTokenDecimals(_tokens[i]);
                prices[i] = estimateInBUSDEther(_tokens[i], 10 ** decimals, decimals);
            } else {
                address womPool = IWomAsset(_tokens[i]).pool();
                uint8 decimals = getTokenDecimals(underlyingToken);
                prices[i] = getLpUsdOut(womPool, underlyingToken, 1 ether);
            }
        }
    }

    function quotePotentialWithdrawalTokenToBUSD(address _womPool, address _fromToken, address _tokenOut, uint256 _lpTokenAmountIn) public returns (uint256) {
        if (_fromToken == _tokenOut) {
            try IWomPool(_womPool).quotePotentialWithdraw(_tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut) {
                uint8 decimals = getTokenDecimals(_tokenOut);
                return estimateInBUSDEther(_tokenOut, tokenAmountOut, decimals);
            } catch {}
        } else {
            try IWomPool(_womPool).quotePotentialWithdrawFromOtherAsset(_fromToken, _tokenOut, _lpTokenAmountIn) returns (uint256 tokenAmountOut, uint256 withdrewAmount) {
                uint8 decimals = getTokenDecimals(_tokenOut);
                return estimateInBUSDEther(_tokenOut, tokenAmountOut, decimals);
            } catch {}
        }
        return 0;
    }

    function tokenToPoolToken(address _token, uint256 _tokenAmount) public view returns (uint256 resAmount, address resToken) {
        address pool = swapTokenByPool[_token];
        resToken = poolToToken[pool];
        if (_tokenAmount == 0) {
            return (0, resToken);
        }
        uint8 decimals = getTokenDecimals(_token);
        try IWomPool(pool).quotePotentialSwap(_token, resToken, int256(10 ** decimals)) returns (uint256 potentialOutcome, uint256 haircut) {
            resAmount = potentialOutcome * _tokenAmount / (10 ** decimals);
        } catch {}
    }

    function estimateInBUSDEther(address _token, uint256 _amountIn, uint256 _decimals) public returns (uint256 result) {
        return _estimateInBUSD(_token, _amountIn, _decimals) * 10 ** (18 - _decimals);
    }

    // Estimates a token equivalent in USD (BUSD) using a Uniswap-compatible router
    function _estimateInBUSD(address _token, uint256 _amountIn, uint256 _decimals) internal returns (uint256 result) {
        if (_amountIn == 0) {
            return 0;
        }
        // 1. All the USD stable tokens are roughly estimated as $1.
        if (isUsdStableToken[_token]) {
            return _amountIn;
        }

        if (swapTokenByPool[_token] != address(0)) {
            (_amountIn, _token) = tokenToPoolToken(_token, _amountIn);
        }

        address router = UNISWAP_ROUTER;
        if (tokenToRouter[_token] != address(0)) {
            router = tokenToRouter[_token];
        }

        address targetStable = MAIN_STABLE_TOKEN;
        uint8 targetStableDecimals = MAIN_STABLE_TOKEN_DECIMALS;
        if (tokenSwapToTargetStable[_token] != address(0)) {
            targetStable = tokenSwapToTargetStable[_token];
            targetStableDecimals = getTokenDecimals(targetStable);
        }

        address[] memory path;
        address[] memory throughTokens = tokenSwapThroughTokens[_token];
        if (throughTokens.length > 0) {
            path = new address[](2 + throughTokens.length);
            path[0] = _token;
            for(uint256 i = 0; i < throughTokens.length; i++) {
                path[1 + i] = throughTokens[i];
            }
            path[path.length - 1] = targetStable;
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
            } catch {}
        } else if (tokenUniV3Fee[_token] != 0) {
            QuoterV2.QuoteExactInputSingleParams memory params = QuoterV2.QuoteExactInputSingleParams(_token, targetStable, oneUnit, tokenUniV3Fee[_token], 0);
            try QuoterV2(UNISWAP_V3_QUOTER).quoteExactInputSingle(params) returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate) {
                result = _amountIn * amountOut / oneUnit;
            } catch {}
        } else {
            try IUniswapV2Router01(router).getAmountsOut(oneUnit, path) returns (uint256[] memory amountsOut) {
                result = _amountIn * amountsOut[amountsOut.length - 1] / oneUnit;
            } catch {}
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
        wmxWom = _getUserWmxWom(_booster, _booster.crvLockRewards(), _user);
        locker = _getUserLocker(_booster.cvxLocker(), _user);
    }

    function allBoosterPoolIds(IBooster _booster) public view returns (uint256[] memory) {
        uint256 len = _booster.poolLength();
        uint256[] memory poolIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            poolIds[i] = i;
        }
        return poolIds;
    }

    function _getUserWmxWom(
        IBooster _booster,
        address _crvLockRewards,
        address _user
    ) internal returns (RewardContractData memory data) {
        RewardItem[] memory rewards = getUserPendingRewards(_booster.mintRatio(), _crvLockRewards, _user);
        uint256 wmxWomBalance = ERC20(_crvLockRewards).balanceOf(_user);
        (uint256 womBalance, ) = tokenToPoolToken(WMX_WOM_TOKEN, wmxWomBalance);
        data = RewardContractData(_crvLockRewards, uint128(wmxWomBalance), uint128(womBalance), uint128(0), uint8(18), rewards);
        data.usdBalance = uint128(_estimateInBUSD(WMX_WOM_TOKEN, data.underlyingBalance, uint8(18)));
    }

    function _getUserLocker(
        address _locker,
        address _user
    ) internal returns (RewardContractData memory data) {
        RewardItem[] memory rewards = _getUserLockerPendingRewards(_locker, _user);
        (uint256 balance, , , ) = IWmxLocker(_locker).lockedBalances(_user);
        data = RewardContractData(_locker, uint128(balance), uint128(balance), uint128(0), uint8(18), rewards);
        data.usdBalance = uint128(_estimateInBUSD(WMX_TOKEN, data.underlyingBalance, uint8(18)));
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
                    rewardContractData[i].usdBalance = uint128(getLpUsdOut(womPool, underlyingToken, lpTokenBalance));
                }
            } catch {}
        }
    }

    function getPoolMintRatio(IBooster _booster, uint256 pid, uint256 defaultMintRatio) public view returns (uint256 resMintRatio) {
        resMintRatio = defaultMintRatio;
        try _booster.customMintRatio(pid) returns (uint256 _customMintRatio) {
            resMintRatio = _customMintRatio == 0 ? defaultMintRatio : _customMintRatio;
        } catch {}
    }

    function getTokenDecimals(address _token) public view returns (uint8) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSelector(ERC20.decimals.selector));

        if (!success) {
            return uint8(18);
        }

        if (data.length == 1) {
            return uint8(data[0]);
        } else if (data.length == 32) {
            uint256 decimalsValue;
            assembly {
                decimalsValue := mload(add(data, 32))
            }
            return uint8(decimalsValue);
        } else {
            return uint8(18);
        }
    }

    function getTokenUnderlying(address _token) public view returns (address) {
        (bool success, bytes memory data) = _token.staticcall(abi.encodeWithSelector(IWomAsset.underlyingToken.selector));

        if (!success || data.length != 32) {
            return address(0);
        }
        address result;
        assembly {
            result := mload(add(data, 32))
        }
        return result;
    }

    function getUserPendingRewards(uint256 _mintRatio, address _rewardsPool, address _user) public
        returns (RewardItem[] memory rewards)
    {
        (address[] memory rewardTokens, uint256[] memory earnedRewards) = IBaseRewardPool4626(_rewardsPool)
            .claimableRewards(_user);

        uint256 len = rewardTokens.length;
        rewards = new RewardItem[](len + 1);
        uint256 earnedWom;
        uint256 womPeriodFinish;
        for (uint256 i = 0; i < earnedRewards.length; i++) {
            IBaseRewardPool4626.RewardState memory tokenRewards = IBaseRewardPool4626(_rewardsPool).tokenRewards(rewardTokens[i]);
            if (rewardTokens[i] == WOM_TOKEN) {
                earnedWom = earnedRewards[i];
                womPeriodFinish = tokenRewards.periodFinish;
            }
            uint8 decimals = getTokenDecimals(rewardTokens[i]);
            rewards[i] = RewardItem(
                rewardTokens[i],
                uint128(earnedRewards[i]),
                uint128(estimateInBUSDEther(rewardTokens[i], earnedRewards[i], decimals)),
                decimals,
                uint128(tokenRewards.periodFinish)
            );
        }
        if (earnedWom > 0) {
            uint256 earned = ITokenMinter(WMX_MINTER).getFactAmounMint(earnedWom);
            earned = _mintRatio > 0 ? earned * _mintRatio / 10000 : earned;
            rewards[len] = RewardItem(WMX_TOKEN, uint128(earned), uint128(_estimateInBUSD(WMX_TOKEN, earned, uint8(18))), uint8(18), uint128(womPeriodFinish));
        }
    }

    function _getUserLockerPendingRewards(address _locker, address _user) internal
        returns (RewardItem[] memory rewards)
    {
        IWmxLocker.EarnedData[] memory userRewards = IWmxLocker(_locker).claimableRewards(_user);

        rewards = new RewardItem[](userRewards.length);
        for (uint256 i = 0; i < userRewards.length; i++) {
            IWmxLockerExt.LockerRewardData memory tokenRewards = IWmxLockerExt(_locker).rewardData(userRewards[i].token);
            uint8 decimals = getTokenDecimals(userRewards[i].token);
            rewards[i] = RewardItem(
                userRewards[i].token,
                uint128(userRewards[i].amount),
                uint128(estimateInBUSDEther(userRewards[i].token, userRewards[i].amount, decimals)),
                decimals,
                uint128(tokenRewards.periodFinish)
            );
        }
    }
}