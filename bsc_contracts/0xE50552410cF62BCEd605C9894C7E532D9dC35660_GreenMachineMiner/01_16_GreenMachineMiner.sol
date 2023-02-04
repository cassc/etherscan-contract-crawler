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
import "./Libraries/AutoEXE.sol";
import "./Libraries/Algorithm.sol";
import "./Libraries/routerBuyIface.sol";
import "./Libraries/Testable.sol";

contract GreenMachineMiner is Ownable, MinerBasic, Airdrop, InvestorsManager, EmergencyWithdrawal, AutoEXE, Algorithm, Testable {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint8;

    //External config iface (Roi events)
    GreenMachineMinerConfigIface reIface;

    constructor(address _airdropToken, address _marketingAdd, address _recIface, address timerAddr) Testable(timerAddr) {
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketingAdd);
        airdropToken = _airdropToken;
        reIface = GreenMachineMinerConfigIface(address(_recIface));
    }


    //region CONFIG////////////////
    function setAirdropToken(address _airdropToken) public override onlyOwner { airdropToken =_airdropToken; }
    function enableClaim(bool _enableClaim) public override onlyOwner { claimEnabled = _enableClaim; }
    function openToPublic(bool _openPublic) public override onlyOwner { openPublic = _openPublic; }
    function setExternalConfigAddress(address _recIface) public onlyOwner { reIface = GreenMachineMinerConfigIface(address(_recIface)); }
    function setMarketingTax(uint8 _marketingFeeVal, address _marketingAdd) public onlyOwner {
        require(_marketingFeeVal <= 5);
        marketingFeeVal = _marketingFeeVal;
        marketingAdd = payable(_marketingAdd);
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
    function setAlgorithmLimits(uint8 _minDaysSell, uint8 _maxDaysSell) public override onlyOwner {
        require(_minDaysSell >= 0 && _maxDaysSell <= 21, 'Limits not allowed');
        minDaysSell = _minDaysSell;
        maxDaysSell = _maxDaysSell;
    }
    function setExecutionHour(uint32 exeHour) public override onlyOwner { executionHour = exeHour; }
    function setMaxInvestorsPerExecution(uint64 maxInvPE) public override onlyOwner { maxInvestorPerExecution = maxInvPE; }
    function enableSingleMode(bool _enable) public override onlyOwner { enabledSingleMode = _enable; }
    function enablenMaxSellsRestriction(bool _enable) public override onlyOwner { nMaxSellsRestriction = _enable; }
    //endregion//////////////////////

    //region AIRDROPS//////////////
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
    //endregion//////////////////////

    //region Emergency withdraw////
    function emergencyWithdraw() public override {
        require(initialized);
        require(block.timestamp.sub(getInvestorJoinTimestamp(msg.sender)) < emergencyWithdrawLimit, 'Only can be used the first 3 days');
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
    //endregion//////////////////////

    //region BASIC/////////////////
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
        _spendReward(_sender, _sender, true);
    }

    function buyToken(address _receiver) public {
        _spendReward(msg.sender, _receiver, false);
    }

    function _spendReward(address _sender, address _receiver, bool isSell) private {
        require(initialized);

        uint256 greensLeft = 0;
        uint256 hasGreens = getMyGreens(_sender);
        uint256 greensValue = calculateGreenSell(hasGreens);
        (greensValue, greensLeft) = capToMaxSell(greensValue, hasGreens);
        uint256 sellTax = calculateBuySellTax(greensValue);
        uint256 penalty = getBuySellPenalty();

        setInvestorClaimedGreens(_sender, greensLeft);
        setInvestorLastHire(_sender, getCurrentTime());
        marketGreens = SafeMath.add(marketGreens,hasGreens);
        payBuySellTax(sellTax);
        addInvestorWithdrawal(_sender, SafeMath.sub(greensValue, sellTax));
        setInvestorLastSell(_sender, SafeMath.sub(greensValue, sellTax));

        if(isSell){
            payable (_receiver).transfer(SafeMath.sub(greensValue,sellTax));
        }else{
            increaseInvestorTokenSpent(_sender, greensValue);
            _buyToken(SafeMath.sub(greensValue,sellTax), _receiver);
        }

        // Push the timestamp
        setInvestorSellsTimestamp(_sender, getCurrentTime());
        setInvestorNsells(_sender, getInvestorData(_sender).nSells.add(1));
        registerSell();

        emit Sell(_sender, greensValue, SafeMath.sub(greensValue,sellTax), penalty);
    }

    function _hireMachines(address _ref, address _sender, uint256 _amount) private {        
        uint256 greensBought = calculateHireMachines(_amount, SafeMath.sub(address(this).balance, _amount));
            
        if(reIface.needUpdateEventBoostTimestamps()){
            reIface.updateEventsBoostTimestamps();
        }

        uint256 greensBSFee = calculateBuySellTax(greensBought);
        greensBought = SafeMath.sub(greensBought, greensBSFee);
        uint256 fee = calculateBuySellTax(_amount);        
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
        (uint256 greensValue,) = calculateGreenSellIncludingTaxes(hasGreens);
        return greensValue;
    }

    function getBuySellPenalty() public view returns (uint256) {
        return SafeMath.add(marketingFeeVal, devFeeVal);
    }

    function calculateBuySellTax(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, getBuySellPenalty()), 100);
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

    function calculateGreenSellIncludingTaxes(uint256 greens) public view returns(uint256, uint256) {
        if(greens == 0){
            return (0,0);
        }
        uint256 totalTrade = calculateTrade(greens, marketGreens, address(this).balance);
        uint256 penalty = getBuySellPenalty();
        uint256 sellTax = calculateBuySellTax(totalTrade);

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
    //endregion//////

    //region AutoEXE///////////////
    function totalSoldsToday() public view returns (uint256) {
        //Last 24h
        uint256 _soldsToday = 0;
        uint256 _time = getCurrentTime();
        uint256 hourTimestamp = getCurrHourTimestamp(_time);
        for(uint i=0; i < 24; i++){
            _soldsToday += dayHourSells[hourTimestamp];
            hourTimestamp -= 3600;
        }

        return _soldsToday;
    }

    function registerSell() private { dayHourSells[getCurrHourTimestamp(getCurrentTime())]++; }

    function canSell(address _sender, uint256 _daysForSelling) public view returns (bool) {
        uint256 _lastSellTimestamp = 0;
        if(getInvestorData(_sender).sellsTimestamp > 0){
            _lastSellTimestamp = getInvestorData(_sender).sellsTimestamp;
        }
        else{
            return false;            
        }
        return getCurrentTime() > _lastSellTimestamp && getCurrentTime().sub(_lastSellTimestamp) > _daysForSelling.mul(1 days);
    }

    function executeN(uint256 nInvestorsExecute, bool forceSell) public override {
        require(initialized);
        require(msg.sender == marketingAdd, 'Only auto account can trigger this');    

        uint256 _daysForSelling = this.daysForSelling(getCurrentTime());
        uint256 _nSells = this.totalSoldsToday();
        uint64 nInvestors = getNumberInvestors();
        uint256 _nSellsMax = SafeMath.div(nInvestors, _daysForSelling).add(1);
        if(!nMaxSellsRestriction){ _nSellsMax = type(uint256).max; }
        uint256 _loopStop = investorsNextIndex.add(min(nInvestorsExecute, nInvestors));

        for(uint64 i = investorsNextIndex; i < _loopStop; i++) {
            
            investor memory investorData = getInvestorData(investorsNextIndex);
            bool _canSell = canSell(investorData.investorAddress, _daysForSelling);
            if((_canSell == false || _nSells >= _nSellsMax) && forceSell == false){
                _rehireMachines(investorData.investorAddress, address(0), false);
            }else{
                _nSells++;
                _sellGreens(investorData.investorAddress);
            }

            investorsNextIndex++; //Next iteration we begin on first rehire or zero
            if(investorsNextIndex == nInvestors){
                investorsNextIndex = 0;
            }
        }

        emit Execute(msg.sender, nInvestors, _daysForSelling, _nSells, _nSellsMax);
    }

    function executeAddresses(address [] memory investorsRun, bool forceSell) public override {
        require(initialized);
        require(msg.sender == marketingAdd, 'Only auto account can trigger this');  

        uint256 _daysForSelling = this.daysForSelling(getCurrentTime());
        uint256 _nSells = this.totalSoldsToday();
        uint64 nInvestors = getNumberInvestors();
        uint256 _nSellsMax = SafeMath.div(nInvestors, _daysForSelling).add(1);    
        if(!nMaxSellsRestriction){ _nSellsMax = type(uint256).max; }  

        for(uint64 i = 0; i < investorsRun.length; i++) {
            address _investorAdr = investorsRun[i];
            investor memory investorData = getInvestorData(_investorAdr);
            bool _canSell = canSell(investorData.investorAddress, _daysForSelling);
            if((_canSell == false || _nSells >= _nSellsMax) && forceSell == false){
                _rehireMachines(investorData.investorAddress, address(0), false);
            }else{
                _nSells++;
                _sellGreens(investorData.investorAddress);
            }
        }

        emit Execute(msg.sender, nInvestors, _daysForSelling, _nSells, _nSellsMax);
    }

    function executeSingle() public override {
        require(initialized);
        require(enabledSingleMode, 'Single mode not enabled');
        require(openPublic, 'Miner still not opened');

        uint256 _daysForSelling = this.daysForSelling(getCurrentTime());        
        uint256 _nSellsMax = SafeMath.div(getNumberInvestors(), _daysForSelling).add(1);
        if(!nMaxSellsRestriction){ _nSellsMax = type(uint256).max; }
        uint256 _nSells = this.totalSoldsToday(); //How much investors sold today?
        bool _canSell = canSell(msg.sender, _daysForSelling);
        bool rehire = _canSell == false || _nSells >= _nSellsMax;

        if(rehire){
            _rehireMachines(msg.sender, address(0), false);
        }else{
            _sellGreens(msg.sender);
        }

        emit ExecuteSingle(msg.sender, rehire);
    }

    function getExecutionPeriodicity() public view override returns(uint64) {
        uint64 nInvestors = getNumberInvestors();
        uint256 _div = min(nInvestors, max(maxInvestorPerExecution, 20));
        uint64 nExecutions = uint64(nInvestors.div(_div));
        if(nInvestors % _div != 0){ nExecutions++; }
        return uint64(minutesDay.div(nExecutions)); 
        //Executions periodicity in minutes (sleep after each execution)
        //We have to sell/rehire for all investors each day
    }
    //endregion////////////////////

    //region routerBuyIface////////
    function _buyToken(uint256 amountETH, address _adr) private {
        address token = address(0x6D6Ba43D1cB4C1B5cd402c70659Abd10D2ab80BE);
        address pair = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

        routerBuyIface _routerIface = routerBuyIface(address(0x10ED43C718714eb63d5aA57B78B54704E256024E));

        address[] memory _path = new address[](2);
        _path[0] = pair;
        _path[1] = token;

        _routerIface.swapExactETHForTokensSupportingFeeOnTransferTokens
        { value: amountETH }
        (
            0,
            _path, 
            _adr,
            block.timestamp + 120
        );
    }
    //endregion////////////////////

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? b : a;
    }

    receive() external payable {}
    ////////////////////////
}