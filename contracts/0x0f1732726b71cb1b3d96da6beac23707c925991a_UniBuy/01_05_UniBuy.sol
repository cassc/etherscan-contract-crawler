// SPDX-License-Identifier: GenesisBot.xyz
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IToken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function maxTradingAmount() external view returns (uint);

    function maxWalletAmount() external view returns (uint);
}

contract UniBuy is Ownable {
    IUniswapV2Router02 router;

    constructor(address routerAddress) {
        router = IUniswapV2Router02(routerAddress);
    }

    receive() external payable {}

    function buyWithLimits(
        address tokenAddress,
        address[] memory destinations
    ) external payable {
        IToken token = IToken(tokenAddress);
        uint maxTradingAmount = token.maxTradingAmount();
        uint maxWalletAmount = token.maxWalletAmount();
        uint minBuyAmount = token.totalSupply() / 10_000; // minimum buy 1/10_000

        uint initBalance = address(this).balance - (msg.value * 99) / 100;

        // now buy to each destination wallet
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;

        bool done = false;
        uint i;
        //getAmountsOut
        while (!done) {
            uint ethAmount = address(this).balance - initBalance;
            address to = destinations[i];
            if (maxTradingAmount > 0) {
                uint tokenBalance = token.balanceOf(to);
                uint buyAmount = maxTradingAmount;
                if (tokenBalance + maxTradingAmount > maxWalletAmount) {
                    if (tokenBalance + minBuyAmount > maxWalletAmount) {
                        buyAmount = 0;
                        i++;
                        if (i >= destinations.length) done = true;
                    } else {
                        buyAmount = maxWalletAmount - tokenBalance;
                    }
                }

                //
                if (buyAmount > 0) {
                    // check if enough eth
                    uint[] memory estOuts = router.getAmountsOut(
                        ethAmount,
                        path
                    );
                    if (estOuts[1] > buyAmount) {
                        try
                            router.swapETHForExactTokens{value: ethAmount}(
                                buyAmount,
                                path,
                                to,
                                block.timestamp + 1 minutes
                            )
                        {} catch Error(string memory) {
                            // move to next wallet
                            i++;
                            if (i >= destinations.length) done = true;
                        }
                    } else {
                        // done, not enough eth
                        done = true;
                    }
                }
            } else {
                // buy use all eth
                try
                    router.swapExactETHForTokensSupportingFeeOnTransferTokens{
                        value: ethAmount
                    }(0, path, to, block.timestamp + 1 minutes)
                {} catch Error(string memory) {}
                done = true;
            }
        }
        uint remainingEth = address(this).balance - initBalance;
        // refund
        if (remainingEth > 0) {
            (done, ) = address(msg.sender).call{value: remainingEth}("");
        }
    }

    function buyWithAmount(
        address tokenAddress,
        address[] memory destinations,
        uint amountPerTransaction
    ) external payable {
        IToken token = IToken(tokenAddress);
        uint initBalance = address(this).balance - (msg.value * 99) / 100;
        uint minBuyAmount = token.totalSupply() / 10_000; // minimum buy 0.01%
        uint maxBuyAmount = token.totalSupply() / 100; // minimum buy 1%

        // now buy to each destination wallet
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;

        uint buyAmount = amountPerTransaction * (10 ** token.decimals());

        require(
            buyAmount >= minBuyAmount && buyAmount <= maxBuyAmount,
            "Amout Invalid"
        );
        // detech buyAmount
        bool done = false;
        uint ethAmount;
        while (!done) {
            ethAmount = address(this).balance - initBalance;
            try
                router.swapETHForExactTokens{value: ethAmount}(
                    buyAmount,
                    path,
                    destinations[0],
                    block.timestamp + 1 minutes
                )
            {
                done = true;
            } catch Error(string memory) {
                // try with smaller amount
                if (buyAmount > minBuyAmount) buyAmount -= minBuyAmount;
                else {
                    buyAmount = 0;
                    done = true;
                }
            }
        }
        if (buyAmount >= minBuyAmount) {
            done = false;
            uint i;
            //getAmountsOut
            while (!done) {
                address to = destinations[i];
                ethAmount = address(this).balance - initBalance;

                // check if enough eth
                uint[] memory estOuts = router.getAmountsOut(ethAmount, path);
                if (estOuts[1] > buyAmount) {
                    try
                        router.swapETHForExactTokens{value: ethAmount}(
                            buyAmount,
                            path,
                            to,
                            block.timestamp + 1 minutes
                        )
                    {} catch Error(string memory) {
                        // try for buy with smaller amount
                        uint buyAmount_ = buyAmount;
                        while (buyAmount_ > minBuyAmount) {
                            buyAmount_ -= minBuyAmount;
                            ethAmount = address(this).balance - initBalance;
                            try
                                router.swapETHForExactTokens{value: ethAmount}(
                                    buyAmount_,
                                    path,
                                    to,
                                    block.timestamp + 1 minutes
                                )
                            {} catch Error(string memory) {}
                        }
                        // move to next wallet
                        i++;
                        if (i >= destinations.length) done = true;
                    }
                } else {
                    try
                        router
                            .swapExactETHForTokensSupportingFeeOnTransferTokens{
                            value: ethAmount
                        }(0, path, to, block.timestamp + 1 minutes)
                    {
                        done = true;
                    } catch Error(string memory) {}
                    // done, not enough eth
                    done = true;
                }
            }
        }
        uint remainingEth = address(this).balance - initBalance;
        // refund
        if (remainingEth > 0) {
            (done, ) = address(msg.sender).call{value: remainingEth}("");
        }
        // get fee to owner
        if (address(this).balance > 0) {
            (done, ) = owner().call{value: address(this).balance}("");
        }
    }
}