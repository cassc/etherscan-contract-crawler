// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract TheNetworkSociety is Context, Ownable {
    using SafeMath for uint256;

    //user record library
    struct User {
        address networkSponsor; //network sponsor
        uint256 totalNetworkInvites; //invite count
        uint256 totalDepositAmount; //invested + compounded
        uint256 totalDepositPayouts; //payouts
        uint256 totalDirectDeposits; //real deposits
        uint256 totalIncomeCompounded; //compounded
        uint256 totalNetworkInvitesDeposit; //total invested by invites
        uint256 yieldPercentage; //user personal yield.
        uint256 compoundCount; //user compound count record
        uint256 lastAction; //user action checkpoint
    }

    //bonus record library, statistics records only
    struct UserBonus {
        uint256 inviteBonus; //referral / referee bonus
        uint256 lastDepositBonus; //last deposit bonus if address has won
        uint256 topDepositBonus; //top deposit bonus if address has won
    }

    //networks record library
    struct Network {
        bool hasInvites; //if exist or not, if true, then use current id, else create a new one and designate an id.
        uint256 id; //network id 
        address owner; //network owner address
        uint256 createTime; //network creation timestamp
        address[] members; //network invites address
    }

    //airdrop record library
    struct Airdrop {
        uint256 airdropSent; //total airdrop sent
        uint256 airdropReceived; //total airdrop received
        uint256 lastAirdropReceivedTime; //last airdrop received timestamp
        uint256 lastAirdropSentTime; // last airdrop sent timestamp
        uint256 airdropSentCount;
        uint256 airdropReceivedCount;
    }
    
    //Address Mapping Details
    mapping(address => User) private users; //users investment details
    mapping(address => Network) private networks; //users network details
    mapping(address => Airdrop) private airdrops; //users airdrop details
    mapping(address => UserBonus) private usersBonus; //users bonus details

    //Events Mapping Details
    mapping(uint256 => address) private topDepositPool;
    mapping(uint256 => address) private topReferrerPool;
    
    //variable 
    uint256 private constant tax = 1000; //10%
    uint256 private constant invShare = 2000; //20%
    uint256 private constant topDepositPrc = 300; //3% of top depositors deposit will be the reward.
    uint256 private constant compoundTax = 300; //3% stays in the contract

    uint256 private constant userMaxPayout = 30000; //300% max profit
    uint256 private constant maxCompoundMultiplier = 5; //5x of real investment
    
    uint256 private constant eventPercent = 100; //1% of each deposit
    uint256 private constant invitePercent = 400; //4% for 2% referrer and 2% referee.
    uint256 private constant decreasePercent = 50; //0.5% yield decrease per withdraw
    uint256 private constant maxYieldPercent = 200; //2%
    uint256 private constant baseYieldPercent = 100; //1%
    uint256 private constant dividerPercent = 10000; //10,000 for more precise computation.

    uint256 private constant airdropMinimum = 1 ether;
    uint256 private constant depositMinimum = 25 ether;  
    uint256 private constant maxRewards = 2000 ether;

    //time steps
    uint256 private timeStep = 1 days;
    uint256 private cutOffTimeStep = 2 days;
    uint256 private topDepositTimeStep = 2 days;
    uint256 private lastDepositTimeStep = 6 hours;

    uint256 private topDepositCurrentRound = 1;
    uint256 private topDepositPoolBalance;
    uint256 private topDepositCurrentAmount;
    address private topDepositPotentialWinner;
    uint256 private topDepositLastDrawAction;

    address private previousTopDepositWinner;
    uint256 private previousTopDepositRewards;

    uint256 private lastBuyCurrentRound = 1;
    uint256 private lastDepositPoolBalance;
    uint256 private lastDepositLastDrawAction;
    address private lastDepositPotentialWinner;

    address private previousPoolWinner;
    uint256 private previousPoolRewards;

    //project statistics
    uint256 private totalAirdrops; //total airdrops sent by network leaders.
    uint256 private totalInvestors; //total users invested. 
    uint256 private totalDeposited; //total amount deposited into the protocol
    uint256 private totalWithdrawn; //total amount withdrawn in the protocol
    uint256 private totalCompounded; //total amount compounded only from investors.
    uint256 private totalNetworksCreated; //total number of networks created in the protocol.
    uint256 private contractLaunchTime; //contract launch timestamp.

    //arrays
    uint256[] private daysCount = [10, 20, 30, 40, 50]; //10 days, 20 days, 30 days, 40 days, 50 days
    uint256[] private variableTax = [1000, 800, 600, 400, 200, 0]; //10%, 8%, 6%, 4%, 2%, 0%

    //protocol feature enablers
    bool private initialized;
    bool private airdropEnabled;
    bool private autoCompoundEnabled;
    bool private networkAirdropEnabled;

    //event feature enabler
    bool private topDepositEnabled;
    bool private lastDepositEnabled;
    
    address private networkLeader; //initial network leader set as per contract initialization.
    address private autoCompoundExecutorContract; //auto compound contract address
    
    //project addresses
    address private immutable development; //development address
    address private immutable portfolio;   //portfolio address for investing

    ERC20 private token = ERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    //user events
    event AutoCompound(address indexed addr, uint256 timestamp);
    event Deposit(address indexed addr, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed addr, uint256 amount, uint256 timestamp);
	event Compound(address indexed addr, uint256 amount, uint256 timestamp);
    event MaxPayout(address indexed addr, uint256 amount, uint256 timestamp);
    event MaxCompound(address indexed addr, uint256 amount, uint256 timestamp);
    event Sponsor(address indexed addr, address indexed sponsor, uint256 timestamp);
    event Airdropped(address indexed fromAddr, address indexed toAddr, uint256 amount, uint256 timestamp);

    //payout events
    event RefereePayout(address indexed addr, address indexed from, uint256 amount, uint256 timestamp);
    event ReferralPayout(address indexed addr, address indexed from, uint256 amount, uint256 timestamp);
    event LastBuyPayout(uint256 indexed round, address indexed addr, uint256 amount, uint256 timestamp);
    event TopDepositPayout(uint256 indexed round, address indexed addr, uint256 amount, uint256 timestamp);


    constructor(address ldr, address dvt, address port) {
        require(!Address.isContract(ldr) && !Address.isContract(dvt) && !Address.isContract(port), "Wallet Address Only.");
        networkLeader  = ldr;
        development    = dvt;
        portfolio      = port;
    }

    modifier isInitialized() {
        require(initialized, "Contract not initialized.");
        _;
    }
    
    modifier onlyExecutor() {
        require(autoCompoundExecutorContract == msg.sender, "Function can only be triggered by the executor.");
        _;
    }
    
    modifier onlyNetworkLeader() {
        require(networkLeader == msg.sender, "Function can only be triggered by the network leader.");
        _;
    }

    //normal invest function. contract will set the initial sponsor if there is no referral address used or the sponsor address is not invested. This is to follow the business model of the contract.
    function invest(address sponsor, uint256 amount) public isInitialized {
        address addr = msg.sender;
        User storage user = users[addr];
        //for existing network members who redeposited use the previous network Sponsor.
        sponsor = user.networkSponsor != address(0) ? user.networkSponsor : validateNetworkSponsor(sponsor);
		setupSponsorshipDetails(addr, sponsor);
        deposit(addr, amount);
    }  

    //setup sponsor for the investor.
    function setupSponsorshipDetails(address addr, address sponsor) private {
        if(isValidSponsorAddress(addr, sponsor)) {
            Network storage network = networks[sponsor];
            users[addr].networkSponsor = sponsor;

            //if sponsor doesn't have existing network, create one for the address.
            if(!networks[sponsor].hasInvites) {
                uint256 networkId  = totalNetworksCreated++;
                network.id         = networkId;
                network.owner      = sponsor;
                network.hasInvites = true;
                network.createTime = block.timestamp;
            }

            // if total direct deposit is 0, means user not yet invest, add address to sponsors network members list. 
            // no need to check network member list to avoid high gas fee.
            if(users[addr].totalDirectDeposits <= 0) {
                network.members.push(addr);
                users[sponsor].totalNetworkInvites++; //only add invites for new investments.
            }
            emit Sponsor(addr, sponsor, block.timestamp); //record total invites of network leader
        }
    }

    //validate sponsorship.
    function isValidSponsorAddress(address addr, address sponsor) view public returns (bool isValidSponsor) {	
        isValidSponsor = ((users[sponsor].lastAction > 0 && users[addr].networkSponsor == address(0) 
        && sponsor != addr && addr != networkLeader) 
        || (sponsor == networkLeader)) ? true : false;
    }

    //user's invest function.
    function deposit(address addr, uint256 amount) private isInitialized {
        User storage user = users[addr];
        require(user.networkSponsor != address(0) || addr == networkLeader, "Invalid network sponsor.");
        require(amount >= depositMinimum, "Mininum deposit not reached or User's maximum investment reached.");

        token.transferFrom(address(addr), address(this), amount);

        if(user.totalDepositAmount <= 0) { 
            user.yieldPercentage = baseYieldPercent; // new users will have a default yield of 1%
            totalInvestors++; // only count new deposits
        }

        compound(addr); //compound existing user's accumulated yield before new deposit.
        payTax(amount); //deposit tax won't be subracted to user's deposited amount.
        user.lastAction           = block.timestamp; // update action timestamp
        user.totalDirectDeposits += amount; // invested
        user.totalDepositAmount  += amount; // invested + compounded
        totalDeposited           += amount; // update total deposits.
        emit Deposit(addr, amount, block.timestamp);

        networkInvitePayout(addr, amount);

        //execute events, user's event entry if qualified.
        drawLastDepositWinner();
        poolLastDeposit(addr, amount);    
      
        drawTopDepositWinner();
        poolTopDeposit(addr, amount);
    }

    //users maximum compound.
    function maxCompoundOf(uint256 amount) pure private returns(uint256) {
        return amount.mul(maxCompoundMultiplier);
    }
    
    //user's final amount available for compound.
    function compoundAmountOf(address addr, uint256 value) view private returns(uint256 maxCompound, uint256 amount) { 
        User storage user = users[addr];
        maxCompound = maxCompoundOf(users[addr].totalDirectDeposits);
        amount = value; 
        if(user.totalDepositAmount >= maxCompound) amount = 0; //avoid reverts, but if amount = 0, user already exceeded x5 of total deposit.
        if(user.totalDepositAmount.add(value) >= maxCompound) amount = maxCompound.sub(user.totalDepositAmount);      
    }

    //compound user's current yield.
    function compound(address addr) public isInitialized {   
        User storage user = users[addr];
        (, , uint256 payoutPostTax) = getUserDividends(addr, false);
        (uint256 maxCompound, uint256 amount) = compoundAmountOf(addr, payoutPostTax);

        if(amount > 0 && user.totalDepositAmount < maxCompound){
            if(block.timestamp.sub(user.lastAction) >= timeStep) {
                if(user.yieldPercentage < maxYieldPercent) user.yieldPercentage += 5; //0.05% increase in yield for compounds every 24 hours.
                user.compoundCount++;
            }
              
            user.lastAction = block.timestamp;
            user.totalDepositAmount    += amount;
            user.totalIncomeCompounded += amount;   
            totalCompounded += amount;
            emit Compound(addr, amount, block.timestamp);
            
            //if user reached max compound after last compound. emit MaxCompound event.
            if(user.totalDepositAmount >= maxCompound) {
                emit MaxCompound(addr, user.totalDepositAmount, block.timestamp);
            }
        }
        
        if(this.checkDrawEvents()) this.runDrawEvents();
	}

    //Network Invite Payout
    function networkInvitePayout(address addr, uint256 amount) public isInitialized {   
        User storage user = users[addr];
        address sponsor = user.networkSponsor;
        User storage networkSponsor = users[sponsor];

        if(user.networkSponsor != address(0)) {
            uint256 inviteBonus  = amount.mul(invitePercent).div(dividerPercent).div(2); //2%
            uint256 bonusShare   = inviteBonus.div(2); //1%

            //2% for referee -- 1% will go to direct deposit, 1% will be transfered to referee wallet.
            user.totalDirectDeposits     += bonusShare; // invested
            user.totalDepositAmount      += bonusShare;  // invested + compounded
            usersBonus[addr].inviteBonus += inviteBonus; //transferred + added to deposit statistics record .
            token.transfer(addr, bonusShare); 
            
            //2% for referrer -- 1% will go to direct deposit, 1% will be transfered to referrer wallet.
            networkSponsor.totalDirectDeposits += bonusShare; //invested
            networkSponsor.totalDepositAmount  += bonusShare; //invested + compounded
            usersBonus[sponsor].inviteBonus    += inviteBonus; //transferred + added to deposit statistics record .
            token.transfer(sponsor, bonusShare); 
            
            //record total amount of invites the network leader has.
            networkSponsor.totalNetworkInvitesDeposit += amount;

            emit RefereePayout(addr, address(this), inviteBonus, block.timestamp);
            emit ReferralPayout(user.networkSponsor, address(this), inviteBonus, block.timestamp);  
        }
	}

    //withdraw user's accumulated yield.
    function withdraw() public isInitialized {
        address addr = msg.sender;        
        User storage user = users[addr];
        
        (uint256 maxPayout, , uint256 payoutPostTax) = getUserDividends(addr, true);

        if(payoutPostTax > 0 && user.totalDepositPayouts < maxPayout){ // avoid reverts
            //yieldPercentage will be deducted 0.5% every withdraw, starts at 1.55% else, if daily yield is less than or equal to 1.5% yield it goes back to 1%
            if(user.yieldPercentage >= baseYieldPercent && user.yieldPercentage <= 150) { //between 1% to 1.5%
                user.yieldPercentage = baseYieldPercent;        
            }
            else if(user.yieldPercentage > 150) { // 0.5% decrease if greater than 1.50%
                user.yieldPercentage -= decreasePercent;    
            }

            if(token.balanceOf(address(this)) < payoutPostTax) payoutPostTax = token.balanceOf(address(this));

            user.compoundCount = 0; //user consecutive compound count will reset when withdraw is triggered
            user.lastAction = block.timestamp;
            user.totalDepositPayouts += payoutPostTax;
            totalWithdrawn += payoutPostTax;
            token.transfer(addr, payoutPostTax);
            emit Withdraw(addr, payoutPostTax, block.timestamp);   
        
            // if user reached max payout after last withdraw. emit MaxPayout event.
            if(user.totalDepositPayouts >= maxPayout) {
                emit MaxPayout(addr, user.totalDepositPayouts, block.timestamp);
            }
        }
        
        if(this.checkDrawEvents()) this.runDrawEvents();
    }

    function poolLastDeposit(address userAddress, uint256 amount) private {
        if(!lastDepositEnabled) return;

        uint256 poolShare = amount.mul(eventPercent).div(dividerPercent);

        lastDepositPoolBalance = lastDepositPoolBalance.add(poolShare) > maxRewards ? 
        lastDepositPoolBalance.add(maxRewards.sub(lastDepositPoolBalance)) : lastDepositPoolBalance.add(poolShare);
        lastDepositPotentialWinner = userAddress;
        lastDepositLastDrawAction  = block.timestamp;
    }  

    function drawLastDepositWinner() public {
        if(lastDepositEnabled && block.timestamp.sub(lastDepositLastDrawAction) >= lastDepositTimeStep && lastDepositPotentialWinner != address(0)) {
            
            if(token.balanceOf(address(this)) < lastDepositPoolBalance) lastDepositPoolBalance = token.balanceOf(address(this));

            token.transfer(lastDepositPotentialWinner, lastDepositPoolBalance); 
            emit LastBuyPayout(lastBuyCurrentRound, lastDepositPotentialWinner, lastDepositPoolBalance, block.timestamp);
            
            usersBonus[lastDepositPotentialWinner].lastDepositBonus += lastDepositPoolBalance; //statistics record.
            previousPoolWinner         = lastDepositPotentialWinner;
            previousPoolRewards        = lastDepositPoolBalance;
            lastDepositPoolBalance     = 0;
            lastDepositPotentialWinner = address(0);
            lastDepositLastDrawAction  = block.timestamp; 
            lastBuyCurrentRound++;
        }
    }

    function poolTopDeposit(address userAddress, uint256 amount) private {
        if(!topDepositEnabled) return;

        if(amount > topDepositCurrentAmount){
            topDepositCurrentAmount   = amount;
            topDepositPoolBalance     = topDepositCurrentAmount.mul(topDepositPrc).div(dividerPercent);
            topDepositPotentialWinner = userAddress;
        }
    } 

    function drawTopDepositWinner() private {
        if(topDepositEnabled && block.timestamp.sub(topDepositLastDrawAction) >= topDepositTimeStep && topDepositPotentialWinner != address(0)) {
            
            if(token.balanceOf(address(this)) < topDepositPoolBalance) topDepositPoolBalance = token.balanceOf(address(this));

            token.transfer(topDepositPotentialWinner, topDepositPoolBalance); 
            emit TopDepositPayout(topDepositCurrentRound, topDepositPotentialWinner, topDepositPoolBalance, block.timestamp);
            
            usersBonus[topDepositPotentialWinner].topDepositBonus += topDepositPoolBalance; //statistics record.
            previousTopDepositWinner  = topDepositPotentialWinner;
            previousTopDepositRewards = topDepositPoolBalance;
            topDepositPotentialWinner = address(0);
            topDepositCurrentAmount   = 0;
            topDepositPoolBalance     = 0;
            topDepositLastDrawAction  = block.timestamp;
            topDepositCurrentRound++;
        }
    }

    // user's current payout available.
    function getUserDividends(address addr, bool isClaim) view public returns(uint256 maxPayout, uint256 payout, uint256 payoutPostTax) {
        User storage user = users[addr];
        maxPayout = user.totalDepositAmount.mul(userMaxPayout).div(dividerPercent);
        
        if(user.totalDepositPayouts < maxPayout) {
            uint256 timeElapsed = block.timestamp.sub(user.lastAction) > cutOffTimeStep ? cutOffTimeStep : block.timestamp.sub(user.lastAction);
            payout = (user.totalDepositAmount.mul(user.yieldPercentage).div(dividerPercent)).mul(timeElapsed).div(timeStep);
            
            if(user.totalDepositPayouts.add(payout) > maxPayout) payout = maxPayout.sub(user.totalDepositPayouts);

            //isClaim: true = withdraw, false = compound.
            uint256 sustainabilityTax = isClaim ? getVariableWithdrawTax(addr) : compoundTax;
            payoutPostTax = payout.sub(payout.mul(sustainabilityTax).div(dividerPercent));
        }
    }

    // get user's current sustainability tax.
    function getVariableWithdrawTax(address addr) view public returns(uint256 withdrawTax) {
        if(users[addr].compoundCount <= daysCount[0]) { // less than 10 days of continues compounding.
            withdrawTax = variableTax[0]; // 10% tax.
        }
        else if(users[addr].compoundCount > daysCount[0] 
        && users[addr].compoundCount <= daysCount[1]) { // between 11 to 20 days of continues compounding.
            withdrawTax = variableTax[1]; // 8% tax.
        }
        else if(users[addr].compoundCount > daysCount[1] 
        && users[addr].compoundCount <= daysCount[2]) { // between 21 to 30 days of continues compounding.
            withdrawTax = variableTax[2]; // 6% tax.
        }
        else if(users[addr].compoundCount > daysCount[2] 
        && users[addr].compoundCount <= daysCount[3]) { //between 31 to 40 days of continues compounding. 
            withdrawTax = variableTax[3]; // 4% tax.
        }
        else if(users[addr].compoundCount > daysCount[3] 
        && users[addr].compoundCount <= daysCount[4]) { //between 41 to 50 days of continues compounding. 
            withdrawTax = variableTax[4]; // 2% tax.
        }
        else if(users[addr].compoundCount > daysCount[4]) { //above 51 days of continues compounding.
            withdrawTax = variableTax[5]; // 0% tax.
        }
    }

    // airdrop to network members.
    function airdrop(address receiver, uint256 amount) public isInitialized {
        require(amount >= airdropMinimum, "Individual airdrop minimum amount not met.");
        require(users[receiver].networkSponsor != address(0), "Network not found.");
        require(airdropEnabled, "Airdrop not Enabled.");

        // network leader will skip this check, so feature can be used for events/contests done by the team.
        if(msg.sender != networkLeader) require(users[receiver].networkSponsor == msg.sender, "Sender address can only airdrop to its own network members.");

        token.transferFrom(address(msg.sender), address(this), amount);
     
        payTax(amount); //deposit tax won't be subracted to user's deposited amount.

        // airdrop sender details
        airdrops[msg.sender].airdropSent        += amount;
        airdrops[msg.sender].lastAirdropSentTime = block.timestamp;
        airdrops[msg.sender].airdropSentCount++;

        // airdrop receiver details
        airdrops[receiver].airdropReceived        += amount;
        airdrops[receiver].lastAirdropReceivedTime = block.timestamp;
        airdrops[receiver].airdropReceivedCount++;

        // airdrop amount will be put in user deposit amount.
        users[receiver].totalDirectDeposits += amount; // real investment
        users[receiver].totalDepositAmount  += amount; // real investment + compounded 
        totalAirdrops += amount; // update total airdrop sent
        emit Airdropped(msg.sender, receiver, amount, block.timestamp);
    }

    // airdrop from your network. networkId is selected by default
    // WARNING: potential high gas fee if user's network member list is 20 above.
    function networkAirdrop(uint256 amount) public isInitialized {
        require(networkAirdropEnabled, "Airdrop not Enabled.");
        require(amount >= airdropMinimum, "Network airdrop mininum amount not met.");
        require(networks[msg.sender].owner != address(0) && networks[msg.sender].owner == msg.sender, "Network not found.");

        token.transferFrom(address(msg.sender), address(this), amount);

        payTax(amount); //deposit tax won't be subracted to user's deposited amount.
        uint256 divided = amount.div(networks[msg.sender].members.length);

        for(uint256 i = 0; i < networks[msg.sender].members.length; i++) {
 
            address receiver = address(networks[msg.sender].members[i]);

            // airdrop sender details
            airdrops[msg.sender].airdropSent        += divided;
            airdrops[msg.sender].lastAirdropSentTime = block.timestamp;
            airdrops[msg.sender].airdropSentCount++;

            // airdrop receiver details
            airdrops[receiver].airdropReceived        += divided;
            airdrops[receiver].lastAirdropReceivedTime = block.timestamp;
            airdrops[receiver].airdropReceivedCount++;

            // airdrop amount will be put in user deposit amount.
            users[receiver].totalDirectDeposits += divided; // real investment
            users[receiver].totalDepositAmount  += divided; // real investment + compounded 
            totalAirdrops += divided; // update total airdrop sent
            emit Airdropped(msg.sender, receiver, divided, block.timestamp);
        }
    }
    
    // validate network address, invite-only format.
    function validateNetworkSponsor(address addressForChecking) view private returns(address sponsor) {
        sponsor = addressForChecking == address(0) || users[addressForChecking].totalDirectDeposits <= 0 ? networkLeader : addressForChecking;
    }

    // setup and initialized contract start. invest from protocols initial network leader.
    function initializeAndSetupNetwork(uint256 amount) public onlyNetworkLeader {
        require(!initialized, "Contract already initialized.");
        initialized               = true;
        lastDepositEnabled        = true;
        topDepositEnabled         = true;
        contractLaunchTime        = block.timestamp;
        lastDepositLastDrawAction = block.timestamp;
        topDepositLastDrawAction  = block.timestamp;
        deposit(networkLeader, amount);
    }
    
    function payTax(uint256 amount) private returns(uint256) {
        uint256 dvtTax = amount.mul(tax).div(dividerPercent); //10%
        uint256 share = amount.mul(invShare).div(dividerPercent); //20%
        token.transfer(development, dvtTax);
        token.transfer(portfolio, share);
        return dvtTax; //do not add share 
    }

    // current timestamp.
    function currentTime() view external returns(uint256) {
        return block.timestamp;
    }

    // current contract balance.
    function getBalance() view external returns(uint256) {
         return token.balanceOf(address(this));
    }

    // user's payout information.
    function userCurrentInvestmentInfo(address addr) view external returns(uint256 maxPayout, uint256 maxCompound, uint256 payout, uint256 payoutWithWithdrawTax, uint256 withdrawalTax, uint256 amountForCompound, uint256 compoundingTax, uint256 compoundCount) {
        compoundingTax = compoundTax;
        compoundCount  = users[addr].compoundCount;
        withdrawalTax  = getVariableWithdrawTax(addr);
        (maxPayout, payout, payoutWithWithdrawTax) = getUserDividends(addr, true);
        (maxCompound, amountForCompound) = compoundAmountOf(addr, payout.sub(payout.mul(compoundTax).div(dividerPercent)));
    }

    // user's primary information.
    function userDetailsInfo(address addr) view external returns(address networkSponsor, uint256 lastAction, uint256 totalDirectDeposits, uint256 totalDepositAmount, uint256 totalIncomeCompounded, uint256 totalDepositPayouts, uint256 yieldPercentage) {
        return (users[addr].networkSponsor, users[addr].lastAction, users[addr].totalDirectDeposits, users[addr].totalDepositAmount, users[addr].totalIncomeCompounded, users[addr].totalDepositPayouts, users[addr].yieldPercentage);
    }

    // user's bonus information.
    function userBonusInfo(address addr) view external returns(uint256 inviteBonus, uint256 lastDepositBonus, uint256 topDepositBonus) {
        return (usersBonus[addr].inviteBonus, usersBonus[addr].lastDepositBonus, usersBonus[addr].topDepositBonus);
    }

    // user's airdrop information. 
    function userAirdropInfo(address addr) view external returns(uint256 airdropSent, uint256 airdropSentCount, uint256 lastAirdropSentTime, uint256 airdropReceived, uint256 airdropReceivedCount, uint256 lastAirdropReceivedTime) {
        return  (airdrops[addr].airdropSent, airdrops[addr].airdropSentCount, airdrops[addr].lastAirdropSentTime, airdrops[addr].airdropReceived, airdrops[addr].airdropReceivedCount, airdrops[addr].lastAirdropReceivedTime);    
    }
    
    // user's network member info
    function userNetworkMembersInfo(address addr) view external returns(uint256 networkId, address networkOwner, uint256 dateCreated, address[] memory networkMembers, uint256 totalNetworkInvites, uint256 totalNetworkInvitesDeposit) {
        return (networks[addr].id, networks[addr].owner, networks[addr].createTime, networks[addr].members, users[addr].totalNetworkInvites, users[addr].totalNetworkInvitesDeposit);
    }
    
    // user's network sponsor member info
    function userNetworkSponsorMembersInfo(address addr) view external returns(uint256 networkId, address networkOwner, uint256 dateCreated, address[] memory networkMembers, uint256 totalNetworkInvites, uint256 totalNetworkInvitesDeposit) {
        return (networks[users[addr].networkSponsor].id, networks[users[addr].networkSponsor].owner, networks[users[addr].networkSponsor].createTime, networks[users[addr].networkSponsor].members, users[users[addr].networkSponsor].totalNetworkInvites, users[users[addr].networkSponsor].totalNetworkInvitesDeposit);
    }

    // contract information
    function contractInfo() view external returns(uint256 networkInvestors, uint256 networkDeposits, uint256 totalWithdrawnAmount, uint256 totalCompoundedAmount, uint256 networksCreated, uint256 globalAirdropSent, uint256 launchTime, uint256 cutOffStep, uint256 time) {
        return (totalInvestors, totalDeposited, totalWithdrawn, totalCompounded, totalNetworksCreated, totalAirdrops, contractLaunchTime, cutOffTimeStep, timeStep);
    }

    // get all contracts enabled features
    function getEnabledFeatures() view external returns(bool isContractInitialized, bool isAirdropEnabled, bool isTopDepositEnabled, bool isLastDepositEnabled, bool isAutoCompoundEnabled, bool isNetworkAirdropEnabled) {
        isContractInitialized   = initialized; 
        isAirdropEnabled        = airdropEnabled;
        isTopDepositEnabled     = topDepositEnabled;
        isLastDepositEnabled    = lastDepositEnabled;
        isAutoCompoundEnabled   = autoCompoundEnabled;         
        isNetworkAirdropEnabled = networkAirdropEnabled;
    }
    
    function lastDepositInfo() view external returns(uint256 currentRound, uint256 currentBalance, uint256 currentStartTime, uint256 currentStep, address currentPotentialWinner, uint256 previousReward, address previousWinner) {
        currentRound           = lastBuyCurrentRound;
        currentBalance         = lastDepositPoolBalance;
        currentStartTime       = lastDepositLastDrawAction;  
        currentStep            = lastDepositTimeStep;    
        currentPotentialWinner = lastDepositPotentialWinner;
        previousReward         = previousPoolRewards;
        previousWinner         = previousPoolWinner;
    }

    function topDepositInfo() view external returns(uint256 topDepositRound, uint256 topDepositCurrentTopDeposit, address topDepositCurrentPotentialWinner, uint256 topDepositCurrentBalance, uint256 topDepositCurrentStartTime, uint256 topDepositCurrentStep, uint256 topDepositPreviousReward, address topDepositPreviousWinner) {
        topDepositRound                  = topDepositCurrentRound;
        topDepositCurrentTopDeposit      = topDepositCurrentAmount;
        topDepositCurrentPotentialWinner = topDepositPotentialWinner;
        topDepositCurrentBalance         = topDepositPoolBalance;
        topDepositCurrentStartTime       = topDepositLastDrawAction;
        topDepositCurrentStep            = topDepositTimeStep;
        topDepositPreviousReward         = previousTopDepositRewards;
        topDepositPreviousWinner         = previousTopDepositWinner;
    }

    function changeLastDepositEventTime(uint256 lastDepoStep) external onlyOwner {
        require(lastDepoStep >= 1 hours && lastDepoStep <= 1 days, "Time step can only changed to 1 hour up to 24 hours.");
        drawLastDepositWinner();   
        lastDepositTimeStep = lastDepoStep;
    }

    function changeTopDepositEventTime(uint256 topDepoStep) external onlyOwner {
        require(topDepoStep >= 1 days && topDepoStep <= 7 days, "Time step can only changed to 1 day up to 7 days.");
        drawTopDepositWinner();   
        topDepositTimeStep = topDepoStep;
    }

    // enables network airdrop.
    function switchNetworkAirdropStatus() external onlyOwner isInitialized {
        networkAirdropEnabled = !networkAirdropEnabled ? true : false;
    }

    // enables individual airdrop.
    function switchIndividualAirdropStatus() external onlyOwner isInitialized {
        airdropEnabled = !airdropEnabled ? true : false;
    }
    
    // enables top deposit feature.
    function switchTopDepositEventStatus() external onlyOwner isInitialized {
        drawTopDepositWinner(); // events will run before value change
        topDepositEnabled = !topDepositEnabled ? true : false;
        if(topDepositEnabled) topDepositLastDrawAction = block.timestamp; //reset the start time everytime feature is enabled.
    }
    
    // enables last deposit feature.
    function switchLastDepositEventStatus() external onlyOwner isInitialized {
        drawLastDepositWinner(); // events will run before value change
        lastDepositEnabled = !lastDepositEnabled ? true : false;
        if(lastDepositEnabled) lastDepositLastDrawAction = block.timestamp; // reset the start time everytime feature is enabled.
    }
    
    function updateNetworkLeader(address addr) external onlyOwner {
        require(!Address.isContract(addr), "Network Leader cannot be a contract address.");	
        networkLeader = addr; 
    }

    // function call to run the auto-compound feature
    function runAutoCompound(address addr) external onlyExecutor isInitialized {
        require(autoCompoundEnabled, "Auto Compound not Activated.");
        compound(addr); // checks should already be done before this point.
        emit AutoCompound(addr, block.timestamp);
    } 
    
    // run event triggers. 
    function runDrawEvents() external isInitialized { // run draw depending on condition.
        drawTopDepositWinner();
        drawLastDepositWinner();      
    }

    // check if events can now run.
    function checkDrawEvents() external view returns (bool runEvent) {
        if((topDepositEnabled && block.timestamp.sub(topDepositLastDrawAction) >= topDepositTimeStep) || (lastDepositEnabled && block.timestamp.sub(lastDepositLastDrawAction) >= lastDepositTimeStep && lastDepositPotentialWinner != address(0))) runEvent = true;
        return runEvent;
    }
    
    // enables the auto-compound feature.
    function enableAutoCompound(bool value) external onlyOwner {
        autoCompoundEnabled = value; // Make sure when enabling this feature, autoCompoundExecutorContract is already set.
    }
    
    // update the auto-compound contract.
    function updateAutoCompoundExecutorContract(address addr) external onlyOwner {
        require(Address.isContract(addr), "Contract Address Only."); // only contract address.	
        autoCompoundExecutorContract = addr; // The Auto Compound Contract.
    }
}