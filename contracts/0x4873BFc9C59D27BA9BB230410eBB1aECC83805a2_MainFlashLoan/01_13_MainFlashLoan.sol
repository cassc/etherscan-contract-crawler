// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ILendingPool.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "hardhat/console.sol";

contract MainFlashLoan is FlashLoanSimpleReceiverBase, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Router02 public sushiswapV1Router;
    uint256 public deadline;

    enum RouterPath {
        UniswapToSushiswap,
        SushiswapToUniswap
    }

    RouterPath public theWay;

    error NotForProfit(string);

    constructor() FlashLoanSimpleReceiverBase(IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e)) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        sushiswapV1Router = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    }

    function checkArbitrageOpportunity(address uniPool, address sushiPool) public view returns (RouterPath) {
        uint256 uniswapPrice = getUniswapPrice(uniPool); // Price of LINK in terms of USDT on Uniswap
        uint256 sushiswapPrice = getSushiswapPrice(sushiPool); // Price of LINK in terms of USDT on Sushiswap

        if (uniswapPrice < sushiswapPrice) {
            // console.log("SMall UNI");
            return RouterPath.UniswapToSushiswap;
        } else if (sushiswapPrice < uniswapPrice) {
            // console.log("SMall SUSHI");

            return RouterPath.SushiswapToUniswap;
        }
        revert NotForProfit("NON-PROFIT");
    }

    function getUniswapPrice(address uniPool) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniPool);
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 token0Decimals = IERC20(pair.token0()).decimals();
        uint256 token1Decimals = IERC20(pair.token1()).decimals();

        if (token0Decimals > token1Decimals) {
            reserve1 = reserve1 * (10 ** (token0Decimals - token1Decimals));
        } else if (token1Decimals > token0Decimals) {
            reserve0 = reserve0 * (10 ** (token1Decimals - token0Decimals));
        }
        // console.log("UNISWAP PRICE", (reserve0 * 1e18) / reserve1);
        return (reserve0 * 1e18) / reserve1;
    }

    function getSushiswapPrice(address sushiPool) public view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(sushiPool);
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 token0Decimals = IERC20(pair.token0()).decimals();
        uint256 token1Decimals = IERC20(pair.token1()).decimals();

        if (token0Decimals > token1Decimals) {
            reserve1 = reserve1 * (10 ** (token0Decimals - token1Decimals));
        } else if (token1Decimals > token0Decimals) {
            reserve0 = reserve0 * (10 ** (token1Decimals - token0Decimals));
        }
        // console.log("SUSHISWAP PRICE", (reserve0 * 1e18) / reserve1);

        return (reserve0 * 1e18) / reserve1;
    }

    function approveUniswapRouter(address token, uint256 amount) public {
        IERC20(token).approve(address(uniswapV2Router), amount);
    }

    function approveSushiswapRouter(address token, uint256 amount) public {
        IERC20(token).approve(address(sushiswapV1Router), amount);
    }

    function executeOperation(
        address assets,
        uint256 amounts,
        uint256 premiums,
        address, /* initiator */
        bytes calldata params
    ) external override returns (bool) {
        // console.log("Inside Execute operations");
        // Extract pool addresses from the params
        (address uniPool, address sushiPool) = abi.decode(params, (address, address));
        // console.log("UniPool", uniPool);
        // console.log("sushiPool", sushiPool);

        // Check for arbitrage opportunity
        RouterPath direction = checkArbitrageOpportunity(uniPool, sushiPool);

        // console.log("direction");

        // console.log("Uniswap Router token0", IUniswapV2Pair(uniPool).token0());

        // Approve the routers to spend tokens
        approveUniswapRouter(IUniswapV2Pair(uniPool).token0(), amounts);
        approveSushiswapRouter(IUniswapV2Pair(sushiPool).token0(), amounts);
        approveUniswapRouter(IUniswapV2Pair(uniPool).token1(), amounts);
        approveSushiswapRouter(IUniswapV2Pair(sushiPool).token1(), amounts);

        // console.log("Allowance before swap: ", IERC20(assets).allowance(address(this), address(uniswapV2Router)));
        // console.log("Balance before swap token 0: ", IERC20(IUniswapV2Pair(uniPool).token0()).balanceOf(address(this)));
        // console.log("Balance before swap token 1: ", IERC20(IUniswapV2Pair(uniPool).token1()).balanceOf(address(this)));
        // console.log("Asset", assets);
        // console.log("Token0:", IUniswapV2Pair(uniPool).token0());
        // console.log("Token1:", IUniswapV2Pair(uniPool).token1());


        if (direction == RouterPath.UniswapToSushiswap) {
            // console.log("RouterPath.UniswapToSushiswap");

            uniswapV2Router.swapExactTokensForTokens(
                amounts,
                0,
                getPathForTokenToToken(IUniswapV2Pair(uniPool).token1(), IUniswapV2Pair(uniPool).token0()),
                address(this),
                block.timestamp + 1800
            );
            // console.log(
            //     "Balance after token 0: ", IERC20(IUniswapV2Pair(uniPool).token0()).balanceOf(address(this))
            // );
            // console.log(
            //     "Balance after token 1: ", IERC20(IUniswapV2Pair(uniPool).token1()).balanceOf(address(this))
            // );

            // console.log("Allowance if token0: ", IERC20(IUniswapV2Pair(sushiPool).token0()).allowance(address(this), address(sushiswapV1Router)));

            sushiswapV1Router.swapExactTokensForTokens(
                IERC20(IUniswapV2Pair(sushiPool).token0()).balanceOf(address(this)),
                0,
                getPathForTokenToToken(IUniswapV2Pair(sushiPool).token0(), IUniswapV2Pair(sushiPool).token1()),
                address(this),
                block.timestamp + 1800
            );

            // console.log(
            //     "Balance Final token 0: ", IERC20(IUniswapV2Pair(uniPool).token0()).balanceOf(address(this))
            // );
            // console.log(
            //     "Balance Final token 1: ", IERC20(IUniswapV2Pair(uniPool).token1()).balanceOf(address(this))
            // );
        } else if (direction == RouterPath.SushiswapToUniswap) {
            // console.log("RouterPath.SushiswapToUniswap");

            sushiswapV1Router.swapExactTokensForTokens(
                amounts,
                0,
                getPathForTokenToToken(IUniswapV2Pair(sushiPool).token1(), IUniswapV2Pair(sushiPool).token0()),
                address(this),
                block.timestamp + 1800
            );

            uniswapV2Router.swapExactTokensForTokens(
                IERC20(IUniswapV2Pair(sushiPool).token0()).balanceOf(address(this)),
                0,
                getPathForTokenToToken(IUniswapV2Pair(uniPool).token0(), IUniswapV2Pair(uniPool).token1()),
                address(this),
                block.timestamp + 1800
            );
        }

        uint256 amountOwed = amounts + premiums;
        IERC20(assets).approve(address(POOL), amountOwed);
        return true;
    }

    function requestFlashLoan(address _token, uint256 _amount, address uniPool, address sushiPool) public onlyOwner {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = abi.encode(uniPool, sushiPool);
        uint16 referralCode = 0;
        // console.log("===================BEFORE REQUEST=====================");
        // console.log("Asset", asset);
        POOL.flashLoanSimple(receiverAddress, asset, amount, params, referralCode);
        // console.log("===================AFTER REQUEST=====================");
    }

    function withdrawETHBalance() public payable onlyOwner {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function withdrawERC20Balance(address _tokenAddress) public payable onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, IERC20(_tokenAddress).balanceOf(address(this)));
    }

    function getPathForTokenToToken(address ERC20Token0, address ERC20Token1) public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = ERC20Token0;
        path[1] = ERC20Token1;
        return path;
    }

    receive() external payable {}
}