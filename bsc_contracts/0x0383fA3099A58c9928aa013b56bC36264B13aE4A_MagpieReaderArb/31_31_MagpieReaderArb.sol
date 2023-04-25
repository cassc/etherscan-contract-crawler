// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {IWombatBribeManagerReader} from "./interfaces/wombat/IWombatBribeManagerReader.sol";
import {IWombatVoter, IWombatGauge} from "./interfaces/wombat/IWombatVoter.sol";
import {IWombatBribeReader} from "./interfaces/wombat/IWombatBribeReader.sol";
import {IAssetReader} from "./interfaces/wombat/IAssetReader.sol";
import {IWombatStakingReader} from "./interfaces/wombat/IWombatStakingReader.sol";
import {IMasterWombatV3Reader} from "./interfaces/wombat/IMasterWombatV3Reader.sol";
import {IMasterMagpieReader} from "./interfaces/IMasterMagpieReader.sol";
import {IMultiRewarderReader} from "./interfaces/wombat/IMultiRewarderReader.sol";
import {IPancakeRouter02Reader} from "./interfaces/pancake/IPancakeRouter02Reader.sol";
import {IWombatRouterReader} from "./interfaces/wombat/IWombatRouterReader.sol";
import {IWombatPoolHelperV2Reader} from "./interfaces/wombat/IWombatPoolHelperV2Reader.sol";
import {AggregatorV3Interface} from "./interfaces/chainlink/AggregatorV3Interface.sol";
import {IUniswapV3Pool} from "./interfaces/uniswapV3/IUniswapV3Pool.sol";
import {ILBQuoter} from "./interfaces/traderjoeV2/ILBQuoter.sol";

/// @title MagpieReader for Arbitrum
/// @author Magpie Team

contract MagpieReaderArb is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMath for uint128;
    /* ============ Structs ============ */

    struct BribeInfo {
        uint256 bribeCallerFee;
        uint256 bribeProtocolFee;
        uint256 usedVote;
        uint256 totalVlMgpInVote;
        BribePool[] pools;
    }

    //   const usedVote = await this.wombatBribeManagerContract.usedVote();  
    // const totalVlMgpInVote = await this.wombatBribeManagerContract.totalVlMgpInVote();

    struct BribePoolReward {
        IERC20 rewardToken; // if rewardToken is 0, native token is used as reward token
        string symbol;
        uint96 tokenPerSec; // 10.18 fixed point
        uint128 accTokenPerShare; // 26.12 fixed point. Amount of reward token each LP token is worth.
        uint128 distributedAmount; // 20.18 fixed point, depending on the decimals of the reward token. This value is used to
        // track the amount of distributed tokens. If `distributedAmount` is closed to the amount of total received
        // tokens, we should refill reward or prepare to stop distributing reward.
    }
    
    struct BribePool {
        address lpAddress;
        string lpSymbol;
        address underlyingToken;
        string underlyingTokenSymbol;
        address poolAddress;
        address rewarder;
        uint256 totalVoteInVlmgp;
        string name;
        bool isActive;

        uint104 supplyBaseIndex;
        uint104 supplyVoteIndex;
        uint40 nextEpochStartTime;
        uint128 claimable;
        bool whitelist;

        IWombatGauge gaugeManager;
        IWombatBribeReader bribe;

        uint128 allocPoint;
        uint128 voteWeight; 

        uint256 wombatStakingUserVotes;
        BribePoolReward[] rewardList;
    }

    struct MagpieInfo {
        address wom;
        address mgp;
        address vlmgp;
        address mWom;
        TokenPrice[] tokenPriceList;
        MagpiePool[] pools;
    }

    struct MagpiePool {
        address stakingToken; // Address of staking token contract to be staked.
        uint256 allocPoint; // How many allocation points assigned to this pool. MGPs to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that MGPs distribution occurs.
        uint256 accMGPPerShare; // Accumulated MGPs per share, times 1e12. See below.
        address rewarder;
        address helper;
        bool    helperNeedsHarvest;
        uint256 emission;
        uint256 sizeOfPool;
        uint256 totalPoint;
        string  poolType;
        string  stakingTokenSymbol;
        uint256  stakingTokenDecimals;
        uint256 poolId;
        uint256 poolTokenPrice;
        bool isWombatPool;
        bool isActive;
        bool isMPGRewardPool;
        WombatStakingPool wombatStakingPool;
        WombatV3Pool wombatV3Pool;
        WombatPoolHelperInfo wombatHelperInfo;
        MagpieRewardInfo rewardInfo;
        MagpieAccountInfo accountInfo;
    }

    struct MagpieAccountInfo {
        uint256 balance;
        uint256 stakedAmount;
        uint256 stakingAllowance;
        uint256 availableAmount;
    }

    struct MagpieRewardInfo {
        uint256 pendingMGP;
        address[]  bonusTokenAddresses;
        string[]  bonusTokenSymbols;
        uint256[]  pendingBonusRewards;
    }

    struct WombatPoolHelperInfo {
        
        bool isNative;
        address depositToken;
        string depositTokenSymbol;
        uint256 depositTokenDecimals;
        address lpToken;
        address stakingToken;
    }

    struct MagpiePoolApr {
        MagpiePoolAprToken[] items;
    }

    struct MagpiePoolAprToken {
        string symbol;
        uint256 price;
        uint256 rewardAmount;
        uint256 tvlAmount; 
        uint256 aprValue;
    }

    struct MagpiePoolTvl {
        uint256 totalSupply;
        address token;
        uint256 price;
        uint256 totalSupplyAmount;
    }

    struct WombatV3Pool {
        address lpToken; // Address of LP token contract.
        ////
        address rewarder;
        uint40 periodFinish;
        ////
        uint128 sumOfFactors; // 20.18 fixed point. the sum of all boosted factors by all of the users in the pool
        uint128 rewardRate; // 20.18 fixed point.
        uint128 rewardRateToMgp; // 20.18 fixed point.
        uint128 boostedEffect; // 20.18 fixed point.
        ////
        uint104 accWomPerShare; // 19.12 fixed point. Accumulated WOM per share, times 1e12.
        uint104 accWomPerFactorShare; // 19.12 fixed point. Accumulated WOM per factor share
        uint40 lastRewardTimestamp;
        uint128 wombatStakingUserAmount;
        uint128 wombatStakingUserFactor;
        // uint128 wombatStakingUserRewardDebt;
        // uint128 wombatStakingUserPendingWom;
        uint256 totalSupply;
        // uint256 normPerSec;
        // uint256 emission;
        // uint256 boostedPerSec;
        WombatV3PoolReward[] rewardList;
        address pool;
        string  poolType;
        // address underlyingToken;
        // string  underlyingTokenSymbol;
        // uint256 underlyingTokenDecimals;
        uint256 assetCash;
        uint256 assetLiability;

    }

    struct WombatV3PoolReward {
         address rewardToken;
         uint96 tokenPerSec;
         uint128 accTokenPerShare;
         uint128 distributedAmount;
         string rewardTokenSymbol;
         uint256 rewardTokenDecimals;
    }

    struct WombatStakingPool {
        uint256 pid;                // pid on master wombat
        address depositToken;       // token to be deposited on wombat
        address lpAddress;          // token received after deposit on wombat
        address receiptToken;       // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
        // string depositTokenSymbol;
        // uint256 depositTokenDecimals; 
        bool isPoolFeeFree;
    }

    struct TokenPrice {
        address token;
        string  symbol;
        uint256 price;
    }

    struct TokenRouter {
        address token;
        string symbol;
        uint256 decimals;
        address[] paths;
        address[] pools;
        address chainlink;
        uint256 routerType;
    }

    /* ============ State Variables ============ */

    IWombatBribeManagerReader public wombatBribeManager; // IWombatBribeManager interface
    IWombatVoter public voter; // Wombat voter interface
    IWombatStakingReader public wombatStaking;
    IMasterMagpieReader public masterMagpie;
    IMasterWombatV3Reader public masterWombatV3;
    IPancakeRouter02Reader public pancakeRouter02;
    IWombatRouterReader public wombatRouter;
    mapping(address => string) public wombatPoolType;
    mapping(address => TokenRouter) public tokenRouterMap;
    address[] public tokenList;
    address public wom;
    address public mWom;
    address public mgp;
    address public vlmgp;

   // IPancakeRouter02Reader constant public PancakeRouter02 = IPancakeRouter02Reader(0x10ED43C718714eb63d5aA57B78B54704E256024E);
   // IWombatRouterReader constant public WombatRouter = IWombatRouterReader(0x19609B03C976CCA288fbDae5c21d4290e9a4aDD7);
    address constant public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address constant public USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    uint256 constant PancakeRouterType = 1;
    uint256 constant WombatRouterType = 2;
    uint256 constant ChainlinkType = 3;
    uint256 constant UniswapV3RouterType = 4; // currently only works for 18 decimal tokens    
    uint256 constant TraderJoeV2Type = 5;
    
    uint256 constant ActiveWombatPool = 1;
    uint256 constant DeactiveWombatPool = 2;
    mapping(uint256 => uint256) public wombatPoolStatus;
    address public mWomSV;

    address constant public TraderJoeV2LBQuoter = 0x7f281f22eDB332807A039073a7F34A4A215bE89e;

    /* ============ Events ============ */

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    // function __MagpieReader_init( 
    //     IMasterMagpieReader _masterMagpie, 
    //     IWombatBribeManagerReader _wombatBribeManager,
    //     IPancakeRouter02Reader _pancakeRouter02,
    //     IWombatRouterReader _wombatRouter,
    //     address _mWomSV
    //     )
    //     public
    //     initializer
    // {
    //     __Ownable_init();
    //     masterMagpie = _masterMagpie;
    //     wombatBribeManager = _wombatBribeManager;
    //     pancakeRouter02 = _pancakeRouter02;
    //     wombatRouter = _wombatRouter;
    //     mWomSV = _mWomSV;
    //     voter = IWombatVoter(wombatBribeManager.voter());
    //     wombatStaking = IWombatStakingReader(wombatBribeManager.wombatStaking());
    //     masterWombatV3 = IMasterWombatV3Reader(wombatStaking.masterWombat());
    // }

    /* ============ External Getters ============ */

    function getMagpieInfo(address account) external view returns (MagpieInfo memory) {
        MagpieInfo memory magpieInfo;
        uint256 poolCount = masterMagpie.poolLength();
        MagpiePool[] memory pools = new MagpiePool[](poolCount);
        TokenPrice[] memory tokenPriceList = getAllTokenPrice();
        for (uint256 i = 0; i < poolCount; ++i) {
           pools[i] = getMagpiePoolInfo(i, account);
        }
        magpieInfo.tokenPriceList = tokenPriceList;
        magpieInfo.pools = pools;
        magpieInfo.wom = wom;
        magpieInfo.mWom = mWom;
        magpieInfo.mgp = mgp;
        magpieInfo.vlmgp = vlmgp;
        return magpieInfo;
    }

    function getMagpiePoolInfo(uint256 poolId, address account) public view returns (MagpiePool memory) {
        MagpiePool memory magpiePool;
        magpiePool.poolId = poolId;
        address registeredToken = masterMagpie.registeredToken(poolId);
        (magpiePool.stakingToken, magpiePool.allocPoint, magpiePool.lastRewardTimestamp, magpiePool.accMGPPerShare, magpiePool.rewarder, magpiePool.helper, magpiePool.helperNeedsHarvest)  = masterMagpie.tokenToPoolInfo(registeredToken);
        (magpiePool.emission, magpiePool.allocPoint, magpiePool.sizeOfPool, magpiePool.totalPoint)  = masterMagpie.getPoolInfo(registeredToken);
        
        magpiePool.stakingTokenSymbol = ERC20(magpiePool.stakingToken).symbol();
        magpiePool.stakingTokenDecimals = ERC20(magpiePool.stakingToken).decimals();
        if (magpiePool.stakingToken == mWom) {
            magpiePool.poolType = "MAGPIE_WOM_POOL";
            magpiePool.isActive = true;
        }
        else if (magpiePool.stakingToken == vlmgp) {
            magpiePool.poolType = "MAGPIE_VLMGP_POOL";
            magpiePool.isActive = true;
        }    
        else if (magpiePool.stakingToken == mWomSV) {
            magpiePool.poolType = "MAGPIE_MWOMSV_POOL";
            magpiePool.isActive = true;
        }
        else if (wombatPoolStatus[poolId] == ActiveWombatPool) {
            magpiePool.wombatHelperInfo = _getWombatHelperInfo(magpiePool.helper);
            magpiePool.wombatStakingPool = _getWombatStakingPoolInfo(magpiePool.wombatHelperInfo.lpToken);
            magpiePool.wombatV3Pool = _getWombatV3PoolInfo(magpiePool.wombatStakingPool.pid);
            IAssetReader assetReader = IAssetReader(magpiePool.wombatV3Pool.lpToken);
            magpiePool.wombatV3Pool.assetCash = assetReader.cash();
            magpiePool.wombatV3Pool.assetLiability = assetReader.liability();
            magpiePool.wombatV3Pool.pool = assetReader.pool();
            // magpiePool.wombatV3Pool.underlyingToken = assetReader.underlyingToken();
            // magpiePool.wombatV3Pool.underlyingTokenDecimals = assetReader.underlyingTokenDecimals();
            // magpiePool.wombatV3Pool.underlyingTokenSymbol =  ERC20(magpiePool.wombatV3Pool.underlyingToken).symbol();
            magpiePool.wombatV3Pool.poolType = wombatPoolType[magpiePool.wombatV3Pool.pool];
            magpiePool.poolType = "WOMBAT_POOL";
            if (magpiePool.wombatV3Pool.rewarder != address(0)) {
                magpiePool.wombatV3Pool.rewardList = _getWombatV3PoolRewardList(magpiePool.wombatV3Pool.rewarder);
            }
            magpiePool.isWombatPool = true;
            magpiePool.isActive = true;
        }
        else if (wombatPoolStatus[poolId] == DeactiveWombatPool) {
            magpiePool.wombatHelperInfo = _getWombatHelperInfo(magpiePool.helper);
            magpiePool.poolType = "WOMBAT_POOL";
            magpiePool.isWombatPool = true;
            magpiePool.isActive = false;
        }
        magpiePool.isMPGRewardPool = masterMagpie.MPGRewardPool(magpiePool.stakingToken);
        if (account != address(0)) {
            magpiePool.rewardInfo = _getMagpieRewardInfo(magpiePool.stakingToken, account);
            magpiePool.accountInfo = _getMagpieAccountInfo(magpiePool, account);
        }
        return magpiePool;
    }

    function getBribeInfo() external view returns (BribeInfo memory) {
        BribeInfo memory bribeInfo;
        uint256 poolCount = wombatBribeManager.getPoolsLength();
        BribePool[] memory pools = new BribePool[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
            address lpAddress = wombatBribeManager.pools(i);
            BribePool memory bribePool;
            bribePool.lpAddress = lpAddress;
            IAssetReader asset = IAssetReader(lpAddress);
            bribePool.underlyingToken = asset.underlyingToken();
            bribePool.underlyingTokenSymbol = ERC20(bribePool.underlyingToken).symbol();
            bribePool.lpSymbol = ERC20(bribePool.lpAddress).symbol();
            (bribePool.poolAddress, bribePool.rewarder, bribePool.totalVoteInVlmgp, bribePool.name, bribePool.isActive) = wombatBribeManager.poolInfos(lpAddress); 
            IWombatVoter.GaugeInfo memory gaugeInfo = voter.infos(lpAddress);
            bribePool.supplyBaseIndex = gaugeInfo.supplyBaseIndex;
            bribePool.supplyVoteIndex = gaugeInfo.supplyVoteIndex;
            bribePool.nextEpochStartTime = gaugeInfo.nextEpochStartTime;
            bribePool.claimable = gaugeInfo.claimable;
            bribePool.whitelist = gaugeInfo.whitelist;
            bribePool.gaugeManager = gaugeInfo.gaugeManager;
            bribePool.bribe = IWombatBribeReader(address(gaugeInfo.bribe));

            IWombatVoter.GaugeWeight memory gaugeWeight = voter.weights(lpAddress);
            bribePool.allocPoint = gaugeWeight.allocPoint;
            bribePool.voteWeight = gaugeWeight.voteWeight;

            bribePool.wombatStakingUserVotes = wombatBribeManager.getVoteForLp(lpAddress);
            if (address(bribePool.bribe) != address(0)) {
                uint256 rewardLength = bribePool.bribe.rewardLength();
                bribePool.rewardList = new BribePoolReward[](rewardLength);
                for (uint256 m = 0; m < rewardLength; m++) {
                    (
                        bribePool.rewardList[m].rewardToken,
                        bribePool.rewardList[m].tokenPerSec,
                        bribePool.rewardList[m].accTokenPerShare,
                        bribePool.rewardList[m].distributedAmount
                    )
                     = bribePool.bribe.rewardInfo(m);
                    bribePool.rewardList[m].symbol = ERC20(address(bribePool.rewardList[m].rewardToken)).symbol();
                }
            }
            pools[i] = bribePool;
        }
        bribeInfo.pools = pools;
        bribeInfo.bribeCallerFee = wombatStaking.bribeCallerFee();
        bribeInfo.bribeProtocolFee = wombatStaking.bribeProtocolFee();
        bribeInfo.usedVote = wombatBribeManager.usedVote();
        bribeInfo.totalVlMgpInVote = wombatBribeManager.totalVlMgpInVote();
        return bribeInfo;
    }

    function getUSDTPrice() public view returns (uint256) {
        return getTokenPrice(USDT, address(0));
    }

    function getUSDCPrice() public view returns (uint256) {
        return getTokenPrice(USDC, address(0));
    }    

    function getWETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    // just to make frontend happy
    function getBUSDPrice() public view returns (uint256) {
        return 0;
    }

    // just to make frontend happy
    function getBNBPrice() public view returns (uint256) {
        return 0;
    }       

    // just to make frontend happy
    function getETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    function getTokenPrice(address token, address unitToken) public view returns (uint256) {
        TokenRouter memory tokenRouter = tokenRouterMap[token];
        uint256 amountOut = 0;
        if (tokenRouter.token != address(0)) {
           if (tokenRouter.routerType == PancakeRouterType) {
            uint256[] memory prices = pancakeRouter02.getAmountsOut(10 ** tokenRouter.decimals , tokenRouter.paths);
            amountOut = prices[tokenRouter.paths.length - 1];
           }
           else if (tokenRouter.routerType == WombatRouterType) {
            (amountOut , ) = wombatRouter.getAmountOut(tokenRouter.paths, tokenRouter.pools, int256(10) ** tokenRouter.decimals);
          
           }
           else if (tokenRouter.routerType == ChainlinkType) {
            AggregatorV3Interface aggregatorV3Interface = AggregatorV3Interface(tokenRouter.chainlink);
              (
                /* uint80 roundID */,
                int256 price,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = aggregatorV3Interface.latestRoundData();
            amountOut = uint256(price * 1e18 / 1e8);
           } else if (tokenRouter.routerType == UniswapV3RouterType) {
            IUniswapV3Pool pool = IUniswapV3Pool(tokenRouter.pools[0]);
            (uint160 sqrtPriceX96,,,,,,) =  pool.slot0();
            amountOut = uint(sqrtPriceX96).mul(uint(sqrtPriceX96)).mul(1e18) >> (96 * 2);
           } else if (tokenRouter.routerType == TraderJoeV2Type) {
            uint256[] memory quotes = (ILBQuoter(TraderJoeV2LBQuoter).findBestPathFromAmountIn(tokenRouter.paths, 10 ** tokenRouter.decimals)).amounts;
            amountOut = quotes[tokenRouter.paths.length - 1];
           }
       
        }
        if (unitToken == address(0)) {
            return amountOut;
        } 

        TokenRouter memory router = tokenRouterMap[unitToken];
        uint256 unitPrice;
        if (router.routerType != ChainlinkType) {
            address target = router.paths[router.paths.length - 1];
            unitPrice = getTokenPrice(unitToken, target);
        } else {
            unitPrice = getTokenPrice(unitToken, address(0));
        }
        
        uint256 uintDecimals =  ERC20(unitToken).decimals();
        return amountOut * unitPrice / (10 ** uintDecimals);
    }

    function getAllTokenPrice() public view returns (TokenPrice[] memory) {
        TokenPrice[] memory items = new TokenPrice[](tokenList.length);
        for(uint256 i = 0; i < tokenList.length; i++) {
            TokenPrice memory tokenPrice;
            TokenRouter memory router = tokenRouterMap[tokenList[i]];
            address target;

            if (router.routerType != ChainlinkType) {
                target = router.paths[router.paths.length - 1];

            }

            tokenPrice.price = getTokenPrice(tokenList[i], target);
            
            tokenPrice.symbol = router.symbol;
            tokenPrice.token = tokenList[i];
            items[i] = tokenPrice;
        }
        return items;
    }

    /* ============ Internal Functions ============ */

    function _getMagpieAccountInfo(MagpiePool memory magpiePool, address account) internal view returns (MagpieAccountInfo memory) {
        MagpieAccountInfo memory accountInfo;
        if (magpiePool.isWombatPool) {
            accountInfo.balance = ERC20(magpiePool.wombatHelperInfo.depositToken).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(magpiePool.wombatHelperInfo.depositToken).allowance(account, address(wombatStaking));
            IWombatPoolHelperV2Reader helper = IWombatPoolHelperV2Reader(magpiePool.helper);
            accountInfo.stakedAmount = helper.balance(account);
            if (magpiePool.wombatHelperInfo.isNative == true) {
                accountInfo.balance = account.balance;
                accountInfo.stakingAllowance = type(uint256).max;
            }
        }
        else {
            accountInfo.balance = ERC20(magpiePool.stakingToken).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(magpiePool.stakingToken).allowance(account, address(masterMagpie));
            (accountInfo.stakedAmount, accountInfo.availableAmount) = masterMagpie.stakingInfo(magpiePool.stakingToken, account);
        }
    
        return accountInfo;
    }

    function _getMagpieRewardInfo(address stakingToken, address account) internal view returns (MagpieRewardInfo memory) {
        MagpieRewardInfo memory rewardInfo;
        (rewardInfo.pendingMGP, rewardInfo.bonusTokenAddresses, rewardInfo.bonusTokenSymbols, rewardInfo.pendingBonusRewards) = masterMagpie.allPendingTokens(stakingToken, account);
        return rewardInfo;
    }

    function _getWombatHelperInfo(address helperAddress) internal view returns (WombatPoolHelperInfo memory) {
        IWombatPoolHelperV2Reader helper = IWombatPoolHelperV2Reader(helperAddress);
        WombatPoolHelperInfo memory wombatHelperInfo;
        wombatHelperInfo.isNative = helper.isNative();
        wombatHelperInfo.depositToken = helper.depositToken();
        wombatHelperInfo.depositTokenSymbol = ERC20(wombatHelperInfo.depositToken).symbol();
        wombatHelperInfo.depositTokenDecimals = ERC20(wombatHelperInfo.depositToken).decimals();
        wombatHelperInfo.lpToken = helper.lpToken();
        wombatHelperInfo.stakingToken = helper.stakingToken();
        return wombatHelperInfo;
    }

    function _getWombatV3PoolRewardList(address rewarderAddress) internal view returns (WombatV3PoolReward[] memory) {
        IMultiRewarderReader rewarder = IMultiRewarderReader(rewarderAddress);
        uint256 rewardCount = rewarder.rewardLength();
        WombatV3PoolReward[] memory rewardList =  new WombatV3PoolReward[](rewardCount);
        for(uint256 n = 0; n < rewardCount; ++n) {
            WombatV3PoolReward memory poolReward;
            (poolReward.rewardToken, poolReward.tokenPerSec, poolReward.accTokenPerShare, poolReward.distributedAmount ) = rewarder.rewardInfo(n);
            poolReward.rewardTokenSymbol = ERC20(poolReward.rewardToken).symbol();
            poolReward.rewardTokenDecimals = ERC20(poolReward.rewardToken).decimals();
            rewardList[n] = poolReward;
        }
        return rewardList;
    }

    function _getWombatV3PoolInfo(uint256 poolId) internal view returns (WombatV3Pool memory) {
        WombatV3Pool memory wombatPool;
        IMasterWombatV3Reader.WombatV3Pool memory v3PoolInfo = masterWombatV3.poolInfoV3(poolId);
        wombatPool.lpToken = v3PoolInfo.lpToken;
        wombatPool.periodFinish = v3PoolInfo.periodFinish;
        wombatPool.rewarder = v3PoolInfo.rewarder;
        wombatPool.rewardRate = v3PoolInfo.rewardRate;
        wombatPool.sumOfFactors = v3PoolInfo.sumOfFactors;
        wombatPool.accWomPerFactorShare = v3PoolInfo.accWomPerFactorShare;
        wombatPool.accWomPerShare = v3PoolInfo.accWomPerShare;
        wombatPool.lastRewardTimestamp = v3PoolInfo.lastRewardTimestamp;
        (wombatPool.wombatStakingUserAmount, wombatPool.wombatStakingUserFactor, , ) = masterWombatV3.userInfo(poolId, address(wombatStaking));
        wombatPool.totalSupply = ERC20(wombatPool.lpToken).balanceOf(address(masterWombatV3));
        return wombatPool;
    }

    function _getWombatStakingPoolInfo(address lpToken) internal view returns (WombatStakingPool memory) {
        WombatStakingPool memory wombatStakingPool;
        IWombatStakingReader.WombatStakingPool memory wombatStakingPoolInfo = wombatStaking.pools(lpToken);
        wombatStakingPool.lpAddress = wombatStakingPoolInfo.lpAddress;
        wombatStakingPool.depositTarget = wombatStakingPoolInfo.depositTarget;
        wombatStakingPool.depositToken = wombatStakingPoolInfo.depositToken;
        wombatStakingPool.helper = wombatStakingPoolInfo.helper;
        wombatStakingPool.isActive = wombatStakingPoolInfo.isActive;
        wombatStakingPool.pid = wombatStakingPoolInfo.pid;
        wombatStakingPool.receiptToken = wombatStakingPoolInfo.receiptToken;
        wombatStakingPool.rewarder = wombatStakingPoolInfo.rewarder;
        wombatStakingPool.isPoolFeeFree = wombatStaking.isPoolFeeFree(lpToken);
        return wombatStakingPool;
    }

    function _addTokenRouteInteral(address tokenAddress, address [] memory paths, address[] memory pools) internal returns (TokenRouter memory tokenRouter) {
        if (tokenRouterMap[tokenAddress].token == address(0)) {
            tokenList.push(tokenAddress);
        }
        tokenRouter.token = tokenAddress;
        tokenRouter.symbol = ERC20(tokenAddress).symbol();
        tokenRouter.decimals = ERC20(tokenAddress).decimals();
        tokenRouter.paths = paths;
        tokenRouter.pools = pools;
    }

    /* ============ Admin Functions ============ */

    function addWombatPoolType(address poolAddress, string memory poolType) external onlyOwner  {
        wombatPoolType[poolAddress] = poolType;
    }

    function addTokenPancakeRouter(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = PancakeRouterType;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }
    function addTokenWombatRouter(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = WombatRouterType;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    function addUniswapV3Router(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = UniswapV3RouterType;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    function addTradeJoeV2Router(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = TraderJoeV2Type;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }        

    function addTokenChainlink(address tokenAddress, address [] memory paths, address[] memory pools, address priceAddress) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = ChainlinkType;
        tokenRouter.chainlink = priceAddress;
        tokenRouterMap[tokenAddress] = tokenRouter;
    }

    function setMagpieWombatPoolStatus(uint256 magpiePoolId, uint256 status) external onlyOwner  {
        wombatPoolStatus[magpiePoolId] = status;
    }

    // function reInit() external onlyOwner  {
    //     mWom = wombatStaking.mWom();
    //     wom = wombatStaking.wom();
    //     mgp = masterMagpie.mgp();
    //     vlmgp = masterMagpie.vlmgp();
    // }

    function setWombatRouter(address _wombatRouter) external onlyOwner  {
        wombatRouter = IWombatRouterReader(_wombatRouter);
    }

}