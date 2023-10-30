/*                              
                    CHAINTOOLS 2023. DEFI REIMAGINED

                                                               2023

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀            2021           ⣰⣾⣿⣶⡄⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀2019⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀     ⠹⣿V4⡄⡷⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⠀⠀⠀⠀⠀⠀⠀⠀ ⣤⣾⣿⣷⣦⡀⠀⠀⠀⠀   ⣿⣿⡏⠁⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⣿⣿⣿⣷⡀⠀⠀⠀⠀ ⢀⣿⣿⣿⣿⣿⠄⠀⠀⠀  ⣰⣿⣿⣧⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⣾⣿⣿⣿⣿⣿⣿⡄⠀⠀ ⢀⣴⣿⣿⣿⠟⠛⠋⠀⠀⠀ ⢸⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⢀⣴⣿⣿⣿⣿⣿⠟⠉⠉⠉⠁⢀⣴⣿⣿V3⣿⣿⠀⠀⠀⠀⠀  ⣾⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣾⣿⣿⣿⣿⣿⠛⠀⠀⠀⠀⠀ ⣾⣿⣿⣿⣿⣿⣿⠁⠀⠀⠀⠀⠀ ⣿⣿⣿⣿⣿⣿⣿⣧⡀⠀⠀⠀⠀   
⠀⠀⠀        2017⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿V2⣿⣿⡿⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀ ⢹⣿ ⣿⣿⣿⣿⠙⢿⣆⠀⠀⠀   
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣴⣦⣤⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿⠛⠿⠿⠶⠶⣶⠀  ⣿ ⢸⣿⣿⣿⣿⣆⠹⠇⠀⠀   
⠀⠀⠀⠀⠀⠀⢀⣠⣴⣿⣿⣿⣿⣷⡆⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⡇⠉⠛⢿⣷⡄⠀⠀⠀⢸⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀  ⠹⠇⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀   
⠀⠀⠀⠀⣠⣴⣿⣿V1⣿⣿⣿⡏⠛⠃⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣇⠀⠀⠘⠋⠁⠀⠀⠀⠈⢿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀  ⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀   
⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣦⠀⠀⠀⠀⠀⠀⠀⠀ ⠸⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀  ⠀⣿⣿⡟⢿⣿⣿⠀⠀⠀⠀   
⠀⢸⣿⣿⣿⣿⣿⠛⠉⠙⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀ ⢈⣿⣿⡟⢹⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣿⡿⠈⣿⣿⡟⠀⠀⠀⠀⠀  ⢸⣿⣿⠀⢸⣿⣿⠀⠀⠀⠀   
⠀⠀⠹⣿⣿⣿⣿⣷⡀⠀⠻⣿⣿⣿⣿⣶⣄⠀⠀⠀⢰⣿⣿⡟⠁⣾⣿⣿⠀⠀⠀⠀⠀⠀⢀⣶⣿⠟⠋⠀⢼⣿⣿⠃⠀⠀⠀⠀⠀  ⣿⣿⠁⠀⢹⣿⣿⠀⠀⠀⠀   
⠀⢀⣴⣿⡿⠋⢹⣿⡇⠀⠀⠈⠙⣿⣇⠙⣿⣷⠀⠀⢸⣿⡟⠀⠀⢻⣿⡏⠀⠀⠀⠀⠀⢀⣼⡿⠁⠀⠀⠀⠘⣿⣿⠀⠀⠀⠀⠀   ⢨⣿⡇⠀⠀⠀⣿⣿⠀⠀⠀⠀   
⣴⣿⡟⠉⠀⠀⣾⣿⡇⠀⠀⠀⠀⢈⣿⡄⠀⠉⠀⠀⣼⣿⡆⠀⠀⢸⣿⣷⠀⠀⠀⠀⢴⣿⣿⠀⠀⠀⠀⠀⠀⣿⣯⡀⠀⠀⠀⠀    ⢸⣿⣇⠀⠀⠀⢺⣿⡄⠀⠀⠀   
⠈⠻⠷⠄⠀⠀⣿⣿⣷⣤⣠⠀⠀⠈⠽⠷⠀⠀⠀⠸⠟⠛⠛⠒⠶⠸⣿⣿⣷⣦⣤⣄⠈⠻⠷⠄⠀⠀⠀⠾⠿⠿⣿⣶⣤⠀    ⠘⠛⠛⠛⠒⠀⠸⠿⠿⠦ 


Telegram: https://t.me/ChaintoolsOfficial
Website: https://www.chaintools.ai/
Whitepaper: https://chaintools-whitepaper.gitbook.io/
Twitter: https://twitter.com/ChaintoolsTech
dApp: https://www.chaintools.wtf/
*/

// import "forge-std/console.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IUniswapV2Router02 {
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface IV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function mint(address to) external returns (uint256 liquidity);

    function kLast() external view returns (uint lastK);

    function getReserves()
        external
        view
        returns (uint stamp, uint res0, uint res1);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IV3Pool {
    function liquidity() external view returns (uint128 Liq);

    struct Info {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function initialize(uint160 sqrtPriceX96) external;

    function positions(
        bytes32 key
    ) external view returns (IV3Pool.Info memory liqInfo);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function slot0()
        external
        view
        returns (uint160, int24, uint16, uint16, uint16, uint8, bool);

    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes memory data
    ) external;

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IWETH {
    function withdraw(uint256 wad) external;

    function approve(address who, uint256 wad) external returns (bool);

    function deposit() external payable;

    function transfer(address dst, uint256 wad) external returns (bool);

    function balanceOf(address _owner) external view returns (uint256);
}

interface IQuoterV2 {
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);
}

interface IV3Factory {
    function getPool(
        address token0,
        address token1,
        uint24 poolFee
    ) external view returns (address);

    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address);
}

interface INonfungiblePositionManager {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function setApprovalForAll(address operator, bool approved) external;

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(
        INonfungiblePositionManager.IncreaseLiquidityParams calldata params
    ) external returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function factory() external view returns (address);

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata mp
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(
        DecreaseLiquidityParams calldata dl
    ) external returns (uint256 amount0, uint256 amount1);

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IRouterV3 {
    function factory() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function WETH9() external view returns (address);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external returns (uint256 amountIn);

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface IChainTools {
    function adjustFomo(uint16 a, uint256 b, address w) external;

    function zapFromETH(
        uint256 minOut,
        address to,
        uint256 flag,
        address upper
    ) external payable returns (uint256 tokenId);

    function getYieldBooster() external view returns (address yb);

    function swapBack() external;

    function flashReward() external;
    function getV3Pool() external view returns(address);
    function getUpperRef(address who) external view returns (address ref);
}

interface IChainToolsV3Utils {
    function getDeviation(
        uint256 amountIn,
        uint256 startTickDeviation
    ) external pure returns (uint256 adjusted);

    function getStartTickDeviation(
        int24 currentTick
    ) external pure returns (uint256 perc);

    function getTickDistance(
        uint256 flag
    ) external pure returns (int24 tickDistance);

    function getCurrentTick() external view returns (int24);

    function findPoolFee(
        address token0,
        address token1
    ) external view returns (uint24 poolFee);

    function findMaxAddDouble(
        uint256 amount0Desired,
        uint256 amount1Desired,
        int24 lower,
        int24 upper
    ) external view returns (uint256 amount0Max, uint256 amount1Max);

    function getPosition(
        uint256 tokenId
    ) external view returns (address token0, address token1, uint128 liquidity);
}

contract ChainToolsYieldVault {
    struct Pending {
        uint128 amount0;
        uint128 amount1;
    }

    INonfungiblePositionManager internal immutable positionManager;
    IChainToolsV3Utils public v3Utils;

    address internal immutable CTLS;
    address internal immutable WETH;
    address internal immutable multiSig;
    address internal immutable v3Router;
    address internal immutable uniswapV3Pool;
    address public keeper;
    uint256 internal minCompAmtETH = 2e17;

    mapping(uint256 => Pending) internal balances;

    error Auth();
    error Max0();
    error Max1();

    event referralPaid(
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Compounded(uint256 indexed tokenId, uint256 c0, uint256 c1);
    event ShiftedPosition(
        uint256 indexed tokenIdOld,
        uint256 indexed tokenIdNew,
        int24 flag,
        uint256 t0,
        uint256 t1
    );
    event BoughtBack(uint256 indexed flag, uint256 a0, uint256 a1);
    event limitOrderCreated(
        address indexed who,
        uint256 tokenId,
        int24 flag,
        uint256 amount0Or1,
        bool isWETH
    );

    event fusedPositions(
        address indexed who,
        uint256 numberOfPositions,
        uint256 newTokenId,
        uint256 amount0Fused,
        uint256 amount1Fused
    );

    constructor(address _v3Utilss, address _ctls) {
        positionManager = INonfungiblePositionManager(
            0xC36442b4a4522E871399CD717aBDD847Ab11FE88
        );
        v3Utils = IChainToolsV3Utils(_v3Utilss);
        CTLS = _ctls;
        v3Router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        IERC20(WETH).approve(address(positionManager), type(uint256).max);
        IERC20(CTLS).approve(address(positionManager), type(uint256).max);
        keeper = 0x5648C24Ea7cFE703836924bF2080ceFa44A12cA8;
        multiSig = 0xb0Df68E0bf4F54D06A4a448735D2a3d7D97A2222;
        IERC20(WETH).approve(address(v3Router), type(uint256).max);
        IERC20(CTLS).approve(address(v3Router), type(uint256).max);
        uniswapV3Pool = 0xc53489F27F4d8A1cdceD3BFe397CAF628e8aBC13;
    }

    function updateV3Utils(address newV3Utils) external {
        if (msg.sender != multiSig) revert Auth();
        v3Utils = IChainToolsV3Utils(newV3Utils);
    }

    //CallStatic
    function filterReady(
        uint256[] calldata tokenIds,
        uint256 minAmount0,
        uint256 minAmount1
    )
        external
        returns (
            uint256[] memory readyToComp,
            uint256[] memory amt0,
            uint256[] memory amt1
        )
    {
        if (msg.sender != keeper) revert Auth();
        unchecked {
            try IChainTools(payable(CTLS)).swapBack() {} catch {}
            try IChainTools(payable(CTLS)).flashReward() {} catch {}

            uint256 tokenIdsL = tokenIds.length;
            readyToComp = new uint256[](tokenIdsL);
            amt0 = new uint256[](tokenIdsL);
            amt1 = new uint256[](tokenIdsL);
            for (uint256 i; i < tokenIdsL; ) {
                uint256 tokenId = tokenIds[i];
                if (tokenId != 0) {
                    try
                        positionManager.collect(
                            INonfungiblePositionManager.CollectParams({
                                tokenId: tokenId,
                                recipient: address(this),
                                amount0Max: type(uint128).max,
                                amount1Max: type(uint128).max
                            })
                        )
                    returns (uint256 claimed0, uint256 claimed1) {
                        Pending memory pen = balances[tokenId];

                        //10% protocol [5% normal tax, 5% compound tax]
                        uint256 pFee0 = claimed0 / 10;

                        claimed0 -= pFee0;

                        balances[1].amount0 += uint128(pFee0);

                        pen.amount0 += uint128(claimed0);
                        pen.amount1 += uint128(claimed1);

                        if (claimed0 > minAmount0 && claimed1 > minAmount1) {
                            readyToComp[i] = tokenId;
                            amt0[i] = claimed0;
                            amt1[i] = claimed1;
                        }

                        balances[tokenId] = pen;
                    } catch {}
                }

                ++i;
            }
        }
    }

    function unite(
        uint256[] calldata tokenIds
    )
        external
        payable
        returns (uint256[] memory reverting, uint256 pFee0)
    {
        if (msg.sender != keeper) revert Auth();
        unchecked {
            if (msg.value != 0) {
                try IChainTools(payable(CTLS)).swapBack() {} catch {}
            }

            try IChainTools(payable(CTLS)).flashReward() {} catch {}

            uint256 tokenIdsL = tokenIds.length;
            reverting = new uint256[](tokenIds.length);
            for (uint256 i; i < tokenIdsL; ) {
                uint256 tokenId = tokenIds[i];
                try
                    positionManager.collect(
                        INonfungiblePositionManager.CollectParams({
                            tokenId: tokenId,
                            recipient: address(this),
                            amount0Max: type(uint128).max,
                            amount1Max: type(uint128).max
                        })
                    )
                returns (uint256 claimed0, uint256 claimed1) {
                    Pending memory pen = balances[tokenId];
                    //10% protocol [5% normal tax, 5% compound tax]
                    pFee0 = claimed0 / 10;
                    claimed0 -= pFee0;

                    balances[1].amount0 += uint128(pFee0);
                    pen.amount0 += uint128(claimed0);
                    pen.amount1 += uint128(claimed1);

                    if (claimed0 != 0 && claimed1 != 0) {
                        try this.increaseLiq(tokenId, pen) {} catch {
                            //CallStatic catch reverting -> exclude from call
                            //If revert during real call, update balances to sync referral rewards
                            balances[tokenId] = pen;
                            reverting[i] = tokenId;
                        }
                    } else {
                        reverting[i] = tokenId;
                        balances[tokenId] = pen;
                    }
                } catch {
                    reverting[i] = tokenId;
                }

                ++i;
            }
        }
    }

    function increaseLiq(
        uint256 tokenId,
        Pending memory pen
    ) external returns (uint256 collected0, uint256 collected1) {
        if (msg.sender != address(this)) revert Auth();
        (, collected0, collected1) = positionManager.increaseLiquidity(
            INonfungiblePositionManager.IncreaseLiquidityParams({
                tokenId: tokenId,
                amount0Desired: pen.amount0,
                amount1Desired: pen.amount1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );
        if (
            collected0 > pen.amount0 &&
            collected0 > IERC20(WETH).balanceOf(address(this))
        ) revert Max0();
        if (
            collected1 > pen.amount1 &&
            collected1 > IERC20(CTLS).balanceOf(address(this))
        ) revert Max1();
        balances[tokenId].amount0 = (pen.amount0 - uint128(collected0));
        balances[tokenId].amount1 = (pen.amount1 - uint128(collected1));
        emit Compounded(tokenId, collected0, collected1);
    }

    //If someone sends tokens by mistake here, we will be able to retrieve it
    function withdrawStuck(address token, uint256 amount) external {
        if (msg.sender != multiSig) revert Auth();
        //compatible with usdt
        if (amount != 0)
            token.call(
                abi.encodeWithSelector(
                    IERC20.transfer.selector,
                    multiSig,
                    amount
                )
            );
        if (address(this).balance > 0) {
            multiSig.call{value: address(this).balance}("");
        }
    }

    function withdraw_yield(uint256 tokenId) external {
        address tokenOwner = positionManager.ownerOf(tokenId);
        if (tokenId == 1) tokenOwner = multiSig;
        if (tokenOwner != msg.sender) revert Auth();
        uint sendAmount0 = balances[tokenId].amount0;
        uint sendAmount1 = balances[tokenId].amount1;
        balances[tokenId].amount0 = 0;
        balances[tokenId].amount1 = 0;
        if(sendAmount0 != 0) IERC20(WETH).transfer(tokenOwner, sendAmount0);
        if(sendAmount1 > 1e8) IERC20(CTLS).transfer(tokenOwner, sendAmount1);
    }

    //PROTOCOL LP/FEES
    function buyback(
        uint256 flag,
        uint128 internalWETHAmt,
        uint128 internalCTLSAmt,
        address to,
        uint256 id
    ) external returns (uint256 t0, uint256 t1) {
        if (tx.origin != keeper && msg.sender != multiSig) revert Auth();

        (t0, t1) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: id,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        unchecked {
            balances[1].amount0 += uint128(t0);
            balances[1].amount1 += uint128(t1);
        }
        if (
            balances[1].amount0 >= internalWETHAmt &&
            balances[1].amount1 >= internalCTLSAmt
        ) {
            unchecked {
                balances[1].amount0 -= internalWETHAmt;
                balances[1].amount1 -= internalCTLSAmt;
            }
            if (flag == 0) {
                try IChainTools(payable(CTLS)).flashReward() {} catch {} //lp reward only
            } else if (flag == 1) {
                //buyback only
                uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
                    IRouterV3.ExactInputSingleParams({
                        tokenIn: WETH,
                        tokenOut: CTLS,
                        fee: 10000,
                        recipient: to,
                        deadline: block.timestamp,
                        amountIn: internalWETHAmt,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    })
                );
                emit BoughtBack(flag, internalWETHAmt, gotTokens);
            } else if (flag == 2) {
                //buyback+lp reward
                uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
                    IRouterV3.ExactInputSingleParams({
                        tokenIn: WETH,
                        tokenOut: CTLS,
                        fee: 10000,
                        recipient: IChainTools(payable(CTLS)).getYieldBooster(),
                        deadline: block.timestamp,
                        amountIn: (internalWETHAmt - (internalWETHAmt / 2)),
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    })
                );
                emit BoughtBack(flag, internalWETHAmt, gotTokens);
                try IChainTools(payable(CTLS)).flashReward() {} catch {}
            } else if (flag == 3) {
                //buyback + swapback + send rewards
                uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
                    IRouterV3.ExactInputSingleParams({
                        tokenIn: WETH,
                        tokenOut: CTLS,
                        fee: 10000,
                        recipient: to,
                        deadline: block.timestamp,
                        amountIn: internalWETHAmt,
                        amountOutMinimum: 0,
                        sqrtPriceLimitX96: 0
                    })
                );
                emit BoughtBack(flag, internalWETHAmt, gotTokens);
                try IChainTools(payable(CTLS)).swapBack() {} catch {}
                try IChainTools(payable(CTLS)).flashReward() {} catch {}
            } 
        } else {
            revert();
        }
    }

    function _collectLPRewards(
        uint256 tokenId
    ) internal returns (uint128 c0, uint128 c1) {
        (uint256 c0u, uint256 c1u) = positionManager.collect(
            INonfungiblePositionManager.CollectParams({
                tokenId: tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );

        c0 = uint128(c0u);
        c1 = uint128(c1u);
    }

    function _decreasePosition(
        uint256 tokenId
    ) internal returns (uint128 a0, uint128 a1) {
        (, , uint128 liq) = v3Utils.getPosition(tokenId);
        positionManager.decreaseLiquidity(
            INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liq,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        (a0, a1) = _collectLPRewards(tokenId);
    }

    receive() external payable {
    }

    function fusePositions(
        uint256[] calldata tokenIds,
        uint256 targetId,
        int24 tickDist,
        uint256 min0Out,
        uint256 min1Out,
        bool swapToTarget
    )
        external
        payable
        returns (uint256 newTokenId, uint256 min0, uint256 min1)
    {
        uint size = tokenIds.length;
        if (size == 1) revert Max0();
        uint128 total0;
        uint128 total1;
        {
            for (uint i; i < size; ) {
                unchecked {
                    address tokenOwner = positionManager.ownerOf(tokenIds[i]);
                    if (msg.sender != tokenOwner) revert Auth();

                    (
                        uint128 WETHRemoved,
                        uint128 tokensRemoved
                    ) = _decreasePosition(tokenIds[i]);
                    total0 += WETHRemoved;
                    total1 += tokensRemoved;

                    ++i;
                }
            }
        }

        //Fuse all into new position
        if (targetId == 0) {
            //Single CTLS
            if (msg.value == 1) {

                uint128 pFee1;
                unchecked {
                    pFee1 = total1 / 40; //2.5% fuseTax
                    balances[1].amount1 += pFee1;
                    total1 -= pFee1;
                }

                uint gotTokens;
                if (swapToTarget) {
                    gotTokens = _swapV3(total0);
                    total0 = 0;
                } 


                // 100% CTLS -> 100% CTLS new Range
                total1 += uint128(gotTokens);
                (newTokenId, min0, min1) = _mintPosition(
                    0,
                    uint256(total1),
                    tickDist,
                    msg.sender,
                    false,
                    0,
                    min1Out
                );
                if (min1 > total1) revert Max1();
                _sendRefunds(total0, total1  - uint128(min1));
                //Double
            } else if (msg.value == 2) {
                uint128 pFee0;
                uint128 pFee1;
                unchecked {
                    pFee0 = total0 / 100;
                    pFee1 = total1 / 100;
                    balances[1].amount0 += pFee0;
                    balances[1].amount1 += pFee1;

                    total0 -= pFee0;
                    total1 -= pFee1;
                }

                //Double -> Double
                (newTokenId, min0, min1) = _mintPosition(
                    uint256(total0),
                    uint256(total1),
                    tickDist,
                    msg.sender,
                    true,
                    min0Out,
                    min1Out
                );

                if (min0 > total0) revert Max0();
                if (min1 > total1) revert Max1();
                _sendRefunds(total0 - uint128(min0), total1 - uint128(min1));
                //Single WETH
            } else if (msg.value == 3) {
                uint128 pFee0;
                unchecked {
                    pFee0 = total0 / 40; //2.5%
                    balances[1].amount0 += pFee0;
                    total0 -= pFee0;
                }
                (newTokenId, min0, min1) = _mintPosition(
                    uint256(total0),
                    0,
                    tickDist,
                    msg.sender,
                    false,
                    min0Out,
                    0
                );


                _sendRefunds(total0 - uint128(min0), total1);
            } else {
                revert Auth();
            }
        } else {
            //Fuse all into target position
            address tokenOwner = positionManager.ownerOf(targetId);
            if (msg.sender != tokenOwner) revert Auth();

            uint128 pFee0;
            uint128 pFee1;
            unchecked {
                pFee0 = total0 / 100; //1.0%
                pFee1 = total1 / 100; //1.0%

                balances[1].amount0 += pFee0;
                balances[1].amount1 += pFee1;

                total0 -= pFee0;
                total1 -= pFee1;
            }

            newTokenId = targetId;

            (, min0, min1) = positionManager.increaseLiquidity(
                INonfungiblePositionManager.IncreaseLiquidityParams({
                    tokenId: targetId,
                    amount0Desired: total0,
                    amount1Desired: total1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );

            if (min0 > total0) revert Max0();
            if (min1 > total1) revert Max1();
            //reuse vars
            _sendRefunds(total0 - uint128(min0), total1 - uint128(min1));
            
        }

        emit fusedPositions(msg.sender, size, targetId == 0 ? newTokenId : targetId,min0, min1);
    }

    function _swapV3(uint256 amountIn) internal returns (uint256 gotTokens) {
        gotTokens = IRouterV3(v3Router).exactInputSingle(
            IRouterV3.ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: CTLS,
                fee: 10000,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function shiftPositionSingle(
        uint256 tokenId,
        uint256 minOut,
        uint256 minOut1,
        int24 tickDist,
        bool swapToTarget
    )
        external
        payable
        returns (uint256 newTokenId, uint256 min0, uint256 min1)
    {
        address tokenOwner = positionManager.ownerOf(tokenId);
        if (msg.sender != tokenOwner) revert Auth();
        (uint128 WETHRemoved, uint128 tokensRemoved) = _decreasePosition(
            tokenId
        );

        if (msg.value == 1) {
            uint128 pFee1;
            unchecked {
                pFee1 = tokensRemoved / 100; //1% from tokens
                balances[1].amount1 += pFee1;
                tokensRemoved -= pFee1;
            }

            uint256 gotTokens;
            if (swapToTarget) {
                gotTokens = _swapV3(WETHRemoved);
                WETHRemoved = 0;
            }
            // 100% CTLS -> 100% CTLS new Range
            (newTokenId, min0, min1) = _mintPosition(
                0,
                tokensRemoved + gotTokens,
                tickDist,
                msg.sender,
                false,
                0,
                minOut
            );
            if (min1 > tokensRemoved) revert Max1();
            _sendRefunds(WETHRemoved, tokensRemoved - min1);
        } else if (msg.value == 2) {
            uint128 pFee1;
            unchecked {
                pFee1 = tokensRemoved / 100; //1% from tokens
                balances[1].amount1 += pFee1;
                tokensRemoved -= pFee1;
            }

            //100% CTLS ->  100% WETH
            uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
                IRouterV3.ExactInputSingleParams({
                    tokenIn: CTLS,
                    tokenOut: WETH,
                    fee: 10000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: tokensRemoved,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );

            (newTokenId, min0, min1) = _mintPosition(
                WETHRemoved + gotTokens,
                0,
                tickDist,
                msg.sender,
                false,
                minOut,
                0
            );

            if (min0 > WETHRemoved + gotTokens) revert Max0();
            _sendRefunds((WETHRemoved + gotTokens) - min0, 0);
        } else if (msg.value == 3) {
            //Single CTLS => Double
            uint128 pFee1;
            unchecked {
                pFee1 = tokensRemoved / 100; //1% from tokens
                balances[1].amount1 += pFee1;
                tokensRemoved -= pFee1;
            }

            uint256 adjusted = uint256(
                v3Utils.getDeviation(
                    tokensRemoved,
                    v3Utils.getStartTickDeviation(v3Utils.getCurrentTick())
                )
            );

            tokensRemoved -= uint128(adjusted);
            //100% CTLS ->  100% WETH
            uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
                IRouterV3.ExactInputSingleParams({
                    tokenIn: CTLS,
                    tokenOut: WETH,
                    fee: 10000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: adjusted,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );

            (newTokenId, min0, min1) = _mintPosition(
                gotTokens,
                tokensRemoved,
                tickDist,
                msg.sender,
                true,
                minOut,
                minOut1
            );

            if (min0 > gotTokens) revert Max0();
            if (min1 > tokensRemoved) revert Max1();
            _sendRefunds(gotTokens - min0,tokensRemoved - min1);
        } else if (msg.value == 4) {
            //Single WETH => Double
            uint128 pFee0;
            unchecked {
                pFee0 = WETHRemoved / 100; //1% from tokens
                balances[1].amount0 += pFee0;
                WETHRemoved -= pFee0;
            }

            uint256 adjusted = uint256(
                v3Utils.getDeviation(
                    WETHRemoved,
                    v3Utils.getStartTickDeviation(v3Utils.getCurrentTick())
                )
            );

            WETHRemoved -= uint128(adjusted);
            //100% CTLS ->  100% WETH
            uint256 gotTokens = IRouterV3(v3Router).exactInputSingle(
                IRouterV3.ExactInputSingleParams({
                    tokenIn: WETH,
                    tokenOut: CTLS,
                    fee: 10000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: adjusted,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );

            (newTokenId, min0, min1) = _mintPosition(
                WETHRemoved,
                gotTokens,
                tickDist,
                msg.sender,
                true,
                minOut,
                minOut1
            );

            if (min0 > WETHRemoved) revert Max0();
            if (min1 > gotTokens) revert Max1();
            _sendRefunds(WETHRemoved - min0, gotTokens - min1);
        } else {
            revert Auth();
        }

        emit ShiftedPosition(tokenId, newTokenId, tickDist, min0, min1);
    }

    function shiftDoubleSidedPosition(
        uint256 tokenId,
        uint256 min0Out,
        uint256 min1Out,
        int24 tickDist,
        bool swapToTarget
    )
        external
        payable
        returns (uint256 newTokenId, uint256 min0, uint256 min1)
    {
        //msg.value == path
        address tokenOwner = positionManager.ownerOf(tokenId);
        if (msg.sender != tokenOwner) revert Auth();
        (uint128 WETHRemoved, uint128 tokensRemoved) = _decreasePosition(
            tokenId
        );
        uint128 pFee0;
        uint128 pFee1;
        uint256 gotTokens;
        unchecked {
            pFee0 = WETHRemoved / 200; //0.5%
            pFee1 = tokensRemoved / 200; //0.5%

            balances[1].amount0 += pFee0;
            balances[1].amount1 += pFee1;

            WETHRemoved -= pFee0;
            tokensRemoved -= pFee1;
        }
        if (msg.value == 1) {
            //Double -> Double
            (newTokenId, min0, min1) = _mintPosition(
                WETHRemoved,
                tokensRemoved,
                tickDist,
                msg.sender,
                true,
                min0Out,
                min1Out
            );

        } else if (msg.value == 2) {

            if (swapToTarget) {
                gotTokens = _swapV3(WETHRemoved);
                WETHRemoved = 0;
            }
            //Double into single CTLS
            (newTokenId, min0, min1) = _mintPosition(
                0,
                tokensRemoved + gotTokens,
                tickDist,
                msg.sender,
                false,
                0,
                min1Out
            );
        } else if (msg.value == 3) {
            //Double into single WETH
            (newTokenId, min0, min1) = _mintPosition(
                WETHRemoved,
                0,
                tickDist,
                msg.sender,
                false,
                min0Out,
                0
            );


        } else {
            revert Auth();
        }

        if (min0 > WETHRemoved) revert Max0();
        if (min1 > tokensRemoved + gotTokens) revert Max1();
        _sendRefunds(WETHRemoved - min0, (tokensRemoved + gotTokens) - min1);
        emit ShiftedPosition(tokenId, newTokenId, tickDist, min0, min1);
    }

    function createLimitOrderPosition(
        uint128 amount0Or1,
        int24 flag,
        bool isToken0,
        uint256 min0Or1Out
    ) external returns (uint256 newTokenId, uint256 min0, uint256 min1) {
        isToken0
            ? IERC20(WETH).transferFrom(msg.sender, address(this), amount0Or1)
            : IERC20(CTLS).transferFrom(msg.sender, address(this), amount0Or1);
        unchecked {
            uint128 pFee = amount0Or1 / 25;

            isToken0
                ? balances[1].amount0 += pFee
                : balances[1].amount1 += pFee;
        }

        (newTokenId, min0, min1) = _mintPosition(
            isToken0 ? amount0Or1 : 0,
            isToken0 ? 0 : amount0Or1,
            flag,
            msg.sender,
            false,
            isToken0 ? min0Or1Out : 0,
            isToken0 ? 0 : min0Or1Out
        );

        if (isToken0) {
            _sendRefunds(amount0Or1 - min0, 0);
        } else {
            _sendRefunds(0, amount0Or1 - min1);
        }
        emit limitOrderCreated(
            msg.sender,
            newTokenId,
            flag,
            isToken0 ? min0 : min1,
            isToken0
        );
    }

    function _sendRefunds(uint256 amount0, uint256 amount1) internal {
        //New - Compute if worth to send back refunds at all
        //New - Adds dust to the protocol [slots already warmed]
        if (amount0 >= 50000 * tx.gasprice) {
            IERC20(WETH).transfer(msg.sender, amount0);
        } else {
            balances[1].amount0 += uint128(amount0);
        }
        if (amount1 >= 5e18) {
            IERC20(CTLS).transfer(msg.sender, amount1);
        } else {
            balances[1].amount1 += uint128(amount1);
        }
    }

    //New - Logic changed - [Allow for any position shifting] [Finds Max Add Amounts]
    function _mintPosition(
        uint256 amt0Desired,
        uint256 amt1Desired,
        int24 tickDist,
        address to,
        bool isDouble,
        uint256 min0,
        uint256 min1
    )
        internal
        returns (uint256 tokenId, uint256 amt0Consumed, uint256 amt1Consumed)
    {
        int24 tick = v3Utils.getCurrentTick();

        if (isDouble) {
            //New - Compute Max Provision Amounts
            (uint256 max0, uint256 max1) = v3Utils.findMaxAddDouble(
                amt0Desired,
                amt1Desired,
                tick - tickDist,
                tick + tickDist
            );

            (tokenId, , amt0Consumed, amt1Consumed) = positionManager.mint(
                INonfungiblePositionManager.MintParams({
                    token0: WETH,
                    token1: CTLS,
                    fee: 10000,
                    tickLower: tick - tickDist,
                    tickUpper: tick + tickDist,
                    amount0Desired: max0, //new - use max add amount0
                    amount1Desired: max1, //new - use max add amount1
                    amount0Min: min0,
                    amount1Min: min1,
                    recipient: to,
                    deadline: block.timestamp
                })
            );

        } else {
            if (amt0Desired == 0) {
                (tokenId, , amt0Consumed, amt1Consumed) = positionManager.mint(
                    INonfungiblePositionManager.MintParams({
                        token0: WETH,
                        token1: CTLS,
                        fee: 10000,
                        tickLower: tick - tickDist,
                        tickUpper: tick - 200,
                        amount0Desired: 0,
                        amount1Desired: amt1Desired,
                        amount0Min: 0,
                        amount1Min: min1,
                        recipient: to,
                        deadline: block.timestamp
                    })
                );
            } else {
                (tokenId, , amt0Consumed, amt1Consumed) = positionManager.mint(
                    INonfungiblePositionManager.MintParams({
                        token0: WETH,
                        token1: CTLS,
                        fee: 10000,
                        tickLower: tick + 200,
                        tickUpper: tick + tickDist,
                        amount0Desired: amt0Desired,
                        amount1Desired: 0,
                        amount0Min: min0,
                        amount1Min: 0,
                        recipient: to,
                        deadline: block.timestamp
                    })
                );
            }
        }
    }

    //GETTERS
    function balanceOf(
        uint256 tokenId
    ) external view returns (uint128 balance0, uint128 balance1) {
        balance0 = balances[tokenId].amount0;
        balance1 = balances[tokenId].amount1;
    }

    function getPosition(
        uint256 tokenId
    )
        external
        view
        returns (address token0, address token1, uint128 liquidity)
    {
        return v3Utils.getPosition(tokenId);
    }

    function findPoolFee(
        address token0,
        address token1
    ) public view returns (uint24 poolFee) {
        return v3Utils.findPoolFee(token0, token1);
    }

    function getDeviation(
        uint256 amountIn,
        uint256 startTickDeviation
    ) external view returns (uint256 adjusted) {
        return v3Utils.getDeviation(amountIn, startTickDeviation);
    }

    function getStartTickDeviation(
        int24 currentTick
    ) external view returns (uint256 perc) {
        return v3Utils.getStartTickDeviation(currentTick);
    }

    function getCurrentTick() external view returns (int24 cTick) {
        return v3Utils.getCurrentTick();
    }

    function getTickDistance(
        uint256 flag
    ) external view returns (int24 tickDistance) {
        return v3Utils.getTickDistance(flag);
    }

    function findApprovalToken(
        address pool
    ) external view returns (address token) {
        return
            this.findApprovalToken(
                IV3Pool(pool).token0(),
                IV3Pool(pool).token1()
            );
    }

    function findApprovalToken(
        address token0,
        address token1
    ) external view returns (address token) {
        require(token0 == WETH || token1 == WETH, "Not WETH Pair");
        token = token0 == WETH ? token1 : token0;
        if (token == CTLS || token == WETH) {
            token = address(0);
        }
    }
}