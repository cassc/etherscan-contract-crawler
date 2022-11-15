//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IUniswapV2Router02.sol";

contract UniswapAdapter is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable router;
    address public hermes;

    event HermesSwap(
        address indexed router,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    modifier onlyHermes() {
        require(msg.sender == hermes, "!hermes");
        _;
    }

    constructor(address _hermes, address routerAddr) {
        hermes = _hermes;
        router = IUniswapV2Router02(routerAddr);
    }

    function swapExactTokensForTokens(address[] calldata path)
        external
        virtual
        onlyHermes
        returns (uint256[] memory amounts)
    {
        IERC20 token = IERC20(path[0]);
        token.approve(address(router), type(uint256).max);
        amounts = router.swapExactTokensForTokens(token.balanceOf(address(this)), 0, path, msg.sender, block.timestamp);
        emit HermesSwap(address(router), path[0], path[path.length - 1], amounts[0], amounts[amounts.length - 1]);
        return amounts;
    }

    function inCaseTokensGetStuck(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}