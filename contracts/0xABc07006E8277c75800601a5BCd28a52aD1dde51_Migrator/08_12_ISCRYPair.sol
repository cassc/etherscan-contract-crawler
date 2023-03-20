// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20Permit.sol';

interface ISCRYPair is ISCRYERC20Permit {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function burnUnbalanced(address to, uint token0Min, uint token1Min) external returns (uint amount0, uint amount1);
    function burnUnbalancedForExactToken(address to, address exactToken, uint amountExactOut) external returns (uint, uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address, address, address) external;

    function setIsFlashSwapEnabled(bool _isFlashSwapEnabled) external;
    function setFeeToAddresses(address _feeTo0, address _feeTo1) external;
    function setRouter(address _router) external;
    function getSwapFee() external view returns (uint256);
}