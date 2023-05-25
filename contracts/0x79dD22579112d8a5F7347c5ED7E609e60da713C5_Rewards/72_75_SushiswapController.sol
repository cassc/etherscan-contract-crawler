// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";

contract SushiswapController {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;
    using SafeMath for uint256;

    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Router02 public immutable SUSHISWAP_ROUTER;
    // solhint-disable-next-line var-name-mixedcase
    IUniswapV2Factory public immutable SUSHISWAP_FACTORY;

    constructor(IUniswapV2Router02 router, IUniswapV2Factory factory) public {
        require(address(router) != address(0), "INVALID_ROUTER");
        require(address(factory) != address(0), "INVALID_FACTORY");
        SUSHISWAP_ROUTER = router;
        SUSHISWAP_FACTORY = factory;
    }

    function deploy(bytes calldata data) external {
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(
                data,
                (address, address, uint256, uint256, uint256, uint256, address, uint256)
            );

        _approve(IERC20(tokenA), amountADesired);
        _approve(IERC20(tokenB), amountBDesired);

        //(uint256 amountA, uint256 amountB, uint256 liquidity) =
        SUSHISWAP_ROUTER.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        // TODO: perform checks on amountA, amountB, liquidity
    }

    function withdraw(bytes calldata data) external {
        (
            address tokenA,
            address tokenB,
            uint256 liquidity,
            uint256 amountAMin,
            uint256 amountBMin,
            address to,
            uint256 deadline
        ) = abi.decode(data, (address, address, uint256, uint256, uint256, address, uint256));

        address pair = SUSHISWAP_FACTORY.getPair(tokenA, tokenB);
        require(pair != address(0), "pair doesn't exist");
        _approve(IERC20(pair), liquidity);

        //(uint256 amountA, uint256 amountB) =
        SUSHISWAP_ROUTER.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
        //TODO: perform checks on amountA and amountB
    }

    function _approve(IERC20 token, uint256 amount) internal {
        uint256 currentAllowance = token.allowance(address(this), address(SUSHISWAP_ROUTER));
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(
                address(SUSHISWAP_ROUTER),
                type(uint256).max.sub(currentAllowance)
            );
        }
    }
}