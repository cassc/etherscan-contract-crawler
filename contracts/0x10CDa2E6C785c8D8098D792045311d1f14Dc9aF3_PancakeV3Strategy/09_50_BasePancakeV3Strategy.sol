// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../libraries/SafeAssetConverter.sol";
import "../../libraries/PancakeV3Library.sol";
import "./BaseConcentratedLiquidityStrategy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

abstract contract BasePancakeV3Strategy is BaseConcentratedLiquidityStrategy, IERC721Receiver {
    using SafeERC20 for IERC20;
    using PancakeV3Library for PancakeV3Library.Data;
    using SafeAssetConverter for IAssetConverter;

    PancakeV3Library.Data public pancakeswap;
    IERC20 public CAKE;

    constructor(IMasterChefV3 farm, uint256 pid) {
        IPancakeV3Pool pool = IPancakeV3Pool(farm.poolInfo(pid).v3Pool);
        INonfungiblePositionManager positionManager = INonfungiblePositionManager(farm.nonfungiblePositionManager());
        pancakeswap = PancakeV3Library.Data({
            token0: pool.token0(),
            token1: pool.token1(),
            fee: pool.fee(),
            positionManager: positionManager,
            farm: farm,
            pool: pool,
            positionTokenId: 0,
            tickSpacing: pool.tickSpacing()
        });

        CAKE = IERC20(farm.CAKE());

        Utils.approveIfZeroAllowance(pancakeswap.token0, address(positionManager));
        Utils.approveIfZeroAllowance(pancakeswap.token1, address(positionManager));
        Utils.approveIfZeroAllowance(pancakeswap.token0, address(farm));
        Utils.approveIfZeroAllowance(pancakeswap.token1, address(farm));
        Utils.approveIfZeroAllowance(address(CAKE), address(assetConverter));
    }

    function token0() public view override returns (address) {
        return pancakeswap.token0;
    }

    function token1() public view override returns (address) {
        return pancakeswap.token1;
    }

    function _isPositionExists() internal view override returns (bool) {
        return !(pancakeswap.positionTokenId == 0);
    }

    function _tickSpacing() internal view override returns (int24) {
        return pancakeswap.tickSpacing;
    }

    function _increaseLiquidity(uint256 amount0, uint256 amount1) internal override {
        pancakeswap.increaseLiquidity(amount0, amount1);
    }

    function _decreaseLiquidity(uint128 liquidity) internal override returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = pancakeswap.decreaseLiquidity(liquidity);
    }

    function _mint(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1) internal override {
        pancakeswap.mint(tickLower, tickUpper, amount0, amount1);
        pancakeswap.enterFarming();
    }

    function getPoolData() public view override returns (int24 currentTick, uint160 sqrtPriceX96) {
        return pancakeswap.getPoolData();
    }

    function getPositionData() public view override returns (PositionData memory) {
        return pancakeswap.getPositionData();
    }

    function _collectAllAndBurn() internal override {
        pancakeswap.collect(type(uint128).max, type(uint128).max);
        pancakeswap.burn();
    }

    function _collect() internal override {
        pancakeswap.collect(type(uint128).max, type(uint128).max);
    }

    function _harvest() internal virtual override {
        if (pancakeswap.positionTokenId == 0) {
            return;
        }

        pancakeswap.claimFarmRewards();
        assetConverter.safeSwap(address(CAKE), asset(), CAKE.balanceOf(address(this)));

        super._harvest();
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}