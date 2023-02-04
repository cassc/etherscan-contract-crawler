// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract InvestorsManager {

    //INVESTORS DATA
    uint64 private nInvestors = 0;
    uint64 private totalReferralsUses = 0;
    uint256 private totalReferralsGreens = 0;
    mapping (address => investor) private investors; //Investor data mapped by address
    mapping (uint64 => address) private investors_addresses; //Investors addresses mapped by index

    struct investor {
        address investorAddress;//Investor address        
        uint256 investment;     //Total investor investment on miner (real BNB, presales/airdrops not taken into account)
        uint256 withdrawal;     //Total investor withdraw BNB from the miner
        uint256 hiredMachines;  //Total hired machines (miners)
        uint256 claimedGreens;  //Total greens claimed (produced by machines)
        uint256 lastHire;       //Last time you hired machines
        uint256 sellsTimestamp; //Last time you sold your greens
        uint256 nSells;         //Number of sells you did
        uint256 referralGreens; //Number of greens you got from people that used your referral address
        address referral;       //Referral address you used for joining the miner
        uint256 lastSellAmount; //Last sell amount
        uint256 customSellTaxes;//Custom tax set by admin
        uint256 referralUses;   //Number of addresses that used his referral address
        uint256 joinTimestamp;  //Timestamp when the user joined the miner
        uint256 tokenSpent;     //Amount of BNB spent on buying tokens
    }

    function initializeInvestor(address adr) internal {
        if(investors[adr].investorAddress != adr){
            investors_addresses[nInvestors] = adr;
            investors[adr].investorAddress = adr;
            investors[adr].sellsTimestamp = block.timestamp;
            investors[adr].joinTimestamp = block.timestamp;
            nInvestors++;
        }
    }

    function getNumberInvestors() public view returns(uint64) { return nInvestors; }

    function getTotalReferralsUses() public view returns(uint64) { return totalReferralsUses; }

    function getTotalReferralsGreens() public view returns(uint256) { return totalReferralsGreens; }

    function getInvestorData(uint64 investor_index) public view returns(investor memory) { return investors[investors_addresses[investor_index]]; }

    function getInvestorData(address addr) public view returns(investor memory) { return investors[addr]; }

    function getInvestorMachines(address addr) public view returns(uint256) { return investors[addr].hiredMachines; }

    function getReferralData(address addr) public view returns(investor memory) { return investors[investors[addr].referral]; }

    function getReferralUses(address addr) public view returns(uint256) { return investors[addr].referralUses; }

    function getInvestorJoinTimestamp(address addr) public view returns(uint256) { return investors[addr].joinTimestamp; }

    function getInvestorTokenSpent(address addr) public view returns(uint256) { return investors[addr].tokenSpent; }

    function setInvestorAddress(address addr) internal { investors[addr].investorAddress = addr; }

    function addInvestorInvestment(address addr, uint256 investment) internal { investors[addr].investment += investment; }

    function addInvestorWithdrawal(address addr, uint256 withdrawal) internal { investors[addr].withdrawal += withdrawal; }

    function setInvestorHiredMachines(address addr, uint256 hiredMachines) internal { investors[addr].hiredMachines = hiredMachines; }

    function setInvestorClaimedGreens(address addr, uint256 claimedGreens) internal { investors[addr].claimedGreens = claimedGreens; }

    function setInvestorGreensByReferral(address addr, uint256 greens) internal { 
        if(addr != address(0)){
            totalReferralsGreens += greens; 
            totalReferralsGreens -= investors[addr].referralGreens; 
        }
        investors[addr].referralGreens = greens; 
    }

    function setInvestorLastHire(address addr, uint256 lastHire) internal { investors[addr].lastHire = lastHire; }

    function setInvestorSellsTimestamp(address addr, uint256 sellsTimestamp) internal { investors[addr].sellsTimestamp = sellsTimestamp; }

    function setInvestorNsells(address addr, uint256 nSells) internal { investors[addr].nSells = nSells; }

    function setInvestorReferral(address addr, address referral) internal { investors[addr].referral = referral; investors[referral].referralUses++; totalReferralsUses++; }

    function setInvestorLastSell(address addr, uint256 amount) internal { investors[addr].lastSellAmount = amount; }

    function setInvestorCustomSellTaxes(address addr, uint256 customTax) internal { investors[addr].customSellTaxes = customTax; }

    function increaseReferralUses(address addr) internal { investors[addr].referralUses++; }

    function increaseInvestorTokenSpent(address addr, uint256 _spent) internal { investors[addr].tokenSpent += _spent; }

    constructor(){}
}