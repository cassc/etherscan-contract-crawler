pragma solidity ^0.8.0;

import "./AddressAccessControl.sol";
import "./BaseCoboSafeModuleAcl.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract NonfungiblePositionManagerAccessControl is
    BaseCoboSafeModuleAcl,
    AddressAccessControl
{
    address public v3Factory;
    constructor(
        address _safeAddress,
        address _safeModule,
        address _v3Factory,
        address[] memory pools
    ) {
        _setSafeAddressAndSafeModule(_safeAddress, _safeModule);
        _setV3Factory(_v3Factory);
        _addAddresses(pools);
    }

    function checkPool(address token0, address token1, uint24 fee) internal view {
        address pool_address = IUniswapV3Factory(v3Factory).getPool(token0, token1, fee);
        require(pool_address != address(0), "not existed v3 pool.");
        _checkAddress(pool_address);
    }

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

    function mint(MintParams calldata params) external view onlySelf {
        onlySafeAddress(params.recipient);
        checkPool(params.token0, params.token1, params.fee);
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external view onlySelf{
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external view onlySelf {

    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external view onlySelf { 
        onlySafeAddress(params.recipient);
    }

    function burn(uint256 tokenId)  external view onlySelf { }

    function _setV3Factory(address _v3Factory) internal {
        require(_v3Factory != address(0), "invalid v3PoolFactory address");
        v3Factory = _v3Factory;
    }

    function setV3Factory(address _v3Factory) external onlyOwner {
        _setV3Factory(_v3Factory);
    }
}