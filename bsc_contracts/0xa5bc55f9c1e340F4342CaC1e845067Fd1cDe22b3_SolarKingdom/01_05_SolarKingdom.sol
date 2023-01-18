pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
 * @author ~ 🅧🅘🅟🅩🅔🅡 ~ (https://twitter.com/Xipzer | https://t.me/Xipzer)
 *
 * ░██████╗░█████╗░██╗░░░░░░█████╗░██████╗░  ██╗░░██╗██╗███╗░░██╗░██████╗░██████╗░░█████╗░███╗░░░███╗
 * ██╔════╝██╔══██╗██║░░░░░██╔══██╗██╔══██╗  ██║░██╔╝██║████╗░██║██╔════╝░██╔══██╗██╔══██╗████╗░████║
 * ╚█████╗░██║░░██║██║░░░░░███████║██████╔╝  █████═╝░██║██╔██╗██║██║░░██╗░██║░░██║██║░░██║██╔████╔██║
 * ░╚═══██╗██║░░██║██║░░░░░██╔══██║██╔══██╗  ██╔═██╗░██║██║╚████║██║░░╚██╗██║░░██║██║░░██║██║╚██╔╝██║
 * ██████╔╝╚█████╔╝███████╗██║░░██║██║░░██║  ██║░╚██╗██║██║░╚███║╚██████╔╝██████╔╝╚█████╔╝██║░╚═╝░██║
 * ╚═════╝░░╚════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░╚═════╝░░╚════╝░╚═╝░░░░░╚═╝
 *
 * Solar Kingdom [Gen 3] - Static Rewards Pool
 *
 * Telegram: https://t.me/SolarFarmMinerOfficial
 * Twitter: https://twitter.com/SolarFarmMiner
 * Landing: https://solarfarm.finance/
 * dApp: https://app.solarfarm.finance/
 */

interface IFrenzyHost
{
    function contribute(address engineer, uint amount, uint time) external;
    function getCurrentSessionStatus() external view returns (bool);
}

contract SolarKingdom is OwnableUpgradeable
{
    IFrenzyHost public frenzyHost;

    bool kingdomActive;
    uint fuelCellRate;

    uint gridInFee;
    uint gridOutFee;

    uint referralBonus;
    uint firstDepositBonus;

    uint minimumDeposit;
    uint maximumWallet;

    uint allowanceThreshold;
    uint minimumFusionThreshold;
    uint completeReferralThreshold;

    uint dailyRewardsFixedThreshold;
    uint dailyRewardsRatioThreshold;

    address payable private gridGiveaway;
    address payable private gridTechnician;

    uint totalEngineers;

    mapping (address => Engineer) private engineers;

    struct Engineer
    {
        uint fuelCells;
        uint lastFusedTimestamp;
        uint lastHarvestedTimestamp;
        uint lastActionTimestamp;
        uint allowance;
        uint freshValue;
        uint totalDeposited;
        uint totalHarvested;
        address referrer;
        address[] basicReferrals;
        address[] completeReferrals;
    }

    event FuelCellsPurchased(uint value, uint amount, uint timestamp, uint tvl);
    event FuelCellsFused(uint value, uint amount, uint timestamp);
    event FuelCellsHarvested(uint value, uint timestamp);
    event FrenzyContribution(uint amount, uint timestamp);

    modifier onlyFrenzy
    {
        require(msg.sender == address(frenzyHost), "SolarGuard: You are not the frenzy operator!");
        _;
    }

//    function initialize(address payable giveawayAddress, address payable technicianAddress) external initializer
//    {
//        __Ownable_init();
//
//        kingdomActive = false;
//        fuelCellRate = 10000000000000; // 1 Fuel Cell == 0.00001 BNB
//
//        gridInFee = 30; // 3%
//        gridOutFee = 60; // 6%
//
//        referralBonus = 50; // 5%
//        firstDepositBonus = 50; // 5%
//
//        minimumDeposit = 10000000000000000; // 0.01 BNB
//        maximumWallet = 200000000000000000000; // 200 BNB
//
//        allowanceThreshold = 3; // 3x
//        minimumFusionThreshold = 10000000000000000; // 0.01 BNB
//        completeReferralThreshold = 500000000000000000; // 0.5 BNB
//
//        dailyRewardsFixedThreshold = 5000000000000000000; // 5 BNB
//        dailyRewardsRatioThreshold = 25; // 2.5%
//
//        gridGiveaway = giveawayAddress;
//        gridTechnician = technicianAddress;
//    }

    function getTotalValueLocked() public view returns (uint)
    {
        return address(this).balance;
    }

    function getEngineerData(address engineer) public view returns (Engineer memory)
    {
        return engineers[engineer];
    }

    function getMaxWalletStatus(address engineer) public view returns (bool)
    {
        return engineers[engineer].fuelCells >= computeBuy(maximumWallet);
    }

    function getSellTier(address engineer) public view returns (uint)
    {
        uint duration = calculateDaysSinceLastHarvest(engineer);

        return duration % 10;
    }

    function getReactorTier(address engineer) public view returns (uint)
    {
        uint totalReferrals = engineers[engineer].completeReferrals.length;

        if (totalReferrals < 5)
            return 1;
        if (totalReferrals < 10)
            return 2;
        if (totalReferrals < 20)
            return 3;
        if (totalReferrals < 40)
            return 4;
        if (totalReferrals < 80)
            return 5;
        if (totalReferrals < 160)
            return 6;
        if (totalReferrals < 320)
            return 7;

        return 8;
    }

    function getRewardsMultiplier(address engineer) public view returns (uint)
    {
        uint totalReferrals = engineers[engineer].completeReferrals.length;

        if (totalReferrals < 5)
            return 40;
        if (totalReferrals < 10)
            return 45;
        if (totalReferrals < 20)
            return 50;
        if (totalReferrals < 40)
            return 55;
        if (totalReferrals < 80)
            return 60;
        if (totalReferrals < 160)
            return 65;
        if (totalReferrals < 320)
            return 70;

        return 75;
    }

    function checkRewardsBalance(address engineer) public view returns (uint)
    {
        return checkRewards(engineer);
    }

    function setFrenzyHost(address frenzyAddress) public onlyOwner
    {
        frenzyHost = IFrenzyHost(frenzyAddress);
    }

    function activateSolarKingdom() public onlyOwner
    {
        require(!kingdomActive, "SolarGuard: Solar Kingdom is already active!");

        kingdomActive = true;
    }

    function airdropMarketers(address migrator, uint amount) public onlyOwner
    {
        Engineer storage engineer = engineers[migrator];

        engineer.totalDeposited += amount / 3;
        engineer.fuelCells += computeFraction(computeBuy(amount), 1000 - gridInFee);
        engineer.freshValue += amount / 3;
        engineer.allowance += amount;

        if (engineer.lastActionTimestamp == 0)
        {
            engineer.lastActionTimestamp = block.timestamp;
            engineer.lastHarvestedTimestamp = block.timestamp;
        }
    }

    function airdropParticipants(address participant, uint amount) public onlyOwner
    {
        Engineer storage engineer = engineers[participant];

        engineer.totalDeposited += 0;
        engineer.fuelCells += computeFraction(computeBuy(amount), 1000 - gridInFee);
        engineer.freshValue += 0;
        engineer.allowance += 0;
    }

    function claimFrenzyPrize(address engineer, uint quantity) public onlyFrenzy
    {
        engineers[engineer].fuelCells += quantity;
    }

    function contributeToFrenzy(uint amount) public
    {
        require(kingdomActive, "SolarGuard: Solar Kingdom must be active!");
        require(address(frenzyHost) != address(0), "SolarGuard: Sorry Engineer, a frenzy host has not been set yet!");
        require(frenzyHost.getCurrentSessionStatus(), "SolarGuard: Sorry Engineer, there is no active frenzy session at the moment!");
        require(amount == 5000 || amount == 10000 || amount == 25000, "SolarGuard: Sorry Engineer, this frenzy session only supports 5000, 10000, 25000 fuel cell deposits!");

        uint time;

        if (amount == 5000)
        {
            require(engineers[msg.sender].fuelCells >= 5000, "SolarGuard: Sorry Engineer, you don't have enough fuel cells to contribute!");
            engineers[msg.sender].fuelCells -= 5000;
            time = 600;
        }
        else if (amount == 10000)
        {
            require(engineers[msg.sender].fuelCells >= 10000, "SolarGuard: Sorry Engineer, you don't have enough fuel cells to contribute!");
            engineers[msg.sender].fuelCells -= 10000;
            time = 1800;
        }
        else if (amount == 25000)
        {
            require(engineers[msg.sender].fuelCells >= 25000, "SolarGuard: Sorry Engineer, you don't have enough fuel cells to contribute!");
            engineers[msg.sender].fuelCells -= 25000;
            time = 60;
        }

        frenzyHost.contribute(msg.sender, amount, time);

        emit FrenzyContribution(amount, block.timestamp);
    }

    function buyFuelCells(address referrer) public payable
    {
        require(kingdomActive, "SolarGuard: Solar Kingdom must be active!");

        Engineer storage engineer = engineers[msg.sender];
        Engineer storage supervisor = engineers[referrer];

        require(msg.value >= minimumDeposit, "SolarGuard: Sorry Engineer, your deposit does not meet the minimum amount!");
        require(engineer.totalDeposited + msg.value <= maximumWallet, "SolarGuard: Sorry Engineer, your deposit exceeds the maximum wallet limit!");
        require(referrer == address(0) || referrer == msg.sender || supervisor.totalDeposited > 0, "SolarGuard: Sorry Engineer, your referrer must be an investor!");

        if (engineer.totalDeposited == 0)
            totalEngineers++;

        engineer.totalDeposited += msg.value;

        uint newFreshValue = 0;

        if (engineer.totalHarvested < engineer.totalDeposited)
            newFreshValue = engineer.totalDeposited - engineer.totalHarvested;

        if (newFreshValue >= engineer.freshValue)
        {
            engineer.allowance = newFreshValue * allowanceThreshold;
            engineer.freshValue = newFreshValue;
        }
        else
            engineer.allowance += msg.value;

        uint totalFuelCells = computeBuy(msg.value);
        uint fuelCellsAcquired = computeFraction(totalFuelCells, 1000 - gridInFee);

        engineer.fuelCells += fuelCellsAcquired;

        if (engineer.referrer == address(0) && referrer != msg.sender && referrer != address(0))
        {
            engineer.referrer = referrer;
            supervisor.basicReferrals.push(msg.sender);

            if (engineer.lastActionTimestamp == 0)
                supervisor.fuelCells += computeFraction(totalFuelCells, firstDepositBonus);
        }

        if (engineer.referrer != address(0) && engineer.totalDeposited >= completeReferralThreshold && !checkReferral(referrer, msg.sender))
            supervisor.completeReferrals.push(msg.sender);

        distributeFees(computeFraction(msg.value, gridInFee), 0);

        if (engineer.lastActionTimestamp == 0)
        {
            engineer.lastActionTimestamp = block.timestamp;
            engineer.lastHarvestedTimestamp = block.timestamp;
        }
        else
            handleFusion(false);

        emit FuelCellsPurchased(msg.value, fuelCellsAcquired, block.timestamp, address(this).balance);
    }

    function fuse() public
    {
        require(kingdomActive, "SolarGuard: Solar Kingdom must be active!");

        handleFusion(true);
    }

    function harvest() public
    {
        require(kingdomActive, "SolarGuard: Solar Kingdom must be active!");

        Engineer storage engineer = engineers[msg.sender];

        require(engineer.totalDeposited > 0, "SolarGuard: Sorry Engineer, you must have buy fuel cells in order to harvest!");
        require(engineer.allowance > 0, "SolarGuard: Sorry Engineer, you have completely depleted your allowance!");

        uint rewards = checkRewards(msg.sender);
        uint taxFee = computeFraction(rewards, gridOutFee);
        rewards -= taxFee;

        uint giveawayFee = calculateGiveawayTax(msg.sender, rewards);
        rewards = calculateHarvestTax(msg.sender, rewards);

        if (rewards >= engineer.allowance)
            rewards = engineer.allowance;

        engineer.allowance -= rewards;

        engineer.lastActionTimestamp = block.timestamp;
        engineer.lastHarvestedTimestamp = block.timestamp;

        distributeFees(taxFee, giveawayFee);
        payable (msg.sender).transfer(rewards);

        emit FuelCellsHarvested(rewards, block.timestamp);
    }

    function checkReferral(address supervisor, address engineer) private view returns (bool)
    {
        for (uint i = 0; i < engineers[supervisor].completeReferrals.length; i++)
            if (engineers[supervisor].completeReferrals[i] == engineer)
                return true;

        return false;
    }

    function checkMinimum(uint a, uint b) private pure returns (uint)
    {
        return a < b ? a : b;
    }

    function computeFraction(uint amount, uint numerator) private pure returns (uint)
    {
        return (amount * numerator) / 1000;
    }

    function computeBuy(uint amount) private view returns (uint)
    {
        return amount / fuelCellRate;
    }

    function computeHarvest(uint amount) private view returns (uint)
    {
        return amount * fuelCellRate;
    }

    function calculateDaysSinceLastHarvest(address engineer) private view returns (uint)
    {
        return (block.timestamp - engineers[engineer].lastHarvestedTimestamp) / 86400;
    }

    function calculateHarvestTax(address engineer, uint amount) private view returns (uint)
    {
        uint sellTier = getSellTier(engineer);

        if (sellTier > 8)
            return amount;

        return computeFraction(amount, 100 + (sellTier * 100));
    }

    function calculateGiveawayTax(address engineer, uint amount) private view returns (uint)
    {
        uint sellTier = getSellTier(engineer);

        if (sellTier > 8)
            return 0;

        return computeFraction(amount, 1000 - (100 + (sellTier * 100))) / 2;
    }

    function distributeFees(uint gridFee, uint giveawayFee) private
    {
        gridTechnician.transfer(gridFee);

        if (giveawayFee > 0)
            gridGiveaway.transfer(giveawayFee);
    }

    function handleFusion(bool fuseRewards) private
    {
        Engineer storage engineer = engineers[msg.sender];

        require(!getMaxWalletStatus(msg.sender), "SolarGuard: Sorry Engineer, your Reactor exceeds the max wallet limit!");
        require(engineer.totalDeposited > 0, "SolarGuard: Sorry Engineer, your must deposit BNB for fuel cells before you can fuse!");

        uint rewards = checkRewards(msg.sender);

        if (fuseRewards)
            require(rewards >= minimumFusionThreshold, "SolarGuard: Sorry Engineer, you must have 0.01 BNB or more in rewards before you can fuse!");

        uint fuelCellsAcquired = computeBuy(rewards);

        engineer.fuelCells += fuelCellsAcquired;
        engineer.lastActionTimestamp = block.timestamp;
        engineer.lastFusedTimestamp = block.timestamp;

        emit FuelCellsFused(rewards, fuelCellsAcquired, block.timestamp);
    }

    function checkRewards(address engineer) private view returns (uint)
    {
        uint duration = block.timestamp - engineers[engineer].lastActionTimestamp;
        uint rewardsMultiplier = getRewardsMultiplier(engineer);
        uint rewards = computeFraction((computeHarvest(engineers[engineer].fuelCells) / 86400), rewardsMultiplier) * duration;

        uint rewardsThreshold = computeFraction(address(this).balance, dailyRewardsRatioThreshold);
        rewardsThreshold = checkMinimum(rewardsThreshold, dailyRewardsFixedThreshold);

        if (rewards > rewardsThreshold)
            return rewardsThreshold;

        return rewards;
    }

    receive() external payable {}
}