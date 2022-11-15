//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IEllipsisPool.sol";

contract EllipsisAdapter is Ownable {
    using SafeERC20 for IERC20;
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

    constructor(address _hermes) {
        hermes = _hermes;
    }

    function exchange(
        address pool,
        IERC20 src,
        IERC20 dst,
        uint8 i,
        uint8 j
    ) external onlyHermes {
        uint256 amountIn = src.balanceOf(address(this));
        // src.approve(pool, type(uint256).max); // Real Ellipsis requires this

        src.transfer(pool, amountIn); // Real Ellipsis does not require this

        IEllipsisPool(pool).exchange(int128(uint128(i)), int128(uint128(j)), amountIn, 0);
        emit HermesSwap(address(pool), address(src), address(dst), amountIn, dst.balanceOf(address(this)));
        dst.transfer(msg.sender, dst.balanceOf(address(this)));
    }

    function inCaseTokensGetStuck(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}