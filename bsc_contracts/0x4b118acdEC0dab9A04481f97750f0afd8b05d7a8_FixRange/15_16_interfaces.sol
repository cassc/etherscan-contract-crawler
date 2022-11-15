// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IiZiSwapPool {

    function state() external view
    returns(
        uint160 sqrtPrice_96,
        int24 currentPoint,
        uint16 observationCurrentIndex,
        uint16 observationQueueLen,
        uint16 observationNextQueueLen,
        bool locked,
        uint128 liquidity,
        uint128 liquidityX
    );
    
    function observations(uint256 index)
        external
        view
        returns (
            uint32 timestamp,
            int56 accPoint,
            bool init
        );

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory accPoints);
}

interface IiZiSwapFactory {

    function fee2pointDelta(uint24 fee) external view returns (int24 pointDelta);

    function pool(
        address tokenX,
        address tokenY,
        uint24 fee
    ) external view returns(address);

}

interface IiZiSwapLiquidityManager {

    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
    
    // infomation of liquidity provided by miner
    struct Liquidity {
        // left point of liquidity-token, the range is [leftPt, rightPt)
        int24 leftPt;
        // right point of liquidity-token, the range is [leftPt, rightPt)
        int24 rightPt;
        // amount of liquidity on each point in [leftPt, rightPt)
        uint128 liquidity;
        // a 128-fixpoint number, as integral of { fee(pt, t)/L(pt, t) }. 
        // here fee(pt, t) denotes fee generated on point pt at time t
        // L(pt, t) denotes liquidity on point pt at time t
        // pt varies in [leftPt, rightPt)
        // t moves from pool created until miner last modify this liquidity-token (mint/addLiquidity/decreaseLiquidity/create)
        uint256 lastFeeScaleX_128;
        uint256 lastFeeScaleY_128;
        // remained tokenX miner can collect, including fee and withdrawed token
        uint256 remainTokenX;
        uint256 remainTokenY;
        // id of pool in which this liquidity is added
        uint128 poolId;
    }

    function liquidities(uint256 tokenId)
        external
        view
        returns (
            int24 leftPt,
            int24 rightPt,
            uint128 liquidity,
            uint256 lastFeeScaleX_128,
            uint256 lastFeeScaleY_128,
            uint256 remainTokenX,
            uint256 remainTokenY,
            uint128 poolId
        );
    
    struct PoolMeta {
        address tokenX;
        address tokenY;
        uint24 fee;
    }

    function poolMetas(uint128 poolId)
        external
        view
        returns (
            address tokenX,
            address tokenY,
            uint24 fee
        );

    struct MintParam {
        // miner address
        address miner;
        // tokenX of swap pool
        address tokenX;
        // tokenY of swap pool
        address tokenY;
        // fee amount of swap pool
        uint24 fee;
        // left point of added liquidity
        int24 pl;
        // right point of added liquidity
        int24 pr;
        // amount limit of tokenX miner willing to deposit
        uint128 xLim;
        // amount limit tokenY miner willing to deposit
        uint128 yLim;
        // minimum amount of tokenX miner willing to deposit
        uint128 amountXMin;
        // minimum amount of tokenY miner willing to deposit
        uint128 amountYMin;

        uint256 deadline;
    }
    
    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    function mint(MintParam calldata params)
        external
        payable
        returns (
            uint256 lid,
            uint128 liquidity,
            uint256 amountX,
            uint256 amountY
        );
    
    function decLiquidity(
        uint256 lid,
        uint128 liquidDelta,
        uint256 amountXMin,
        uint256 amountYMin,
        uint256 deadline
    ) external returns (
        uint256 amountX,
        uint256 amountY
    );

    function collect(
        address recipient,
        uint256 lid,
        uint128 amountXLim,
        uint128 amountYLim
    ) external payable returns (
        uint256 amountX,
        uint256 amountY
    );

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}