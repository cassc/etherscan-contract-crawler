// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.10;


import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Address} from "Address.sol";

import "IUniswapRouterV2.sol";
import "IV3Pool.sol";
import "IV2Pool.sol";
import "IV3Quoter.sol";
import "IBalancerV2Vault.sol";
import "IBalancerV2WeightedPool.sol";
import "IBalancerV2StablePool.sol";
import "ICurveRouter.sol";
import "ICurvePool.sol";
import "IV3Simulator.sol";
import "IBalancerV2Simulator.sol";

enum SwapType { 
    CURVE, //0
    UNIV2, //1
    SUSHI, //2
    UNIV3, //3
    UNIV3WITHWETH, //4 
    BALANCER, //5
    BALANCERWITHWETH //6 
}

/// @title OnChainPricing
/// @author Alex the Entreprenerd for BadgerDAO
/// @author Camotelli @rayeaster
/// @dev Mainnet Version of Price Quoter, hardcoded for more efficiency
/// @notice To spin a variant, just change the constants and use the Component Functions at the end of the file
/// @notice Instead of upgrading in the future, just point to a new implementation
/// @notice TOC
/// UNIV2
/// UNIV3
/// BALANCER
/// CURVE
/// UTILS
/// 
contract OnChainPricingMainnet {
    using Address for address;
    
    // Assumption #1 Most tokens liquid pair is WETH (WETH is tokenized ETH for that chain)
    // e.g on Fantom, WETH would be wFTM
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// == Uni V2 Like Routers || These revert on non-existent pair == //
    // UniV2
    address public constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Spookyswap
    bytes public constant UNIV2_POOL_INITCODE = hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f";
    address public constant UNIV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // Sushi
    address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    bytes public constant SUSHI_POOL_INITCODE = hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303";
    address public constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    // Curve / Doesn't revert on failure
    address public constant CURVE_ROUTER = 0x8e764bE4288B842791989DB5b8ec067279829809; // Curve quote and swaps
		
    // UniV3 impl credit to https://github.com/1inch/spot-price-aggregator/blob/master/contracts/oracles/UniswapV3Oracle.sol
    address public constant UNIV3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    bytes32 public constant UNIV3_POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address public constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // BalancerV2 Vault
    address public constant BALANCERV2_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public constant BALANCERV2_NONEXIST_POOLID = "BALANCER-V2-NON-EXIST-POOLID";
    // selected Balancer V2 pools for given pairs on Ethereum with liquidity > $5M: https://dev.balancer.fi/references/subgraphs#examples
    bytes32 public constant BALANCERV2_WSTETH_WETH_POOLID = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    bytes32 public constant BALANCERV2_WBTC_WETH_POOLID = 0xa6f548df93de924d73be7d25dc02554c6bd66db500020000000000000000000e;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    bytes32 public constant BALANCERV2_USDC_WETH_POOLID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 public constant BALANCERV2_BAL_WETH_POOLID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    bytes32 public constant BALANCERV2_FEI_WETH_POOLID = 0x90291319f1d4ea3ad4db0dd8fe9e12baf749e84500020000000000000000013c;
    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    bytes32 public constant BALANCERV2_BADGER_WBTC_POOLID = 0xb460daa847c45f1c4a41cb05bfb3b51c92e41b36000200000000000000000194;
    address public constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
    bytes32 public constant BALANCERV2_GNO_WETH_POOLID = 0xf4c0dd9b82da36c07605df83c8a416f11724d88b000200000000000000000026;
    address public constant GNO = 0x6810e776880C02933D47DB1b9fc05908e5386b96;
    bytes32 public constant BALANCERV2_CREAM_WETH_POOLID = 0x85370d9e3bb111391cc89f6de344e801760461830002000000000000000001ef;
    address public constant CREAM = 0x2ba592F78dB6436527729929AAf6c908497cB200;	
    bytes32 public constant BALANCERV2_LDO_WETH_POOLID = 0xbf96189eee9357a95c7719f4f5047f76bde804e5000200000000000000000087;
    address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;	
    bytes32 public constant BALANCERV2_SRM_WETH_POOLID = 0x231e687c9961d3a27e6e266ac5c433ce4f8253e4000200000000000000000023;
    address public constant SRM = 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF;	
    bytes32 public constant BALANCERV2_rETH_WETH_POOLID = 0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112;
    address public constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;	
    bytes32 public constant BALANCERV2_AKITA_WETH_POOLID = 0xc065798f227b49c150bcdc6cdc43149a12c4d75700020000000000000000010b;
    address public constant AKITA = 0x3301Ee63Fb29F863f2333Bd4466acb46CD8323E6;	
    bytes32 public constant BALANCERV2_OHM_DAI_WETH_POOLID = 0xc45d42f801105e861e86658648e3678ad7aa70f900010000000000000000011e;
    address public constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    bytes32 public constant BALANCERV2_COW_WETH_POOLID = 0xde8c195aa41c11a0c4787372defbbddaa31306d2000200000000000000000181;
    bytes32 public constant BALANCERV2_COW_GNO_POOLID = 0x92762b42a06dcdddc5b7362cfb01e631c4d44b40000200000000000000000182;
    address public constant COW = 0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB;
    bytes32 public constant BALANCERV2_AURA_WETH_POOLID = 0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251;
    address public constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    bytes32 public constant BALANCERV2_AURABAL_BALWETH_POOLID = 0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249;
    
    address public constant GRAVIAURA = 0xBA485b556399123261a5F9c95d413B4f93107407;
    address public constant DIGG = 0x798D1bE841a82a273720CE31c822C61a67a601C3;
    bytes32 public constant BALANCERV2_AURABAL_GRAVIAURA_WETH_POOLID = 0x0578292cb20a443ba1cde459c985ce14ca2bdee5000100000000000000000269;
    bytes32 public constant BALANCER_V2_WBTC_DIGG_GRAVIAURA_POOLID = 0x8eb6c82c3081bbbd45dcac5afa631aac53478b7c000100000000000000000270;

    // NOTE: Not used due to possible migration： https://forum.balancer.fi/t/vulnerability-disclosure/3179
    bytes32 public constant BALANCERV2_DAI_USDC_USDT_POOLID = 0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000063;

    address public constant AURABAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
    address public constant BALWETHBPT = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    uint256 public constant CURVE_FEE_SCALE = 100000;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    /// @dev helper library to simulate Uniswap V3 swap
    address public immutable uniV3Simulator;
    /// @dev helper library to simulate Balancer V2 swap
    address public immutable balancerV2Simulator;


    /// UniV3, replaces an array
    /// @notice We keep above constructor, because this is a gas optimization
    ///     Saves storing fee ids in storage, saving 2.1k+ per call
    uint256 constant univ3_fees_length = 4;
    function univ3_fees(uint256 i) internal pure returns (uint24) {
        if(i == 0){
            return uint24(100);
        } else if (i == 1) {
            return uint24(500);
        } else if (i == 2) {
            return uint24(3000);
        } 
        // else if (i == 3) {
        return uint24(10000);
    }

    constructor(address _uniV3Simulator, address _balancerV2Simulator){
        uniV3Simulator = _uniV3Simulator;
        balancerV2Simulator = _balancerV2Simulator;
    }

    struct Quote {
        SwapType name;
        uint256 amountOut;
        bytes32[] pools; // specific pools involved in the optimal swap path
        uint256[] poolFees; // specific pool fees involved in the optimal swap path, typically in Uniswap V3
    }

    /// @dev Given tokenIn, out and amountIn, returns true if a quote will be non-zero
    /// @notice Doesn't guarantee optimality, just non-zero
    function isPairSupported(address tokenIn, address tokenOut, uint256 amountIn) external view returns (bool) {
        // Sorted by "assumed" reverse worst case
        // Go for higher gas cost checks assuming they are offering best precision / good price

        // If There's a Bal Pool, since we have to hardcode, then the price is probably non-zero
        bytes32 poolId = getBalancerV2Pool(tokenIn, tokenOut);
        if (poolId != BALANCERV2_NONEXIST_POOLID){
            return true;
        }

        // If no pool this is fairly cheap, else highly likely there's a price
        if(checkUniV3PoolsExistence(tokenIn, tokenOut)) {
            return true;
        }

        // Highly likely to have any random token here
        if(getUniPrice(UNIV2_ROUTER, tokenIn, tokenOut, amountIn) > 0) {
            return true;
        }

        // Otherwise it's probably on Sushi
        if(getUniPrice(SUSHI_ROUTER, tokenIn, tokenOut, amountIn) > 0) {
            return true;
        }

        // Curve at this time has great execution prices but low selection
        (, uint256 curveQuote) = getCurvePrice(CURVE_ROUTER, tokenIn, tokenOut, amountIn);
        if (curveQuote > 0){
            return true;
        }

        return false;
    }

    /// @dev External function, virtual so you can override, see Lenient Version
    /// @param tokenIn - The token you want to sell
    /// @param tokenOut - The token you want to buy
    /// @param amountIn - The amount of token you want to sell
    function findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) external view virtual returns (Quote memory) {
        return _findOptimalSwap(tokenIn, tokenOut, amountIn);
    }

    /// @dev View function for testing the routing of the strategy
    /// See {findOptimalSwap}
    function _findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) internal view returns (Quote memory) {
        bool wethInvolved = (tokenIn == WETH || tokenOut == WETH);
        uint256 length = wethInvolved? 5 : 7; // Add length you need

        Quote[] memory quotes = new Quote[](length);
        bytes32[] memory dummyPools;
        uint256[] memory dummyPoolFees;

        (address curvePool, uint256 curveQuote) = getCurvePrice(CURVE_ROUTER, tokenIn, tokenOut, amountIn);
        if (curveQuote > 0){		   
            (bytes32[] memory curvePools, uint256[] memory curvePoolFees) = _getCurveFees(curvePool);
            quotes[0] = Quote(SwapType.CURVE, curveQuote, curvePools, curvePoolFees);		
        } else {
            quotes[0] = Quote(SwapType.CURVE, curveQuote, dummyPools, dummyPoolFees);         			
        }

        quotes[1] = Quote(SwapType.UNIV2, getUniPrice(UNIV2_ROUTER, tokenIn, tokenOut, amountIn), dummyPools, dummyPoolFees);

        quotes[2] = Quote(SwapType.SUSHI, getUniPrice(SUSHI_ROUTER, tokenIn, tokenOut, amountIn), dummyPools, dummyPoolFees);

        quotes[3] = Quote(SwapType.UNIV3, getUniV3Price(tokenIn, amountIn, tokenOut), dummyPools, dummyPoolFees);

        quotes[4] = Quote(SwapType.BALANCER, getBalancerPriceAnalytically(tokenIn, amountIn, tokenOut), dummyPools, dummyPoolFees);

        if(!wethInvolved){
            quotes[5] = Quote(SwapType.UNIV3WITHWETH, (_useSinglePoolInUniV3(tokenIn, tokenOut) > 0 ? 0 : getUniV3PriceWithConnector(tokenIn, amountIn, tokenOut, WETH)), dummyPools, dummyPoolFees);	

            quotes[6] = Quote(SwapType.BALANCERWITHWETH, getBalancerPriceWithConnectorAnalytically(tokenIn, amountIn, tokenOut, WETH), dummyPools, dummyPoolFees);		
        }

        // Because this is a generalized contract, it is best to just loop,
        // Ideally we have a hierarchy for each chain to save some extra gas, but I think it's ok
        // O(n) complexity and each check is like 9 gas
        Quote memory bestQuote = quotes[0];
        unchecked {
            for(uint256 x = 1; x < length; ++x) {
                if(quotes[x].amountOut > bestQuote.amountOut) {
                    bestQuote = quotes[x];
                }
            }
        }


        return bestQuote;
    }    

    /// === Component Functions === /// 
    /// Why bother?
    /// Because each chain is slightly different but most use similar tech / forks
    /// May as well use the separate functoions so each OnChain Pricing on different chains will be slightly different
    /// But ultimately will work in the same way

    /// === UNIV2 === ///

    /// @dev Given the address of the UniV2Like Router, the input amount, and the path, returns the quote for it
    function getUniPrice(address router, address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
	
        // check pool existence first before quote against it
        bool _univ2 = (router == UNIV2_ROUTER);
        
        (address _pool, address _token0, ) = pairForUniV2((_univ2? UNIV2_FACTORY : SUSHI_FACTORY), tokenIn, tokenOut, (_univ2? UNIV2_POOL_INITCODE : SUSHI_POOL_INITCODE));
        if (!_pool.isContract()){
            return 0;
        }
		
        bool _zeroForOne = (_token0 == tokenIn);
        (uint256 _t0Balance, uint256 _t1Balance, ) = IUniswapV2Pool(_pool).getReserves();
        // Use dummy magic number as a quick-easy substitute for liquidity (to avoid one SLOAD) since we have pool reserve check in it
        bool _basicCheck = _checkPoolLiquidityAndBalances(1, (_zeroForOne? _t0Balance : _t1Balance), amountIn);
        return _basicCheck? getUniV2AmountOutAnalytically(amountIn, (_zeroForOne? _t0Balance : _t1Balance), (_zeroForOne? _t1Balance : _t0Balance)) : 0;
    }
	
    /// @dev reference https://etherscan.io/address/0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F#code#L122
    function getUniV2AmountOutAnalytically(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
	
    function pairForUniV2(address factory, address tokenA, address tokenB, bytes memory _initCode) public pure returns (address, address, address) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);		
        address pair = getAddressFromBytes32Lsb(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                _initCode // init code hash
        )));
        return (pair, token0, token1);
    }
	
    /// === UNIV3 === ///
	
    /// @dev explore Uniswap V3 pools to check if there is a chance to resolve the swap with in-range liquidity (i.e., without crossing ticks)
    /// @dev check helper UniV3SwapSimulator for more
    /// @return maximum output (with current in-range liquidity & spot price) and according pool fee
    function sortUniV3Pools(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256, uint24){
        uint256 _maxQuote;
        uint24 _maxQuoteFee;
		
        {
            // Heuristic: If we already know high TVL Pools, use those
            uint24 _bestFee = _useSinglePoolInUniV3(tokenIn, tokenOut);
            (address token0, address token1, bool token0Price) = _ifUniV3Token0Price(tokenIn, tokenOut);
			
            {
                if (_bestFee > 0) {
                    (,uint256 _bestOutAmt) = _checkSimulationInUniV3(token0, token1, amountIn, _bestFee, token0Price);
                    return (_bestOutAmt, _bestFee);
                }
            }
			
            (uint256 _maxQAmt, uint24 _maxQFee) = _simLoopAllUniV3Pools(token0, token1, amountIn, token0Price); 
            _maxQuote = _maxQAmt;
            _maxQuoteFee = _maxQFee;
        }
		
        return (_maxQuote, _maxQuoteFee);
    }	
	
    /// @dev loop over all possible Uniswap V3 pools to find a proper quote
    function _simLoopAllUniV3Pools(address token0, address token1, uint256 amountIn, bool token0Price) internal view returns (uint256, uint24) {		
        uint256 _maxQuote;
        uint24 _maxQuoteFee;
        uint256 feeTypes = univ3_fees_length;		
	
        for (uint256 i = 0; i < feeTypes;){
            uint24 _fee = univ3_fees(i);
                
            {			 
                // TODO: Partial rewrite to perform initial comparison against all simulations based on "liquidity in range"
                // If liq is in range, then lowest fee auto-wins
                // Else go down fee range with liq in range 
                // NOTE: A tick is like a ratio, so technically X ticks can offset a fee
                // Meaning we prob don't need full quote in majority of cases, but can compare number of ticks
                // per pool per fee and pre-rank based on that
                (, uint256 _outAmt) = _checkSimulationInUniV3(token0, token1, amountIn, _fee, token0Price);
                if (_outAmt > _maxQuote){
                    _maxQuote = _outAmt;
                    _maxQuoteFee = _fee;
                }
                unchecked { ++i; }	
            }
        }
		
        return (_maxQuote, _maxQuoteFee);		
    }
	
    /// @dev tell if there exists some Uniswap V3 pool for given token pair
    function checkUniV3PoolsExistence(address tokenIn, address tokenOut) public view returns (bool){
        uint256 feeTypes = univ3_fees_length;	
        (address token0, address token1, ) = _ifUniV3Token0Price(tokenIn, tokenOut);
        bool _exist;
        {    
          for (uint256 i = 0; i < feeTypes;){
             address _pool = _getUniV3PoolAddress(token0, token1, univ3_fees(i));
             if (_pool.isContract()) {
                 _exist = true;
                 break;
             }
             unchecked { ++i; }	
          }				 
        }	
        return _exist;		
    }
	
    /// @dev Uniswap V3 pool in-range liquidity check
    /// @return true if cross-ticks full simulation required for the swap otherwise false (in-range liquidity would satisfy the swap)
    function checkUniV3InRangeLiquidity(address token0, address token1, uint256 amountIn, uint24 _fee, bool token0Price, address _pool) public view returns (bool, uint256){
        {    
             if (!_pool.isContract()) {
                 return (false, 0);
             }
			 
             bool _basicCheck = _checkPoolLiquidityAndBalances(IUniswapV3Pool(_pool).liquidity(), IERC20(token0Price? token0 : token1).balanceOf(_pool), amountIn);
             if (!_basicCheck) {
                 return (false, 0);
             }
			 
             UniV3SortPoolQuery memory _sortQuery = UniV3SortPoolQuery(_pool, token0, token1, _fee, amountIn, token0Price);
            try IUniswapV3Simulator(uniV3Simulator).checkInRangeLiquidity(_sortQuery) returns (bool _crossTicks, uint256 _inRangeSimOut){
                 return (_crossTicks, _inRangeSimOut);
             } catch {
                 return (false, 0);			 
             }
        }
    }
	
    /// @dev internal function to avoid stack too deep for 1) check in-range liquidity in Uniswap V3 pool 2) full cross-ticks simulation in Uniswap V3
    function _checkSimulationInUniV3(address token0, address token1, uint256 amountIn, uint24 _fee, bool token0Price) internal view returns (bool, uint256) {
        bool _crossTick;
        uint256 _outAmt;
        
        address _pool = _getUniV3PoolAddress(token0, token1, _fee);		
        {
             // in-range swap check: find out whether the swap within current liquidity would move the price across next tick
             (bool _outOfInRange, uint256 _outputAmount) = checkUniV3InRangeLiquidity(token0, token1, amountIn, _fee, token0Price, _pool);
             _crossTick = _outOfInRange;
             _outAmt = _outputAmount;
        }
        {
             // unfortunately we need to do a full simulation to cross ticks
             if (_crossTick){
                 _outAmt = simulateUniV3Swap(token0, amountIn, token1, _fee, token0Price, _pool);
             } 
        }
        return (_crossTick, _outAmt);
    }
	
    /// @dev internal function for a basic sanity check pool existence and balances
    /// @return true if basic check pass otherwise false
    function _checkPoolLiquidityAndBalances(uint256 _liq, uint256 _reserveIn, uint256 amountIn) internal pure returns (bool) {
	    
        {
             // heuristic check0: ensure the pool initiated with valid liquidity in place
             if (_liq == 0) {
                 return false;
             }
        }
		
        {
            // TODO: In a later check, we check slot0 liquidity
            // Is there any change that slot0 gives us more information about the liquidity in range,
            // Such that optimistically it would immediately allow us to determine a winning pool?
            // Prob winning pool would be: Lowest Fee, with Liquidity covered within the tick
		
             // heuristic check1: ensure the pool tokenIn reserve makes sense in terms of [amountIn], i.e., the pool is liquid compared to swap amount
             // say if the pool got 100 tokenA, and you tried to swap another 100 tokenA into it for the other token, 
             // by the math of AMM, this will drastically imbalance the pool, so the quote won't be good for sure
             return _reserveIn > amountIn;
        }		
    }
	
    /// @dev simulate Uniswap V3 swap using its tick-based math for given parameters
    /// @dev check helper UniV3SwapSimulator for more
    function simulateUniV3Swap(address token0, uint256 amountIn, address token1, uint24 _fee, bool token0Price, address _pool) public view returns (uint256) {
        try IUniswapV3Simulator(uniV3Simulator).simulateUniV3Swap(_pool, token0, token1, token0Price, _fee, amountIn) returns (uint256 _simOut) {
             return _simOut;
        } catch {
             return 0;			
        }
    }	
	
    /// @dev Given the address of the input token & amount & the output token
    /// @return the quote for it
    function getUniV3Price(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256) {		
        (uint256 _maxInRangeQuote, ) = sortUniV3Pools(tokenIn, amountIn, tokenOut);		
        return _maxInRangeQuote;
    }
	
    /// @dev Given the address of the input token & amount & the output token & connector token in between (input token ---> connector token ---> output token)
    /// @return the quote for it
    function getUniV3PriceWithConnector(address tokenIn, uint256 amountIn, address tokenOut, address connectorToken) public view returns (uint256) {
        // Skip if there is a mainstrem direct swap or connector pools not exist
        if (!checkUniV3PoolsExistence(tokenIn, connectorToken) || !checkUniV3PoolsExistence(connectorToken, tokenOut)){
            return 0;
        }
		
        uint256 connectorAmount = getUniV3Price(tokenIn, amountIn, connectorToken);	
        if (connectorAmount > 0){	
            return getUniV3Price(connectorToken, connectorAmount, tokenOut);
        } else{
            return 0;
        }
    }
	
    /// @dev return token0 & token1 and if token0 equals tokenIn
    function _ifUniV3Token0Price(address tokenIn, address tokenOut) internal pure returns (address, address, bool){
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        return (token0, token1, token0 == tokenIn);
    }
	
    /// @dev query with the address of the token0 & token1 & the fee tier
    /// @return the uniswap v3 pool address
    function _getUniV3PoolAddress(address token0, address token1, uint24 fee) internal pure returns (address) {
        bytes32 addr = keccak256(abi.encodePacked(hex"ff", UNIV3_FACTORY, keccak256(abi.encode(token0, token1, fee)), UNIV3_POOL_INIT_CODE_HASH));
        return address(uint160(uint256(addr)));
    }
	
    /// @dev selected token pair which will try a chosen Uniswap V3 pool ONLY among all possible fees
    /// @dev picked from most traded pool (Volume 7D) in https://info.uniswap.org/#/pools
    /// @dev mainly 5 most-popular tokens WETH-WBTC-USDC-USDT-DAI (Volume 24H) https://info.uniswap.org/#/tokens
    /// @return 0 if all possible fees should be checked otherwise the ONLY pool fee we should go for
    function _useSinglePoolInUniV3(address tokenIn, address tokenOut) internal pure returns(uint24) {
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        if (token1 == WETH && (token0 == USDC || token0 == WBTC || token0 == DAI)) {
            return 500;
        } else if (token0 == WETH && token1 == USDT) {
            return 500;
        } else if (token1 == USDC && token0 == DAI) {
            return 100;
        } else if (token0 == USDC && token1 == USDT) {
            return 100;
        } else if (token1 == USDC && token0 == WBTC) {
            return 3000;
        } else {
            return 0;
        }
    }	

    /// === BALANCER === ///
	
    /// @dev Given the input/output token, returns the quote for input amount from Balancer V2 using its underlying math
    function getBalancerPriceAnalytically(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256) { 
        bytes32 poolId = getBalancerV2Pool(tokenIn, tokenOut);
        if (poolId == BALANCERV2_NONEXIST_POOLID){
            return 0;
        }
        return getBalancerQuoteWithinPoolAnalytcially(poolId, tokenIn, amountIn, tokenOut);
    }
	
    function getBalancerQuoteWithinPoolAnalytcially(bytes32 poolId, address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256) {			
        uint256 _quote;		
        address _pool = getAddressFromBytes32Msb(poolId);
        
        {
            (address[] memory tokens, uint256[] memory balances, ) = IBalancerV2Vault(BALANCERV2_VAULT).getPoolTokens(poolId);
			
            uint256 _inTokenIdx = _findTokenInBalancePool(tokenIn, tokens);
            require(_inTokenIdx < tokens.length, "!inBAL");
            uint256 _outTokenIdx = _findTokenInBalancePool(tokenOut, tokens);
            require(_outTokenIdx < tokens.length, "!outBAL");
			 
            if(balances[_inTokenIdx] <= amountIn) return 0;
		
            /// Balancer math for spot price of tokenIn -> tokenOut: weighted value(number * price) relation should be kept
            try IBalancerV2StablePool(_pool).getAmplificationParameter() returns (uint256 currentAmp, bool, uint256) {
                // stable pool math
                {
                   ExactInStableQueryParam memory _stableQuery = ExactInStableQueryParam(tokens, balances, currentAmp, _inTokenIdx, _outTokenIdx, amountIn, IBalancerV2StablePool(_pool).getSwapFeePercentage());

                    try IBalancerV2Simulator(balancerV2Simulator).calcOutGivenInForStable(_stableQuery) returns (uint256 balQuote) {
                        _quote = balQuote;
                    } catch  {
                        _quote = 0;
                    }    

                }
            } catch {
                // weighted pool math
                {
                   uint256[] memory _weights = IBalancerV2WeightedPool(_pool).getNormalizedWeights();
                   require(_weights.length == tokens.length, "!lenBAL");
                   ExactInQueryParam memory _query = ExactInQueryParam(tokenIn, tokenOut, balances[_inTokenIdx], _weights[_inTokenIdx], balances[_outTokenIdx], _weights[_outTokenIdx], amountIn, IBalancerV2WeightedPool(_pool).getSwapFeePercentage());

                    try IBalancerV2Simulator(balancerV2Simulator).calcOutGivenIn(_query) returns (uint256 balQuote) {
                        _quote = balQuote;
                    } catch {
                        _quote = 0;
                    }
                }
            }
        }
		
        return _quote;
    }
	
    function _findTokenInBalancePool(address _token, address[] memory _tokens) internal pure returns (uint256){	    
        uint256 _len = _tokens.length;
        for (uint256 i = 0; i < _len; ){
            if (_tokens[i] == _token){
                return i;
            }
            unchecked{ ++i; }
        } 
        return type(uint256).max;
    }
	
    /// @dev Given the input/output/connector token, returns the quote for input amount from Balancer V2 using its underlying math
    function getBalancerPriceWithConnectorAnalytically(address tokenIn, uint256 amountIn, address tokenOut, address connectorToken) public view returns (uint256) { 
        if (getBalancerV2Pool(tokenIn, connectorToken) == BALANCERV2_NONEXIST_POOLID || getBalancerV2Pool(connectorToken, tokenOut) == BALANCERV2_NONEXIST_POOLID){
            return 0;
        }
		
        uint256 _in2ConnectorAmt = getBalancerPriceAnalytically(tokenIn, amountIn, connectorToken);
        if (_in2ConnectorAmt <= 0){
            return 0;
        }
        return getBalancerPriceAnalytically(connectorToken, _in2ConnectorAmt, tokenOut);    
    }
	
    /// @return selected BalancerV2 pool given the tokenIn and tokenOut 
    function getBalancerV2Pool(address tokenIn, address tokenOut) public pure returns(bytes32){
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        if (token0 == CREAM && token1 == WETH){
            return BALANCERV2_CREAM_WETH_POOLID;
        } else if (token0 == GNO && token1 == WETH){
            return BALANCERV2_GNO_WETH_POOLID;
        } else if (token0 == WBTC && token1 == BADGER){
            return BALANCERV2_BADGER_WBTC_POOLID;
        } else if (token0 == FEI && token1 == WETH){
            return BALANCERV2_FEI_WETH_POOLID;
        } else if (token0 == BAL && token1 == WETH){
            return BALANCERV2_BAL_WETH_POOLID;
        } else if (token0 == USDC && token1 == WETH){
            return BALANCERV2_USDC_WETH_POOLID;
        } else if (token0 == WBTC && token1 == WETH){
            return BALANCERV2_WBTC_WETH_POOLID;
        } else if (token0 == WSTETH && token1 == WETH){
            return BALANCERV2_WSTETH_WETH_POOLID;
        } else if (token0 == LDO && token1 == WETH){
            return BALANCERV2_LDO_WETH_POOLID;
        } else if (token0 == SRM && token1 == WETH){
            return BALANCERV2_SRM_WETH_POOLID;
        } else if (token0 == rETH && token1 == WETH){
            return BALANCERV2_rETH_WETH_POOLID;
        } else if (token0 == AKITA && token1 == WETH){
            return BALANCERV2_AKITA_WETH_POOLID;
        } else if ((token0 == OHM && token1 == WETH) || (token0 == OHM && token1 == DAI)){
            return BALANCERV2_OHM_DAI_WETH_POOLID;
        } else if (token0 == GNO && token1 == COW){
            return BALANCERV2_COW_GNO_POOLID;
        } else if (token0 == WETH && token1 == COW){
            return BALANCERV2_COW_WETH_POOLID;
        } else if (token0 == WETH && token1 == AURA){
            return BALANCERV2_AURA_WETH_POOLID;
        } else if (token0 == BALWETHBPT && token1 == AURABAL){
            return BALANCERV2_AURABAL_BALWETH_POOLID;
        } else if (token0 == AURABAL && token1 == WETH){
            return BALANCERV2_AURABAL_GRAVIAURA_WETH_POOLID;
        } else if (token0 == GRAVIAURA && token1 == WETH){
            return BALANCERV2_AURABAL_GRAVIAURA_WETH_POOLID;
        } else if (token0 == WBTC && token1 == DIGG){
            return BALANCER_V2_WBTC_DIGG_GRAVIAURA_POOLID;
        } else if (token0 == DIGG && token1 == GRAVIAURA){
            return BALANCER_V2_WBTC_DIGG_GRAVIAURA_POOLID;
        
        } else{
            return BALANCERV2_NONEXIST_POOLID;
        }		
    }

    /// === CURVE === ///

    /// @dev Given the address of the CurveLike Router, the input amount, and the path, returns the quote for it
    function getCurvePrice(address router, address tokenIn, address tokenOut, uint256 amountIn) public view returns (address, uint256) {
        try ICurveRouter(router).get_best_rate(tokenIn, tokenOut, amountIn) returns (address pool, uint256 curveQuote) {
            return (pool, curveQuote);
        } catch {
            return (address(0), 0);
        }
    }
	
    /// @return assembled curve pools and fees in required Quote struct for given pool
    // TODO: Decide if we need fees, as it costs more gas to compute
    function _getCurveFees(address _pool) internal view returns (bytes32[] memory, uint256[] memory){	
        bytes32[] memory curvePools = new bytes32[](1);
        curvePools[0] = convertToBytes32(_pool);
        uint256[] memory curvePoolFees = new uint256[](1);
        curvePoolFees[0] = ICurvePool(_pool).fee() * CURVE_FEE_SCALE / 1e10;//https://curve.readthedocs.io/factory-pools.html?highlight=fee#StableSwap.fee
        return (curvePools, curvePoolFees);
    }

    /// === UTILS === ///

    /// @dev Given a address input, return the bytes32 representation
    // TODO: Figure out if abi.encode is better -> Benchmark on GasLab
    function convertToBytes32(address _input) public pure returns (bytes32){
        return bytes32(uint256(uint160(_input)) << 96);
    }
	
    /// @dev Take for example the _input "0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC"
    /// @return the result of "0x111122223333444455556666777788889999aAaa"
    function getAddressFromBytes32Msb(bytes32 _input) public pure returns (address){
        return address(uint160(bytes20(_input)));
    }
	
    /// @dev Take for example the _input "0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC"
    /// @return the result of "0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc"
    function getAddressFromBytes32Lsb(bytes32 _input) public pure returns (address){
        return address(uint160(uint256(_input)));
    }
}