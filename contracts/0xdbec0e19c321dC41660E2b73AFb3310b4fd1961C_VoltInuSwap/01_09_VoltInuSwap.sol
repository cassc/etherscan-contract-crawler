// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IUniswapV2Factory {
    function getPair(address token0, address token1) external returns (address);
}

contract VoltInuSwap is OwnableUpgradeable {

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
    IUniswapV2Factory factory;
    address private UNISWAP_V2_ROUTER;
    address private UNISWAP_FACTORY;

    address private WETH;

    address internal constant deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public fee;
    address public pairAddress;

    function initialize(address uniswap_v2_router, address uniswap_factory, address _weth) public initializer {
        __Ownable_init();
        UNISWAP_V2_ROUTER = uniswap_v2_router;
        UNISWAP_FACTORY = uniswap_factory;
        WETH = _weth;
        fee = 50;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external {
        IERC20Upgradeable(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        // uint256 feeAmount = (_amountIn * fee) / 10000;
        // uint256 _amountInSub = _amountIn - feeAmount;

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                msg.sender,
                block.timestamp
            );

        // uint256 feeAmountHalf = feeAmount / 2;

        // if (!(_tokenIn == WETH)) {
        //     IERC20(_tokenIn).transferFrom(
        //         address(this),
        //         deadAddress,
        //         feeAmountHalf
        //     );

        //     IERC20(VOLT).approve(address(this), feeAmountHalf);
        //     IERC20(VOLT).transferFrom(
        //         address(this),
        //         deadAddress,
        //         feeAmountHalf
        //     );
        // }
    }

    function getPair(address _tokenIn, address _tokenOut)
        external
        returns (address)
    {
        return IUniswapV2Factory(UNISWAP_FACTORY).getPair(_tokenIn, _tokenOut);
    }

    function getAmountOutMin(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256) {
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswapV2Router02(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function setPairAddress(address _pair) external onlyOwner {
        pairAddress = _pair;
    }

    function setFactory(address _addr) external onlyOwner {
        UNISWAP_FACTORY = _addr;
    }

    function setRouter(address _addr) external onlyOwner {
        UNISWAP_V2_ROUTER = _addr;
    }

    function setWeth(address _addr) external onlyOwner {
        WETH = _addr;
    }
}