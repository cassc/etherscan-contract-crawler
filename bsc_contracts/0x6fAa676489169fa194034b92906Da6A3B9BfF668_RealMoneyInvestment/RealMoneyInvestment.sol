/**
 *Submitted for verification at BscScan.com on 2022-10-14
*/

// SPDX-License-Identifier: UNLICENSED
// Declared the versions of the Solidity compiler
pragma solidity ^0.8.16;

contract RealMoneyInvestment{
    struct Skyscraper {
        uint256 Gold;
        uint256 money;
        uint256 money2;
        uint256 yield;
        uint256 timestamp;
        uint256 hrs;
        address ref;
        uint256 refs;
        uint256 refDeps;
        uint8[8] Printers;
    }
    mapping(address => Skyscraper) public Skyscrapers;
    uint256 public totalPrinters;
    uint256 public totalSkyscrapers;
    uint256 public totalInvested;
    address public manager = msg.sender;

    function addGold(address ref) public payable {
        uint256 Gold = msg.value / 2e13;
        require(Gold > 0, "Zero Gold");
        address user = msg.sender;
        totalInvested += msg.value;
        if (Skyscrapers[user].timestamp == 0) {
            totalSkyscrapers++;
            ref = Skyscrapers[ref].timestamp == 0 ? manager : ref;
            Skyscrapers[ref].refs++;
            Skyscrapers[user].ref = ref;
            Skyscrapers[user].timestamp = block.timestamp;
        }
        ref = Skyscrapers[user].ref;
        Skyscrapers[ref].Gold += (Gold * 7) / 100;
        Skyscrapers[ref].money += (Gold * 100 * 3) / 100;
        Skyscrapers[ref].refDeps += Gold;
        Skyscrapers[user].Gold += Gold;
        payable(manager).transfer((msg.value * 3) / 100);
    }

    function withdrawMoney() public {
        address user = msg.sender;
        uint256 money = Skyscrapers[user].money;
        Skyscrapers[user].money = 0;
        uint256 amount = money * 2e11;
        payable(user).transfer(address(this).balance < amount ? address(this).balance : amount);
    }

    function collectMoney() public {
        address user = msg.sender;
        syncSkyscraper(user);
        Skyscrapers[user].hrs = 0;
        Skyscrapers[user].money += Skyscrapers[user].money2;
        Skyscrapers[user].money2 = 0;
    }

    function upgradeSkyscraper(uint256 InvestmentId) public {
        require(InvestmentId < 8, "Max 8 Investments");
        address user = msg.sender;
        syncSkyscraper(user);
        Skyscrapers[user].Printers[InvestmentId]++;
        totalPrinters++;
        uint256 Printers = Skyscrapers[user].Printers[InvestmentId];
        Skyscrapers[user].Gold -= getUpgradePrice(InvestmentId, Printers);
        Skyscrapers[user].yield += getYield(InvestmentId, Printers);
    }

    function sellSkyscraper() public {
        collectMoney();
        address user = msg.sender;
        uint8[8] memory Printers = Skyscrapers[user].Printers;
        totalPrinters -= Printers[0] + Printers[1] + Printers[2] + Printers[3] + Printers[4] + Printers[5] + Printers[6] + Printers[7];
        Skyscrapers[user].money += Skyscrapers[user].yield * 24 * 14;
        Skyscrapers[user].Printers = [0, 0, 0, 0, 0, 0, 0, 0];
        Skyscrapers[user].yield = 0;
    }

    function getPrinters(address addr) public view returns (uint8[8] memory) {
        return Skyscrapers[addr].Printers;
    }

    function syncSkyscraper(address user) internal {
        require(Skyscrapers[user].timestamp > 0, "User is not registered");
        if (Skyscrapers[user].yield > 0) {
            uint256 hrs = block.timestamp / 3600 - Skyscrapers[user].timestamp / 3600;
            if (hrs + Skyscrapers[user].hrs > 24) {
                hrs = 24 - Skyscrapers[user].hrs;
            }
            Skyscrapers[user].money2 += hrs * Skyscrapers[user].yield;
            Skyscrapers[user].hrs += hrs;
        }
        Skyscrapers[user].timestamp = block.timestamp;
    }

    function getUpgradePrice(uint256 InvestmentId, uint256 PrinterId) internal pure returns (uint256) {
        if (PrinterId == 1) return [500, 1500, 4500, 13500, 40500, 120000, 365000, 1000000][InvestmentId];
        if (PrinterId == 2) return [625, 1800, 5600, 16800, 50600, 150000, 456000, 1200000][InvestmentId];
        if (PrinterId == 3) return [780, 2300, 7000, 21000, 63000, 187000, 570000, 1560000][InvestmentId];
        if (PrinterId == 4) return [970, 3000, 8700, 26000, 79000, 235000, 713000, 2000000][InvestmentId];
        if (PrinterId == 5) return [1200, 3600, 11000, 33000, 98000, 293000, 890000, 2500000][InvestmentId];
        revert("Incorrect PrinterId");
    }

    function getYield(uint256 InvestmentId, uint256 PrinterId) internal pure returns (uint256) {
        if (PrinterId == 1) return [41, 130, 399, 1220, 3750, 11400, 36200, 104000][InvestmentId];
        if (PrinterId == 2) return [52, 157, 498, 1530, 4700, 14300, 45500, 126500][InvestmentId];
        if (PrinterId == 3) return [65, 201, 625, 1920, 5900, 17900, 57200, 167000][InvestmentId];
        if (PrinterId == 4) return [82, 264, 780, 2380, 7400, 22700, 72500, 216500][InvestmentId];
        if (PrinterId == 5) return [103, 318, 995, 3050, 9300, 28700, 91500, 275000][InvestmentId];
        revert("Incorrect PrinterId");
    }
}