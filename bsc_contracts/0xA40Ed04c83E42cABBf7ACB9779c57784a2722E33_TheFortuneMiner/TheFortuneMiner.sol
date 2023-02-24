/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TheFortuneMiner {
    using SafeMath for uint256;

    /** base parameters **/
    uint256 public EGGS_TO_HIRE_1MINERS = 2592000;
    uint256 public REFERRAL = 10;
    uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public PROJECT = 100;
    uint256 public BUYBACK = 100;
    uint256 public PARTNER = 50;
    uint256 public MARKETING = 50;
    uint256 public MARKETING_SELL = 50;
    uint256 public MARKET_EGGS_DIVISOR = 5;

    /** bonus **/
    uint256 public COMPOUND_BONUS = 10; /** 1% **/
    uint256 public COMPOUND_BONUS_MAX_TIMES = 10; /** 10 days. **/
    uint256 public COMPOUND_STEP = 24 * 60 * 60; /** every 24 hours. **/

    /** withdrawal tax **/
    uint256 public WITHDRAWAL_TAX = 900;
    uint256 public WITHDRAWAL_TAX_DAYS = 3;

    /* lottery */
    bool public LOTTERY_ACTIVATED = false;
    uint256 public LOTTERY_START_TIME;
    uint256 public LOTTERY_PERCENT = 5;
    uint256 public LOTTERY_MAX_DEPOSITOR_PERCENT = 5;
    uint256 public LOTTERY_STEP = 24 * 60 * 60; /** every 24 hours. **/
    uint256 public LOTTERY_TICKET_PRICE = 0.01 ether; /** 0.01 BNB **/
    uint256 public MAX_LOTTERY_TICKET_COMPOUND = 50;
    uint256 public MAX_LOTTERY_TICKET_DEPOSIT = 50;

    uint256 public lotteryRound = 0;

    /* statistics */
    uint256 public totalStaked;
    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalRefBonus;
    uint256 public totalWithdrawn;
    uint256 public totalLotteryBonus;

    /* miner parameters */
    uint256 public marketEggs = 86400000000;
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public contractStarted = false;

    /** whale control features **/
    uint256 public CUTOFF_STEP = 48 * 60 * 60; /** 48 hours  **/
    uint256 public MIN_INVEST = 0.05 ether; /** 0.05 BNB  **/
    uint256 public WITHDRAW_COOLDOWN = 24 * 60 * 60; /** 24 hours  **/
    uint256 public WITHDRAW_LIMIT = 30 ether; /** 30 BNB  **/
    uint256 public WALLET_DEPOSIT_LIMIT = 30 ether; /** 30 BNB  **/

    /* addresses */
    address payable public owner;
    address payable public project;
    address payable public partner;
    address payable public marketing;
    address payable public buyback;

    struct User {
        uint256 initialDeposit;
        uint256 userDeposit;
        uint256 miners;
        uint256 claimedEggs;
        uint256 totalLotteryBonus;
        uint256 lastHatch;
        address referrer;
        uint256 referralsCount;
        uint256 referralEggRewards;
        uint256 totalWithdrawn;
        uint256 dailyCompoundBonus;
        uint256 withdrawCount;
        uint256 lastWithdrawTime;
    }

    struct LotteryParticipant {
        address addr;
        uint256 depositTickets;
        uint256 compoundTickets;
        uint256 totalTickets;
        uint256 depositAmount;
    }

    struct LotteryHistory {
        uint256 round;
        address lotteryWinner;
        address maxDepositWinner;
        uint256 lotteryPot;
        uint256 maxDepositorPot;
        address[] participants;
        uint256 totalParticipants;
        uint256 totalTickets;
    }

    mapping(uint256 => LotteryHistory) public lotteries; // round => Lottery
    mapping(address => User) public users; // address => User
    mapping(uint256 => mapping(address => LotteryParticipant)) public lotteryParticipants; /** round => address => LotteryParticipant **/

    event LotteryWinner(
        address indexed winner,
        uint256 pot,
        uint256 indexed round
    );

    event MaxDepositorWinner(
        address indexed winner,
        uint256 pot,
        uint256 depositAmount,
        uint256 indexed round
    );

    event Deposited(
        address indexed adr,
        address indexed ref,
        uint256 bnbamount
    );

    event Compounded(
        address indexed adr
    );

    event Claimed(
        address indexed adr,
        uint256 bnbToClaim
    );

    event Started();

    constructor(
        address payable _project,
        address payable _partner,
        address payable _marketing,
        address payable _buyback
    ) {
        require(
            !isContract(_project) &&
                !isContract(_partner) &&
                !isContract(_marketing) &&
                !isContract(_buyback)
        );
        owner = payable(msg.sender);
        project = _project;
        partner = _partner;
        marketing = _marketing;
        buyback = _buyback;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Admin use only");
        _;
    }

    function startContract()
        public
        onlyOwner
    {
        require(!contractStarted, "Contract is already started");
        contractStarted = true;
        LOTTERY_ACTIVATED = true;
        LOTTERY_START_TIME = block.timestamp;

        emit Started();
    }

     //fund contract with BNB before launch.
    function fundContract() external payable onlyOwner {
        require(msg.value > 0);
    }

    function hatchEggs(bool isCompound) public {
        require(contractStarted || msg.sender == owner, "Contract not yet Started.");
        User storage user = users[msg.sender];
        uint256 eggsUsed = getMyEggs();
        uint256 eggsForCompound = eggsUsed;

        if (isCompound) {
            uint256 dailyCompoundBonus = getDailyCompoundBonus(msg.sender, eggsForCompound);
            eggsForCompound = eggsForCompound.add(dailyCompoundBonus);
            uint256 eggsUsedValue = calculateEggSell(eggsForCompound);
            user.userDeposit = user.userDeposit.add(eggsUsedValue);
            totalCompound = totalCompound.add(eggsUsedValue);

            if (LOTTERY_ACTIVATED && eggsUsedValue >= LOTTERY_TICKET_PRICE && msg.sender != owner) {
                buyTickets(msg.sender, eggsUsedValue, true);
            }
        }

        if (block.timestamp.sub(user.lastHatch) >= COMPOUND_STEP) {
            if (user.dailyCompoundBonus < COMPOUND_BONUS_MAX_TIMES) {
                user.dailyCompoundBonus = user.dailyCompoundBonus.add(1);
            }
        }

        user.miners = user.miners.add(eggsForCompound.div(EGGS_TO_HIRE_1MINERS));
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;

        if (block.timestamp.sub(user.lastWithdrawTime) >= COMPOUND_STEP) {
            user.withdrawCount = 0;
        }

        marketEggs = marketEggs.add(eggsUsed.div(MARKET_EGGS_DIVISOR));

        emit Compounded(msg.sender);
    }

    function sellEggs() public {
        require(contractStarted, "Contract not yet Started.");
        User storage user = users[msg.sender];
        if (user.lastHatch.add(WITHDRAW_COOLDOWN) > block.timestamp) {
            revert("Withdrawals can only be done after withdraw cooldown.");
        }

        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);

        if (WITHDRAW_LIMIT != 0 && eggValue > WITHDRAW_LIMIT) {
            eggValue = WITHDRAW_LIMIT;
        }

        user.withdrawCount = user.withdrawCount.add(1);
        if (user.withdrawCount >= WITHDRAWAL_TAX_DAYS) {
            eggValue = eggValue.sub(eggValue.mul(WITHDRAWAL_TAX).div(PERCENTS_DIVIDER));
        }

        user.dailyCompoundBonus = 0;
        user.lastWithdrawTime = block.timestamp;
        user.claimedEggs = 0;
        user.lastHatch = block.timestamp;
        marketEggs = marketEggs.add(hasEggs);

        if (getBalance() < eggValue) {
            eggValue = getBalance();
        }
        uint256 eggsPayout = eggValue.sub(payFeesSell(eggValue));
        user.totalWithdrawn = user.totalWithdrawn.add(eggsPayout);
        totalWithdrawn = totalWithdrawn.add(eggsPayout);
        payable(msg.sender).transfer(eggsPayout);


        ///@dev if no new investment or compound, sell will also trigger lottery
        if (block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) {
            chooseWinners();
        }

        emit Claimed(msg.sender, eggsPayout);

    }

    function buyEggs(address ref) public payable {
        require(contractStarted || msg.sender == owner, "Contract not yet Started.");

        User storage user = users[msg.sender];

        require(msg.value >= MIN_INVEST, "Mininum investment not met.");
        require(
            user.initialDeposit.add(msg.value) <= WALLET_DEPOSIT_LIMIT,
            "Max deposit limit reached."
        );

        uint256 eggsBought = calculateEggBuy(msg.value, getBalance().sub(msg.value));
        user.userDeposit = user.userDeposit.add(msg.value);
        user.initialDeposit = user.initialDeposit.add(msg.value);
        user.claimedEggs = user.claimedEggs.add(eggsBought);

        if (user.referrer == address(0)) {
            if (ref != msg.sender) {
                user.referrer = ref;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].referralsCount = users[upline1]
                    .referralsCount
                    .add(1);
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                /** referral rewards will be in ELK value **/
                uint256 refRewards = msg.value.mul(REFERRAL).div(PERCENTS_DIVIDER);
                users[upline].referralEggRewards = users[upline]
                    .referralEggRewards
                    .add(refRewards);
                payable(upline).transfer(refRewards);
                totalRefBonus = totalRefBonus.add(refRewards);
            }
        }

        uint256 eggsPayout = payFees(msg.value);
        totalStaked = totalStaked.add(msg.value.sub(eggsPayout));
        totalDeposits = totalDeposits.add(1);

        if (LOTTERY_ACTIVATED &&  msg.value >= LOTTERY_TICKET_PRICE && msg.sender != owner) {
            buyTickets(msg.sender, msg.value, false);
        }

        hatchEggs(false);

        emit Deposited(msg.sender, ref, msg.value);
    }

    function payFees(uint256 eggValue) internal returns (uint256) {
        uint256 projectFee = eggValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        uint256 partnerFee = eggValue.mul(PARTNER).div(PERCENTS_DIVIDER);
        uint256 marketingFee = eggValue.mul(MARKETING).div(PERCENTS_DIVIDER);
        uint256 buybackFee = eggValue.mul(BUYBACK).div(PERCENTS_DIVIDER);
        payable(project).transfer(projectFee);
        payable(marketing).transfer(marketingFee);
        payable(partner).transfer(partnerFee);
        payable(buyback).transfer(buybackFee);
        return projectFee.add(partnerFee).add(buybackFee).add(marketingFee);
    }

    function payFeesSell(uint256 eggValue) internal returns (uint256) {
        uint256 marketingFee = eggValue.mul(MARKETING_SELL).div(PERCENTS_DIVIDER);
        payable(marketing).transfer(marketingFee);
        return marketingFee;
    }

    function getFees(uint256 eggValue)
        public
        view
        returns (
            uint256 _projectFee,
            uint256 _partnerFee,
            uint256 _marketingFee,
            uint256 _buybackFee
        )
    {
        _projectFee = eggValue.mul(PROJECT).div(PERCENTS_DIVIDER);
        _partnerFee = eggValue.mul(PARTNER).div(PERCENTS_DIVIDER);
        _marketingFee = eggValue.mul(MARKETING).div(PERCENTS_DIVIDER);
        _buybackFee = eggValue.mul(BUYBACK).div(PERCENTS_DIVIDER);
    }

    /** lottery section! **/
    function buyTickets(address userAddress, uint256 amount, bool isCompound) private {
        require(amount != 0, "zero purchase amount");

        LotteryHistory storage currentLottery = lotteries[lotteryRound];
        LotteryParticipant storage participant = lotteryParticipants[lotteryRound][userAddress];

        uint256 numDepositTickets = participant.depositTickets;
        uint256 numCompoundTickets = participant.compoundTickets;

        uint256 numTickets = amount.div(LOTTERY_TICKET_PRICE);

        if (numDepositTickets == 0 && numCompoundTickets == 0 && numTickets > 0) {
            currentLottery.totalParticipants = currentLottery.totalParticipants.add(1);
            currentLottery.participants.push(userAddress);
        }

        if (isCompound) {
            if (numCompoundTickets.add(numTickets) > MAX_LOTTERY_TICKET_COMPOUND) {
                numTickets = MAX_LOTTERY_TICKET_COMPOUND.sub(numCompoundTickets);
            }
            participant.compoundTickets = numCompoundTickets.add(numTickets);
        } else {
            if (numDepositTickets.add(numTickets) > MAX_LOTTERY_TICKET_DEPOSIT) {
                numTickets = MAX_LOTTERY_TICKET_DEPOSIT.sub(numDepositTickets);
            }
            participant.depositTickets = numDepositTickets.add(numTickets);
            participant.depositAmount = participant.depositAmount.add(amount);
        }
        participant.totalTickets = participant.totalTickets.add(numTickets);
        participant.addr = userAddress;
        lotteryParticipants[lotteryRound][userAddress] = participant;

        _updatePots();
        currentLottery.totalTickets = currentLottery.totalTickets.add(numTickets);

        if (block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP) {
            chooseWinners();
        }
    }

    function _updatePots() private {
        // 1% of contract balance
        LotteryHistory storage currentLottery = lotteries[lotteryRound];
        uint256 balance = getBalance();

        currentLottery.lotteryPot = balance.mul(LOTTERY_PERCENT).div(
            PERCENTS_DIVIDER
        );
        currentLottery.maxDepositorPot = balance.mul(LOTTERY_MAX_DEPOSITOR_PERCENT).div(PERCENTS_DIVIDER);
    }

    function chooseWinners() public {
        require(
            (block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP),
            "current lottery round is still in progress"
        );

        LotteryHistory storage currentLottery = lotteries[lotteryRound];
        uint256 totalParticipants = currentLottery.totalParticipants;
        if (totalParticipants != 0) {
            _updatePots();
            _chooseLotteryWinner();
            _chooseMaxDepositor();
        }

        /** reset lotteryRound **/
        LOTTERY_START_TIME = block.timestamp;
        lotteryRound = lotteryRound.add(1);
    }

    function _chooseLotteryWinner() private {
        require(
            (block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP),
            "current lottery round is still in progress"
        );
        LotteryHistory storage currentLottery = lotteries[lotteryRound];
        require(
            currentLottery.totalParticipants > 0,
            "there are no participants in current lottery"
        );

        uint256 totalParticipants = currentLottery.totalParticipants;
        address[] memory participants = currentLottery.participants;

        require(
            participants.length == totalParticipants,
            "there was a problem with participants tracking"
        );
        // find random lottery winner
        uint256[] memory init_range = new uint256[](totalParticipants);
        uint256[] memory end_range = new uint256[](totalParticipants);

        uint256 last_range = 0;

        for (uint256 i = 0; i < totalParticipants; i++) {
            address currentAddress = participants[i];
            uint256 numTickets = lotteryParticipants[lotteryRound][currentAddress].totalTickets;
            uint256 range0 = last_range.add(1);
            uint256 range1 = range0.add(numTickets.div(1e18));

            init_range[i] = range0;
            end_range[i] = range1;
            last_range = range1;
        }

        uint256 random = _getRandom().mod(last_range).add(1);
        for (uint256 i = 0; i < totalParticipants; i++) {
            if ((random >= init_range[i]) && (random <= end_range[i])) {
                /** winner found **/
                address winnerAddress = participants[i];
                currentLottery.lotteryWinner = winnerAddress;
                uint256 pot = currentLottery.lotteryPot;
                /** lottery prize will be converted to buy miners **/
                _payoutLottery(winnerAddress, pot);
                emit LotteryWinner(winnerAddress, pot, lotteryRound);
                break;
            }
        }
    }

    function _payoutLottery(address winnerAddress, uint256 amount) private {
        User storage user = users[winnerAddress];
        uint256 eggsReward = calculateEggBuy(amount, getBalance().sub(amount));
        user.miners = user.miners.add(eggsReward.div(EGGS_TO_HIRE_1MINERS));
        /** record users total lottery rewards **/
        user.totalLotteryBonus = user.totalLotteryBonus.add(amount);
        totalLotteryBonus = totalLotteryBonus.add(amount);
    }

    /** select lottery winner **/
    function _getRandom() private view returns (uint256) {
        bytes32 _blockhash = blockhash(block.number - 1);
        uint256 currentPot = lotteries[lotteryRound].lotteryPot;
        return
            uint256(
                keccak256(
                    abi.encode(
                        _blockhash,
                        block.timestamp,
                        currentPot,
                        block.difficulty,
                        marketEggs,
                        getBalance()
                    )
                )
            );
    }

    function _chooseMaxDepositor() private {
        require(
            (block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP),
            "current lottery round is still in progress"
        );
        LotteryHistory storage currentLottery = lotteries[lotteryRound];
        require(
            currentLottery.totalParticipants > 0,
            "there are no participants in current lottery"
        );

        /** lottery prize will be converted to buy miners **/
        uint256 pot = currentLottery.maxDepositorPot;
        (uint256 maxDeposit, address maxDepositor) = getLargestDepositor();
        currentLottery.maxDepositWinner = maxDepositor;
        _payoutLottery(maxDepositor, pot);
        emit MaxDepositorWinner(maxDepositor, pot, maxDeposit, lotteryRound);
    }

    function getLargestDepositor() public view returns (uint256 maxDeposit, address maxDepositor) {
        LotteryHistory storage currentLottery = lotteries[lotteryRound];
        uint256 totalParticipants = currentLottery.totalParticipants;
        address[] memory participants = currentLottery.participants;

        // loop through total participants and compare every deposit to find the max
        maxDeposit = 0;
        maxDepositor;
        for (uint256 i = 0; i < totalParticipants; i++) {
            LotteryParticipant storage participant = lotteryParticipants[lotteryRound][participants[i]];
            if (maxDeposit < participant.depositAmount) {
                maxDeposit = participant.depositAmount;
                maxDepositor = participant.addr;
            }
        }
    }

    function chooseLotteryWinner() public onlyOwner {
        _chooseLotteryWinner();
    }

    function chooseMaxDepositor() public onlyOwner {
        _chooseMaxDepositor();
    }

    function getDailyCompoundBonus(address _adr, uint256 amount)
        public
        view
        returns (uint256)
    {
        if (users[_adr].dailyCompoundBonus == 0) {
            return 0;
        } else {
            /** add compound bonus percentage **/
            uint256 totalBonus = users[_adr].dailyCompoundBonus.mul(
                COMPOUND_BONUS
            );
            uint256 result = amount.mul(totalBonus).div(PERCENTS_DIVIDER);
            return result;
        }
    }

    function getLotteryHistory(uint256 round)
        public
        view
        returns (
            address lotteryWinner,
            address maxDepositWinner,
            uint256 lotteryPot,
            uint256 maxDepositorPot,
            uint256 totalParticipants,
            uint256 totalTickets
        )
    {
        lotteryWinner = lotteries[round].lotteryWinner;
        maxDepositWinner = lotteries[round].maxDepositWinner;
        lotteryPot = lotteries[round].lotteryPot;
        maxDepositorPot = lotteries[round].maxDepositorPot;
        totalParticipants = lotteries[round].totalParticipants;
        totalTickets = lotteries[round].totalTickets;
    }

    function getLotteryInfo()
        public
        view
        returns (
            uint256 round,
            uint256 startTime,
            uint256 step,
            uint256 ticketPrice,
            uint256 maxDepositTicket,
            uint256 maxCompoundTicket,
            uint256 lotteryPercent,
            uint256 maxDepositorPercent
        )
    {
        round = lotteryRound;
        startTime = LOTTERY_START_TIME;
        step = LOTTERY_STEP;
        ticketPrice = LOTTERY_TICKET_PRICE;
        lotteryPercent = LOTTERY_PERCENT;
        maxDepositorPercent = LOTTERY_MAX_DEPOSITOR_PERCENT;
        maxDepositTicket = MAX_LOTTERY_TICKET_DEPOSIT;
        maxCompoundTicket = MAX_LOTTERY_TICKET_COMPOUND;
    }

    function getUserInfo(address _adr)
        public
        view
        returns (
            uint256 _initialDeposit,
            uint256 _userDeposit,
            uint256 _miners,
            uint256 _claimedEggs,
            uint256 _totalLotteryBonus,
            uint256 _lastHatch,
            address _referrer,
            uint256 _referrals,
            uint256 _totalWithdrawn,
            uint256 _referralEggRewards,
            uint256 _dailyCompoundBonus,
            uint256 _lastWithdrawTime,
            uint256 _withdrawCount
        )
    {
        _initialDeposit = users[_adr].initialDeposit;
        _userDeposit = users[_adr].userDeposit;
        _miners = users[_adr].miners;
        _claimedEggs = users[_adr].claimedEggs;
        _totalLotteryBonus = users[_adr].totalLotteryBonus;
        _lastHatch = users[_adr].lastHatch;
        _referrer = users[_adr].referrer;
        _referrals = users[_adr].referralsCount;
        _totalWithdrawn = users[_adr].totalWithdrawn;
        _referralEggRewards = users[_adr].referralEggRewards;
        _dailyCompoundBonus = users[_adr].dailyCompoundBonus;
        _lastWithdrawTime = users[_adr].lastWithdrawTime;
        _withdrawCount = users[_adr].withdrawCount;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }

    function getUserTickets(address _userAddress) public view returns (uint256 compound, uint256 deposit) {
        LotteryParticipant storage participant = lotteryParticipants[lotteryRound][_userAddress];
        compound = participant.compoundTickets;
        deposit = participant.depositTickets;
    }

    function getLotteryTimer() public view returns (uint256) {
        return LOTTERY_START_TIME.add(LOTTERY_STEP);
    }

    function getLotteryParticipants(uint256 round) public view returns (address[] memory) {
        return lotteries[round].participants;
    }

    function getAvailableEarnings(address _adr) public view returns (uint256) {
        uint256 userEggs = users[_adr].claimedEggs.add(
            getEggsSinceLastHatch(_adr)
        );
        return calculateEggSell(userEggs);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(PSN, bs),
                SafeMath.add(
                    PSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(PSN, rs),
                            SafeMath.mul(PSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, getBalance());
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, getBalance());
    }

    /** How many miners and eggs per day user will recieve based on ELK deposit **/
    function getEggsYield(uint256 amount)
        public
        view
        returns (uint256, uint256)
    {
        uint256 eggsAmount = calculateEggBuy(
            amount,
            getBalance().add(amount).sub(amount)
        );
        uint256 miners = eggsAmount.div(EGGS_TO_HIRE_1MINERS);
        uint256 day = 1 days;
        uint256 eggsPerDay = day.mul(miners);
        uint256 earningsPerDay = calculateEggSellForYield(eggsPerDay, amount);
        return (miners, earningsPerDay);
    }

    function calculateEggSellForYield(uint256 eggs, uint256 amount)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eggs, marketEggs, getBalance().add(amount));
    }

    function getSiteInfo()
        public
        view
        returns (
            uint256 _totalStaked,
            uint256 _totalDeposits,
            uint256 _totalCompound,
            uint256 _totalRefBonus,
            uint256 _totalLotteryBonus,
            uint256 _totalWithdrawn
        )
    {
        _totalStaked = totalStaked;
        _totalDeposits = totalDeposits;
        _totalCompound = totalCompound;
        _totalRefBonus = totalRefBonus;
        _totalLotteryBonus = totalLotteryBonus;
        _totalWithdrawn = totalWithdrawn;
    }

    function getMyMiners() public view returns (uint256) {
        return users[msg.sender].miners;
    }

    function getMyEggs() public view returns (uint256) {
        return
            users[msg.sender].claimedEggs.add(
                getEggsSinceLastHatch(msg.sender)
            );
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsSinceLastHatch = block.timestamp.sub(
            users[adr].lastHatch
        );
        /** get min time. **/
        uint256 cutoffTime = min(secondsSinceLastHatch, CUTOFF_STEP);
        uint256 secondsPassed = min(EGGS_TO_HIRE_1MINERS, cutoffTime);
        return secondsPassed.mul(users[adr].miners);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    /** lottery enabler **/
    function ENABLE_LOTTERY() public onlyOwner {
        require(contractStarted);
        LOTTERY_ACTIVATED = true;
        LOTTERY_START_TIME = block.timestamp;
    }

    function DISABLE_LOTTERY() public onlyOwner {
        require(contractStarted);
        LOTTERY_ACTIVATED = false;
    }

    /** wallet addresses **/
    function CHANGE_OWNERSHIP(address value) external onlyOwner {
        owner = payable(value);
    }

    function CHANGE_PROJECT(address value) external onlyOwner {
        project = payable(value);
    }

    function CHANGE_PARTNER(address value) external onlyOwner {
        partner = payable(value);
    }

    function CHANGE_MARKETING(address value) external onlyOwner {
        marketing = payable(value);
    }

    /** percentage **/

    /**
        2592000 - 3%
        2160000 - 4%
        1728000 - 5%
        1440000 - 6%
        1200000 - 7%
        1080000 - 8%
         959000 - 9%
         864000 - 10%
         720000 - 12%
    **/
    function PRC_EGGS_TO_HIRE_1MINERS(uint256 value) external onlyOwner {
        require(value >= 720000 && value <= 2592000); /** min 3% max 12%**/
        EGGS_TO_HIRE_1MINERS = value;
    }

    function PRC_PROJECT(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 200); /** 20% max **/
        PROJECT = value;
    }

    function PRC_PARTNER(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 100); /** 10% max **/
        PARTNER = value;
    }

    function PRC_MARKETING(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 100); /** 10% max **/
        MARKETING = value;
    }

    function PRC_MARKETING_SELL(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 100); /** 10% max **/
        MARKETING_SELL = value;
    }

    function PRC_REFERRAL(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 100); /** 10% max **/
        REFERRAL = value;
    }

    function PRC_MARKET_EGGS_DIVISOR(uint256 value) external onlyOwner {
        require(value <= 80); /** 50 = 2% **/
        MARKET_EGGS_DIVISOR = value;
    }

    /** withdrawal tax **/
    function SET_WITHDRAWAL_TAX(uint256 value) external onlyOwner {
        require(value <= 900); /** Max Tax is 90% or lower **/
        WITHDRAWAL_TAX = value;
    }

    function SET_WITHDRAW_DAYS_TAX(uint256 value) external onlyOwner {
        require(value <= 6); /** Max 6 days **/
        WITHDRAWAL_TAX_DAYS = value;
    }

    /** bonus **/
    function SET_COMPOUND_BONUS(uint256 value) external onlyOwner {
        require(value >= 10 && value <= 500); /** 50% max **/
        COMPOUND_BONUS = value;
    }

    function SET_COMPOUND_BONUS_MAX_TIMES(uint256 value)
        external
        onlyOwner
    {
        require(value <= 20); /** 20 max **/
        COMPOUND_BONUS_MAX_TIMES = value;
    }

    function SET_COMPOUND_STEP(uint256 value) external onlyOwner {
        require(value <= 24);
        COMPOUND_STEP = value * 60 * 60;
    }

    /* lottery setters */
    function SET_LOTTERY_STEP(uint256 value) external onlyOwner {
        require(value <= 48);
        LOTTERY_STEP = value * 60 * 60;
    }

    function SET_LOTTERY_PERCENT(uint256 value) external onlyOwner {
        require(value >= 5 && value <= 50); /** 5% max **/
        LOTTERY_PERCENT = value;
    }

    function SET_LOTTERY_MAX_DEPOSITOR_PERCENT(uint256 value)
        external
        onlyOwner
    {
        require(value >= 5 && value <= 50); /** 5% max **/
        LOTTERY_MAX_DEPOSITOR_PERCENT = value;
    }

    function SET_LOTTERY_TICKET_PRICE(uint256 value) external onlyOwner {
        LOTTERY_TICKET_PRICE = value * 1 ether;
    }

    function SET_MAX_LOTTERY_TICKET_COMPOUND(uint256 value) external onlyOwner {
        require(value >= 1 && value <= 500);
        MAX_LOTTERY_TICKET_COMPOUND = value;
    }

    function SET_MAX_LOTTERY_TICKET_DEPOSIT(uint256 value) external onlyOwner {
        require(value >= 1 && value <= 500);
        MAX_LOTTERY_TICKET_DEPOSIT = value;
    }

    function SET_INVEST_MIN(uint256 value) external onlyOwner {
        MIN_INVEST = value * 1 ether;
    }

    function SET_CUTOFF_STEP(uint256 value) external onlyOwner {
        CUTOFF_STEP = value * 60 * 60;
    }

    function SET_WITHDRAW_COOLDOWN(uint256 value) external onlyOwner {
        require(value <= 24);
        WITHDRAW_COOLDOWN = value * 60 * 60;
    }

    function SET_WITHDRAW_LIMIT(uint256 value) external onlyOwner {
        require(value == 0 || value >= 1);
        WITHDRAW_LIMIT = value * 1 ether;
    }

    function SET_WALLET_DEPOSIT_LIMIT(uint256 value) external onlyOwner {
        require(value >= 20);
        WALLET_DEPOSIT_LIMIT = value * 1 ether;
    }
}

library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}