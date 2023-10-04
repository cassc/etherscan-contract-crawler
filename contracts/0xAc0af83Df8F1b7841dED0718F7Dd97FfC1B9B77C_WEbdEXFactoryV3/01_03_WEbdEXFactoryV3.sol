//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WEbdEXFactoryV3 is Ownable {
    Bot[] internal bots;
    address public faucets;
    address public wusd;
    address public usdt;
    address public dai;
    address public usdc;
    address public switchWUSD;
    address public swapBook;
    address public payments;

    struct Bot {
        string name;
        string wallet;
        address faucets;
        address wusd;
        address usdt;
        address dai;
        address usdc;
        address botManager;
        address switchWUSD;
        address swapBook;
        address pass;
        address networkPool;
        address strategies;
        address payments;
    }

    constructor(
        address faucets_,
        address wusd_,
        address usdt_,
        address dai_,
        address usdc_,
        address switchWUSD_,
        address swapBook_,
        address payments_
    ) {
        faucets = faucets_;
        wusd = wusd_;
        usdt = usdt_;
        dai = dai_;
        usdc = usdc_;
        switchWUSD = switchWUSD_;
        swapBook = swapBook_;
        payments = payments_;
    }

    function addBot(
        string memory name,
        string memory wallet,
        address botManager,
        address pass,
        address strategies,
        address networkPool
    ) public onlyOwner {
        bots.push(
            Bot(
                name,
                wallet,
                faucets,
                wusd,
                usdt,
                dai,
                usdc,
                botManager,
                switchWUSD,
                swapBook,
                pass,
                networkPool,
                strategies,
                payments
            )
        );
    }

    function getBots() public view onlyOwner returns (Bot[] memory) {
        return bots;
    }
}