pragma solidity 0.8.15;

import "IERC20.sol";
import "Ownable.sol";
import "SafeERC20.sol";

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
    using SafeERC20 for IERC20;
    
    IUniswapV2Router public router;
    IUniswapV2Factory public factory;

    address public WETH;
    address public assetConverter;

    mapping(address => bool) internal isApproved;

    constructor(address _assetConverter, address _router) Ownable() {
        require(_assetConverter != address(0), "Zero address provided");
        require(_router != address(0), "Zero address provided");
        assetConverter = _assetConverter;
        router = IUniswapV2Router(_router);
        factory = IUniswapV2Factory(router.factory());
        WETH = router.WETH();
    }

    function swap(
        address source,
        address destination,
        uint256 value,
        address beneficiary
    ) external returns (uint256) {
        require(msg.sender == assetConverter, "Invalid caller");
        address[] memory path;
        if (factory.getPair(source, destination) != address(0)) {
            path = new address[](2);
            path[0] = source;
            path[1] = destination;
        } else {
            if ((factory.getPair(source, WETH) != address(0)) && (factory.getPair(WETH, destination) != address(0))) {
                path = new address[](3);
                path[0] = source;
                path[1] = WETH;
                path[2] = destination;
            }
            else {
                revert("Route was not found");
            }
        }
        if (!isApproved[source]) {
            IERC20(source).safeIncreaseAllowance(address(router), type(uint256).max);
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