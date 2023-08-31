pragma solidity 0.6.6;

import "./ILinkswapERC20.sol";

interface ILinkswapPair is ILinkswapERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Lock(address indexed sender, uint256 lockupPeriod, uint256 liquidityLockupAmount);
    event Unlock(address indexed sender, uint256 liquidityUnlocked);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function addressToLockupExpiry(address) external view returns (uint256);

    function addressToLockupAmount(address) external view returns (uint256);

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

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function tradingFeePercent() external view returns (uint256);

    function lastSlippageBlocks() external view returns (uint256);

    function priceAtLastSlippageBlocks() external view returns (uint256);

    function lastSwapPrice() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function lock(uint256 lockupPeriod, uint256 liquidityLockupAmount) external;

    function unlock() external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function setTradingFeePercent(uint256 _tradingFeePercent) external;

    // functions only callable by LinkswapFactory
    function initialize(
        address _token0,
        address _token1,
        uint256 _tradingFeePercent
    ) external;

    function listingLock(
        address lister,
        uint256 lockupPeriod,
        uint256 liquidityLockupAmount
    ) external;
}