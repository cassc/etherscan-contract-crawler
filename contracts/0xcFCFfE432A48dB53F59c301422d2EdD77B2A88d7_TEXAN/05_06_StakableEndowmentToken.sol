// SPDX-License-Identifier: UNLICENSED
// @title Stakeable Endowment Token
// @author Origin Addrress
// @notice This contract is proprietary and may not be copied or used without permission.
// @dev Stakable Endowment Main Functions for Staking, Scraping, and Ending Stakes
// @notice These are the main public functions for the token.

pragma solidity ^0.8.13;

import "./ERC20.sol";

abstract contract StakableEndowmentToken is ERC20 {
    // Launch timeTime 
    // Dec 22 12AM GMT
    uint256 internal constant LAUNCH_TIME = 1671667200;  //The time of launch
                                            
    // Global Constants Constants
    uint256 internal constant MIN_STAKE_DAYS = 1;
    uint256 internal constant MAX_STAKE_DAYS = 8036; // Approx 22 years and half a day
    uint256 internal constant MAX_STAKE_YEARS = 22; //

    uint256 internal constant MIN_STAKE_AMOUNT = 10000;
    uint256 internal constant MAX_STAKE_AMOUNT = 1e29; // 100B Stake is the max (100000000000000000000000000000)

    // This is the Endowment Supply. For security reasons we made this an 
    // internal variable that only this contract can change.
    
    // The initial supply is 97 Trillion locked in the contract
    uint256 internal _endowmentSupply = (97 * 1e30);

    // Global Variables
    uint256 g_latestStakeId = 0;     // the global stake id starting at zero so first take will be 1
    uint256 g_stakedStars = 0;      // the amount of wei that is already staked
    uint256 g_stakedPrincipleStars = 0;      // the amount of principle that is staked in wei
    uint256 g_penalizedStars = 0;  // these are the Stars that have been set aside from penalties
    uint256 g_stakedCount = 0;  // current count of active stakes based on + and - in startStake and endStake

    // For Calculations
    uint256 constant PRECISION = 1e18;   // 18 decimals
    uint256 constant YEARDIVIDER = 36525;  // must use yearprecision multiplier with this (100)
    uint256 constant YEARPRECISION = 100;  // because of integers only multiple by precision, divide by precision



    // @notice This contract has the utilities necessary for the Staking Endowment Token below
    event StartStake(
        address indexed stakeAddress,  // Address
        uint256 indexed stakeId,
        uint256 indexed eventName,
        uint256 startDay,
        uint256 stakedDays,
        uint256 principle,
        uint256 possibleInterest
    );

    event ScrapeStake(
        address indexed stakeAddress,
        uint256 indexed stakeId,
        uint256 indexed eventName,
        uint256 scrapeDay,
        uint256 previousScrapedInterest,
        uint256 oldPossibleInterest,
        uint256 scrapedInterest,
        uint possibleInterest
    );

    event EndStake(
        address indexed stakeAddress,
        uint256 indexed stakeId,
        uint256 indexed eventName,
        uint256 endStakeDay,
        uint256 principle,
        uint256 oldPossibleInterest,
        uint256 scrapedInterest,
        uint256 penalties,
        uint256 stakeTotal
    );

    // @dev Memory resident Stake for temporary use
    // @param uint256 _stakeId
    // @param uint256 _stakedPrinciple
    // @param uint256 _startDay
    // @param uint256 _scrapeDay
    // @param uint256 _stakedDays
    // @param uint256 _scrapedInterest
    // @param uint256 _possibleStars
    struct TempStake {
        uint256 _stakeId;
        uint256 _stakedPrinciple;
        uint256 _startDay;
        uint256 _scrapeDay;
        uint256 _stakedDays;
        uint256 _scrapedInterest;
        uint256 _possibleStars;
    }

    // @dev Permenant Stake for Storage
    // @param uint256 stakeId The stake ID
    // @param uint256 stakedPrinciple The initial principle staked
    // @param uint256 startDay The day the stake was started
    // @param uint256 scrapeDay The day the stake was scraped
    // @param uint256 stakedDays The days of the stake commitment
    // @param uint256 scrapedInterest The interest that has been scraped if any
    // @param uint256 possibleStars The potential amount of stars for this stake
    struct PermStake {
        uint256 stakeId;
        uint256 stakedPrinciple;
        uint256 startDay;
        uint256 scrapeDay;
        uint256 stakedDays;
        uint256 scrapedInterest;
        uint256 possibleStars;
    }

    // initialize the Store of Stakes.
    mapping(address => PermStake[]) public Stakes;

    // @dev Private: This emits the event
    // and was moved due to stack limits
    // @param uint256 stakeId - the stake id
    // @param uint256 interestDays the days of interest applied in this case
    // @param uint256 previousInterest - the amount of interest previously scraped
    // @param uint256 previousPossibleStars - what the previous amount of interest was before the scrape
    // @param uint256 scrapedInterest - the amount of interest scraped by this action
    // @param uint256 newPossibleIntest - the possible interest
    function emitScrapeEvent(uint256 stakeId, uint256 interestDays, uint256 previousInterest, uint256 previousPossibleStars, uint256 scrapedInterest, uint256 newPossibleInterest ) 
    internal 
    {
        // Emit the stake scrape event
        emit ScrapeStake(
            msg.sender,         // event Sender set here
            stakeId,            // stake Id
            uint(2),            // event id is 2
            interestDays,
            previousInterest,
            previousPossibleStars,
            scrapedInterest,
            newPossibleInterest
        );
    }

    // @dev Public Function: Open a stake.
    // @param uint256 stakedPrinciple Number of Stars to stake
    // @param uint256 stakedDays length of days in the stake
    function startStake(uint256 stakedPrinciple, uint256 stakedDays)
    external
    {
        // make sure the stake params are within guidelines or throw an error
        _assurePrincipleAndStakedDaysAreValid(stakedPrinciple, stakedDays);
        
        //Calculate possible payout
        uint256 possibleInterest = _calculateInterest(stakedPrinciple, stakedDays);
        
        // Create total possible stars
        uint256 possibleStars = possibleInterest + stakedPrinciple;  // ALL possible interest AND principle
        
        require(_endowmentSupply >  possibleInterest, "There is not enough to cover your stake");

        // Start the stake
        _startStake(stakedPrinciple, stakedDays, possibleStars);
        

        // the principle is burned from token supply, and the possible interest is pulled from the endowmentSupply
        _endowmentSupply = _endowmentSupply - possibleInterest; 
        
        
        // Add to global counter
        // Add principle only
        g_stakedPrincipleStars += stakedPrinciple;
        // Add all possible interest and principle to stakedStars.
        g_stakedStars += possibleStars;
        // Stake is official Ready to go
    }

    // @dev Public Function: Scrape stake
    // @dev This will calculate the eligible days since the previous stake
    // and mint the interest back to the user. This will also recalculate
    // the possible amount of interest.
    // @param uint256 stakeIndex  the index of the stake based on the order of active stakes
    // @param uint256 myStakeId The stake's id that is unique to the stake
    function scrapeStake(uint256 stakeIndex, uint256 myStakeId)
    external
    {
        PermStake[] storage permStakes = Stakes[msg.sender];
        require(permStakes.length != 0, "Empty stake list");
        require(stakeIndex < permStakes.length, "stakeIndex invalid");
        
        // load a copy of temporary stake 
        TempStake memory stake = TempStake(0,0,0,0,0,0,0);

        _loadStake(permStakes[stakeIndex], myStakeId, stake);
        // load up the stake reference also
        PermStake storage permStakeRef = Stakes[msg.sender][stakeIndex];
        // Defaults
        uint256 previousInterest = stake._scrapedInterest;
        uint256 previousPossibleStars = stake._possibleStars;
        // Calculate Days
        uint[6] memory calcDays = _calculateStakeDays(stake._startDay, stake._stakedDays, stake._scrapeDay);
        // Returns Calculated Days in an array like below
        // 0 curDay - Current Day
        // 1 startDay - Start Day
        // 2 scrapeDay - The previous day this was scraped - (default to startDay, and is set when scraped)
        // 3 endOfStakeDay - The final day of this stake (startDay + stakedDays or total days in stake)
        // 4 interestDays - Days that are used to CALCULATE INTEREST
        // 5 possibleDays -  (endOfStakeDays - currentDay)
        // scrapeServedDays // days that are interest bearing days
        uint256 currentInterest = 0;
        uint256 lostInterest = 0;
        uint256 newPossibleInterest = 0;
        uint256 curDay = calcDays[0];
        // the stake start day must be < the currentDay
        require(curDay > stake._startDay, "Scraping is not allowed, stake must start first");
        // make sure the curDay is within the scope of "scrapeable days"
        require(curDay <= calcDays[3], "Scraping is not allowed, must end stake");

        
        // Scraping is allowed only if the curDay is greater than the scrapeDay
        //PER SEI-04 - to save possible gas for the user
        require(curDay > calcDays[2], "Scraping is not allowed until 1 or more staked days has completed");

        // we will require this check so it doesn't waste resource by running these other calcs
        // you can't scrape twice on the same day so current Day must greater than previous scraped day
        // will equal 0 or previous accumulated amount
        previousInterest = stake._scrapedInterest;
        // total possible interest that was reserved for your stake
        // previousPossibleStars = stake._possibleStars; //includes principle
        // Calculate total based on interestDays
        currentInterest = _calculateInterest(stake._stakedPrinciple, calcDays[4]);
        // Calculate NEW possibleInterest based on EndofStake Days - currentDay
        newPossibleInterest = _calculateInterest(stake._stakedPrinciple, (calcDays[3]-calcDays[0]));
        uint newPossibleInterestPlusPrinciple = newPossibleInterest + stake._stakedPrinciple;
        // Lost interest = the interest you could have had - what you have now
        // What I have: 
            // previousPossibleStars - (includes principle)
            // newPossibleInterestPlusPrinciple  - newPossibleInterest also include principle
            // currentInterest - what we are minting for interest
        // just in case the previous possible interest is less than the new possible interest
        uint previousStarsAndCurrentInterest = previousPossibleStars > currentInterest ? (previousPossibleStars - currentInterest) : 0;
        if (previousStarsAndCurrentInterest > newPossibleInterestPlusPrinciple) {
            // lost interest gets minted back to the OA
            lostInterest = previousStarsAndCurrentInterest - newPossibleInterestPlusPrinciple;
        }
        // Now do the work based on values above calculate actual payout
        // penalties do not happen here, because there is a force closed function.
        // If there is accrued interest, send this back to the user
        // If there is no accrued interest, then nothing changes and all stays the same.
        if (currentInterest != 0) {

            // Mint this back to message sender
            _mint(msg.sender, currentInterest);
            
            // Mint lost interest back to the endowment supply
            if (lostInterest > 0) {
                 _endowmentSupply = _endowmentSupply + lostInterest;
            }


            // Set the total amount of accrued interest
            stake._scrapedInterest = previousInterest + currentInterest;
            // set the new possible interest in the stake... should continually get smaller and smaller
            stake._possibleStars  = newPossibleInterestPlusPrinciple;
            // Set the Scrape day to today
            stake._scrapeDay = curDay;
            //update the current stake to the new values
            _updateStake(permStakeRef, stake);
            // Emit the stake scrape event
            emitScrapeEvent(
                stake._stakeId,
                uint256(calcDays[4]),
                uint256(previousInterest),
                previousPossibleStars,
                stake._scrapedInterest,
                newPossibleInterest
            );
            // update global values
            // Adds back previous possible interest to the global variable
            g_stakedStars -= previousPossibleStars;
            // Removes the new current possible interest 
            g_stakedStars += newPossibleInterestPlusPrinciple;
        }
    }

    // @dev Public Function: End the Stake: This will calculate the amount of
    // interest, mint it back to the user, and remove the stake from the stakeList Map
    // @param uint256 stakeIndex  the index of the stake based on order and may change based on active stakes
    // @param uint256 myStakeId The stake's id
    function endStake(uint256 stakeIndex, uint256 myStakeId)
    external
    {
        PermStake[] storage permStakes = Stakes[msg.sender];
        require(permStakes.length != 0, "Stake List is Empty");
        require(stakeIndex < permStakes.length, "not a valid stakeIndex");
        
        // get temporary stake into memory
        TempStake memory stake = TempStake(0,0,0,0,0,0,0);

        _loadStake(permStakes[stakeIndex], myStakeId, stake);
        // Defaults
        uint256 servedDays = 0;
        uint256 stakeTotal;
        uint256 interestAccrued = 0;
        uint256 penalty = 0;
        // Calculate Days - returns Calculated Days in an array like below
        // 0 curDay - Current Day
        // 1 startDay - Start Day
        // 2 scrapeDay - The previous day this was scraped - (default to startDay, and is set when scraped)
        // 3 endOfStakeDay - The final day of this stake (startDay + stakedDays or total days in stake)
        // 4 interestDays - Days that are used to CALCULATE INTEREST
        // 5 possibleDays -  (endOfStakeDays - currentDay)
        uint[6] memory calcDays = _calculateStakeDays(stake._startDay, stake._stakedDays, stake._scrapeDay);
        // Stake Insurance - in case someone makes a mistake
        // if The stake has not started, then mint all possible back to the OA (removed)
        // if The stake has not started, then mint all possible back to the Endowment Supply
        if (calcDays[0] < calcDays[1]) {

            // Add the possible stars back to the endowment supply (minus the principle of course)
            _endowmentSupply = _endowmentSupply + (stake._possibleStars - stake._stakedPrinciple);

            
            // make sure that stakeTotal and penalty = 0 
            stakeTotal = 0;
            penalty = 0;
            // Add principle back to user
            _mint(msg.sender, stake._stakedPrinciple);
            // remove this from global stats
            g_stakedStars -= stake._possibleStars;
             

            // remove from the global principle stats
            g_stakedPrincipleStars -= stake._stakedPrinciple;
        
        } else {
            // served days is day from start day
            servedDays = calcDays[0] - calcDays[1];
            // calculate stake performance
            (stakeTotal, interestAccrued, penalty) = _calculateStakeTotal(stake);

            // Check for penalties
            if (penalty > 0) {
                // Zero interest gets returned
                // Possible Interest should get sent back to Endowment Supply
                _endowmentSupply += (stake._possibleStars - stake._stakedPrinciple);
                
                // Update global variables - to keep track of penalizedStars
                g_penalizedStars += penalty;

                // Remove possible stars from the global variable g_stakedStars
                if(g_stakedStars >= (stake._possibleStars)){
                    g_stakedStars -= (stake._possibleStars);
                }
                                
                // Remove the principle amount from global variable g_stakedPrincipleStars
                if(g_stakedPrincipleStars >= stake._stakedPrinciple){
                    g_stakedPrincipleStars -= stake._stakedPrinciple;
                }

            } else {
                // This is a good stake
                // There are no possible stars anymore
                // There is only interestAccrued, so remove that from global variable g_stakedStars

                // Remove all possible stars from g_stakedstars
                if (g_stakedStars >= interestAccrued){
                    g_stakedStars -= interestAccrued;    
                }
                // Possible Stars has Principle Included... InterestAccrued does not.
                // so we need to back out the principle also
                if (g_stakedStars >= stake._stakedPrinciple){
                    g_stakedStars -= stake._stakedPrinciple;    
                }

                // NOTE: Stake Total is Both the interestAccrued + Principle and that 
                // goes back to the user

                // Speaking of principle, let's also remove it from g_stakedPrincipleStars
                if(g_stakedPrincipleStars >= stake._stakedPrinciple){
                    g_stakedPrincipleStars -= stake._stakedPrinciple;    
                }
            }

            // Calculations are done, so let's mint back to the user,
            // Stake total could equal principle + stars, or principle - penalty
            if (stakeTotal != 0) {
                // We do not mint penalties back
                // This amount should be principle + any Interest Earned
                // OR if penalties, then this is principle minus penalties
                
                _mint(msg.sender, stakeTotal);
                
                // minted stake total back to user
                // ready to end the stake, so continue

            }
        } // end else
        
        // emit the stake end event and remove the stake from Stakes
        emit EndStake(
            msg.sender,
            stake._stakeId,
            uint256(3), // stake event id
            uint256(calcDays[3]),
            uint256(stake._stakedPrinciple),
            uint256(stake._possibleStars),
            uint256(stake._scrapedInterest),
            uint256(penalty),
            uint256(stakeTotal)
        );
        // Remove the Stake from your stake list
        uint256 lastIndex = permStakes.length - 1;
        // If it's the last element, then skip
        if (stakeIndex != lastIndex) {
            permStakes[stakeIndex] = permStakes[lastIndex];
        }
        permStakes.pop();
        // stake remove is finished - remove from the the global Active Stakes Count

        g_stakedCount = g_stakedCount - 1;
    }

    // @dev get the allocated supply of the token
    function allocatedSupply()
    external
    view
    returns (
        uint256
    )
    {
        return _allocatedSupply();
    }

    // @dev Public Function: Returns the current Day since the launch date
    // @return current day number
    function currentDay()
    external
    view
    returns (
        uint
    )
    {
        return _currentDay();
    }

    // @dev Reports Global gives a list of global variables for reporting
    // returns:
    // uint256 staked_stars,  sum of interest + principle
    // uint256 staked_principle_stars  // total staked based only on principle, what users actually staked,
    // uint256 total_supply, 
    // uint256 allocated_supply,
    // uint256 penalized_stars,
    // uint256 current_day,
    // uint256 latest_stake_id
    // uint256 staked_count total active stakes + and - at the end of startStake and endStake
    function reportGlobals()
    external
    view
    returns (
        uint256 staked_stars, 
        uint256 staked_principle_stars,
        uint256 total_supply,
        uint256 allocated_supply,
        uint256 penalized_stars,
        uint256 current_day,
        uint256 latest_stake_id,
        uint256 staked_count,
        uint256 endowment_supply
    )
    {
        staked_stars = g_stakedStars;
        staked_principle_stars = g_stakedPrincipleStars;
        

        total_supply = super.totalSupply() + g_stakedStars + _endowmentSupply;
        

        allocated_supply = _allocatedSupply();
        penalized_stars = g_penalizedStars;
        current_day = _currentDay();
        latest_stake_id = g_latestStakeId;
        staked_count = g_stakedCount;
        endowment_supply = _endowmentSupply;

        return (staked_stars, staked_principle_stars, total_supply, allocated_supply, penalized_stars, current_day, latest_stake_id, staked_count, endowment_supply);
    }

    // @dev Public Function: Return the count of stakes in the stakeList map
    // @param address userAddress - address of staker
    function countStakes(address userAddress)
    external
    view
    returns (
        uint256
    )
    {
        return Stakes[userAddress].length;
    }

    // Calculate Days
    // Returns Calculated Days in an array like below
    // 0 curDay - Current Day
    // 1 startDay - Start Day
    // 2 scrapeDay - The previous day this was scraped - (default to startDay, and is set when scraped)
    // 3 endOfStakeDay - The final day of this stake (startDay + stakedDays or total days in stake)
    // 4 interestDays - Days that are used to CALCULATE INTEREST
    // 5 possibleDays -  (endOfStakeDays - currentDay)
    // @param uint256 tempStartDay
    // @param uint256 tempStakedDays
    // @param uint256 tempScrapeDay
    function calculateStakeDays(uint256 tempStartDay, uint256 tempStakedDays, uint256 tempScrapeDay)
    external
    view
    returns (
        uint[6] memory
    )
    {
        uint[6] memory calcDays = _calculateStakeDays(tempStartDay, tempStakedDays, tempScrapeDay);
        return (calcDays);
    }

    // @dev Calculate the interest of a scenario
    // @param uint256 stakedPrinciple The amount of principle for the stake
    // @param uint256 stakedDays the number of days to commit to a stake
    function calculateInterest(uint256 stakedPrinciple, uint256 stakedDays)
    external
    pure
    returns(
        uint256 interest
    )
    {
        _assurePrincipleAndStakedDaysAreValid(stakedPrinciple, stakedDays);
        interest = _calculateInterest(stakedPrinciple, stakedDays);

        return (interest);
    }

    // @dev This give the totalsupply plus the totalstaked.  Total staked also
    // includes the interest that may be accrued from time and principle.
    // @return Allocated Supply in Stars
    function _allocatedSupply()
    private
    view
    returns (
        uint256
    )
    {

        return super.totalSupply() + g_stakedStars;

    }

    // @dev Private function that calculates the current day from day 1
    // @return Current day number
    function _currentDay()
    internal
    view
    returns (
        uint256 temp_currentDay
    )
    {
        return (block.timestamp - LAUNCH_TIME) / 1 days;
    }

    // @dev Private Function to load the stake into memory
    // Takes stake store and pushes the values into it
    // @param PermStake stakeRef reference of values to get
    // @param uint256 myStakeId or the globalStakeId
    // @param TempStake stake to load into memory as st or current stake
    // Requirements:
    // `stakeId must exist in the list`, so both the position (zero index AND stakeID must be correct)
    function _loadStake(PermStake storage stakeRef, uint256 myStakeId, TempStake memory stake)
    internal
    view
    {
        //require current stake index is valid
        require(myStakeId == stakeRef.stakeId, "myStakeId not in stake");
        stake._stakeId = stakeRef.stakeId;
        stake._stakedPrinciple = stakeRef.stakedPrinciple;
        stake._startDay = stakeRef.startDay;
        stake._scrapeDay = stakeRef.scrapeDay;
        stake._stakedDays = stakeRef.stakedDays;
        stake._scrapedInterest = stakeRef.scrapedInterest;
        stake._possibleStars = stakeRef.possibleStars;
    }

    // @dev Private Function for updating the stake
    // returns nothing, it just updates the stake passed to it
    // @param PermStake stakeRef the reference to the original mapping of the stake store
    // @param TempStake stake the new instance to update from
    function _updateStake(PermStake storage stakeRef, TempStake memory stake)
    internal
    {
        stakeRef.stakeId = stake._stakeId;
        stakeRef.stakedPrinciple = uint256(stake._stakedPrinciple);
        stakeRef.startDay = uint256(stake._startDay);
        stakeRef.scrapeDay = uint256(stake._scrapeDay);
        stakeRef.stakedDays = uint256(stake._stakedDays);
        stakeRef.scrapedInterest = uint256(stake._scrapedInterest);
        stakeRef.possibleStars = uint256(stake._possibleStars);
    }

    // @dev Internal Function Start a Stake Internal Function
    // @param uint256 stakedPrinciple
    // @param uint256 stakedDays length of days in the stake
    // @param uint256 possibleStars allocated total for this stake
    function _startStake(
        uint256 stakedPrinciple,
        uint256 stakedDays,
        uint256 possibleStars
    )
    private
    {
        // Get the current day
        uint256 cday = _currentDay();
        // starts the next day
        uint256 startDay = cday + 1;
        // automaticall set scrape day to start day
        uint256 scrapeDay = startDay;
        // Burn the tokens from the sender
        _burn(msg.sender, stakedPrinciple);
        // Get the global stake id and create the stake
        uint256 newStakeId = ++g_latestStakeId;
        // push the new stake into the sender's stake list
        Stakes[msg.sender].push(
            PermStake(
                newStakeId,
                stakedPrinciple,
                startDay,
                scrapeDay,
                stakedDays,
                uint256(0),
                possibleStars
            )
        );
        // emit the stake start event
        emit StartStake(
            msg.sender,
            uint256(newStakeId),
            uint256(1),
            startDay,
            stakedDays,
            stakedPrinciple,
            possibleStars
        );
        // Add to the global Active Stakes
        g_stakedCount = g_stakedCount + 1;
    }

    // @dev Require and validate the basic min/max stake parameters
    // @param uint256 principle
    // @param uint256 servedDays
    function _assurePrincipleAndStakedDaysAreValid(uint256 principle, uint256 servedDays)
    internal
    pure
    {
        // validate the stake days and principle 
        require(servedDays >= MIN_STAKE_DAYS, "Stake length is too small");
        require(servedDays <= MAX_STAKE_DAYS, "Stake length is too large");
        require(principle >= MIN_STAKE_AMOUNT, "Principle is not high enough");
        require(principle <= MAX_STAKE_AMOUNT, "Principle is too high");
    }

    // @dev Calculate Interest Function
    // @notice This calculates the amount of interest for the number of servedDays.
    // This divides up served days into buckets of yearly increments based on 365.25 days
    // Then applies the rate of return based on the interestTable.
    // @param uint256 principle - the principle to apply
    // @param uint256 servedDays - the number of days to calculate.
    function _calculateInterest(uint256 principle, uint256 servedDays)
    internal
    pure
    returns(
        uint256 totalInterest
    )
    {
        // year is 365.25, but we need to multiply by 100 to keep it integer'istic
        uint256 workingDays = servedDays * YEARPRECISION;
        // This will fill up based on the days.
        // Daily Interest Table is based on 18 decimals so
        uint[23] memory dailyInterestTable = _getDailyInterestTable();
        // Set an index to increment for the while loops
        uint256 workingidx = 0;
        uint256 appliedInterestRate = 0;
        uint256 tempInterestAmount = 0;
        uint256 current = 0;

        while (workingidx < MAX_STAKE_YEARS) {
            if (workingDays > YEARDIVIDER) {
                current = YEARDIVIDER;
                workingDays -= YEARDIVIDER;
            } else {
                // x is less than than MaxStakeYears, so set the remainder to this.
                current = workingDays;  // this will give the days left over
                workingDays = 0;
            }
            // apply this years interest rate to the days inside that year
            appliedInterestRate = dailyInterestTable[workingidx];
            
            // days (36525) * interest for this year divided by 100 multiplied by principle then divide py precision
            
            // tempInterestAmount = (((current * appliedInterestRate) / YEARPRECISION) * principle) / (PRECISION * PRECISION); //36 decimals
            
            uint tempInterestAmountNumerator = 0;
            tempInterestAmountNumerator = ((current * appliedInterestRate) * principle) / YEARPRECISION;
            tempInterestAmount = tempInterestAmountNumerator / (PRECISION * PRECISION); //36

            // apply the principle and add it to the running total of interest
            totalInterest += tempInterestAmount;   // divide by 100 because of our days... days return as 36525 and not 365.25
            workingidx = workingidx + 1;  // keep running for the full 22 years.
            if (workingDays == 0) {
                break;
            }
        }

        return (totalInterest);
    }

    // @dev CalculatePenalty
    // @notice This calculates the penalty if there is one.
    // The rules for penalty:
    //     - if a stake is less than 50% complete, then you get 50% of your principle returned
    //     - if a stake is greater than 50%, you get the percentage back for each day from 100%
    //         example: Stake is 60% complete. You should receive 60% of your principle back.
    // @param TempStake stake the stake to calculate penalties for
    function _calculatePenalty(TempStake memory stake)
    internal
    view
    returns(
        uint256 penaltyAmount
    )
    {
        // calculate the penalty for forcing and end stake
        uint[6] memory calcDays = _calculateStakeDays(stake._startDay, stake._stakedDays, stake._scrapeDay);
        uint256 pct = 0;
        uint256 pctleft = 0;
        uint256 pctprecision = 100;
        uint256 daysSinceStart = 0;
        uint256 totalStakeDays = stake._stakedDays * pctprecision;
        // Check served days to make sure it's at least 1
        if (totalStakeDays <= 0) {
            totalStakeDays = 1 * pctprecision; //sets minimum amt for calculation        
        }
        if (calcDays[0] < calcDays[1]) {
            // should never happen... condition handled in parent
        } else if (calcDays[0] == calcDays[1]) {
            daysSinceStart = (1 * pctprecision);
        } else {
            // number of days since start day
            daysSinceStart = (calcDays[0] - calcDays[1]) * pctprecision;
        }
        // basic pct made here
        pct = (daysSinceStart * pctprecision) / totalStakeDays;
        // decision time - anything 50 or less is counted as 50
        if (pct <= 50) {
            pctleft = 50;
        } else if (pct > 50 && pct < 100) {
            pctleft = 100 - pct;
        } else {
            pctleft = 0;
        }
        // calculate penalties from pctleft
        penaltyAmount = (stake._stakedPrinciple * pctleft) / 100;
        // This cannot be less than zero
        if (penaltyAmount <= 0) {
            penaltyAmount = 0;
        }
        // this should never exceed the amount, but just in case lets test for it anyway
        if (penaltyAmount > stake._stakedPrinciple) {
            penaltyAmount = stake._stakedPrinciple;
        }

        return (penaltyAmount);
    }

    // @param TempStake stake
    function _calculateStakeTotal(TempStake memory stake)
    internal
    view
    returns (
        uint256 stakeTotal,
        uint256 currentInterest,
        uint256 penalty
    )
    {
        penalty = 0;
        stakeTotal = 0;  // total return of the stake
        currentInterest = 0;
        uint256 appliedPrinciple = 0;
        uint256 previousInterest = stake._scrapedInterest;
        uint[6] memory calcDays = _calculateStakeDays(stake._startDay, stake._stakedDays, stake._scrapeDay);
        // Returns Calculated Days in an array like below
        // 0 curDay - Current Day
        // 1 startDay - Start Day
        // 2 scrapeDay - The previous day this was scraped - (default to startDay, and is set when scraped)
        // 3 endOfStakeDay - The final day of this stake (startDay + stakedDays or total days in stake)
        // 4 interestDays - Days that are used to CALCULATE INTEREST
        // 5 possibleDays -  (endOfStakeDays - currentDay)
        // if InterestDays is less than staked days
        // if (calcDays[4] < stake._stakedDays) {
        // if currentDay is less than endofstake day
        if (calcDays[0] < calcDays[3]) {
            // calculate the penalty if any
            penalty = _calculatePenalty(stake);
            if (penalty > stake._stakedPrinciple) {
                // this should never happen but if it does, then set to 50% of the principle
                appliedPrinciple = stake._stakedPrinciple / 2;
            } else {
                // this should return a "prorated" amount of principle from 51% to 99%
                appliedPrinciple = (stake._stakedPrinciple - penalty);
            }
            // A broken stake will only give you the portion of your principle back, not your interest.
            stakeTotal = appliedPrinciple;
            currentInterest = 0;
        } else {
            // There is no penalty if stake is completed
            currentInterest = _calculateInterest(stake._stakedPrinciple, calcDays[4]);
            // Set the total amount of accrued interest
            stake._scrapedInterest = previousInterest + currentInterest;
            // stake is finished, so we set this to zero
            stake._possibleStars = 0;
            // total amount of stake to be returned to user
            stakeTotal = currentInterest + stake._stakedPrinciple;
            penalty = 0;
        }
    }

    // This returns days in this order:
    // 0 curDay - Current Day
    // 1 startDay - Start Day
    // 2 scrapeDay - The previous day this was scraped - (default to startDay, and is set when scraped)
    // 3 endOfStakeDay - The final day of this stake (startDay + stakedDays or total days in stake)
    // 4 interestDays - Days that are used to CALCULATE INTEREST
    // 5 possibleDays -  (endOfStakeDays - currentDay)
    // @dev Calculate Days
    // @notice This returns an array of calculated days of your stake based on the current day.
    // @param uint256 startDay
    // @param uint256 stakedDays length of days in the stake
    // @param uint256 scrapeDay
    function _calculateStakeDays(uint256 startDay, uint256 stakedDays, uint256 scrapeDay)
    internal
    view
    returns (uint[6] memory)
    {
        // if the stakedDays is less than the minimum, throw an error
        require(stakedDays >= MIN_STAKE_DAYS, "stake days must be greater than 1");
        uint256 curDay = _currentDay();  //ex. day 25
        uint256 endOfStakeDay = startDay + stakedDays; //ex. Day 52
        // find the higher of the two days ( startDay or a more recent scrapeDay )
        uint256 targetStartDay = scrapeDay >= startDay ? scrapeDay : startDay;
        // the possible interest bearing days
        uint256 possibleDays = endOfStakeDay - targetStartDay;
        uint256 interestDays = 0;
        // if the currentDay is greater than the end stake day, we subtract:
        // targetStartDay from the endOfStakeDay giving us the interest days.
        // otherwise we take the currentDay and subtract the same targetStartDay because it's still an active stake.
        if (targetStartDay > curDay) {
            // probably a new stake so we'll default to zero
            // this also keeps this from subtracting current day from target day
            // and for the beginning of a stake, it will be a negative 1
            interestDays = 0;
        } else {
            interestDays = curDay >= endOfStakeDay ? (endOfStakeDay - targetStartDay) : (curDay - targetStartDay);
        }

        return [
            uint(curDay),
            startDay,
            scrapeDay,
            endOfStakeDay,
            interestDays,
            possibleDays
        ];
    }

    // @dev getDailyInterestTable
    // @notice This table has precalculated values for the 22 year buckets that calculate the interest
    // based on the number of days you have within each year.
    function _getDailyInterestTable()
    internal
    pure
    returns (uint[23] memory tableOfInterest)
    {
        // These values are precalculated and will never change once this is made live.
        // based on 36 decimals
        tableOfInterest = [
        uint(136892539356605065023956194387405), 
             164271047227926078028747433264887, 
             219028062970568104038329911019849, 
             301163586584531143052703627652292, 
             410677618069815195071868583162217, 
             547570157426420260095824777549623, 
             711841204654346338124572210814510, 
             903490759753593429158110882956878, 
             1122518822724161533196440793976728, 
             1368925393566050650239561943874058, 
             1642710472279260780287474332648870, 
             1943874058863791923340177960301163, 
             2272416153319644079397672826830937, 
             2628336755646817248459958932238193, 
             3011635865845311430527036276522929, 
             3422313483915126625598904859685147, 
             3860369609856262833675564681724845, 
             4325804243668720054757015742642026, 
             4818617385352498288843258042436687, 
             5338809034907597535934291581108829, 
             5886379192334017796030116358658453, 
             6461327857631759069130732375085557, 
             0
            ];

        return (tableOfInterest);
    }


    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // The Endowment Supply is the total amount of token available for staking rewards to the stakers.
        // A proper representation of Total Supply is the Endowment Supply + what is in the ERC20 total supply
        uint totSupply = super.totalSupply() + g_stakedStars + _endowmentSupply;

        return (totSupply);
    }
    /**
     * @dev Follows same convention as IERC20-totalsupply
     */
    function endowmentSupply() public view returns (uint256) {
        // The Endowment Supply is the total amount of token available for staking rewards to the stakers.
        // A proper representation of Total Supply is the Endowment Supply + what is in the ERC20 total supply
        return _endowmentSupply;
    }    
    
    /**
     * @dev Follows same convention as IERC20-totalsupply
     */
    function originalSupply() public view returns (uint256) {
        // The Endowment Supply is the total amount of token available for staking rewards to the stakers.
        // A proper representation of Total Supply is the Endowment Supply + what is in the ERC20 total supply
        return (super.totalSupply());
    }

}