// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/// @title Interface for LiquidityManager
interface ILiquidityManager {
    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address);

    /// parameters when calling mint, grouped together to avoid stake too deep
    struct MintParam {
        // miner address
        address miner;
        // tokenX of swap pool
        address tokenX;
        // tokenY of swap pool
        address tokenY;
        // fee amount of swap pool
        uint16 fee;
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
    /// @notice Add a new liquidity and generate a nft.
    /// @param mintParam params, see MintParam for more
    /// @return lid id of nft
    /// @return liquidity amount of liquidity added
    /// @return amountX amount of tokenX deposited
    /// @return amountY amount of tokenY depsoited
    function mint(MintParam calldata mintParam) external payable returns(
        uint256 lid,
        uint128 liquidity,
        uint256 amountX,
        uint256 amountY
    );

    /// parameters when calling addLiquidity, grouped together to avoid stake too deep
    struct AddLiquidityParam {
        // id of nft
        uint256 lid;
        // amount limit of tokenX user willing to deposit
        uint128 xLim;
        // amount limit of tokenY user willing to deposit
        uint128 yLim;
        // min amount of tokenX user willing to deposit
        uint128 amountXMin;
        // min amount of tokenY user willing to deposit
        uint128 amountYMin;

        uint256 deadline;
    }

    /// @notice Add liquidity to a existing nft.
    /// @param addLiquidityParam see AddLiquidityParam for more
    /// @return liquidityDelta amount of added liquidity
    /// @return amountX amount of tokenX deposited
    /// @return amountY amonut of tokenY deposited
    function addLiquidity(
        AddLiquidityParam calldata addLiquidityParam
    ) external payable returns (
        uint128 liquidityDelta,
        uint256 amountX,
        uint256 amountY
    );

    /// @notice Decrease liquidity from a nft.
    /// @param lid id of nft
    /// @param liquidDelta amount of liqudity to decrease
    /// @param amountXMin min amount of tokenX user want to withdraw
    /// @param amountYMin min amount of tokenY user want to withdraw
    /// @param deadline deadline timestamp of transaction
    /// @return amountX amount of tokenX refund to user
    /// @return amountY amount of tokenY refund to user
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

    function liquidities(uint256 lid) external view returns(
        int24 leftPt,
    // right point of liquidity-token, the range is [leftPt, rightPt)
        int24 rightPt,
    // amount of liquidity on each point in [leftPt, rightPt)
        uint128 liquidity,
    // a 128-fixpoint number, as integral of { fee(pt, t)/L(pt, t) }.
    // here fee(pt, t) denotes fee generated on point pt at time t
    // L(pt, t) denotes liquidity on point pt at time t
    // pt varies in [leftPt, rightPt)
    // t moves from pool created until miner last modify this liquidity-token (mint/addLiquidity/decreaseLiquidity/create)
        uint256 lastFeeScaleX_128,
        uint256 lastFeeScaleY_128,
    // remained tokenX miner can collect, including fee and withdrawed token
        uint256 remainTokenX,
        uint256 remainTokenY,
    // id of pool in which this liquidity is added
        uint128 poolId
    );

    function poolMetas(uint128 poolId) external view returns(
    // tokenX of pool
        address tokenX,
    // tokenY of pool
        address tokenY,
    // fee amount of pool
        uint16 fee
    );
    /// @notice Collect fee gained of token withdrawed from nft.
    /// @param recipient address to receive token
    /// @param lid id of nft
    /// @param amountXLim amount limit of tokenX to collect
    /// @param amountYLim amount limit of tokenY to collect
    /// @return amountX amount of tokenX actually collect
    /// @return amountY amount of tokenY actually collect
    function collect(
        address recipient,
        uint256 lid,
        uint128 amountXLim,
        uint128 amountYLim
    ) external payable returns (
        uint256 amountX,
        uint256 amountY
    );
}