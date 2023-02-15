// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/token/ERC20/Token.sol";
import "openzeppelin/contracts/utils/math/SafeMath.sol";
import "openzeppelin/contracts/utils/Context.sol";
import "openzeppelin/contracts/utils/Address.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract ETRNL is Context, Ownable, Token {
    using SafeMath for uint256;

    uint256 private constant percentDivider = 1000;
    uint256 private constant standardDivider = 100;
    uint256 private constant maxPayoutETRNL = 2500;
    uint256 private constant timeStep = 1 days;
    uint256 private constant priceDivider = 1 ether;
    uint256 private constant initialTokenMint = 150000 ether;  

    uint256 private topDepositTimeStep = 2 days;
    uint256 private lastDepositTimeStep = 12 hours;

    bool private initialize;
    bool private topDepositEnabled;
    bool private lastDepositEnabled;

    uint256 private topDepositCurrentRound = 1;
    uint256 private topDepositPoolBalance;
    uint256 private topDepositCurrentAmount;
    address private topDepositPotentialWinner;
    uint256 private topDepositLastDrawAction;

    address private previousTopDepositWinner;
    uint256 private previousTopDepositRewards;

    uint256 private lastBuyCurrentRound = 1;
    uint256 private lastDepositPoolBalance = 500 ether; //last deposit reward will always start at 500 BUSD
    uint256 private lastDepositLastDrawAction;
    address private lastDepositPotentialWinner;

    address private previousPoolWinner;
    uint256 private previousPoolRewards;

    uint256 private ownerMintCheckpoint;

    struct Properties {
        uint256 refDepth;
        uint256 refBonus;
        
        // daily payouts
        uint256 busdTokenDailyPayout;
        uint256 eternalTokenDailyPayout;
        
        // limits
        uint256 tokenStakeFactor;
        uint256 sellCooldown;
        uint256 cutOffTimeStep;
        uint256 maxPayoutCap;
        uint256 maxRewards;
        uint256 minInvestAmount;
        uint256 maxInvestAmount;
        bool airdropEnabled;
        uint256 airdropMinAmount;
        
        // taxes
        uint256 BUSDTokenStakeTax;
        uint256 eternalTokenStakeTax;
        uint256 antiDumpRate;
        uint256 antiDumpTax;
        uint256 sellTax;
        uint256 eternalTokenClaimTax;
        uint256 BUSDTokenClaimTax;
        
        // whale tax
        uint256 depositBracketSize;
        uint256 depositBracketMax;
    }

    struct Stats {
        uint256 totalUsers;
        uint256 totalBUSDTokenStaked;
        uint256 totalEternalTokenStaked;
        uint256 totalCompounded;
        uint256 totalAirdropped;
        uint256 totalRefBonuses;
    }

    struct Stake {
        uint256 checkpoint;
        uint256 totalStaked;
        uint256 lastStakeTime;
        uint256 totalClaimedTokens;
        uint256 unClaimedTokens;
    }

    struct User {
        address referrer;
        uint256 totalStructure;
        uint256 referrals; 
        uint256 totalClaimed;
        uint256 lastSale;
        uint256 totalBonus;
        uint256 referralRoundRobinPosition;
        Stake stakeBUSD; 
        Stake stakeEternal;
    }

    struct Airdrop {
        uint256 totalAirdropsReceived;
        uint256 airdropsReceivedCount;
        uint256 lastAirdropReceived;
        uint256 totalAirdropsSent;
        uint256 airdropsSentCount;
        uint256 lastAirdropSent;
    }

    struct UserBonus {
        uint256 lastDepositBonus;
        uint256 topDepositBonus;
    }
    
    Stats public _stats;
    Airdrop public _airdrops;
    UserBonus public _userBonus;

    Properties private _properties;

    mapping(address => User) private _users;
    mapping(address => Airdrop) private airdrops;
    mapping(address => UserBonus) private usersBonus;

    event NewDeposit(address indexed addr, uint256 amount);
    event NewStake(address indexed addr, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event SellToken(address indexed addr, uint256 amountTokens, uint256 amountExchange);
    event ClaimToken(address indexed addr, uint256 amount, uint256 timestamp);
    event LastDepositPayout(uint256 indexed round, address indexed addr, uint256 amount, uint256 timestamp);
    event TopDepositPayout(uint256 indexed round, address indexed addr, uint256 amount, uint256 timestamp);
    
    constructor() {
        BUSDToken = IERC20(busd);

        _properties.refDepth                = 5;
        _properties.tokenStakeFactor        = 1;
        _properties.refBonus                = 25;
        _properties.busdTokenDailyPayout    = 10;
        _properties.eternalTokenDailyPayout = 20;
        _properties.depositBracketMax       = 10;
        _properties.eternalTokenStakeTax    = 50;
        _properties.eternalTokenClaimTax    = 100;
        _properties.BUSDTokenClaimTax       = 100;
        _properties.BUSDTokenStakeTax       = 100;
        _properties.antiDumpRate            = 250;
        _properties.antiDumpTax             = 500;
        _properties.sellTax                 = 200;

        _properties.sellCooldown            = 7 days;
        _properties.cutOffTimeStep          = 10 days;
        
        _properties.airdropMinAmount        = 1 ether;
        _properties.minInvestAmount         = 25 ether;
        _properties.maxInvestAmount         = 100000 ether;
        _properties.depositBracketSize      = 5000 ether;
        _properties.maxRewards              = 2000 ether;
        _properties.maxPayoutCap            = 100000 ether;

        _mint(msg.sender, initialTokenMint);
    }
    
    function initializeETRNL() external onlyOwner {
        require(!initialize, "Protocol already initialized.");

        initialize                          = true;
        lastDepositEnabled                  = true;
        topDepositEnabled                   = true;
        _properties.airdropEnabled          = true;

        lastDepositLastDrawAction           = block.timestamp;
        topDepositLastDrawAction            = block.timestamp;
        ownerMintCheckpoint                 = block.timestamp;
    }

    function poolLastDeposit(address userAddress, uint256 amount) private {
        if(!lastDepositEnabled) return;

        uint256 poolShare = amount.mul(5).div(percentDivider); //0.5% of each deposit will be put into the prize pool.

        lastDepositPoolBalance = lastDepositPoolBalance.add(poolShare) > _properties.maxRewards ? 
        lastDepositPoolBalance.add(_properties.maxRewards.sub(lastDepositPoolBalance)) : lastDepositPoolBalance.add(poolShare);
        lastDepositPotentialWinner = userAddress;
        lastDepositLastDrawAction  = block.timestamp;
    }  

    function drawLastDepositWinner() public {
        if(lastDepositEnabled && block.timestamp.sub(lastDepositLastDrawAction) >= lastDepositTimeStep && lastDepositPotentialWinner != address(0)) {
            
            if(BUSDToken.balanceOf(address(this)) < lastDepositPoolBalance) lastDepositPoolBalance = BUSDToken.balanceOf(address(this));

            BUSDToken.transfer(lastDepositPotentialWinner, lastDepositPoolBalance); 
            emit LastDepositPayout(lastBuyCurrentRound, lastDepositPotentialWinner, lastDepositPoolBalance, block.timestamp);
            
            usersBonus[lastDepositPotentialWinner].lastDepositBonus += lastDepositPoolBalance;
            previousPoolWinner         = lastDepositPotentialWinner;
            previousPoolRewards        = lastDepositPoolBalance;
            lastDepositPoolBalance     = 500 ether; //reset to the 500 BUSD base reward
            lastDepositPotentialWinner = address(0);
            lastDepositLastDrawAction  = block.timestamp; 
            lastBuyCurrentRound++;
        }
    }

    function poolTopDeposit(address userAddress, uint256 amount) private {
        if(!topDepositEnabled) return;

        if(amount > topDepositCurrentAmount) {
            topDepositCurrentAmount   = amount;
            topDepositPoolBalance     = topDepositCurrentAmount.mul(20).div(percentDivider); //2% of the deposited amount will be put into the pool.
            topDepositPotentialWinner = userAddress;
        }
    } 

    function drawTopDepositWinner() private {
        if(topDepositEnabled && block.timestamp.sub(topDepositLastDrawAction) >= topDepositTimeStep && topDepositPotentialWinner != address(0)) {
            
            if(BUSDToken.balanceOf(address(this)) < topDepositPoolBalance) topDepositPoolBalance = BUSDToken.balanceOf(address(this));

            BUSDToken.transfer(topDepositPotentialWinner, topDepositPoolBalance); 
            emit TopDepositPayout(topDepositCurrentRound, topDepositPotentialWinner, topDepositPoolBalance, block.timestamp);
            
            usersBonus[topDepositPotentialWinner].topDepositBonus += topDepositPoolBalance;
            previousTopDepositWinner  = topDepositPotentialWinner;
            previousTopDepositRewards = topDepositPoolBalance;
            topDepositPotentialWinner = address(0);
            topDepositCurrentAmount   = 0;
            topDepositPoolBalance     = 0;
            topDepositLastDrawAction  = block.timestamp;
            topDepositCurrentRound++;
        }
    }

    function deposit(address referrer, uint256 amount) public payable {
        User storage user = _users[msg.sender];    
        require(initialize, "Protocol not yet initialize.");
        require(amount >= _properties.minInvestAmount, "Deposit minimum not met.");
        require(user.stakeBUSD.totalStaked <= _properties.maxInvestAmount, "Max busd staked reached.");

        BUSDToken.transferFrom(msg.sender, address(this), amount);

        _processFee(amount);
        _setUpline(msg.sender, referrer);
        _refPayout(msg.sender, amount, _properties.refBonus);

        if (user.stakeBUSD.totalStaked == 0) {
            user.stakeBUSD.checkpoint = block.timestamp;	
            user.lastSale = block.timestamp; //set the initial last sale timestamp for 1st time deposits.	
            _stats.totalUsers++;	
        } else {
            updateStakeBUSD(msg.sender);	
        }
        _stakeBUSDToken(msg.sender, amount);
    }

    function _stakeBUSDToken(address addr, uint256 amount) internal {
        User storage user = _users[addr];
        
        user.stakeBUSD.lastStakeTime = block.timestamp;
        user.stakeBUSD.totalStaked += amount;
        _stats.totalBUSDTokenStaked += amount;

        emit NewDeposit(addr, amount);
        
        if(this.checkDrawEvents()) this.runDrawEvents();
        poolLastDeposit(addr, amount);    
        poolTopDeposit(addr, amount);
        
    }

    function maxStakeFor(address _addr) public view returns (uint256) {
        User storage user = _users[_addr];
        uint256 stake = user.stakeBUSD.totalStaked;
        return stake.mul(_properties.tokenStakeFactor);
    }

    function stakeEternalToken(uint256 amount) public {  
        User storage user = _users[msg.sender];
        require(initialize, "Protocol not yet initialized.");
        require(amount <= balanceOf(msg.sender), "Insufficient Balance.");

        uint256 stakeFee = amount.mul(_properties.eternalTokenStakeTax).div(percentDivider); //5% ETRNL stake tax
        uint256 adjustedAmount = amount.sub(stakeFee);
        require(user.stakeEternal.totalStaked.add(adjustedAmount) <= maxStakeFor(msg.sender), "Cannot exceed stake max");

        updateStakeEternal(msg.sender);
        // burn tokens to balance total supply.
        _burn(msg.sender, amount);
        _stakeEternalToken(msg.sender, adjustedAmount);
    }

    function _stakeEternalToken(address addr, uint256 amount) internal {
        User storage user = _users[addr];
        updateStakeEternal(msg.sender);
        user.stakeEternal.lastStakeTime = block.timestamp;
        user.stakeEternal.totalStaked += amount;
        _stats.totalEternalTokenStaked += amount;

        emit NewStake(addr, amount);
        
        if(this.checkDrawEvents()) this.runDrawEvents();
    }

    function compoundBUSD() external {
        _compoundBUSD(msg.sender);
    }

    function compoundEternal() external {
        _compoundEternal(msg.sender);
    }

    function _compoundBUSD(address addr) internal {
        uint256 amount = claimFromBUSD(addr, true);
        
        if(amount > 0) { //avoid reverts
            require(getContractBalance() > amount, "Insufficient balance");

            _refPayout(addr, amount, _properties.refBonus);
            _stakeEternalToken(addr, amount);
            _stats.totalCompounded += amount;
        }
        
        if(this.checkDrawEvents()) this.runDrawEvents();
    }

    function _compoundEternal(address addr) internal {
        uint256 claim = claimFromEternal(addr, true);
        
        if(claim > 0) {  //avoid reverts
            _stakeEternalToken(addr, claim);
            _stats.totalCompounded += claim;
        }
        
        if(this.checkDrawEvents()) this.runDrawEvents();
    }

    function sacrificeETRNL(uint256 amount) external {
        _burn(msg.sender, amount);
    }    

    function mintController() external onlyOwner {
        require(block.timestamp.sub(ownerMintCheckpoint) >= _properties.sellCooldown, "Can only mint once a week to control token price.");
        _mint(msg.sender, 10000 ether);
        ownerMintCheckpoint = block.timestamp;
    }  

    function _setUpline(address addr, address referrer) internal {
        User storage user = _users[addr];

        if (user.referrer == address(0) && addr != owner()) {
            
            if (_users[referrer].stakeBUSD.totalStaked == 0 || referrer == addr) {
                referrer = owner(); //owner is a multi-sig address.
            }

            user.referrer = referrer;
            address upline = user.referrer;
            _users[upline].referrals++;

            for (uint256 i = 0; i < _properties.refDepth; i++) {
                if (upline == address(0)) break;

                _users[upline].totalStructure++;

                upline = _users[upline].referrer;
            }
        }
    }

    function _refPayout(address addr, uint256 amount, uint256 refBonus) internal {
        User storage user = _users[addr];
        address upline = user.referrer;
        uint256 bonus = amount.mul(refBonus).div(percentDivider);

        for (uint256 i = 0; i < _properties.refDepth; i++) {
            // if we have reached the top of the chain
            if (upline == address(0)) {
                // the equivalent of looping through all available
                user.referralRoundRobinPosition = _properties.refDepth;
                break;
            }
            if (user.referralRoundRobinPosition == i) {
                // user can only get ref payout if they have deposited the min investment amount
                // AND total eternal token staked is not more than max minting token deposits
                if (_users[upline].stakeBUSD.totalStaked >= _properties.minInvestAmount && _users[upline].stakeEternal.totalStaked <= maxStakeFor(upline)) {
                    updateStakeBUSD(upline);
                    _users[upline].stakeBUSD.totalStaked += bonus;
                    _users[upline].totalBonus += bonus;
                    _stats.totalBUSDTokenStaked += bonus;
                    _stats.totalRefBonuses += bonus;

                    emit NewDeposit(upline, bonus);

                    if (_users[upline].referrer == address(0)) {
                        user.referralRoundRobinPosition = _properties.refDepth;
                    }

                    break; // no need to keep looping, we've already paid the referrer
                }

                user.referralRoundRobinPosition += 1;
            }

            upline = _users[upline].referrer;
        }

        user.referralRoundRobinPosition += 1;

        if (user.referralRoundRobinPosition >= _properties.refDepth) {
            user.referralRoundRobinPosition = 0;
        }
    }

    function getNextUpline(address _addr) public view returns (address nextUpline, bool minInvest, bool maxStake) {
        address upline = _users[_addr].referrer;

        for (uint8 i = 0; i < _properties.refDepth; i++) {
            if (upline == address(0)) {
                break;
            }
            if (_users[_addr].referralRoundRobinPosition == i) {
                minInvest = _users[upline].stakeBUSD.totalStaked >= _properties.minInvestAmount;
                maxStake = _users[upline].stakeEternal.totalStaked <= maxStakeFor(upline);
                return (upline, minInvest, maxStake);
            }

            upline = _users[upline].referrer;

        }
        return (address(0), false, false);
    }

    function _processFee(uint256 amount) internal {
        uint256 devTax = amount.mul(_properties.BUSDTokenStakeTax).div(percentDivider);
        BUSDToken.transfer(feeReceiver, devTax);
    }

    function updateStakeBUSD(address addr) private {
        User storage user = _users[addr];
        uint256 payout = getPayoutBUSD(addr);
        if (payout > 0) {
            user.stakeBUSD.unClaimedTokens += payout;
        }
        user.stakeBUSD.checkpoint = block.timestamp;
    }

    function getPayoutBUSD(address _addr) private view returns (uint256 value) {
        User storage user = _users[_addr];
        
        uint256 timeElapsed = block.timestamp.sub(user.stakeBUSD.checkpoint) > _properties.cutOffTimeStep ? _properties.cutOffTimeStep : block.timestamp.sub(user.stakeBUSD.checkpoint);
        value = (user.stakeBUSD.totalStaked.mul(_properties.busdTokenDailyPayout).div(percentDivider)).mul(timeElapsed).div(timeStep);
        
        return value;
    }

    function updateStakeEternal(address _addr) private {
        User storage user = _users[_addr];
        uint256 amount = getPayoutEternal(_addr);
        if (amount > 0) user.stakeEternal.unClaimedTokens += amount; //will only add if there's ETRNL Dividends
        user.stakeEternal.checkpoint = block.timestamp;
    }

    function getPayoutEternal(address _addr) private view returns (uint256 value) {
        User storage user = _users[_addr];
        
        uint256 timeElapsed = block.timestamp.sub(user.stakeEternal.checkpoint) > _properties.cutOffTimeStep ? _properties.cutOffTimeStep : block.timestamp.sub(user.stakeEternal.checkpoint);
        value = (user.stakeEternal.totalStaked.mul(_properties.eternalTokenDailyPayout).div(percentDivider)).mul(timeElapsed).div(timeStep);
        
        return value;
    }

    // 200% apr on token stake
    function maxPayoutFor(address addr) public view returns(uint256) {
        User storage user = _users[addr];
        uint256 amount = user.stakeEternal.totalStaked;
        return amount.mul(maxPayoutETRNL).div(percentDivider); 
    }

    function _payoutFor(address addr, uint256 amount, uint256 tax) internal view returns (uint256) {
        uint256 realizedAmount = payoutFor(addr, amount);
        uint256 claimFee = realizedAmount.mul(tax).div(percentDivider);
        return realizedAmount.sub(claimFee);
    }

    function payoutFor(address addr, uint256 amount) public view returns (uint256) {
        // apply whale tax
        uint256 tax = sustainabilityFee(addr, amount);
        uint256 fee = amount.mul(tax).div(standardDivider);
        return amount.sub(fee);
    }

    function sustainabilityFee(address addr, uint256 pendingDiv) public view returns (uint256) {
        User storage user = _users[addr];
        uint256 bracket = user.totalClaimed.add(pendingDiv).div(_properties.depositBracketSize);
        bracket = bracket > _properties.depositBracketMax ? _properties.depositBracketMax : bracket;
        return bracket.mul(5);
    }

    function claimFromBUSD(address addr, bool isCompound) internal returns (uint256) {
        User storage user = _users[addr];
        uint256 maxPayout = _properties.maxPayoutCap;
        require(user.totalClaimed < maxPayout, "Max payout reached.");

        updateStakeBUSD(addr);
        uint256 amount = user.stakeBUSD.unClaimedTokens;
        //if claim from compound set claim tax to 5%, else 10% tax.
        uint256 adjustedAmount = isCompound ? _payoutFor(addr, amount, _properties.eternalTokenStakeTax) : _payoutFor(addr, amount, _properties.BUSDTokenClaimTax);

        // payout remaining allowable divs if exceeds
        if(user.totalClaimed.add(adjustedAmount) > maxPayout) {
            adjustedAmount = maxPayout.sub(user.totalClaimed);
        }

        user.totalClaimed += amount;
        user.stakeBUSD.totalClaimedTokens += amount;
        user.stakeBUSD.unClaimedTokens = 0;

        return adjustedAmount;
    }

    function claimFromEternal(address addr, bool isCompound) internal returns (uint256) {
        User storage user = _users[addr];
        uint256 maxPayout = maxPayoutFor(addr);
        require(user.totalClaimed < _properties.maxPayoutCap, "Max payout reached.");
        require(user.stakeEternal.totalClaimedTokens < maxPayout, "Staking pool Max payout reached.");

        updateStakeEternal(msg.sender);
        uint256 amount = user.stakeEternal.unClaimedTokens;        
        //if claim from compound set claim tax to 5%, else 10% tax.
        uint256 adjustedAmount = isCompound ? _payoutFor(addr, amount, _properties.eternalTokenStakeTax) : _payoutFor(addr, amount, _properties.eternalTokenClaimTax);

        //payout remaining allowable divs if exceeds
        if(user.totalClaimed.add(adjustedAmount) > _properties.maxPayoutCap) {
            adjustedAmount = _properties.maxPayoutCap.sub(user.totalClaimed);
        } else if (user.stakeEternal.totalClaimedTokens.add(adjustedAmount) > maxPayout) {
            adjustedAmount = maxPayout.sub(user.stakeEternal.totalClaimedTokens);
        }

        user.totalClaimed += amount;
        user.stakeEternal.totalClaimedTokens += amount;
        user.stakeEternal.unClaimedTokens = 0;

        return adjustedAmount;
    }

    function claimFromBUSD() public {
        uint256 amount = claimFromBUSD(msg.sender, false);
        require(amount > 0, "No rewards to claim.");

        _mint(msg.sender, amount);
        emit ClaimToken(msg.sender, amount, block.timestamp);
    }

    function claimFromEternal() public {
        uint256 amount = claimFromEternal(msg.sender, false);
        require(amount > 0, "No rewards to claim.");

        _mint(msg.sender, amount);
        emit ClaimToken(msg.sender, amount, block.timestamp);
    }

    function claimAll() public {
        uint256 amountM = claimFromBUSD(msg.sender, false);
        uint256 amountT = claimFromEternal(msg.sender, false);
        uint256 total = amountM.add(amountT);

        require(total > 0, "No rewards to claim.");

        _mint(msg.sender, total);
        emit ClaimToken(msg.sender, total, block.timestamp);
    }
	
	function compoundAll() public {
        _compoundBUSD(msg.sender);	
        _compoundEternal(msg.sender);	
    }
    
    function sellToken(uint256 amount) public {
        amount = amount > balanceOf(msg.sender) ? balanceOf(msg.sender) : amount;
        require(amount > 0 ,"User does not have any token to sell.");
        require(exceedsCooldown(msg.sender), "Sell cooldown in effect.");

        uint256 sellFee = _sellTaxAmount(msg.sender, amount);
        uint256 realizedAmount = amount.sub(sellFee);
        uint256 exchangeAmount = tokenToBUSDToken(realizedAmount);

        require(getContractBalance() > exchangeAmount);

        _burn(msg.sender, amount); //burn sold tokens.
        _users[msg.sender].lastSale = block.timestamp;
        BUSDToken.transfer(msg.sender, exchangeAmount);

        emit SellToken(msg.sender, realizedAmount, exchangeAmount);
		if(this.checkDrawEvents()) this.runDrawEvents();
    }

    function _sellTaxAmount(address from, uint256 amount) internal view returns (uint256) {
        User storage user = _users[from];
        uint256 taxes = amount.mul(_properties.sellTax).div(percentDivider);
        
        if(amount > user.stakeEternal.totalStaked.mul(_properties.antiDumpRate).div(percentDivider)) {
            uint256 tax = amount.mul(_properties.antiDumpTax).div(percentDivider);
            taxes.add(tax);
        }

        return taxes;
    }

    function exceedsCooldown(address addr) public view returns (bool) {
        User storage user = _users[addr];
        return block.timestamp.sub(user.lastSale) >= _properties.sellCooldown;
    }

    function airdrop(address receiver, uint256 amount) external {
        require(_properties.airdropEnabled, "Airdrop is disabled.");
        require(msg.sender != receiver);
        require(amount >= _properties.airdropMinAmount);

        address sender = msg.sender;
        User storage recipient = _users[receiver];
        //Make sure _to exists in the system
        require(recipient.referrer != address(0), "Airdrop recipient not found.");

        uint256 tax = amount.mul(_properties.eternalTokenStakeTax).div(percentDivider); //5% ETRNL stake tax
        uint256 realizedAmount = amount.sub(tax);
        require(recipient.stakeEternal.totalStaked.add(realizedAmount) <= maxStakeFor(receiver), "Max Stake reached.");
        updateStakeEternal(receiver);
        
        //burn because unclaimed tokens are minted when they are claimed
        _burn(msg.sender, amount);

        //Fund to token stake (with tax applied)
        recipient.stakeEternal.totalStaked += realizedAmount;
        _stats.totalEternalTokenStaked = _stats.totalEternalTokenStaked.add(realizedAmount);
        _stats.totalAirdropped += amount;

        //recipient statistics
        airdrops[receiver].totalAirdropsReceived += realizedAmount;
        airdrops[receiver].airdropsReceivedCount++;
        airdrops[receiver].lastAirdropReceived = block.timestamp;

        //sender statistics
        airdrops[sender].totalAirdropsSent += amount;
        airdrops[sender].airdropsSentCount++;
        airdrops[sender].lastAirdropSent = block.timestamp;

        emit NewStake(receiver, amount);
        emit NewAirdrop(sender, receiver, amount, block.timestamp);
		if(this.checkDrawEvents()) this.runDrawEvents();
    }

    function getUserUnclaimedTokensInfo(address addr) 
        public 
        view 
        returns (
            uint256 busd, 
            uint256 eternal
        ) 
    {
        User storage user = _users[addr];
        return 
        (
            getPayoutBUSD(addr).add(user.stakeBUSD.unClaimedTokens),
            getPayoutEternal(addr).add(user.stakeEternal.unClaimedTokens)
        );
    }

    function getAPY() public view returns (uint256 apym, uint256 apyt) {
        return 
        (
            _properties.busdTokenDailyPayout.mul(365).div(10),
            _properties.eternalTokenDailyPayout.mul(365).div(10)
        );
    }

    function getUserStakeInfo(address addr)
        public
        view
        returns (
            uint256 totalStaked,
            uint256 checkpoint,
            uint256 lastStakeTime,
            uint256 unClaimedTokens,

            uint256 totalStakedEternal,
            uint256 checkpointEternal,
            uint256 lastStakeTimeEternal,
            uint256 totalClaimedTokensEternal,
            uint256 unClaimedTokensEternal
        )
    {
        User storage user = _users[addr];
        totalStaked = user.stakeBUSD.totalStaked;
        checkpoint = user.stakeBUSD.checkpoint;
        lastStakeTime = user.stakeBUSD.lastStakeTime;
        unClaimedTokens = user.stakeBUSD.unClaimedTokens;

        totalStakedEternal = user.stakeEternal.totalStaked;
        checkpointEternal = user.stakeEternal.checkpoint;
        lastStakeTimeEternal = user.stakeEternal.lastStakeTime;
        totalClaimedTokensEternal = user.stakeEternal.totalClaimedTokens;
        unClaimedTokensEternal = user.stakeEternal.unClaimedTokens;
    }

    function getUserInfo(address addr)
        external
        view
        returns (
            address referrer,
            uint256 totalStructure,
            uint256 referrals,
            uint256 totalClaimed,
            uint256 totalBonus,
            uint256 referralRoundRobinPosition,
            uint256 lastSale
        )
    {
        User storage user = _users[addr];
        return (
            user.referrer,
            user.totalStructure,
            user.referrals,
            user.totalClaimed,
            user.totalBonus,
            user.referralRoundRobinPosition,
            user.lastSale
        );
    }

    function getUserAirdropDetails(address addr)
        external
        view
        returns (
            uint256 totalAirdropsReceived,
            uint256 airdropsReceivedCount,
            uint256 lastAirdropReceived,
            uint256 totalAirdropsSent,
            uint256 airdropsSentCount,
            uint256 lastAirdropSent
        )
    {
        Airdrop storage air = airdrops[addr];
        return (
            air.totalAirdropsReceived,
            air.airdropsReceivedCount,
            air.lastAirdropReceived,
            air.totalAirdropsSent,
            air.airdropsSentCount,
            air.lastAirdropSent
        );
    }
    
    function getContractPayouts() 
        external 
        view 
        returns 
        (   
            uint256 busdTokenDailyPayout,
            uint256 eternalTokenDailyPayout
        ) 
    {
        return (
        _properties.busdTokenDailyPayout,
        _properties.eternalTokenDailyPayout);
    }

    function getContractLimits() 
        external 
        view 
        returns 
        (   
            uint256 tokenStakeFactor,
            uint256 sellCooldown,
            uint256 cutOffTimeStep,
            uint256 maxPayoutCap,
            uint256 maxRewards,
            uint256 minInvestAmount,
            uint256 maxInvestAmount,
            bool airdropEnabled,
            uint256 airdropMinAmount
        ) 
    {
        return (
        _properties.tokenStakeFactor,
        _properties.sellCooldown,
        _properties.cutOffTimeStep,
        _properties.maxPayoutCap,
        _properties.maxRewards,
        _properties.minInvestAmount,
        _properties.maxInvestAmount,
        _properties.airdropEnabled,
        _properties.airdropMinAmount);
    }

    function getContractTaxes() 
        external 
        view 
        returns 
        (   
            uint256 BUSDTokenStakeTax,
            uint256 eternalTokenStakeTax,
            uint256 antiDumpRate,
            uint256 antiDumpTax,
            uint256 sellTax,
            uint256 eternalTokenClaimTax,
            uint256 BUSDTokenClaimTax
        ) 
    {
        return (
        _properties.BUSDTokenStakeTax,
        _properties.eternalTokenStakeTax,
        _properties.antiDumpRate,
        _properties.antiDumpTax,
        _properties.sellTax,
        _properties.eternalTokenClaimTax,
        _properties.BUSDTokenClaimTax);
    }

    function getWhaleTax() 
        external 
        view 
        returns 
        (   
            uint256 depositBracketMax,
            uint256 depositBracketSize
        ) 
    {
        return (
        _properties.depositBracketMax,
        _properties.depositBracketSize);
    }
    
    function lastDepositInfo() 
        view 
        external 
        returns(
            bool isLastDepositEnabled, 
            uint256 currentRound, 
            uint256 currentBalance, 
            uint256 currentStartTime, 
            uint256 currentStep, 
            address currentPotentialWinner, 
            uint256 previousReward, 
            address previousWinner
        ) 
    {
        isLastDepositEnabled   = lastDepositEnabled;
        currentRound           = lastBuyCurrentRound;
        currentBalance         = lastDepositPoolBalance;
        currentStartTime       = lastDepositLastDrawAction;  
        currentStep            = lastDepositTimeStep;    
        currentPotentialWinner = lastDepositPotentialWinner;
        previousReward         = previousPoolRewards;
        previousWinner         = previousPoolWinner;
    }

    function topDepositInfo() 
        view 
        external 
        returns(
            bool isTopDepositEnabled, 
            uint256 topDepositRound, 
            uint256 topDepositCurrentTopDeposit, 
            address topDepositCurrentPotentialWinner, 
            uint256 topDepositCurrentBalance, 
            uint256 topDepositCurrentStartTime, 
            uint256 topDepositCurrentStep, 
            uint256 topDepositPreviousReward, 
            address topDepositPreviousWinner
        ) 
    {
        isTopDepositEnabled              = topDepositEnabled;
        topDepositRound                  = topDepositCurrentRound;
        topDepositCurrentTopDeposit      = topDepositCurrentAmount;
        topDepositCurrentPotentialWinner = topDepositPotentialWinner;
        topDepositCurrentBalance         = topDepositPoolBalance;
        topDepositCurrentStartTime       = topDepositLastDrawAction;
        topDepositCurrentStep            = topDepositTimeStep;
        topDepositPreviousReward         = previousTopDepositRewards;
        topDepositPreviousWinner         = previousTopDepositWinner;
    }

    function getUserTokenBalanceInfo(address addr) 
        public 
        view 
        returns (
            uint256 busd, 
            uint256 eternal
        ) 
    {
        return (
            BUSDToken.balanceOf(addr),
            balanceOf(addr)
        );
    }

    function getContractBalance() 
        public 
        view 
        returns (
            uint256
        ) 
    {
        return BUSDToken.balanceOf(address(this));
    }

    function getEternalTokenPrice() 
        public 
        view 
        returns (
            uint256
        ) 
    {
        uint256 balance = getContractBalance().mul(priceDivider);
        uint256 totalSupply = totalSupply().add(1);
        return balance.div(totalSupply);
    }

    function BUSDTokenToToken(uint256 BUSDTokenAmount) 
        public 
        view 
        returns (
            uint256
        ) 
    {
        return BUSDTokenAmount.mul(priceDivider).div(getEternalTokenPrice());
    }

    function tokenToBUSDToken(uint256 tokenAmount) 
        public 
        view 
        returns (
            uint256
        ) 
    {
        return tokenAmount.mul(getEternalTokenPrice()).div(priceDivider);
    }
    
    function checkDrawEvents() 	
        external 	
        view 	
        returns (	
            bool runEvent	
        ) 	
    {	
        if((topDepositEnabled && block.timestamp.sub(topDepositLastDrawAction) >= topDepositTimeStep && topDepositPotentialWinner != address(0)) 	
        || (lastDepositEnabled && block.timestamp.sub(lastDepositLastDrawAction) >= lastDepositTimeStep && lastDepositPotentialWinner != address(0)))	
        runEvent = true;	
        return runEvent;	
    }
    
    function runDrawEvents() external {
        drawTopDepositWinner();
        drawLastDepositWinner();      
    }

    //owner only functions
    function changeAccumulationTimeStep(uint256 accumulationTime) external onlyOwner {
        require(accumulationTime >= 1 days && accumulationTime <= 15 days, "Accumulation time step can only changed to 1 day up to 7 days."); 
        _properties.cutOffTimeStep = accumulationTime;
    }

    function changeLastDepositEventTimeStep(uint256 lastDepoStep) external onlyOwner {
        require(lastDepoStep >= 1 hours && lastDepoStep <= 1 days, "Time step can only changed to 1 hour up to 24 hours.");
        drawLastDepositWinner();   
        lastDepositTimeStep = lastDepoStep;
    }

    function changeSellCooldownTimeStep(uint256 sellCooldownStep) external onlyOwner {
        //change to days in mainnet
        require(sellCooldownStep >= 1 days && sellCooldownStep <= 15 days, "Time step can only changed to 1 day up to 15 days.");
        _properties.sellCooldown = sellCooldownStep;
    }

    //only change this value when the previous round is concluded!
    function changeLastDepositInitialBalance(uint256 balance) external onlyOwner {
        require(balance >= 50 ether && balance <= 1000 ether, "Initial balance should be greater than or equal to 50 BUSD and less than or equal 1,000 BUSD");
        lastDepositPoolBalance = balance;
    }

    function changeTopDepositEventTime(uint256 topDepoStep) external onlyOwner {
        require(topDepoStep >= 1 days && topDepoStep <= 7 days, "Time step can only changed to 1 day up to 7 days.");
        drawTopDepositWinner();   
        topDepositTimeStep = topDepoStep;
    }
    
    function switchNetworkAirdropStatus() external onlyOwner {
        _properties.airdropEnabled  = !_properties.airdropEnabled ? true : false;
    }
    
    function switchTopDepositEventStatus() external onlyOwner {
        drawTopDepositWinner();
        topDepositEnabled = !topDepositEnabled ? true : false;
        if(topDepositEnabled) topDepositLastDrawAction = block.timestamp;
    }
    
    function switchLastDepositEventStatus() external onlyOwner {
        drawLastDepositWinner();
        lastDepositEnabled = !lastDepositEnabled ? true : false;
        if(lastDepositEnabled) lastDepositLastDrawAction = block.timestamp;
    }
}