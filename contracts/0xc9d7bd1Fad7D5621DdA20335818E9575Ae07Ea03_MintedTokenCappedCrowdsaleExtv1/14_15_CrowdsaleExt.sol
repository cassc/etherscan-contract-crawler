// SPDX-License-Identifier: MIT


/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

pragma solidity 0.7.6;

import "./SafeMathLibExt.sol";
import "./Haltable.sol";
import "./PricingStrategy.sol";
import "./FinalizeAgent.sol";
import "./FractionalERC20Ext.sol";
import "./TokenVesting.sol";
import "./Allocatable.sol";


/**
 * Abstract base contract for token sales.
 *
 * Handle
 * - start and end dates
 * - accepting investments
 * - minimum funding goal and refund
 * - various statistics during the crowdfund
 * - different pricing strategies
 * - different investment policies (require server side customer id, allow only whitelisted addresses)
 *
 */
abstract contract CrowdsaleExt is Allocatable, Haltable {

    /* Max investment count when we are still allowed to change the multisig address */
    uint public constant MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

    using SafeMathLibExt for uint256;
    using SafeMathLibExt for uint8;

    /* The token we are selling */
    FractionalERC20Ext public token;

    /* How we are going to price our offering */
    PricingStrategy public pricingStrategy;

    /* Post-success callback */
    FinalizeAgent public finalizeAgent;

    TokenVesting public tokenVesting;

    /* name of the crowdsale tier */
    string public name;

    /* tokens will be transfered from this address */
    address public multisigWallet;

    /* if the funding goal is not reached, investors may withdraw their funds */
    uint256 public minimumFundingGoal;

    /* current withdrawn, amount already withdrawn for the contract to multisig */
    uint256 public currentRaisedFundWithdrawn;

    /* the UNIX timestamp start date of the crowdsale */
    uint256 public startsAt;

    /* the UNIX timestamp end date of the crowdsale */
    uint256 public endsAt;

    /* the number of tokens already sold through this contract*/
    uint256 public tokensSold = 0;

    /* How many wei of funding we have raised */
    uint256 public weiRaised = 0;

    /* How many distinct addresses have invested */
    uint256 public investorCount = 0;

    /* Has this crowdsale been finalized */
    bool public finalized;

    bool public isWhiteListed;

      /* Token Vesting Contract */
    address public tokenVestingAddress;

    address[] public joinedCrowdsales;
    uint8 public joinedCrowdsalesLen = 0;
    uint8 public constant joinedCrowdsalesLenMax = 50;

    struct JoinedCrowdsaleStatus {
        bool isJoined;
        uint8 position;
    }

    mapping (address => JoinedCrowdsaleStatus) public joinedCrowdsaleState;

    /** How much ETH each address has invested to this crowdsale */
    mapping (address => uint256) public investedAmountOf;

    /** How much tokens this crowdsale has credited for each investor address */
    mapping (address => uint256) public tokenAmountOf;

    struct WhiteListData {
        bool status;
        uint256 minCap;
        uint256 maxCap;
    }

    //is crowdsale updatable
    bool public isUpdatable;

    /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
    mapping (address => WhiteListData) public earlyParticipantWhitelist;

    /** List of whitelisted addresses */
    address[] public whitelistedParticipants;

    /** This is for manul testing for the interaction from owner wallet. 
    You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
    uint256 public ownerTestValue;

    /** State machine
    *
    * - Preparing: All contract initialization calls and variables have not been set yet
    * - Prefunding: We have not passed start time yet
    * - Funding: Active crowdsale
    * - Success: Minimum funding goal reached
    * - Failure: Minimum funding goal not reached before ending time
    * - Finalized: The finalized has been called and succesfully executed
    */
    enum State { Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized }

    // A new investment was made
    event Invested(address investor, uint256 weiAmount, uint256 tokenAmount, uint128 customerId);

    // Address early participation whitelist status changed
    event Whitelisted(address addr, bool status, uint256 minCap, uint256 maxCap);
    event WhitelistItemChanged(address addr, bool status, uint256 minCap, uint256 maxCap);

    // Crowdsale start time has been changed
    event StartsAtChanged(uint256 newStartsAt);

    // Crowdsale end time has been changed
    event EndsAtChanged(uint256 newEndsAt);

    // Fund Withdrawn for contract to the Multisig Wallet
    event FundWithdrawnToMultiSigWallet(uint256 amount, uint256 time);

    constructor(
        string memory _name, 
        address _token, 
        PricingStrategy _pricingStrategy, 
        address _multisigWallet, 
        uint256 _start, 
        uint256 _end, 
        uint256 _minimumFundingGoal, 
        bool _isUpdatable, 
        bool _isWhiteListed, 
        address _tokenVestingAddress
    ) {

        require(_multisigWallet != address(0), "Multisig Wallet set to Null Address");
        require(_token != address(0), "Token set to Null Address");
        require(_tokenVestingAddress != address(0), "Token Vesting Address set to Null Address");

        owner = msg.sender;

        name = _name;

        tokenVestingAddress = _tokenVestingAddress;

        token = FractionalERC20Ext(_token);

        setPricingStrategy(_pricingStrategy);

        multisigWallet = _multisigWallet;
        // if (multisigWallet == 0) {
        //     revert();
        // }

        if (_start == 0) {
            revert("Start Cannot be zero");
        }

        startsAt = _start;

        if (_end == 0) {
            revert("End Cannot be zero");
        }

        endsAt = _end;

        // Don't mess the dates
        if (startsAt >= endsAt) {
            revert("Start should be greater or equal to end time");
        }

        // Minimum funding goal can be zero
        minimumFundingGoal = _minimumFundingGoal;

        isUpdatable = _isUpdatable;

        isWhiteListed = _isWhiteListed;
    }

    /**
    * Don't expect to just send in money and get tokens.
    */
    // function() external payable {
    //     buy();
    // }
    receive() external payable {
        buy();
    }

    /**
    * The basic entry point to participate the crowdsale process.
    *
    * Pay for funding, get invested tokens back in the sender address.
    */
    function buy() public payable {
        invest(msg.sender);
    }

    /**
    * Allow anonymous contributions to this crowdsale.
    */
    function invest(address addr) public payable {
        investInternal(addr, 0);
    }

    /**
    * Make an investment.
    *
    * Crowdsale must be running for one to invest.
    * We must have not pressed the emergency brake.
    *
    * @param receiver The Ethereum address who receives the tokens
    * @param customerId (optional) UUID v4 to track the successful payments on the server side
    *
    */
    function investInternal(address receiver, uint128 customerId) private stopInEmergency {

        // Determine if it's a good time to accept investment from this participant
        if (getState() == State.PreFunding) {
            // Are we whitelisted for early deposit
            revert("Prefund State Error");
        } else if (getState() == State.Funding) {
            // Retail participants can only come in when the crowdsale is running
            // pass
            if (isWhiteListed) {
                if (!earlyParticipantWhitelist[receiver].status) {
                    revert("Participant not whitelist");
                }
            }
        } else {
            // Unwanted state
            revert("Invalid state");
        }

        uint256 weiAmount = msg.value;

        // Account presale sales separately, so that they do not count against pricing tranches
        uint256 tokenAmount = pricingStrategy.calculatePrice(weiAmount, tokensSold, token.decimals());

        if (tokenAmount == 0) {
          // Dust transaction
            revert("Zero Token Amount");
        }

        if (isWhiteListed) {
            if (weiAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
              // weiAmount < minCap for investor
                revert("MinCap not meet");
            }

            // Check that we did not bust the investor's cap
            if (isBreakingInvestorCap(receiver, weiAmount)) {
                revert("Breaking Investor Cap");
            }

            updateInheritedEarlyParticipantWhitelist(receiver, weiAmount);
        } else {
            if (weiAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
                revert("Less than Minimum Cap and Receiver Amount 0");
            }
        }

        if (investedAmountOf[receiver] == 0) {
          // A new investor
            investorCount.plus(1);
        }

        // Update investor
        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

        // Update totals
        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        // Check that we did not bust the cap
        if (isBreakingCap(tokensSold)) {
            revert("Breaking Cap");
        }

        assignTokens(receiver, tokenAmount);

        // Send the token if wei raised is greater than the minimum funding goal
        if(weiRaised >= minimumFundingGoal){
            if(currentRaisedFundWithdrawn == 0){
                //update the current raised fund withdraw amount
                currentRaisedFundWithdrawn = weiRaised;
                withdrawContractFund(weiRaised);
            }else{
                //update the current raised fund withdraw amount
                currentRaisedFundWithdrawn += weiAmount;
                withdrawContractFund(weiAmount);
            }
        }

        // Tell us invest was success
        emit Invested(receiver, weiAmount, tokenAmount, customerId);
    }

    /** 
    * Withdraw investment If minimum funding goal is reached
    * 
    * Crowdsale should get more than minimum fuding for eth released by the contract
    * to the multisig wallet 
    *
    * Owner can call this function
    * 
    */
    function withdrawContractFund(uint256 withdrawAmount) internal {
        //check if multi sig wallet is not contract address
        // bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        // bytes32 codehash;
        uint32 size;

        address walletAddress = multisigWallet;

        assembly {
            size := extcodesize(walletAddress)
            // codehash := extcodehash(walletAddress)
        }
        require(size == 0, "Multi Sig Wallet not contract address");
        // require(size == 0 && (codehash == 0x0 || codehash == accountHash), "Multi Sig Wallet not contract address");
                
        // Pocket the money
        (bool success, ) = payable(multisigWallet).call{value: withdrawAmount}("");
        require(success, "Transfer failed to Multisig Wallet");
        // if (!multisigWallet.send(weiAmount)) revert();

        emit FundWithdrawnToMultiSigWallet(withdrawAmount, block.timestamp);
    }



    /**
    * allocate tokens for the early investors.
    *
    * Preallocated tokens have been sold before the actual crowdsale opens.
    * This function mints the tokens and moves the crowdsale needle.
    *
    * Investor count is not handled; it is assumed this goes for multiple investors
    * and the token distribution happens outside the smart contract flow.
    *
    * No money is exchanged, as the crowdsale team already have received the payment.
    *
    * param weiPrice Price of a single full token in wei
    *
    */
    function allocate(address receiver, uint256 tokenAmount, uint128 customerId, uint256 lockedTokenAmount) external onlyAllocateAgent {
        require(receiver != address(0), "Receiver Address set to 0 address");
      // cannot lock more than total tokens
        require(lockedTokenAmount <= tokenAmount, "Locked token amount must be equal or smaller than token amount");
        uint256 weiPrice = pricingStrategy.oneTokenInWei(tokensSold, token.decimals());
        // This can be also 0, we give out tokens for free
        uint256 weiAmount = (weiPrice.times(tokenAmount))/10**uint256(token.decimals());         

        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

        // assign locked token to Vesting contract
        if (lockedTokenAmount > 0) {
            tokenVesting = TokenVesting(tokenVestingAddress);
            // to prevent minting of tokens which will be useless as vesting amount cannot be updated
            require(!tokenVesting.isVestingSet(receiver), "Token Vesting Amount Already Set");
            assignTokens(tokenVestingAddress, lockedTokenAmount);
            // set vesting with default schedule
            tokenVesting.setVestingWithDefaultSchedule(receiver, lockedTokenAmount); 
        }

        // assign remaining tokens to contributor
        if (tokenAmount - lockedTokenAmount > 0) {
            assignTokens(receiver, tokenAmount - lockedTokenAmount);
        }

        // Tell us invest was success
        emit Invested(receiver, weiAmount, tokenAmount, customerId);
    }

    //
    // Modifiers
    //
    /** Modified allowing execution only if the crowdsale is currently running.  */

    modifier inState(State state) {
        if (getState() != state) 
            revert("Crowd Sale is not Running");
        _;
    }

    function distributeReservedTokens(uint256 reservedTokensDistributionBatch) 
    external inState(State.Success) onlyOwner stopInEmergency {
      // Already finalized
        if (finalized) {
            revert("Already Finalized");
        }

        // Finalizing is optional. We only call it if we are given a finalizing agent.
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.distributeReservedTokens(reservedTokensDistributionBatch);
        }
    }

    function areReservedTokensDistributed() public view returns (bool) {
        return finalizeAgent.reservedTokensAreDistributed();
    }

    function canDistributeReservedTokens() external view returns(bool) {
        CrowdsaleExt lastTierCntrct = CrowdsaleExt(payable(getLastTier()));
        if ((lastTierCntrct.getState() == State.Success) &&
        !lastTierCntrct.halted() && !lastTierCntrct.finalized() && !lastTierCntrct.areReservedTokensDistributed())
            return true;
        return false;
    }

    /**
    * Finalize a succcesful crowdsale.
    *
    * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
    */
    function finalize() external inState(State.Success) onlyOwner stopInEmergency {

      // Already finalized
        if (finalized) {
            revert("Already Finalized");
        }

      // Finalizing is optional. We only call it if we are given a finalizing agent.
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.finalizeCrowdsale();
        }

        finalized = true;
    }

    /**
    * Allow to (re)set finalize agent.
    *
    * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
    */
    function setFinalizeAgent(FinalizeAgent addr) external onlyOwner {
        assert(address(addr) != address(0));
        assert(address(finalizeAgent) == address(0));
        finalizeAgent = addr;

        // Don't allow setting bad agent
        if (!finalizeAgent.isFinalizeAgent()) {
            revert("Agent Already Finalized");
        }
    }

    /**
    * Allow addresses to do early participation.
    */
    function setEarlyParticipantWhitelist(address addr, bool status, uint256 minCap, uint256 maxCap) public onlyOwner {
        if (!isWhiteListed) revert("Already Whitelisted");
        assert(addr != address(0));
        assert(maxCap > 0);
        assert(minCap <= maxCap);
        assert(block.timestamp <= endsAt);

        if (!isAddressWhitelisted(addr)) {
            whitelistedParticipants.push(addr);
            emit Whitelisted(addr, status, minCap, maxCap);
        } else {
            emit WhitelistItemChanged(addr, status, minCap, maxCap);
        }

        earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
    }

    function setEarlyParticipantWhitelistMultiple(address[] memory addrs, bool[] memory statuses, uint256[] memory minCaps, uint256[] memory maxCaps) 
    external onlyOwner {
        if (!isWhiteListed) revert("Already Whitelisted");
        assert(block.timestamp <= endsAt);
        assert(addrs.length == statuses.length);
        assert(statuses.length == minCaps.length);
        assert(minCaps.length == maxCaps.length);
        for (uint256 iterator = 0; iterator < addrs.length; iterator++) {
            setEarlyParticipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
        }
    }

    function decreaseEarlyParticipantWhitelistMaxCap(address addr, uint256 weiAmount) public {
        if (!isWhiteListed) revert("Already Whitelisted");
        assert(addr != address(0));
        assert(block.timestamp <= endsAt);
        assert(isTierJoined(msg.sender));
        if (weiAmount < earlyParticipantWhitelist[addr].minCap && tokenAmountOf[addr] == 0) revert("Cannot update Early Paricipant Whitelist");
        //if (addr != msg.sender && contractAddr != msg.sender) throw;
        uint256 newMaxCap = earlyParticipantWhitelist[addr].maxCap;
        newMaxCap = newMaxCap.minus(weiAmount);
        earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
    }

    function updateInheritedEarlyParticipantWhitelist(address reciever, uint256 weiAmount) private {
        if (!isWhiteListed) revert("Not Whitelisted");
        if (weiAmount < earlyParticipantWhitelist[reciever].minCap && tokenAmountOf[reciever] == 0) revert("Cannot update Early Paricipant Whitelist");

        uint8 tierPosition = getTierPosition(address(this));

        for (uint8 j = tierPosition+1; j < joinedCrowdsalesLen; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(payable(joinedCrowdsales[j]));
            crowdsale.decreaseEarlyParticipantWhitelistMaxCap(reciever, weiAmount);
        }
    }

    function isAddressWhitelisted(address addr) public view returns(bool) {
        for (uint256 i = 0; i < whitelistedParticipants.length; i++) {
            if (whitelistedParticipants[i] == addr) {
                return true;
                break;
            }
        }

        return false;
    }

    function whitelistedParticipantsLength() external view returns (uint256) {
        return whitelistedParticipants.length;
    }

    function isTierJoined(address addr) public view returns(bool) {
        return joinedCrowdsaleState[addr].isJoined;
    }

    function getTierPosition(address addr) public view returns(uint8) {
        return joinedCrowdsaleState[addr].position;
    }

    function getLastTier() public view returns(address) {
        if (joinedCrowdsalesLen > 0){
            return joinedCrowdsales[joinedCrowdsalesLen.minus(1)];
        }
        else
            return address(0);
    }

    function setJoinedCrowdsales(address addr) private onlyOwner {
        assert(addr != address(0));
        assert(joinedCrowdsalesLen <= joinedCrowdsalesLenMax);
        assert(!isTierJoined(addr));
        joinedCrowdsales.push(addr);
        joinedCrowdsaleState[addr] = JoinedCrowdsaleStatus({
            isJoined: true,
            position: joinedCrowdsalesLen
        });
        joinedCrowdsalesLen.plus(1);
    }

    function updateJoinedCrowdsalesMultiple(address[] memory addrs) external onlyOwner {
        assert(addrs.length > 0);
        assert(joinedCrowdsalesLen == 0);
        assert(addrs.length <= joinedCrowdsalesLenMax);
        for (uint8 iter = 0; iter < addrs.length; iter++) {
            setJoinedCrowdsales(addrs[iter]);
        }
    }

    function setStartsAt(uint256 time) external onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(block.timestamp <= time); // Don't change past
        assert(time <= endsAt);
        assert(block.timestamp <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(payable(getLastTier()));
        if (lastTierCntrct.finalized()) revert("Last Tier Contract Finalized");

        uint8 tierPosition = getTierPosition(address(this));

        //start time should be greater then end time of previous tiers
        for (uint8 j = 0; j < tierPosition; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(payable(joinedCrowdsales[j]));
            assert(time >= crowdsale.endsAt());
        }

        startsAt = time;
        emit StartsAtChanged(startsAt);
    }

    /**
    * Allow crowdsale owner to close early or extend the crowdsale.
    *
    * This is useful e.g. for a manual soft cap implementation:
    * - after X amount is reached determine manual closing
    *
    * This may put the crowdsale to an invalid state,
    * but we trust owners know what they are doing.
    *
    */
    function setEndsAt(uint256 time) external onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(block.timestamp <= time);// Don't change past
        assert(startsAt <= time);
        assert(block.timestamp <= endsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(payable(getLastTier()));
        if (lastTierCntrct.finalized()) revert("Last Tier Contract Finalized");


        uint8 tierPosition = getTierPosition(address(this));

        for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(payable(joinedCrowdsales[j]));
            assert(time <= crowdsale.startsAt());
        }

        endsAt = time;
        emit EndsAtChanged(endsAt);
    }

    /**
    * Allow to (re)set pricing strategy.
    *
    * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
    */
    function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
        assert(address(_pricingStrategy) != address(0));
        pricingStrategy = _pricingStrategy;

        // Don't allow setting bad agent
        if (!pricingStrategy.isPricingStrategy()) {
            revert("Cannot Set Bad Pricing Strategy");
        }
    }

    /**
    * Allow to (re)set Token.
    * @param _token upgraded token address
    */
    function setCrowdsaleTokenExtv1(address _token) external onlyOwner {
        assert(_token != address(0));
        token = FractionalERC20Ext(_token);
        
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.setCrowdsaleTokenExtv1(_token);
        }
    }

    /**
    * Allow to change the team multisig address in the case of emergency.
    *
    * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
    * (we have done only few test transactions). After the crowdsale is going
    * then multisig address stays locked for the safety reasons.
    */
    function setMultisig(address addr) external onlyOwner {
        require(addr != address(0), "Multi Sig Wallet Cannot be Null Address");
      // Change
        if (investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
            revert("Investor count greater than Max nvestments");
        }

        multisigWallet = addr;
    }

    /**
    * Return true if the crowdsale has raised enough money to be a successful.
    */
    function isMinimumGoalReached() public view returns (bool reached) {
        return weiRaised >= minimumFundingGoal;
    }

    /**
    * Check if the contract relationship looks good.
    */
    function isFinalizerSane() external view returns (bool sane) {
        return finalizeAgent.isSane();
    }

    /**
    * Check if the contract relationship looks good.
    */
    function isPricingSane() external view returns (bool sane) {
        return pricingStrategy.isSane();
    }

    /**
    * Crowdfund state machine management.
    *
    * We make it a function and do not assign the result to a variable, 
    * so there is no chance of the variable being stale.
    */
    function getState() public view returns (State) {
        if(finalized) return State.Finalized;
        else if (address(finalizeAgent) == address(0)) return State.Preparing;
        else if (!finalizeAgent.isSane()) return State.Preparing;
        else if (!pricingStrategy.isSane()) return State.Preparing;
        else if (block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
        else if (isMinimumGoalReached()) return State.Success;
        else return State.Failure;
    }

    /** Interface marker. */
    function isCrowdsale() external pure returns (bool) {
        return true;
    }

    //
    // Abstract functions
    //

    /**
    * Check if the current invested breaks our cap rules.
    *
    *
    * The child contract must define their own cap setting rules.
    * We allow a lot of flexibility through different capping strategies (ETH, token count)
    * Called from invest().
    *  
    * @param tokensSoldTotal What would be our total sold tokens count after this transaction
    *
    * @return limitBroken true if taking this investment would break our cap rules
    */
    function isBreakingCap(uint256 tokensSoldTotal) public view virtual returns (bool limitBroken);

    function isBreakingInvestorCap(address receiver, uint256 tokenAmount) public view virtual returns (bool limitBroken);

    /**
    * Check if the current crowdsale is full and we can no longer sell any tokens.
    */
    function isCrowdsaleFull() public view virtual returns (bool);

    /**
    * Create new tokens or transfer issued tokens to the investor depending on the cap model.
    */
    function assignTokens(address receiver, uint256 tokenAmount) internal virtual;
}