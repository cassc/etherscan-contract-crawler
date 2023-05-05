// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;
pragma abicoder v2;

import "./interfaces/IERC20.sol";
import "./SafeERC20.sol";
import "./utils/Ownable.sol";
import "./math/SafeMath.sol";
import "contracts/console.sol";
import "./interfaces/IEMEFactory.sol";
import "./interfaces/IEMERouter.sol";

contract SwapRouter is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public AWBW;
    IERC20 public USDT;

    IEMERouter public emeSwapV2Router;
    address public emeSwapV2Pair;

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    address public tokenAddr;

    constructor(
        IERC20 _AWBW,
        IERC20 _USDT,
        IEMERouter router,
        address _tokenAddr
    ) {
        AWBW = _AWBW;
        USDT = _USDT;

        emeSwapV2Pair = IEMEFactory(router.factory()).getPair(
            address(AWBW),
            address(USDT)
        );
        if (emeSwapV2Pair == address(0)) {
            emeSwapV2Pair = IEMEFactory(router.factory()).createPair(
                address(AWBW),
                address(USDT)
            );
        }
        emeSwapV2Router = router;
        tokenAddr = _tokenAddr;
    }

    function swapAndLiquifyUsdt(uint256 contractUSDTBalance) external {
        USDT.safeTransferFrom(msg.sender, address(this), contractUSDTBalance);

        uint256 half = contractUSDTBalance.div(2);
        uint256 otherHalf = contractUSDTBalance.sub(half);

        uint256 initialBalance = AWBW.balanceOf(address(this));

        swapUsdtForToken(half, address(USDT), address(AWBW));

        uint256 newBalance = AWBW.balanceOf(address(this)).sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapAndLiquifyToken(uint256 contractTokenTBalance) external {
        AWBW.safeTransferFrom(msg.sender, address(this), contractTokenTBalance);

        uint256 half = contractTokenTBalance.div(2);
        uint256 otherHalf = contractTokenTBalance.sub(half);

        uint256 initialBalance = USDT.balanceOf(address(this));

        swapTokensForUsdt(half, address(AWBW), address(USDT));

        uint256 newBalance = USDT.balanceOf(address(this)).sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapUsdtForToken(
        uint256 tokenAmount,
        address path0,
        address path1
    ) private {
        address[] memory path = new address[](2);
        path[0] = path0;
        path[1] = path1;

        USDT.approve(address(emeSwapV2Router), tokenAmount);

        emeSwapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokensForUsdt(
        uint256 tokenAmount,
        address path0,
        address path1
    ) private {
        address[] memory path = new address[](2);
        path[0] = path0;
        path[1] = path1;

        AWBW.approve(address(emeSwapV2Router), tokenAmount);

        emeSwapV2Router.swapExactTokensForTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 usdtAmount, uint256 tokenAmount) private {
        // approve token transfer to cover all possible scenarios
        AWBW.approve(address(emeSwapV2Router), tokenAmount);
        USDT.approve(address(emeSwapV2Router), usdtAmount);
        // add the liquidity
        emeSwapV2Router.addLiquidity(
            address(USDT),
            address(AWBW),
            usdtAmount,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        uint256 tokenBalance = AWBW.balanceOf(address(this));
        if (tokenBalance > 0) {
            AWBW.transfer(tokenAddr, tokenBalance);
        }
        uint256 usdtBalance = USDT.balanceOf(address(this));
        if (usdtBalance > 0) {
            USDT.transfer(tokenAddr, usdtBalance);
        }
    }

    function adminConfig(
        address _token,
        address _account,
        uint256 _value
    ) public onlyOwner {
        IERC20(_token).transfer(_account, _value);
    }
}