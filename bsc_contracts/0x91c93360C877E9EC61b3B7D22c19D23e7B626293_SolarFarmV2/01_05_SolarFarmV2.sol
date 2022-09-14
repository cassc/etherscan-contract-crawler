// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/*
 * @author ~ 🅧🅘🅟🅩🅔🅡 ~ (https://twitter.com/Xipzer | https://t.me/Xipzer)
 *
 * ░██████╗░█████╗░██╗░░░░░░█████╗░██████╗░  ███████╗░█████╗░██████╗░███╗░░░███╗  ██╗░░░██╗██████╗░
 * ██╔════╝██╔══██╗██║░░░░░██╔══██╗██╔══██╗  ██╔════╝██╔══██╗██╔══██╗████╗░████║  ██║░░░██║╚════██╗
 * ╚█████╗░██║░░██║██║░░░░░███████║██████╔╝  █████╗░░███████║██████╔╝██╔████╔██║  ╚██╗░██╔╝░░███╔═╝
 * ░╚═══██╗██║░░██║██║░░░░░██╔══██║██╔══██╗  ██╔══╝░░██╔══██║██╔══██╗██║╚██╔╝██║  ░╚████╔╝░██╔══╝░░
 * ██████╔╝╚█████╔╝███████╗██║░░██║██║░░██║  ██║░░░░░██║░░██║██║░░██║██║░╚═╝░██║  ░░╚██╔╝░░███████╗
 * ╚═════╝░░╚════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝  ╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░░░░╚═╝  ░░░╚═╝░░░╚══════╝
 *
 * Solar Farm V2.0 [Gen 4] - BSC BNB Miner
 *
 * Telegram: https://t.me/SolarFarmMinerOfficial
 * Twitter: https://twitter.com/SolarFarmMiner
 * dApp: https://app.solarfarm.finance/
 */

contract SolarFarmV2 is OwnableUpgradeable
{
    uint private gridPower;
    uint private returnsIndex;

    uint private buyDampener;
    uint private sellDampener;
    uint private compoundDampener;

    uint private compoundCooldown;
    uint private baseCompoundBonus;
    uint private maxCompoundBonus;

    uint private compoundBonusThreshold;
    uint private minCompoundsThreshold;
    uint private allowanceThreshold;

    uint private baseAbuseFee;
    uint private dumpAbuseFee;
    uint private dumpAbusePenalty;
    uint private spamAbuseFee;
    uint private spamAbusePenalty;

    uint private referralReward;

    uint private gridFee;
    uint private maxGridFee;

    bool private minerInitialized;
    bool private solarGuardActivated;

    address payable private gridTechnician;

    mapping(address => UserData) private users;
    mapping(address => bool) private botUsers;

    struct UserData
    {
        uint solarPanels;
        uint storedPower;
        uint allowance;
        uint freshValue;
        uint amountSold;
        uint amountDeposited;
        uint sellsCount;
        uint totalCompoundsCount;
        uint currentCompoundsCount;
        uint lastSellTimestamp;
        uint lastCompoundTimestamp;
        uint lastActionTimestamp;
        uint compoundBonusTier;
        address referrer;
        address[] referees;
    }

    uint private shootingStarTimestamp;
    uint private shootingStarAbusePenalty;
    uint private shootingStarAmplifier;

    event MinerActivated(uint timestamp);
    event ShootingStar(uint amplifier, uint timestamp);
    event DumpPenaltyChanged(uint penalty, uint timestamp);
    event SpamPenaltyChanged(uint penalty, uint timestamp);
    event BuyDampenerChanged(uint dampener, uint timestamp);
    event SellDampenerChanged(uint dampener, uint timestamp);
    event CompoundDampenerChanged(uint dampener, uint timestamp);
    event ReturnsIndexChanged(uint index, uint timestamp);
    event GridFeeChanged(uint fee, uint timestamp);
    event PanelsPurchased(uint amount, uint timestamp);
    event PowerSold(uint amount, uint timestamp);

//    function initialize(address payable technicianAddress) external initializer
//    {
//        __Ownable_init();
//
//        gridPower = 108000000000;
//        returnsIndex = 604800;
//
//        buyDampener = 100;
//        sellDampener = 500;
//        compoundDampener = 200;
//
//        compoundCooldown = 5400;
//        baseCompoundBonus = 15;
//        maxCompoundBonus = 150;
//
//        compoundBonusThreshold = 3;
//        minCompoundsThreshold = 15;
//        allowanceThreshold = 5;
//
//        baseAbuseFee = 500;
//        dumpAbuseFee = 500;
//        dumpAbusePenalty = 100;
//        spamAbuseFee = 750;
//        spamAbusePenalty = 50;
//
//        referralReward = 100;
//
//        gridFee = 60;
//        maxGridFee = 100;
//
//        minerInitialized = false;
//        solarGuardActivated = false;
//
//        gridTechnician = technicianAddress;
//    }

    function getTotalValueLocked() public view returns (uint)
    {
        return address(this).balance;
    }

    function getSolarPanels(address user) public view returns (uint)
    {
        return users[user].solarPanels;
    }

    function getRemainingAllowance(address user) public view returns (uint)
    {
        return users[user].allowance;
    }

    function getFreshValue(address user) public view returns (uint)
    {
        return users[user].freshValue;
    }

    function getAmountSold(address user) public view returns (uint)
    {
        return users[user].amountSold;
    }

    function getAmountDeposited(address user) public view returns (uint)
    {
        return users[user].amountDeposited;
    }

    function getSellsCount(address user) public view returns (uint)
    {
        return users[user].sellsCount;
    }

    function getTotalCompoundsCount(address user) public view returns (uint)
    {
        return users[user].totalCompoundsCount;
    }

    function getCurrentCompoundsCount(address user) public view returns (uint)
    {
        return users[user].currentCompoundsCount;
    }

    function getLastSellTimestamp(address user) public view returns (uint)
    {
        return users[user].lastSellTimestamp;
    }

    function getLastCompoundTimestamp(address user) public view returns (uint)
    {
        return users[user].lastCompoundTimestamp;
    }

    function getCompoundBonusTier(address user) public view returns (uint)
    {
        return users[user].compoundBonusTier;
    }

    function getReferrer(address user) public view returns (address)
    {
        return users[user].referrer;
    }

    function getReferees(address user) public view returns (address[] memory)
    {
        return users[user].referees;
    }

    function getBotStatus(address user) public view returns (bool)
    {
        return botUsers[user];
    }

    function getShootingStarStatus() public view returns (bool)
    {
        if (block.timestamp > shootingStarTimestamp)
            if (block.timestamp - shootingStarTimestamp <= 86400)
                return true;

        return false;
    }

    function checkStarAbuseStatus() public view returns (bool)
    {
        if (block.timestamp > shootingStarTimestamp)
        {
            if (block.timestamp - shootingStarTimestamp <= 172800)
                return true;
        }
        else
            if (shootingStarTimestamp - block.timestamp <= 86400)
                return true;

        return false;
    }

    function checkBaseAbuseStatus(address user, uint amount) public view returns (bool)
    {
        if (amount >= users[user].allowance)
            return true;
        return false;
    }

    function checkDumpAbuseStatus(address user, uint amount) public view returns (bool)
    {
        if (amount >= users[user].freshValue)
            return true;
        return false;
    }

    function checkSpamAbuseStatus(address user) public view returns (bool)
    {
        if (users[user].currentCompoundsCount < minCompoundsThreshold)
            return true;
        return false;
    }

    function checkRewardsBalance(address user) public view returns (uint)
    {
        return computeSellTrade(checkPowerTotal(user));
    }

    function checkPowerTotal(address user) public view returns (uint)
    {
        return users[user].storedPower + checkFreshPower(user);
    }

    function checkFreshPower(address user) public view returns (uint)
    {
        uint sessionDuration = checkMinimum(returnsIndex, block.timestamp - users[user].lastActionTimestamp);

        return sessionDuration * users[user].solarPanels;
    }

    function checkMinimum(uint a, uint b) private pure returns (uint)
    {
        return a < b ? a : b;
    }

    function computeFraction(uint amount, uint numerator) private pure returns (uint)
    {
        return (amount * numerator) / 1000;
    }

    function computeTrade(uint a, uint b, uint c) private view returns (uint)
    {
        return computeFraction((a * b) / c, 1000 - gridFee);
    }

    function computeBuyTrade(uint amount) private view returns (uint)
    {
        uint balance = address(this).balance - amount;

        return computeTrade(gridPower, amount, balance);
    }

    function computeSellTrade(uint amount) private view returns (uint)
    {
        return computeTrade(address(this).balance, amount, gridPower);
    }

    function computeSimulatedBuy(uint amount) public view returns (uint)
    {
        return computeTrade(gridPower, amount, address(this).balance);
    }

    function computeSimulatedSell(uint amount) public view returns (uint)
    {
        return computeSellTrade(amount);
    }

    function setDumpAbusePenalty(uint penalty) external onlyOwner
    {
        require(penalty <= 500, "SolarGuard: Penalty value exceeds 50%!");

        dumpAbusePenalty = penalty;
        emit DumpPenaltyChanged(penalty, block.timestamp);
    }

    function setSpamAbusePenalty(uint penalty) external onlyOwner
    {
        require(penalty <= 500, "SolarGuard: Penalty value exceeds 50%!");

        spamAbusePenalty = penalty;
        emit SpamPenaltyChanged(penalty, block.timestamp);
    }

    function setBuyDampener(uint dampener) external onlyOwner
    {
        require(dampener <= 1000, "SolarGuard: Dampener value exceeds 100%!");

        buyDampener = dampener;
        emit BuyDampenerChanged(dampener, block.timestamp);
    }

    function setSellDampener(uint dampener) external onlyOwner
    {
        require(dampener <= 1000, "SolarGuard: Dampener value exceeds 100%!");

        sellDampener = dampener;
        emit SellDampenerChanged(dampener, block.timestamp);
    }

    function setCompoundDampener(uint dampener) external onlyOwner
    {
        require(dampener <= 1000, "SolarGuard: Dampener value exceeds 100%!");

        compoundDampener = dampener;
        emit CompoundDampenerChanged(dampener, block.timestamp);
    }

    function setGridFee(uint fee) external onlyOwner
    {
        require(fee <= maxGridFee, "SolarGuard: Fee provided is above max fee!");

        gridFee = fee;
        emit GridFeeChanged(fee, block.timestamp);
    }

    function setReturnsIndex(uint index) external onlyOwner
    {
        require(index <= 8640000, "SolarGuard: New index must be greater than or equal to 1%");
        require(index >= 86400, "SolarGuard: New index must be less than or equal to 100%");

        returnsIndex = index;
        emit ReturnsIndexChanged(index, block.timestamp);
    }

    function buyPanels(address referrer) external payable
    {
        require(minerInitialized, "SolarGuard: Miner has not yet been activated!");

        if (solarGuardActivated)
            botUsers[msg.sender] = true;
        else
        {
            require(!botUsers[msg.sender], "SolarGuard: You are a contract abuser!");

            UserData storage user = users[msg.sender];

            if (user.referrer == address(0))
                if (referrer == msg.sender)
                    user.referrer = address(0);
                else
                {
                    user.referrer = referrer;
                    users[referrer].referees.push(msg.sender);
                }

            user.amountDeposited += msg.value;

            uint newFreshValue = 0;

            if (user.amountSold < user.amountDeposited)
                newFreshValue = user.amountDeposited - user.amountSold;

            if (newFreshValue >= user.freshValue)
            {
                user.allowance = newFreshValue * allowanceThreshold;
                user.freshValue = newFreshValue;
            }
            else
                user.allowance += msg.value;

            uint powerAcquired = computeBuyTrade(msg.value);

            user.lastCompoundTimestamp = block.timestamp - compoundCooldown;

            if (block.timestamp > shootingStarTimestamp)
                if (block.timestamp - shootingStarTimestamp <= 86400)
                    user.storedPower += computeFraction(powerAcquired, 1000 + shootingStarAmplifier);
                else
                    user.storedPower += powerAcquired;
            else
                user.storedPower += powerAcquired;

            if (user.currentCompoundsCount > 0)
            {
                user.totalCompoundsCount--;
                user.currentCompoundsCount--;
            }

            uint referrerAmount = computeFraction(msg.value, referralReward);

            users[user.referrer].storedPower += computeFraction(powerAcquired, referralReward);
            users[user.referrer].allowance += referrerAmount;
            users[user.referrer].amountDeposited += referrerAmount;

            gridPower -= computeFraction(powerAcquired, buyDampener);
            gridTechnician.transfer(computeFraction(msg.value, gridFee));

            compoundPower();

            emit PanelsPurchased(msg.value, block.timestamp);
        }
    }

    function sellPower(uint amount) external
    {
        require(minerInitialized, "SolarGuard: Miner has not yet been activated!");
        require(!botUsers[msg.sender], "SolarGuard: You are a contract abuser!");

        UserData storage user = users[msg.sender];
        uint totalPower = checkPowerTotal(msg.sender);

        require(amount <= totalPower, "SolarGuard: Amount is greater than power held!");

        uint amountRequested = computeSellTrade(amount);

        require(amountRequested <= computeFraction(address(this).balance, 10), "SolarGuard: Amount is greater than 5% maximum sell!");

        uint gridReserve = (amountRequested / (1000 - gridFee)) * 1000;

        if (user.solarPanels == 0)
            amountRequested = computeFraction(amountRequested, baseAbuseFee);
        else
        {
            require(user.totalCompoundsCount >= minCompoundsThreshold, "SolarGuard: You have not met the compounds requirement!");

//            if (block.timestamp > shootingStarTimestamp)
//            {
//                if (block.timestamp - shootingStarTimestamp <= 172800)
//                    user.solarPanels = computeFraction(user.solarPanels, 1000 - shootingStarAbusePenalty);
//            }
//            else
//                if (shootingStarTimestamp - block.timestamp <= 86400)
//                    user.solarPanels = computeFraction(user.solarPanels, 1000 - shootingStarAbusePenalty);

            if (amountRequested >= user.allowance)
                if (user.allowance > 0)
                    amountRequested = user.allowance + computeFraction(amountRequested - user.allowance, baseAbuseFee);
                else
                    amountRequested = computeFraction(amountRequested, baseAbuseFee);

            if (amountRequested >= user.freshValue)
            {
                amountRequested = computeFraction(amountRequested, dumpAbuseFee);
                user.solarPanels = computeFraction(user.solarPanels, 1000 - dumpAbusePenalty);
            }

            if (user.currentCompoundsCount < minCompoundsThreshold)
            {
                amountRequested = computeFraction(amountRequested, 1000 - spamAbuseFee);
                user.solarPanels = computeFraction(user.solarPanels, 1000 - spamAbusePenalty);
            }

            user.compoundBonusTier = 0;
            user.currentCompoundsCount = 0;
        }

        user.storedPower = 0;

        if (amount < totalPower)
            user.storedPower = totalPower - amount;

        if (gridReserve < user.allowance)
            user.allowance -= gridReserve;
        else
            user.allowance = 0;

        user.lastSellTimestamp = block.timestamp;
        user.lastActionTimestamp = block.timestamp;

        user.sellsCount++;
        user.amountSold += gridReserve;

        gridPower += computeFraction(amount, sellDampener);
        gridTechnician.transfer(computeFraction(gridReserve, gridFee));
        payable (msg.sender).transfer(amountRequested);

        emit PowerSold(amountRequested, block.timestamp);
    }

    function compoundPower() public
    {
        require(minerInitialized, "SolarGuard: Miner has not yet been activated!");
        require(!botUsers[msg.sender], "SolarGuard: You are a contract abuser!");

        UserData storage user = users[msg.sender];

        require(block.timestamp - user.lastCompoundTimestamp >= compoundCooldown, "SolarGuard: You are on cooldown!");

        uint userPower = checkPowerTotal(msg.sender);
        uint minersAcquired = userPower / returnsIndex;

        user.storedPower = 0;
        user.lastCompoundTimestamp = block.timestamp;
        user.lastActionTimestamp = block.timestamp;

        user.totalCompoundsCount++;
        user.currentCompoundsCount++;

        if (user.currentCompoundsCount >= compoundBonusThreshold)
        {
            if (user.currentCompoundsCount / compoundBonusThreshold > user.compoundBonusTier)
                if (user.compoundBonusTier < maxCompoundBonus / baseCompoundBonus)
                    user.compoundBonusTier++;
                else
                    if (user.compoundBonusTier < 2 * maxCompoundBonus / baseCompoundBonus)
                        if (user.currentCompoundsCount >= 480 && user.compoundBonusTier < 20)
                            user.compoundBonusTier += 8;
                        else if (user.currentCompoundsCount >= 112 && user.compoundBonusTier < 12)
                            user.compoundBonusTier += 2;

            minersAcquired += computeFraction(minersAcquired, user.compoundBonusTier * baseCompoundBonus);
        }

        user.solarPanels += minersAcquired;

        gridPower += computeFraction(userPower, compoundDampener);
    }

    function catchAbuser(address user) external onlyOwner
    {
        botUsers[user] = true;
    }

    function freeInnocent(address user) external onlyOwner
    {
        botUsers[user] = false;
    }

    function activateMiner() external payable onlyOwner
    {
        require(!minerInitialized, "SolarGuard: Miner can only be activated once!");

        minerInitialized = true;
        solarGuardActivated = true;

        emit MinerActivated(block.timestamp);
    }

    function releaseGuard() external onlyOwner
    {
        require(solarGuardActivated, "SolarGuard: Startup guard can only be deactivated once!");

        solarGuardActivated = false;
    }

    function shootingStar(uint amplifier, uint time) external onlyOwner
    {
        require(amplifier <= 500 && amplifier >= 100, "SolarGuard: Shooting Star value amplifier must be between 10% and 50%!");
        require(time >= block.timestamp, "SolarGuard: Shooting Star time cannot be in the past!");

        shootingStarAmplifier = amplifier;
        shootingStarTimestamp = time;

        emit ShootingStar(shootingStarAmplifier, shootingStarTimestamp);
    }

    receive() external payable {}
}