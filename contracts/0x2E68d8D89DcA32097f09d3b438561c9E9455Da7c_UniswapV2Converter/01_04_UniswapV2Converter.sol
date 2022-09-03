pragma solidity >=0.8.0;

import "IERC20.sol";
import "Ownable.sol";

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract UniswapV2Converter is Ownable {
    IUniswapV2Router public router;
    IUniswapV2Factory public factory;

    IERC20 public WETH;

    mapping(address => bool) internal isApproved;

    constructor(address _router) Ownable() {
        router = IUniswapV2Router(_router);
        factory = IUniswapV2Factory(router.factory());
        WETH = IERC20(router.WETH());
    }

    function swap(
        address source,
        address destination,
        uint256 value,
        address beneficiary
    ) external returns (uint256) {
        address[] memory path;
        if (factory.getPair(source, destination) != address(0)) {
            path = new address[](2);
            path[0] = source;
            path[1] = destination;
        } else {
            path = new address[](3);
            path[0] = source;
            path[1] = address(WETH);
            path[2] = destination;
        }
        if (!isApproved[source]) {
            IERC20(source).approve(address(router), type(uint256).max);
            isApproved[source] = true;
        }
        return
            router.swapExactTokensForTokens(
                value,
                1,
                path,
                beneficiary,
                block.timestamp
            )[path.length - 1];
    }
}