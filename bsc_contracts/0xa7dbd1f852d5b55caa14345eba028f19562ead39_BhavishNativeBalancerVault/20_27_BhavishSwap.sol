// SPDX-License-Identifier: BSD-4-Clause

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../Interface/IBhavishSDK.sol";

pragma solidity ^0.8.13;

contract BhavishSwap is AccessControl {
    using SafeERC20 for IERC20;

    address public UNISWAP_FACTORY;
    address public UNISWAP_ROUTER;
    mapping(bytes32 => address[]) public pathMapper;
    uint256 public decimals = 3;

    struct SwapStruct {
        uint256 amountIn;
        uint256 deadline;
        bytes32 fromAsset;
        bytes32 toAsset;
    }

    modifier onlyAsset(bytes32 fromAsset, bytes32 toAsset) {
        address[] memory path = getPath(fromAsset, toAsset);
        require(path.length > 1, "Asset swap not supported");
        _;
    }

    modifier onlyAdmin(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "Address not an admin");
        _;
    }

    constructor(address uniswapFactory, address uniswapRouter) {
        UNISWAP_FACTORY = uniswapFactory;
        UNISWAP_ROUTER = uniswapRouter;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Add funds
     */
    receive() external payable {}

    function setPath(
        bytes32 fromAsset,
        bytes32 toAsset,
        address[] memory path
    ) external onlyAdmin(msg.sender) {
        require(path.length > 1, "Path cannot be empty or 1");
        pathMapper[keccak256((abi.encode(fromAsset, toAsset)))] = path;
    }

    function getPath(bytes32 fromAsset, bytes32 toAsset) public view returns (address[] memory) {
        return pathMapper[keccak256(abi.encode(fromAsset, toAsset))];
    }

    // Get the amounts out for the specified path
    function getAmountsOut(
        uint256 amountIn,
        bytes32 fromAsset,
        bytes32 toAsset
    ) public view onlyAsset(fromAsset, toAsset) returns (uint256[] memory amounts) {
        address[] memory path = getPath(fromAsset, toAsset);
        amounts = new uint256[](path.length);
        amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(amountIn, path);
    }

    function swapExactTokensForETH(
        SwapStruct memory _swapStruct,
        address to,
        uint256 slippage
    ) external onlyAsset(_swapStruct.fromAsset, _swapStruct.toAsset) returns (uint256[] memory amounts) {
        address[] memory path = getPath(_swapStruct.fromAsset, _swapStruct.toAsset);
        uint256[] memory amountsOut = getAmountsOut(_swapStruct.amountIn, _swapStruct.fromAsset, _swapStruct.toAsset);
        uint256 amountOut = amountsOut[amountsOut.length - 1] -
            ((amountsOut[amountsOut.length - 1] * slippage) / 10**decimals);
        IERC20(path[0]).safeApprove(UNISWAP_ROUTER, _swapStruct.amountIn);
        amounts = IUniswapV2Router02(UNISWAP_ROUTER).swapExactTokensForETH(
            _swapStruct.amountIn,
            amountOut,
            path,
            to,
            _swapStruct.deadline
        );
    }

    function swapExactETHForTokens(
        SwapStruct memory _swapStruct,
        address to,
        uint256 slippage
    ) external payable onlyAsset(_swapStruct.fromAsset, _swapStruct.toAsset) returns (uint256[] memory amounts) {
        address[] memory path = getPath(_swapStruct.fromAsset, _swapStruct.toAsset);
        uint256[] memory amountsOut = getAmountsOut(msg.value, _swapStruct.fromAsset, _swapStruct.toAsset);
        uint256 amountOut = amountsOut[amountsOut.length - 1] -
            ((amountsOut[amountsOut.length - 1] * slippage) / 10**decimals);
        amounts = IUniswapV2Router02(UNISWAP_ROUTER).swapExactETHForTokens{ value: msg.value }(
            amountOut,
            path,
            to,
            _swapStruct.deadline
        );
    }
}