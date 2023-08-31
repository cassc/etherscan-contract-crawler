/**
 *Submitted for verification at Etherscan.io on 2021-01-20
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IValueLiquidFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

    function feeTo() external view returns (address);

    function formula() external view returns (address);

    function protocolFee() external view returns (uint256);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function isPair(address) external view returns (bool);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external returns (address pair);

    function getWeightsAndSwapFee(address pair)
        external
        view
        returns (
            uint32 tokenWeight0,
            uint32 tokenWeight1,
            uint32 swapFee
        );

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setProtocolFee(uint256) external;
}

/*
    Bancor Formula interface
*/
interface IValueLiquidFormula {
    function getReserveAndWeights(address pair, address tokenA)
        external
        view
        returns (
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint32 tokenWeightA,
            uint32 tokenWeightB,
            uint32 swapFee
        );

    function getFactoryReserveAndWeights(
        address factory,
        address pair,
        address tokenA
    )
        external
        view
        returns (
            address tokenB,
            uint256 reserveA,
            uint256 reserveB,
            uint32 tokenWeightA,
            uint32 tokenWeightB,
            uint32 swapFee
        );

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountIn);

    function getPairAmountIn(
        address pair,
        address tokenIn,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 tokenWeightIn,
        uint32 tokenWeightOut,
        uint32 swapFee
    ) external view returns (uint256 amountOut);

    function getPairAmountOut(
        address pair,
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getAmountsIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getFactoryAmountsIn(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getFactoryAmountsOut(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function ensureConstantValue(
        uint256 reserve0,
        uint256 reserve1,
        uint256 balance0Adjusted,
        uint256 balance1Adjusted,
        uint32 tokenWeight0
    ) external view returns (bool);

    function getReserves(
        address pair,
        address tokenA,
        address tokenB
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function getOtherToken(address pair, address tokenA) external view returns (address tokenB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    function mintLiquidityFee(
        uint256 totalLiquidity,
        uint112 reserve0,
        uint112 reserve1,
        uint32 tokenWeight0,
        uint32 tokenWeight1,
        uint112 collectedFee0,
        uint112 collectedFee1
    ) external view returns (uint256 amount);
}

interface IValueLiquidPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

interface IStakePool {
    event Deposit(address indexed account, uint256 amount);
    event AddRewardPool(uint256 indexed poolId);
    event UpdateRewardPool(uint256 indexed poolId, uint256 endRewardBlock, uint256 rewardPerBlock);
    event PayRewardPool(
        uint256 indexed poolId,
        address indexed rewardToken,
        address indexed account,
        uint256 pendingReward,
        uint256 rebaseAmount,
        uint256 paidReward
    );
    event UpdateRewardRebaser(uint256 indexed poolId, address rewardRebaser);
    event UpdateRewardMultiplier(uint256 indexed poolId, address rewardMultiplier);
    event Withdraw(address indexed account, uint256 amount);

    function version() external returns (uint256);

    function pair() external returns (address);

    function initialize(
        address _pair,
        uint256 _unstakingFrozenTime,
        address _rewardFund,
        address _timelock
    ) external;

    function stake(uint256) external;

    function stakeFor(address _account) external;

    function withdraw(uint256) external;

    function getReward(uint8 _pid, address _account) external;

    function getAllRewards(address _account) external;

    function pendingReward(uint8 _pid, address _account) external view returns (uint256);

    function getEndRewardBlock(uint8 _pid) external view returns (address, uint256);

    function getRewardPerBlock(uint8 pid) external view returns (uint256);

    function rewardPoolInfoLength() external view returns (uint256);

    function unfrozenStakeTime(address _account) external view returns (uint256);

    function emergencyWithdraw() external;

    function updateReward() external;

    function updateReward(uint8 _pid) external;

    function updateRewardPool(
        uint8 _pid,
        uint256 _endRewardBlock,
        uint256 _rewardPerBlock
    ) external;

    function getRewardMultiplier(
        uint8 _pid,
        uint256 _from,
        uint256 _to,
        uint256 _rewardPerBlock
    ) external view returns (uint256);

    function getRewardRebase(
        uint8 _pid,
        address _rewardToken,
        uint256 _pendingReward
    ) external view returns (uint256);

    function updateRewardRebaser(uint8 _pid, address _rewardRebaser) external;

    function updateRewardMultiplier(uint8 _pid, address _rewardMultiplier) external;

    function getUserInfo(uint8 _pid, address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256 accumulatedEarned,
            uint256 lockReward,
            uint256 lockRewardReleased
        );

    function addRewardPool(
        address _rewardToken,
        address _rewardRebaser,
        address _rewardMultiplier,
        uint256 _startBlock,
        uint256 _endRewardBlock,
        uint256 _rewardPerBlock,
        uint256 _lockRewardPercent,
        uint256 _startVestingBlock,
        uint256 _endVestingBlock
    ) external;

    function removeLiquidity(
        address provider,
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address provider,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address provider,
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

interface IValueLiquidRouter {
    struct Swap {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount; // tokenInAmount / tokenOutAmount
        uint256 limitReturnAmount; // minAmountOut / maxAmountIn
        uint256 maxPrice;
        bool isBPool;
    }

    function factory() external view returns (address);

    function controller() external view returns (address);

    function formula() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        address tokenOut,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external;

    function addStakeLiquidity(
        address stakePool,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addStakeLiquidityETH(
        address stakePool,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256 totalAmountOut);

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline,
        uint8 flag
    ) external payable returns (uint256 totalAmountIn);
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "ds-math-division-by-zero");
        c = a / b;
    }
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IBPool is IERC20 {
    function version() external view returns (uint256);

    function swapExactAmountIn(
        address,
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256, uint256);

    function swapExactAmountOut(
        address,
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256, uint256);

    function calcInGivenOut(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256);

    function calcOutGivenIn(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256);

    function getDenormalizedWeight(address) external view returns (uint256);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 _swapFee) external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function finalize(
        uint256 _swapFee,
        uint256 _initPoolSupply,
        address[] calldata _bindTokens,
        uint256[] calldata _bindDenorms
    ) external;

    function setPublicSwap(bool _publicSwap) external;

    function setController(address _controller) external;

    function setExchangeProxy(address _exchangeProxy) external;

    function getFinalTokens() external view returns (address[] memory tokens);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function joinPoolFor(
        address account,
        uint256 rewardAmountOut,
        uint256[] calldata maxAmountsIn
    ) external;

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function finalizeRewardFundInfo(address _rewardFund, uint256 _unstakingFrozenTime) external;

    function addRewardPool(
        IERC20 _rewardToken,
        uint256 _startBlock,
        uint256 _endRewardBlock,
        uint256 _rewardPerBlock,
        uint256 _lockRewardPercent,
        uint256 _startVestingBlock,
        uint256 _endVestingBlock
    ) external;

    function isBound(address t) external view returns (bool);

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface IStakePoolController {
    event MasterCreated(address indexed farm, address indexed pair, uint256 version, address timelock, address stakePoolRewardFund, uint256 totalStakePool);
    event SetWhitelistStakingFor(address indexed contractAddress, bool value);
    event SetWhitelistStakePool(address indexed contractAddress, int8 value);
    event SetStakePoolCreator(address indexed contractAddress, uint256 verion);
    event SetWhitelistRewardRebaser(address indexed contractAddress, bool value);
    event SetWhitelistRewardMultiplier(address indexed contractAddress, bool value);
    event SetStakePoolVerifier(address indexed contractAddress, bool value);
    event ChangeGovernance(address indexed governance);
    event SetFeeCollector(address indexed feeCollector);
    event SetFeeToken(address indexed token);
    event SetFeeAmount(uint256 indexed amount);

    struct PoolRewardInfo {
        address rewardToken;
        address rewardRebaser;
        address rewardMultiplier;
        uint256 startBlock;
        uint256 endRewardBlock;
        uint256 rewardPerBlock;
        uint256 lockRewardPercent;
        uint256 startVestingBlock;
        uint256 endVestingBlock;
        uint256 unstakingFrozenTime;
        uint256 rewardFundAmount;
    }

    function allStakePools(uint256) external view returns (address stakePool);

    function isStakePool(address contractAddress) external view returns (bool);

    function isStakePoolVerifier(address contractAddress) external view returns (bool);

    function isWhitelistStakingFor(address contractAddress) external view returns (bool);

    function isWhitelistStakePool(address contractAddress) external view returns (int8);

    function setStakePoolVerifier(address contractAddress, bool state) external;

    function setWhitelistStakingFor(address contractAddress, bool state) external;

    function setWhitelistStakePool(address contractAddress, int8 state) external;

    function addStakePoolCreator(address contractAddress) external;

    function isWhitelistRewardRebaser(address contractAddress) external view returns (bool);

    function setWhitelistRewardRebaser(address contractAddress, bool state) external;

    function isWhitelistRewardMultiplier(address contractAddress) external view returns (bool);

    function setWhitelistRewardMultiplier(address contractAddress, bool state) external;

    function allStakePoolsLength() external view returns (uint256);

    function create(
        uint256 version,
        address pair,
        uint256 delayTimeLock,
        PoolRewardInfo calldata poolRewardInfo,
        uint8 flag
    ) external returns (address);

    function createPair(
        uint256 version,
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee,
        uint256 delayTimeLock,
        PoolRewardInfo calldata poolRewardInfo,
        uint8 flag
    ) external returns (address);

    function setGovernance(address) external;

    function setFeeCollector(address _address) external;

    function setFeeToken(address _token) external;

    function setFeeAmount(uint256 _token) external;
}

contract ValueLiquidRouter is IValueLiquidRouter {
    using SafeMath for uint256;
    address public immutable override factory;
    address public immutable override controller;
    address public immutable override formula;
    address public immutable override WETH;
    address private constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }
    modifier discountCHI(uint8 flag) {
        uint256 gasStart = gasleft();
        _;
        if ((flag & 0x1) == 1) {
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        }
    }

    constructor(
        address _factory,
        address _controller,
        address _WETH
    ) {
        factory = _factory;
        controller = _controller;
        formula = IValueLiquidFactory(_factory).formula();
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        require(IValueLiquidFactory(factory).isPair(pair), "Router: Invalid pair");
        (uint256 reserveA, uint256 reserveB) = IValueLiquidFormula(formula).getReserves(pair, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = IValueLiquidFormula(formula).quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = IValueLiquidFormula(formula).quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function _addLiquidityToken(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = _addLiquidity(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    }

    function addLiquidity(
        address pair,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidityToken(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        liquidity = IValueLiquidPair(pair).mint(to);
    }

    function addStakeLiquidity(
        address stakePool,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        require(IStakePoolController(controller).isStakePool(stakePool), "Router: Invalid stakePool");
        address pair = IStakePool(stakePool).pair();
        (amountA, amountB) = _addLiquidityToken(pair, tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        liquidity = IValueLiquidPair(pair).mint(stakePool);
        IStakePool(stakePool).stakeFor(msg.sender);
    }

    function addStakeLiquidityETH(
        address stakePool,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        require(IStakePoolController(controller).isStakePool(stakePool), "Router: Invalid stakePool");
        (amountToken, amountETH, liquidity) = _addLiquidityETH(
            IStakePool(stakePool).pair(),
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            stakePool
        );
        IStakePool(stakePool).stakeFor(msg.sender);
    }

    function _addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to
    )
        internal
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(pair, token, WETH, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        transferETHTo(amountETH, pair);
        liquidity = IValueLiquidPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function addLiquidityETH(
        address pair,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        public
        payable
        virtual
        override
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH, liquidity) = _addLiquidityETH(pair, token, amountTokenDesired, amountTokenMin, amountETHMin, to);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        address tokenIn,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        address input = tokenIn;
        for (uint256 i = 0; i < path.length; i++) {
            IValueLiquidPair pairV2 = IValueLiquidPair(path[i]);
            address token0 = pairV2.token0();
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out, address output) =
                input == token0 ? (uint256(0), amountOut, pairV2.token1()) : (amountOut, uint256(0), token0);
            address to = i < path.length - 1 ? path[i + 1] : _to;
            pairV2.swap(amount0Out, amount1Out, to, new bytes(0));
            input = output;
        }
    }

    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline,
        uint8 flag
    ) public virtual override discountCHI(flag) ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IValueLiquidFormula(formula).getFactoryAmountsOut(factory, tokenIn, tokenOut, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");

        TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
        _swap(tokenIn, amounts, path, to);
    }

    function swapTokensForExactTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external virtual override discountCHI(flag) ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IValueLiquidFormula(formula).getFactoryAmountsIn(factory, tokenIn, tokenOut, amountOut, path);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
        _swap(tokenIn, amounts, path, to);
    }

    function swapExactETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable virtual override discountCHI(flag) ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IValueLiquidFormula(formula).getFactoryAmountsOut(factory, WETH, tokenOut, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        transferETHTo(amounts[0], path[0]);
        _swap(WETH, amounts, path, to);
    }

    function swapTokensForExactETH(
        address tokenIn,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external virtual override discountCHI(flag) ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IValueLiquidFormula(formula).getFactoryAmountsIn(factory, tokenIn, WETH, amountOut, path);
        require(amounts[0] <= amountInMax, "Router: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
        _swap(tokenIn, amounts, path, address(this));
        transferAll(ETH_ADDRESS, to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external virtual override discountCHI(flag) ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IValueLiquidFormula(formula).getFactoryAmountsOut(factory, tokenIn, WETH, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amounts[0]);
        _swap(tokenIn, amounts, path, address(this));
        transferAll(ETH_ADDRESS, to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokens(
        address tokenOut,
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable virtual override discountCHI(flag) ensure(deadline) returns (uint256[] memory amounts) {
        amounts = IValueLiquidFormula(formula).getFactoryAmountsIn(factory, WETH, tokenOut, amountOut, path);
        require(amounts[0] <= msg.value, "Router: EXCESSIVE_INPUT_AMOUNT");
        transferETHTo(amounts[0], path[0]);
        _swap(WETH, amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(
        address tokenIn,
        address[] memory path,
        address _to
    ) internal virtual {
        address input = tokenIn;
        for (uint256 i; i < path.length; i++) {
            IValueLiquidPair pair = IValueLiquidPair(path[i]);

            uint256 amountInput;
            uint256 amountOutput;
            address currentOutput;
            {
                (address output, uint256 reserveInput, uint256 reserveOutput, uint32 tokenWeightInput, uint32 tokenWeightOutput, uint32 swapFee) =
                    IValueLiquidFormula(formula).getFactoryReserveAndWeights(factory, address(pair), input);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = IValueLiquidFormula(formula).getAmountOut(
                    amountInput,
                    reserveInput,
                    reserveOutput,
                    tokenWeightInput,
                    tokenWeightOutput,
                    swapFee
                );
                currentOutput = output;
            }
            (uint256 amount0Out, uint256 amount1Out) = input == pair.token0() ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
            address to = i < path.length - 1 ? path[i + 1] : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
            input = currentOutput;
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external virtual override discountCHI(flag) ensure(deadline) {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amountIn);
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(tokenIn, path, to);
        require(IERC20(tokenOut).balanceOf(to).sub(balanceBefore) >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        address tokenOut,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external payable virtual override discountCHI(flag) ensure(deadline) {
        //            require(path[0] == WETH, 'Router: INVALID_PATH');
        uint256 amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(path[0], amountIn));
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(WETH, path, to);
        require(IERC20(tokenOut).balanceOf(to).sub(balanceBefore) >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint8 flag
    ) external virtual override discountCHI(flag) ensure(deadline) {
        TransferHelper.safeTransferFrom(tokenIn, msg.sender, path[0], amountIn);
        _swapSupportingFeeOnTransferTokens(tokenIn, path, address(this));
        uint256 amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        transferAll(ETH_ADDRESS, to, amountOut);
    }

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountIn,
        uint256 minTotalAmountOut,
        uint256 deadline,
        uint8 flag
    ) public payable virtual override discountCHI(flag) ensure(deadline) returns (uint256 totalAmountOut) {
        transferFromAll(tokenIn, totalAmountIn);
        uint256 balanceBefore;
        if (!isETH(tokenOut)) {
            balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);
        }

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountOut;
            for (uint256 k = 0; k < swapSequences[i].length; k++) {
                Swap memory swap = swapSequences[i][k];
                if (k == 1) {
                    // Makes sure that on the second swap the output of the first was used
                    // so there is not intermediate token leftover
                    swap.swapAmount = tokenAmountOut;
                }

                if (swap.isBPool) {
                    TransferHelper.safeApprove(swap.tokenIn, swap.pool, swap.swapAmount);

                    (tokenAmountOut, ) = IBPool(swap.pool).swapExactAmountIn(
                        swap.tokenIn,
                        swap.swapAmount,
                        swap.tokenOut,
                        swap.limitReturnAmount,
                        swap.maxPrice
                    );
                } else {
                    tokenAmountOut = _swapSingleSupportFeeOnTransferTokens(swap.tokenIn, swap.tokenOut, swap.pool, swap.swapAmount, swap.limitReturnAmount);
                }
            }

            // This takes the amountOut of the last swap
            totalAmountOut = tokenAmountOut.add(totalAmountOut);
        }

        transferAll(tokenOut, msg.sender, totalAmountOut);
        transferAll(tokenIn, msg.sender, getBalance(tokenIn));

        if (isETH(tokenOut)) {
            require(totalAmountOut >= minTotalAmountOut, "ERR_LIMIT_OUT");
        } else {
            require(IERC20(tokenOut).balanceOf(msg.sender).sub(balanceBefore) >= minTotalAmountOut, "<minTotalAmountOut");
        }
    }

    function multihopBatchSwapExactOut(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint256 maxTotalAmountIn,
        uint256 deadline,
        uint8 flag
    ) public payable virtual override discountCHI(flag) ensure(deadline) returns (uint256 totalAmountIn) {
        transferFromAll(tokenIn, maxTotalAmountIn);

        for (uint256 i = 0; i < swapSequences.length; i++) {
            uint256 tokenAmountInFirstSwap;
            // Specific code for a simple swap and a multihop (2 swaps in sequence)
            if (swapSequences[i].length == 1) {
                Swap memory swap = swapSequences[i][0];
                tokenAmountInFirstSwap = _swapSingleMixOut(
                    swap.tokenIn,
                    swap.tokenOut,
                    swap.pool,
                    swap.swapAmount,
                    swap.limitReturnAmount,
                    swap.maxPrice,
                    swap.isBPool
                );
            } else {
                // Consider we are swapping A -> B and B -> C. The goal is to buy a given amount
                // of token C. But first we need to buy B with A so we can then buy C with B
                // To get the exact amount of C we then first need to calculate how much B we'll need:
                uint256 intermediateTokenAmount;
                // This would be token B as described above
                Swap memory secondSwap = swapSequences[i][1];
                if (secondSwap.isBPool) {
                    IBPool poolSecondSwap = IBPool(secondSwap.pool);
                    intermediateTokenAmount = poolSecondSwap.calcInGivenOut(
                        poolSecondSwap.getBalance(secondSwap.tokenIn),
                        poolSecondSwap.getDenormalizedWeight(secondSwap.tokenIn),
                        poolSecondSwap.getBalance(secondSwap.tokenOut),
                        poolSecondSwap.getDenormalizedWeight(secondSwap.tokenOut),
                        secondSwap.swapAmount,
                        poolSecondSwap.swapFee()
                    );
                } else {
                    address[] memory paths = new address[](1);
                    paths[0] = secondSwap.pool;
                    uint256[] memory amounts =
                        IValueLiquidFormula(formula).getFactoryAmountsIn(factory, secondSwap.tokenIn, secondSwap.tokenOut, secondSwap.swapAmount, paths);
                    intermediateTokenAmount = amounts[0];
                    require(intermediateTokenAmount <= secondSwap.limitReturnAmount, "Router: EXCESSIVE_INPUT_AMOUNT");
                }

                //// Buy intermediateTokenAmount of token B with A in the first pool
                Swap memory firstSwap = swapSequences[i][0];
                tokenAmountInFirstSwap = _swapSingleMixOut(
                    firstSwap.tokenIn,
                    firstSwap.tokenOut,
                    firstSwap.pool,
                    intermediateTokenAmount,
                    firstSwap.limitReturnAmount,
                    firstSwap.maxPrice,
                    firstSwap.isBPool
                );

                //// Buy the final amount of token C desired
                if (secondSwap.isBPool) {
                    _swapPBoolOut(
                        secondSwap.tokenIn,
                        secondSwap.tokenOut,
                        secondSwap.pool,
                        secondSwap.swapAmount,
                        secondSwap.limitReturnAmount,
                        secondSwap.maxPrice
                    );
                } else {
                    _swapSingle(secondSwap.tokenIn, secondSwap.pool, intermediateTokenAmount, secondSwap.swapAmount);
                }
            }

            totalAmountIn = tokenAmountInFirstSwap.add(totalAmountIn);
        }

        require(totalAmountIn <= maxTotalAmountIn, "ERR_LIMIT_IN");

        transferAll(tokenOut, msg.sender, getBalance(tokenOut));
        transferAll(tokenIn, msg.sender, getBalance(tokenIn));
    }

    function transferFromAll(address token, uint256 amount) internal returns (bool) {
        if (isETH(token)) {
            IWETH(WETH).deposit{value: msg.value}();
        } else {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        }
        return true;
    }

    function getBalance(address token) internal view returns (uint256) {
        if (isETH(token)) {
            return IWETH(WETH).balanceOf(address(this));
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function _swapSingleMixOut(
        address tokenIn,
        address tokenOut,
        address pool,
        uint256 swapAmount,
        uint256 limitReturnAmount,
        uint256 maxPrice,
        bool isBPool
    ) internal returns (uint256 tokenAmountIn) {
        if (isBPool) {
            return _swapPBoolOut(tokenIn, tokenOut, pool, swapAmount, limitReturnAmount, maxPrice);
        } else {
            address[] memory paths = new address[](1);
            paths[0] = pool;
            uint256[] memory amounts = IValueLiquidFormula(formula).getFactoryAmountsIn(factory, tokenIn, tokenOut, swapAmount, paths);
            tokenAmountIn = amounts[0];
            require(tokenAmountIn <= limitReturnAmount, "Router: EXCESSIVE_INPUT_AMOUNT");

            _swapSingle(tokenIn, pool, tokenAmountIn, amounts[1]);
        }
    }

    function _swapPBoolOut(
        address tokenIn,
        address tokenOut,
        address pool,
        uint256 swapAmount,
        uint256 limitReturnAmount,
        uint256 maxPrice
    ) internal returns (uint256 tokenAmountIn) {
        TransferHelper.safeApprove(tokenIn, pool, limitReturnAmount);

        (tokenAmountIn, ) = IBPool(pool).swapExactAmountOut(tokenIn, limitReturnAmount, tokenOut, swapAmount, maxPrice);
    }

    function _swapSingle(
        address tokenIn,
        address pair,
        uint256 targetSwapAmount,
        uint256 targetOutAmount
    ) internal {
        TransferHelper.safeTransfer(tokenIn, pair, targetSwapAmount);
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == IValueLiquidPair(pair).token0() ? (uint256(0), targetOutAmount) : (targetOutAmount, uint256(0));

        IValueLiquidPair(pair).swap(amount0Out, amount1Out, address(this), new bytes(0));
    }

    function _swapSingleSupportFeeOnTransferTokens(
        address tokenIn,
        address tokenOut,
        address pool,
        uint256 swapAmount,
        uint256 limitReturnAmount
    ) internal returns (uint256 tokenAmountOut) {
        TransferHelper.safeTransfer(tokenIn, pool, swapAmount);

        uint256 amountOutput;
        {
            (, uint256 reserveInput, uint256 reserveOutput, uint32 tokenWeightInput, uint32 tokenWeightOutput, uint32 swapFee) =
                IValueLiquidFormula(formula).getFactoryReserveAndWeights(factory, pool, tokenIn);
            uint256 amountInput = IERC20(tokenIn).balanceOf(pool).sub(reserveInput);
            amountOutput = IValueLiquidFormula(formula).getAmountOut(amountInput, reserveInput, reserveOutput, tokenWeightInput, tokenWeightOutput, swapFee);
        }
        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));
        (uint256 amount0Out, uint256 amount1Out) = tokenIn == IValueLiquidPair(pool).token0() ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
        IValueLiquidPair(pool).swap(amount0Out, amount1Out, address(this), new bytes(0));

        tokenAmountOut = IERC20(tokenOut).balanceOf(address(this)).sub(balanceBefore);
        require(tokenAmountOut >= limitReturnAmount, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
    }

    function transferETHTo(uint256 amount, address to) internal {
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(to, amount));
    }

    function transferAll(
        address token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            IWETH(WETH).withdraw(amount);
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
        return true;
    }

    function isETH(address token) internal pure returns (bool) {
        return (token == ETH_ADDRESS);
    }
}