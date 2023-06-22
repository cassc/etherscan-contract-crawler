// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {ICamelotPair} from "./interfaces/uniswapV2/ICamelotPair.sol";
import {AggregatorV3Interface} from "./interfaces/chainlink/AggregatorV3Interface.sol";
import {IUniswapV3Pool} from "./interfaces/uniswapV3/IUniswapV3Pool.sol";
import {ICamelotRouter} from "./interfaces/uniswapV2/ICamelotRouter.sol";
import {ILBQuoter} from "./interfaces/traderjoeV2/ILBQuoter.sol";
import {IMasterPenpieReader} from "./interfaces/penpieReader/IMasterPenpieReader.sol";
import {IPendleStakingReader} from "./interfaces/penpieReader/IPendleStakingReader.sol";
import {IPenpieReceiptTokenReader} from "./interfaces/penpieReader/IPenpieReceiptTokenReader.sol";
import {IPendleMarketReader} from "./interfaces/penpieReader/IPendleMarketReader.sol";
import {IVLPenpieReader} from "./interfaces/penpieReader/IVLPenpieReader.sol";

/// @title MagpieReader for Arbitrum
/// @author Magpie Team

contract PenpieReader is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

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

    struct PenpieInfo {
        address masterPenpie;
        address pendleStaking;
        address vlPenpie;
        address penpieOFT;
        address mPendleOFT;
        address PENDLE;
        address WETH;
        address mPendleConvertor;
        uint256 autoBribeFee;
        PenpiePool[] pools;
    }

    struct PenpiePool {
        uint256 poolId;
        address stakingToken; // Address of staking token contract to be staked.
        address receiptToken; // Address of receipt token contract represent a staking position
        uint256 allocPoint; // How many allocation points assigned to this pool. Penpies to distribute per second.
        uint256 lastRewardTimestamp; // Last timestamp that Penpies distribution occurs.
        uint256 accPenpiePerShare; // Accumulated Penpies per share, times 1e12. See below.
        uint256 totalStaked;
        uint256 emission;
        uint256 allocpoint;
        uint256 sizeOfPool;
        uint256 totalPoint;
        address rewarder;
        bool    isActive;  
        bool isPendleMarket;
        string poolType;
        ERC20TokenInfo stakedTokenInfo;
        PendleMarket pendleMarket;
        PendleStakingPoolInfo pendleStakingPoolInfo;
        PenpieAccountInfo  accountInfo;
        PenpieRewardInfo rewardInfo;
        VlPenpieLockInfo vlPenpieLockInfo;
    }

    struct VlPenpieLockInfo {
        uint256 userTotalLocked;
        uint256 userAmountInCoolDown;
        VlPenpieUserUnlocking[] userUnlockingSchedule;
        uint256 totalPenalty;
        uint256 nextAvailableUnlockSlot;
        bool isFull;
    }

    struct VlPenpieUserUnlocking {
        uint256 startTime;
        uint256 endTime;
        uint256 amountInCoolDown; // total amount comitted to the unlock slot, never changes except when reseting slot
        uint256 expectedPenaltyAmount;
        uint256 amountToUser;
    }  

    struct PenpieRewardInfo {
        uint256 pendingPenpie;
        address[]  bonusTokenAddresses;
        string[]  bonusTokenSymbols;
        uint256[]  pendingBonusRewards;
    }

    struct PendleMarket {
       address marketAddress;
       ERC20TokenInfo SY;
       ERC20TokenInfo PT;
       ERC20TokenInfo YT;
    }

    struct PenpieAccountInfo {
        
        uint256 balance;
        uint256 stakedAmount;
        uint256 stakingAllowance;
        uint256 availableAmount;
        uint256 mPendleConvertAllowance;
        uint256 lockPenpieAllowance;
        uint256 pendleBalance;
        uint256 penpieBalance;
    }

    struct PendleStakingPoolInfo {
        address market;
        address rewarder;
        address helper;
        address receiptToken;
        uint256 lastHarvestTime;
        bool isActive;
        uint256 activeBalance;
        uint256 lpBalance;
    }

    struct ERC20TokenInfo {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    /* ============ State Variables ============ */

    mapping(address => TokenRouter) public tokenRouterMap;
    address[] public tokenList;

    uint256 constant CamelotRouterType = 1;
    uint256 constant WombatRouterType = 2;
    uint256 constant ChainlinkType = 3;
    uint256 constant UniswapV3RouterType = 4;
    uint256 constant TraderJoeV2Type = 5;
    
    address constant public TraderJoeV2LBQuoter = 0x7f281f22eDB332807A039073a7F34A4A215bE89e;
    ICamelotRouter constant public CamelotRouter = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IMasterPenpieReader public masterPenpie;
    IPendleStakingReader public pendleStaking;
    address public penpieOFT;
    address public vlPenpie;
    address public mPendleOFT;
    address public PENDLE;
    address public WETHToken;
    address public mPendleConvertor;
    address public Penpie;
    uint256 public autoBribeFee;

    /* ============ Events ============ */

    /* ============ Errors ============ */

    /* ============ Constructor ============ */

    function __PenpieReader_init() public initializer {
        __Ownable_init();
    }

    /* ============ External Getters ============ */

    // function getUSDTPrice() public view returns (uint256) {
    //     return getTokenPrice(USDT, address(0));
    // }

    // function getUSDCPrice() public view returns (uint256) {
    //     return getTokenPrice(USDC, address(0));
    // }    

    function getWETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    // just to make frontend happy
    function getETHPrice() public view returns (uint256) {
        return getTokenPrice(WETH, address(0));
    }

    function getTokenPrice(address token, address unitToken) public view returns (uint256) {
        TokenRouter memory tokenRouter = tokenRouterMap[token];
        uint256 amountOut = 0;
        if (tokenRouter.token != address(0)) {
           if (tokenRouter.routerType == CamelotRouterType) {
            uint256[] memory prices = CamelotRouter.getAmountsOut(10 ** tokenRouter.decimals , tokenRouter.paths);
            amountOut = prices[tokenRouter.paths.length - 1];
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
            amountOut = uint(sqrtPriceX96) * (uint(sqrtPriceX96)) * (1e18) >> (96 * 2);
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

    function getERC20TokenInfo(address token) public view returns (ERC20TokenInfo memory) {
        ERC20TokenInfo memory tokenInfo;
        tokenInfo.tokenAddress = token;
        ERC20 tokenContract = ERC20(token);
        tokenInfo.symbol = tokenContract.symbol();
        tokenInfo.decimals = tokenContract.decimals();
        return tokenInfo;
    }

    function getPenpieInfo(address account)  external view returns (PenpieInfo memory) {
        PenpieInfo memory info;
        uint256 poolCount = masterPenpie.poolLength();
        PenpiePool[] memory pools = new PenpiePool[](poolCount);
        for (uint256 i = 0; i < poolCount; ++i) {
           pools[i] = getPenpiePoolInfo(i, account);
        }
        info.pools = pools;
        info.masterPenpie = address(masterPenpie);
        info.pendleStaking = address(pendleStaking);
        info.penpieOFT = penpieOFT;
        info.vlPenpie = vlPenpie;
        info.mPendleOFT = mPendleOFT;
        info.PENDLE = PENDLE;
        info.WETH = WETHToken;
        info.mPendleConvertor = mPendleConvertor;
        info.autoBribeFee = autoBribeFee;
        return info;
    }

    function getPenpiePoolInfo(uint256 poolId, address account) public view returns (PenpiePool memory) {
        PenpiePool memory penpiePool;
        penpiePool.poolId = poolId;
        address registeredToken = masterPenpie.registeredToken(poolId);
        IMasterPenpieReader.PenpiePoolInfo memory penpiePoolInfo = masterPenpie.tokenToPoolInfo(registeredToken);
        penpiePool.stakingToken = penpiePoolInfo.stakingToken;
        penpiePool.allocPoint = penpiePoolInfo.allocPoint;
        penpiePool.lastRewardTimestamp = penpiePoolInfo.lastRewardTimestamp;
        penpiePool.accPenpiePerShare = penpiePoolInfo.accPenpiePerShare;
        penpiePool.totalStaked = penpiePoolInfo.totalStaked;
        penpiePool.rewarder = penpiePoolInfo.rewarder;
        penpiePool.isActive = penpiePoolInfo.isActive;
        penpiePool.receiptToken = penpiePoolInfo.receiptToken;
        (penpiePool.emission, penpiePool.allocpoint, penpiePool.sizeOfPool, penpiePool.totalPoint) = masterPenpie.getPoolInfo(penpiePool.stakingToken);
        if (penpiePool.stakingToken == vlPenpie) {
            penpiePool.poolType = "VLPENPIE_POOL";
            penpiePool.stakedTokenInfo = getERC20TokenInfo(penpiePool.stakingToken);
            penpiePool.vlPenpieLockInfo = getVlPenpieLockInfo(account);
        }
        else if (penpiePool.stakingToken == penpieOFT) {
            penpiePool.poolType = "PENPIEOFT_POOL";
            penpiePool.stakedTokenInfo = getERC20TokenInfo(penpiePool.stakingToken);
        }
        else if (penpiePool.stakingToken == mPendleOFT) {
            penpiePool.poolType = "MPENDLE_POOL";
            penpiePool.stakedTokenInfo = getERC20TokenInfo(penpiePool.stakingToken);
        }
        else if (penpiePool.stakingToken != penpiePool.receiptToken) {
            penpiePool.isPendleMarket = true;
        }
        if (penpiePool.isPendleMarket == true) {
            penpiePool.poolType = "PENDLE_MARKET";
            PendleMarket memory pendleMarket;
           // IPenpieReceiptTokenReader penpieReceiptTokenReader = IPenpieReceiptTokenReader(penpiePoolInfo.stakingToken);
            pendleMarket.marketAddress = penpiePoolInfo.stakingToken;
            IPendleMarketReader pendleMarketReader = IPendleMarketReader(pendleMarket.marketAddress);
            (address SY, address PT, address YT) = pendleMarketReader.readTokens();
            pendleMarket.SY = getERC20TokenInfo(SY);
            pendleMarket.PT = getERC20TokenInfo(PT);
            pendleMarket.YT = getERC20TokenInfo(YT);
            IPendleStakingReader.PendleStakingPoolInfo memory poolInfo = pendleStaking.pools(pendleMarket.marketAddress);
            PendleStakingPoolInfo memory pendleStakingPoolInfo;
            pendleStakingPoolInfo.helper = poolInfo.helper;
            pendleStakingPoolInfo.isActive = poolInfo.isActive;
            pendleStakingPoolInfo.market = poolInfo.market;
            pendleStakingPoolInfo.receiptToken = poolInfo.receiptToken;
            pendleStakingPoolInfo.rewarder = poolInfo.rewarder;
            pendleStakingPoolInfo.lastHarvestTime = poolInfo.lastHarvestTime;
            pendleStakingPoolInfo.activeBalance = pendleMarketReader.activeBalance(address(pendleStaking));
            pendleStakingPoolInfo.lpBalance = ERC20(pendleMarket.marketAddress).balanceOf(address(pendleStaking));
            penpiePool.pendleStakingPoolInfo = pendleStakingPoolInfo;
            penpiePool.pendleMarket = pendleMarket;
            penpiePool.stakedTokenInfo = getERC20TokenInfo(pendleMarket.marketAddress);
        }
    

        if (account != address(0)) {
            penpiePool.accountInfo = getPenpieAccountInfo(penpiePool, account);
            penpiePool.rewardInfo = getPenpieRewardInfo(penpiePool.stakingToken, account);
        }
        return penpiePool;
    }

    function getVlPenpieLockInfo(address account) public view returns (VlPenpieLockInfo memory) {
        VlPenpieLockInfo memory vlPenpieLockInfo;
        IVLPenpieReader vlPenpieReader = IVLPenpieReader(vlPenpie);
        vlPenpieLockInfo.totalPenalty = vlPenpieReader.totalPenalty();
        if (account != address(0)) {
            try vlPenpieReader.getNextAvailableUnlockSlot(account) returns (uint256 nextAvailableUnlockSlot) {
                vlPenpieLockInfo.isFull = false;
            }
            catch {
                vlPenpieLockInfo.isFull = true;
            }
            vlPenpieLockInfo.userAmountInCoolDown = vlPenpieReader.getUserAmountInCoolDown(account);
            vlPenpieLockInfo.userTotalLocked = vlPenpieReader.getUserTotalLocked(account);
            IVLPenpieReader.UserUnlocking[] memory userUnlockingList = vlPenpieReader.getUserUnlockingSchedule(account);
            VlPenpieUserUnlocking[] memory vlPenpieUserUnlockingList = new VlPenpieUserUnlocking[](userUnlockingList.length);
            for(uint256 i = 0; i < userUnlockingList.length; i++) {
                VlPenpieUserUnlocking memory vlPenpieUserUnlocking;
                IVLPenpieReader.UserUnlocking memory userUnlocking = userUnlockingList[i];
                vlPenpieUserUnlocking.startTime = userUnlocking.startTime;
                vlPenpieUserUnlocking.endTime = userUnlocking.endTime;
                vlPenpieUserUnlocking.amountInCoolDown = userUnlocking.amountInCoolDown;
                (uint256 penaltyAmount, uint256 amountToUser) = vlPenpieReader.expectedPenaltyAmountByAccount(account, i);
                vlPenpieUserUnlocking.expectedPenaltyAmount = penaltyAmount;
                vlPenpieUserUnlocking.amountToUser = amountToUser;
                vlPenpieUserUnlockingList[i] = vlPenpieUserUnlocking;
            }
            vlPenpieLockInfo.userUnlockingSchedule = vlPenpieUserUnlockingList;
        }
        return vlPenpieLockInfo;
    }


    function getPenpieAccountInfo(PenpiePool memory pool, address account) public view returns (PenpieAccountInfo memory) {
        PenpieAccountInfo memory accountInfo;
        if (pool.isPendleMarket) {
            accountInfo.balance = ERC20(pool.pendleMarket.marketAddress).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(pool.pendleMarket.marketAddress).allowance(account, address(pendleStaking));
            accountInfo.stakedAmount = ERC20(pool.pendleStakingPoolInfo.receiptToken).balanceOf(account);
        }
        else {
            accountInfo.balance = ERC20(pool.stakingToken).balanceOf(account);
            accountInfo.stakingAllowance = ERC20(pool.stakingToken).allowance(account, address(masterPenpie));
            (accountInfo.stakedAmount, accountInfo.availableAmount) = masterPenpie.stakingInfo(pool.stakingToken, account);
        }
        if (pool.stakingToken == mPendleOFT) {
            accountInfo.mPendleConvertAllowance = ERC20(PENDLE).allowance(account, mPendleConvertor);
            accountInfo.pendleBalance = ERC20(PENDLE).balanceOf(account);
        }
        if  (pool.stakingToken == vlPenpie) {
            accountInfo.lockPenpieAllowance = ERC20(penpieOFT).allowance(account, vlPenpie);
            accountInfo.penpieBalance = ERC20(penpieOFT).balanceOf(account);
        }
        
        return accountInfo;
    }

    function getPenpieRewardInfo(address stakingToken, address account) public view returns (PenpieRewardInfo memory) {
        PenpieRewardInfo memory rewardInfo;
        (rewardInfo.pendingPenpie, rewardInfo.bonusTokenAddresses, rewardInfo.bonusTokenSymbols, rewardInfo.pendingBonusRewards) = masterPenpie.allPendingTokens(stakingToken, account);
        return rewardInfo;
    }

  

    /* ============ Internal Functions ============ */

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

    function addTokenCamelotRouter(address tokenAddress, address [] memory paths, address[] memory pools) external onlyOwner  {
        TokenRouter memory tokenRouter = _addTokenRouteInteral(tokenAddress, paths, pools);
        tokenRouter.routerType = CamelotRouterType;
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

    function setMasterPenpie(IMasterPenpieReader _masterPenpie)  external onlyOwner  {
        masterPenpie = _masterPenpie;
        vlPenpie = masterPenpie.vlPenpie();
        penpieOFT = masterPenpie.penpieOFT();
    }

    function setPendleStaking(IPendleStakingReader _pendleStaking)  external onlyOwner  {
        pendleStaking = _pendleStaking;
        mPendleOFT = pendleStaking.mPendleOFT();
        PENDLE = pendleStaking.PENDLE();
        WETHToken = pendleStaking.WETH();
        mPendleConvertor = pendleStaking.mPendleConvertor();
        autoBribeFee = pendleStaking.autoBribeFee();
    }
}


//  const lockAllowance = await tokenContract.allowance(this.account, pool.locker);
      
//       const userTotalLocked: ethers.BigNumber = await lockerContract.getUserTotalLocked(this.account);
//       const startUnlock = userTotalLocked.sub(userTotalVotedInVlmgp);
//       const formatUserTotalLocked = formatEther(userTotalLocked);
      
//       const userAmountInCoolDown: ethers.BigNumber = await lockerContract.getUserAmountInCoolDown(this.account);
//       const formatUserAmountInCoolDown = formatEther(userAmountInCoolDown);
//       const yourLocking = userAmountInCoolDown.add(userTotalLocked);

//     //  const length = await lockerContract.getUserUnlockSlotLength(this.account);
//       const datas: LockItemInfo [] = [];
//       const blockNumber = await this.provider.getBlockNumber();
//       const block = await this.provider.getBlock(blockNumber);
//       const userUnlockingSchedule = await lockerContract.getUserUnlockingSchedule(this.account);
//       const totalPenalty = await lockerContract.totalPenalty();
//       const formatTotalPenalty = formatEther(totalPenalty);
//       const fixedFormatTotalPenalty = toSignificant(formatTotalPenalty);
//       let lastIndex = 0;
//       for (let i = 0; i < userUnlockingSchedule.length; i++) {
//         const item = userUnlockingSchedule[i]
      
//         let expectedPenaltyAmount = ethers.constants.Zero;
//         if (pool.type === "MAGPIE_VLMGP_POOL") {
//           const result = await lockerContract.expectedPenaltyAmount(i);
//           expectedPenaltyAmount = result.penaltyAmount;
//         }
//         const userGetAmount =  item.amountInCoolDown.sub(expectedPenaltyAmount);
//         if (!item.amountInCoolDown.isZero()) {
//           lastIndex = i;
//         }
//         datas.push({
//           unlockStartTime: item.startTime.toNumber(),
//           formatUnlockStartTime:  dayjs(item.startTime.toNumber() * 1000).format(
//             "YYYY/MM/DD"
//           ),
//           unlockEndTime: item.endTime.toNumber(),
//           formatUnlockEndTime:  dayjs(item.endTime.toNumber() * 1000).format(
//             "YYYY/MM/DD"
//           ),
//           coolDownAmount: item.amountInCoolDown,
//           formatCoolDownAmount: formatEther(item.amountInCoolDown),
//           fixedFormatCoolDownAmount: toSignificant(formatEther(item.amountInCoolDown)),
//           currentBlockTime: block.timestamp,
//           expectedPenaltyAmount,
//           formatExpectedPenaltyAmount: formatEther(expectedPenaltyAmount),
//           fixedFormatExpectedPenaltyAmount: toSignificant(formatEther(expectedPenaltyAmount)),
//           userGetAmount,
//           formatUserGetAmount: formatEther(userGetAmount),
//           fixedFormatUserGetAmount: toSignificant(formatEther(userGetAmount)),
//         });
//       }
//       let isFull = false;
//       try {
//         await lockerContract.getNextAvailableUnlockSlot(this.account)
//       }
//       catch(error) {
//         isFull = true;
//       }
//       return {
//         isFull,
//         lastSlotIndex: lastIndex,
//         userUnlockSlotLength: userUnlockingSchedule.length,
//         lockAllowance,
//         userTotalLocked,
//         formatUserTotalLocked,
//         fixedFormatUserTotalLocked: toSignificant(formatUserTotalLocked),
//         userAmountInCoolDown,
//         formatUserAmountInCoolDown,
//         fixedFormatUserAmountInCoolDown: toSignificant(formatUserAmountInCoolDown),
//         userLockList: datas,
//         totalPenalty,
//         formatTotalPenalty,
//         fixedFormatTotalPenalty,
//         startUnlock,
//         formatStartUnlock: formatEther(startUnlock),
//         fixedFormatStartUnlock: toSignificant(formatEther(startUnlock)),
//         yourLocking,
//         formatYourLocking: formatEther(yourLocking),
//         fixedFormatYourLocking: toSignificant(formatEther(yourLocking)),
//         userTotalVotedInVlmgp,
//         formatUserTotalVotedInVlmgp:  formatEther(userTotalVotedInVlmgp),
//         fixedFormatUserTotalVotedInVlmgp: toSignificant(formatEther(userTotalVotedInVlmgp))
//       };