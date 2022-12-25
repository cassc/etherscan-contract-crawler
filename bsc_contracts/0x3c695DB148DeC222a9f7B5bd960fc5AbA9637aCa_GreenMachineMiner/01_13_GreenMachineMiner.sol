/*
    GreenMachineMiner - BSC BNB Miner
    Developed by Kraitor <TG: kraitordev>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BasicLibraries/SafeMath.sol";
import "./BasicLibraries/Ownable.sol";
import "./BasicLibraries/IBEP20.sol";
import "./Libraries/MinerBasic.sol";
import "./Libraries/Airdrop.sol";
import "./Libraries/InvestorsManager.sol";
import "./Libraries/GreenMachineMinerConfigIface.sol";
import "./Libraries/EmergencyWithdrawal.sol";
import "./Libraries/Testable.sol";

contract GreenMachineMiner is Ownable, MinerBasic, Airdrop, InvestorsManager, EmergencyWithdrawal, Testable {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint8;

    //External config iface (Roi events)
    GreenMachineMinerConfigIface reIface;

    //From milkfarmV1
    mapping (address => uint256[]) private sellsTimestamps;
    mapping (address => uint256) private customSellTaxes;

    constructor(address _airdropToken, address _marketingAdd, address _recIface, address timerAddr) Testable(timerAddr) {
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketingAdd);
        airdropToken = _airdropToken;
        reIface = GreenMachineMinerConfigIface(address(_recIface));
    }


    //CONFIG////////////////
    function setAirdropToken(address _airdropToken) public override onlyOwner { airdropToken =_airdropToken; }
    function enableClaim(bool _enableClaim) public override onlyOwner { claimEnabled = _enableClaim; }
    function openToPublic(bool _openPublic) public override onlyOwner { openPublic = _openPublic; }
    function setExternalConfigAddress(address _recIface) public onlyOwner { reIface = GreenMachineMinerConfigIface(address(_recIface)); }
    function setMarketingTax(uint8 _marketingFeeVal, address _marketingAdd) public onlyOwner {
        require(_marketingFeeVal <= 5);
        marketingFeeVal = _marketingFeeVal;
        marketingAdd = payable(_marketingAdd);
    }
    function setDevTax(uint8 _devFeeVal, address _devAdd) public onlyOwner {
        require(_devFeeVal <= 5);
        devFeeVal = _devFeeVal;
        recAdd = payable(_devAdd);
    }
    function setEmergencyWithdrawPenalty(uint256 _penalty) public override onlyOwner {
        require(_penalty < 100);
        emergencyWithdrawPenalty = _penalty;
    }
    function setMaxSellPc(uint256 _maxSellNum, uint256 _maxSellDiv) public onlyOwner {
        require(_maxSellDiv <= 1000 && _maxSellDiv >= 10, "Invalid values");
        require(_maxSellNum < _maxSellDiv && uint256(1000).mul(_maxSellNum) >= _maxSellDiv, "Min max sell is 0.1% of TLV");
        maxSellNum = _maxSellNum;
        maxSellDiv = _maxSellDiv;
    }
    function setRewardsPercentage(uint32 _percentage) public onlyOwner {
        require(_percentage >= 15, 'Percentage cannot be less than 15');
        rewardsPercentage = _percentage;
    }
    function setMaxBuy(uint256 _maxBuyTwoDecs) public onlyOwner {
        maxBuy = _maxBuyTwoDecs.mul(1 ether).div(100);
    }
    ////////////////////////



    //AIRDROPS//////////////
    function claimMachines(address ref) public override {
        require(initialized);
        require(claimEnabled, 'Claim still not available');

        uint256 airdropTokens = IBEP20(airdropToken).balanceOf(msg.sender);
        IBEP20(airdropToken).transferFrom(msg.sender, address(this), airdropTokens); //The token has to be approved first
        IBEP20(airdropToken).burn(airdropTokens); //Tokens burned

        //GreenBNB is used to buy machines (miners)
        uint256 machinesClaimed = calculateHireMachines(airdropTokens, address(this).balance);

        setInvestorClaimedGreens(msg.sender, SafeMath.add(getInvestorData(msg.sender).claimedGreens, machinesClaimed));
        _rehireMachines(msg.sender, ref, true);

        emit ClaimMachines(msg.sender, machinesClaimed, airdropTokens);
    }
    ////////////////////////


    //Emergency withdraw////
    function emergencyWithdraw() public override {
        require(initialized);
        require(getInvestorData(msg.sender).withdrawal < getInvestorData(msg.sender).investment, 'You already recovered your investment');
        require(getInvestorData(msg.sender).hiredMachines > 1, 'You cant use this function');
        uint256 amountToWithdraw = getInvestorData(msg.sender).investment.sub(getInvestorData(msg.sender).withdrawal);
        uint256 amountToWithdrawAfterTax = amountToWithdraw.mul(uint256(100).sub(emergencyWithdrawPenalty)).div(100);
        require(amountToWithdrawAfterTax > 0, 'There is nothing to withdraw');
        uint256 amountToWithdrawTaxed = amountToWithdraw.sub(amountToWithdrawAfterTax);

        addInvestorWithdrawal(msg.sender, amountToWithdraw);
        setInvestorHiredMachines(msg.sender, 1); //Burn

        if(amountToWithdrawTaxed > 0){
            recAdd.transfer(amountToWithdrawTaxed);
        }

        payable (msg.sender).transfer(amountToWithdrawAfterTax);

        emit EmergencyWithdraw(getInvestorData(msg.sender).investment, getInvestorData(msg.sender).withdrawal, amountToWithdraw, amountToWithdrawAfterTax, amountToWithdrawTaxed);
    }
    ////////////////////////


    //BASIC/////////////////
    function seedMarket() public payable onlyOwner {
        require(marketGreens == 0);
        initialized = true;
        marketGreens = 108000000000;
    }

    function hireMachines(address ref) public payable {
        require(initialized);
        require(openPublic, 'Miner still not opened');
        require(maxBuy == 0 || msg.value <= maxBuy);

        _hireMachines(ref, msg.sender, msg.value);
    }

    function rehireMachines() public {
        _rehireMachines(msg.sender, address(0), false);
    }

    function sellGreens() public {
        _sellGreens(msg.sender);
    }

    function _rehireMachines(address _sender, address ref, bool isClaim) private {
        require(initialized);

        if(ref == _sender) {
            ref = address(0);
        }
                
        if(getInvestorData(_sender).referral == address(0) && getInvestorData(_sender).referral != _sender && getInvestorData(_sender).referral != ref) {
            setInvestorReferral(_sender, ref);
        }
        
        uint256 greensUsed = getMyGreens(_sender);
        uint256 newMachines = SafeMath.div(greensUsed, GREENS_TO_HATCH_1MACHINE);

        if(newMachines > 0 && getInvestorData(_sender).hiredMachines == 0){            
            initializeInvestor(_sender);
        }

        setInvestorHiredMachines(_sender, SafeMath.add(getInvestorData(_sender).hiredMachines, newMachines));
        setInvestorClaimedGreens(_sender, 0);
        setInvestorLastHire(_sender, getCurrentTime());
        
        //send referral greens
        setInvestorGreensByReferral(getReferralData(_sender).investorAddress, getReferralData(_sender).referralGreens.add(SafeMath.div(greensUsed, 8)));
        setInvestorClaimedGreens(getReferralData(_sender).investorAddress, SafeMath.add(getReferralData(_sender).claimedGreens, SafeMath.div(greensUsed, 8))); 

        //boost market to nerf miners hoarding
        if(isClaim == false){
            marketGreens = SafeMath.add(marketGreens, SafeMath.div(greensUsed, 5));
        }

        emit RehireMachines(_sender, newMachines, getInvestorData(_sender).hiredMachines, getNumberInvestors(), getReferralData(_sender).claimedGreens, marketGreens, greensUsed);
    }
    
    function _sellGreens(address _sender) private {
        require(initialized);

        uint256 greensLeft = 0;
        uint256 hasGreens = getMyGreens(_sender);
        uint256 greensValue = calculateGreenSell(hasGreens);
        (greensValue, greensLeft) = capToMaxSell(greensValue, hasGreens);
        uint256 sellTax = calculateBuySellTax(greensValue, _sender);
        uint256 penalty = getBuySellPenalty(_sender);

        setInvestorClaimedGreens(_sender, greensLeft);
        setInvestorLastHire(_sender, getCurrentTime());
        marketGreens = SafeMath.add(marketGreens,hasGreens);
        payBuySellTax(sellTax);
        addInvestorWithdrawal(_sender, SafeMath.sub(greensValue, sellTax));
        setInvestorLastSell(_sender, SafeMath.sub(greensValue, sellTax));
        payable (_sender).transfer(SafeMath.sub(greensValue,sellTax));

        // Push the timestamp
        setInvestorSellsTimestamp(_sender, getCurrentTime());
        setInvestorNsells(_sender, getInvestorData(_sender).nSells.add(1));
        //From milkfarmV1
        sellsTimestamps[msg.sender].push(block.timestamp);

        emit Sell(_sender, greensValue, SafeMath.sub(greensValue,sellTax), penalty);
    }

    function _hireMachines(address _ref, address _sender, uint256 _amount) private {        
        uint256 greensBought = calculateHireMachines(_amount, SafeMath.sub(address(this).balance, _amount));
            
        if(reIface.needUpdateEventBoostTimestamps()){
            reIface.updateEventsBoostTimestamps();
        }

        uint256 greensBSFee = calculateBuySellTax(greensBought, _sender);
        greensBought = SafeMath.sub(greensBought, greensBSFee);
        uint256 fee = calculateBuySellTax(_amount, _sender);        
        payBuySellTax(fee);
        setInvestorClaimedGreens(_sender, SafeMath.add(getInvestorData(_sender).claimedGreens, greensBought));
        addInvestorInvestment(_sender, _amount);
        _rehireMachines(_sender, _ref, false);

        emit Hire(_sender, greensBought, _amount);
    }

    function capToMaxSell(uint256 greensValue, uint256 greens) public view returns(uint256, uint256){
        uint256 maxSell = address(this).balance.mul(maxSellNum).div(maxSellDiv);
        if(maxSell >= greensValue){
            return (greensValue, 0);
        }
        else{
            uint256 greensMaxSell = maxSell.mul(greens).div(greensValue);
            if(greens > greensMaxSell){
                return (maxSell, greens.sub(greensMaxSell));
            }else{
                return (maxSell, 0);
            }
        }     
    }

    function getRewardsPercentage() public view returns (uint32) { return rewardsPercentage; }

    function getMarketGreens() public view returns (uint256) {
        return marketGreens;
    }
    
    function greensRewards(address adr) public view returns(uint256) {
        uint256 hasGreens = getMyGreens(adr);
        uint256 greensValue = calculateGreenSell(hasGreens);
        return greensValue;
    }

    function greensRewardsIncludingTaxes(address adr) public view returns(uint256) {
        uint256 hasGreens = getMyGreens(adr);
        (uint256 greensValue,) = calculateGreenSellIncludingTaxes(hasGreens, adr);
        return greensValue;
    }

    function getBuySellPenalty(address adr) public view returns (uint256) {
        return getSellPenalty(adr);
        //return SafeMath.add(marketingFeeVal, devFeeVal);
    }

    function calculateBuySellTax(uint256 amount, address _sender) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, getBuySellPenalty(_sender)), 100);
    }

    function payBuySellTax(uint256 amountTaxed) private {  
        uint256 fullTax = devFeeVal.add(marketingFeeVal);         
        payable(recAdd).transfer(amountTaxed.mul(devFeeVal).div(fullTax));        
        payable(marketingAdd).transfer(amountTaxed.mul(marketingFeeVal).div(fullTax));        
    }

    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        uint256 valueTrade = SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
        if(rewardsPercentage > 15) {
            return SafeMath.div(SafeMath.mul(valueTrade,rewardsPercentage), 15);
        }

        return valueTrade;
    }
    
    function calculateGreenSell(uint256 greens) public view returns(uint256) {
        if(greens > 0){
            return calculateTrade(greens, marketGreens, address(this).balance);
        }
        else{
            return 0;
        }
    }

    function calculateGreenSellIncludingTaxes(uint256 greens, address adr) public view returns(uint256, uint256) {
        if(greens == 0){
            return (0,0);
        }
        uint256 totalTrade = calculateTrade(greens, marketGreens, address(this).balance);
        uint256 penalty = getBuySellPenalty(adr);
        uint256 sellTax = calculateBuySellTax(totalTrade, adr);

        return (
            SafeMath.sub(totalTrade, sellTax),
            penalty
        );
    }
    
    function calculateHireMachines(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return reIface.applyROIEventBoost(calculateHireMachinesNoEvent(eth, contractBalance));
    }

    function calculateHireMachinesNoEvent(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketGreens);
    }
    
    function calculateHireMachinesSimple(uint256 eth) public view returns(uint256) {
        return calculateHireMachines(eth, address(this).balance);
    }

    function calculateHireMachinesSimpleNoEvent(uint256 eth) public view returns(uint256) {
        return calculateHireMachinesNoEvent(eth, address(this).balance);
    }
    
    function isInitialized() public view returns (bool) {
        return initialized;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyGreens(address adr) public view returns(uint256) {
        return SafeMath.add(getInvestorData(adr).claimedGreens, getGreensSinceLastHire(adr));
    }
    
    function getGreensSinceLastHire(address adr) public view returns(uint256) {        
        uint256 secondsPassed=min(GREENS_TO_HATCH_1MACHINE, SafeMath.sub(getCurrentTime(), getInvestorData(adr).lastHire));
        return SafeMath.mul(secondsPassed, getInvestorData(adr).hiredMachines);
    }

    function getSellPenalty(address addr) public view returns (uint256) {

        // If there is custom sell tax for this address, then return it
        if(customSellTaxes[addr] > 0) {
            return customSellTaxes[addr];
        }

        uint256 sellsInRow = getSellsInRow(addr);
        uint256 numberOfSells = sellsTimestamps[addr].length;
        uint256 _sellTax = marketingFeeVal;

        if(numberOfSells > 0) {
            uint256 lastSell = sellsTimestamps[addr][numberOfSells - 1];

            if(sellsInRow == 0) {
                if((block.timestamp - 30 days) > lastSell) { // 1% sell tax for everyone who hold / rehire during 30+ days
                    _sellTax = 0;
                } else if((lastSell + 4 days) <= block.timestamp) { // 5% sell tax for everyone who sell after 4 days of last sell
                    _sellTax = marketingFeeVal;
                } else if((lastSell + 3 days) <= block.timestamp) { // 8% sell tax for everyone who sell after 3 days of last sell
                    _sellTax = 7;
                } else { // otherwise 10% sell tax
                    _sellTax = 9;
                }
            } else if(sellsInRow == 1) {  // 20% sell tax for everyone who sell 2 days in a row
                _sellTax = 19;
            } else if(sellsInRow >= 2) {  // 40% sell tax for everyone who sell 3 or more days in a row
                _sellTax = 39;
            }
        }

        return SafeMath.add(_sellTax, devFeeVal);
    }

    function setCustomSellTaxForAddress(address adr, uint256 percentage) public onlyOwner {
        customSellTaxes[adr] = percentage;
    }

    function getCustomSellTaxForAddress(address adr) public view returns (uint256) {
        return customSellTaxes[adr];
    }

    function removeCustomSellTaxForAddress(address adr) public onlyOwner {
        delete customSellTaxes[adr];
    }

    function getSellsInRow(address addr) public view returns(uint256) {
        uint256 sellsInRow = 0;
        uint256 numberOfSells = sellsTimestamps[addr].length;
        if(numberOfSells == 1) {
            if(sellsTimestamps[addr][0] >= (block.timestamp - 1 days)) {
                return 1;
            }
        } else if(numberOfSells > 1) {
            uint256 lastSell = sellsTimestamps[addr][numberOfSells - 1];

            if((lastSell + 1 days) <= block.timestamp) {
                return 0;
            } else {

                for(uint256 i = numberOfSells - 1; i > 0; i--) {
                    if(isSellInRow(sellsTimestamps[addr][i-1], sellsTimestamps[addr][i])) {
                        sellsInRow++;
                    } else {
                        if(i == (numberOfSells - 1))
                            sellsInRow = 0;

                        break;
                    }
                }

                if((lastSell + 1 days) > block.timestamp) {
                    sellsInRow++;
                }
            }
        }

        return sellsInRow;
    }

    function isSellInRow(uint256 previousDay, uint256 currentDay) private pure returns(bool) {
        return currentDay <= (previousDay + 1 days);
    }
    /////////////////

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? b : a;
    }

    receive() external payable {}
    ////////////////////////
}