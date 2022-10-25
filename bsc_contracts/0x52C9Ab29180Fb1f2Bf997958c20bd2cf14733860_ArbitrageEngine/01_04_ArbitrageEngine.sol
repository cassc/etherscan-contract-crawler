// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract ArbitrageEngine {
    address public owner;

    // Events
    event Received(address sender, uint256 value);
    event Withdraw(address to, uint256 value);
    event Minner_fee(uint256 value);
    event Withdraw_token(address to, uint256 value);

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the Owner");
        _;
    }

    function start(
        address srcRouter,
        address destRouter,
        address token0,
        address token1,
        uint256 amount,
        uint256 maxBlockNumber,
        bool profitCheck,
        bool checkOutMinAmount
    ) external onlyOwner {
        require(block.number <= maxBlockNumber, "e00");

        // recheck for stopping and gas usage
        (uint256 profit, uint256 outAmounts, uint256 outRepays) = _profitCheck(
            token0,
            token1,
            amount,
            srcRouter,
            destRouter
        );

        if (profitCheck) {
            // profit needs to be greater than 0, otherwise revert a transaction
            require(profit > 0, "e01");
        }

        if (checkOutMinAmount) {
            _swap(amount, outAmounts, srcRouter, token0, token1);
            _swap(outAmounts, outRepays, destRouter, token1, token0);
        } else {
            _swap(amount, 0, srcRouter, token0, token1);
            _swap(outAmounts, 0, destRouter, token1, token0);
        }
    }

    function withdraw_token(address _token) external onlyOwner returns (bool) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "There is no token balance!");
        bool check = IERC20(_token).transfer(owner, balance);

        emit Withdraw_token(owner, balance);
        return check;
    }

    function _swap(
        uint256 amountIn,
        uint256 amountOutMin,
        address routerAddress,
        address sell_token,
        address buy_token
    ) internal {
        IERC20(sell_token).approve(routerAddress, amountIn);

        address[] memory path = new address[](2);
        path[0] = sell_token;
        path[1] = buy_token;

        IUniswapV2Router02(routerAddress)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                block.timestamp
            );
    }

    function _profitCheck(
        address _tokenPay, // source currency when we will get; example BNB
        address _tokenSwap, // swapped currency with the source currency; example BUSD
        uint256 _amountTokenPay, // example: BNB => 10 * 1e18
        address _sourceRouter,
        address _targetRouter
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address[] memory path1 = new address[](2);
        address[] memory path2 = new address[](2);

        // path1 represents the forwarding exchange from source currency to swapped currency
        path1[0] = path2[1] = _tokenPay;
        // path2 represents the backward exchange from swapeed currency to source currency
        path1[1] = path2[0] = _tokenSwap;

        uint256 amountOut = IUniswapV2Router02(_sourceRouter).getAmountsOut(
            _amountTokenPay,
            path1
        )[1];
        uint256 amountRepay = IUniswapV2Router02(_targetRouter).getAmountsOut(
            amountOut,
            path2
        )[1];

        return (
            amountRepay > _amountTokenPay
                ? uint256(amountRepay - _amountTokenPay)
                : 0, // our profit or loss; example output: BNB
            amountOut,
            amountRepay // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}