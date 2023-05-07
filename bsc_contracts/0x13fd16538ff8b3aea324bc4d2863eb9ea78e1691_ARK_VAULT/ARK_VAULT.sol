/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

/*
 *          .      .                                                 .                  
 *               .                                                                      
 *            .;;..         .':::::::::::::;,..    .'::;..   . .':::;'. .               
 *           'xKXk;.      . .oXXXXXXXXXXXXXXKOl'.  .oXXKc.    .l0XX0o.                  
 *          .dXXXXk, .      .;dddddddddddddkKXXk,  .oXXKc.  .:kXXKx,.  .                
 *       . .oKXXXXXx'              .  .    .oKXXo. .oXXKc..'dKXXOc. .    .              
 *     .. .lKXXkxKXXx. .                   .lKXXo. .oXXKd;lOXXKo'.      .               
 *       .cKXXk'.oKXKd.      .cloollllllolox0XXO;. .oXXXXXXXXKl. .                      
 *   .  .c0XXk,  .dXXKo. .  .lXXXXXXXXXXXXXXX0d,.. .oXXXOxkKXKk:.                       
 *     .:0XXO;.   'xXXKl.   .oXXKxcccccco0XXKc.  . .oXXKc..cOXXKd,.                     
 *     ;OXX0:.     ,kXX0c.  .oXXKc      .:0XXO,    .oXXKc. .'o0XX0l.                    
 *    ,kXX0c.       ,OXX0:. .oXXKc.  ..  .c0XXk,   .oXXKc. . .;xKXKk;.                  
 *   .cxxxc.        .;xxko. .:kkx;.       .:xxxl.  .:xxx;. .   .cxxxd;. .               
 *   ......          ...... ......       . ......   .....       .......                 
 *               .             .             ..                                         
 * 
 * ARK VAULT
 *
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXPair {
    function sync() external;
}

interface ILEGACY {
    function getCwr(address investor) external view returns (uint256);
    function getLevels(address investor) external view returns (uint256);
}

interface IBOND {
    function unstake(address investor, uint256 amount) external;
    function stake(address investor, uint256 amount) external;
    function claimRewardsFor(address investor) external;
    function distributeRewards() external;
    function addToRewardsPool(uint256 busdAmount) external;
    function sendRewards(uint256 busdAmount) external;
    function getBondBalance(address investor) external view returns(uint256);
    function checkAvailableRewards(address investor) external view returns(uint256);
}

interface ICCVRF {
    function getRandomNumbers(uint256 howMany, uint256 max) external payable returns(uint256[] memory);
}

interface ISWAP {
    function vaultSellForBUSD(address investor, uint256 amount) external;
    function vaultAddLiquidityWithArk(address investor, uint256 amount) external;
}

interface IVAULT {
    function principalBalance(address _address) external view returns (uint256);
    function airdropBalance(address _address) external view returns (uint256);
    function deposits(address _address) external view returns (uint256);
    function newDeposits(address _address) external view returns (uint256);
    function out(address _address) external view returns (uint256);
    function postTaxOut(address _address) external view returns (uint256);
    function roi(address _address) external view returns (uint256);
    function tax(address _address) external view returns (uint256);
    function cwr(address _address) external view returns (uint256);
    function maxCwr(address _address) external view returns (uint256);
    function penalized(address _address) external view returns (bool);
    function accountReachedMaxPayout(address _address) external view returns (bool);
    function doneCompounding(address _address) external view returns (bool);
    function lastAction(address _address) external view returns (uint256);
    function compounds(address _address) external view returns (uint256);
    function withdrawn(address _address) external view returns (uint256);
    function airdropped(address _address) external view returns (uint256);
    function airdropsReceived(address _address) external view returns (uint256);
    function roundRobinRewards(address _address) external view returns (uint256);
    function directRewards(address _address) external view returns (uint256);
    function timeOfEntry(address _address) external view returns (uint256);
    function referrerOf(address _address) external view returns (address);
    function roundRobinPosition(address _address) external view returns (uint256);
    function upline(address _address, uint i) external view returns (address);
    function totalPrizeMoneyPaid() external view returns (uint256);
    function totalWinners() external view returns (uint256);
}

contract ARK_VAULT {
    address private constant TOKEN = 0x111120a4cFacF4C78e0D6729274fD5A5AE2B1111;
    address private constant SERVER = 0x764361cA766d0807da988f0Ac95332F2A6F90720;
    IBEP20 public constant ARK = IBEP20(TOKEN);
    IDEXPair private constant ARK_POOL = IDEXPair(0x4004D3856499d947564521511dCD28e1155C460b);
    IBEP20 public constant BUSD = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    ICCVRF public constant VRF = ICCVRF(0xf8B22e7446E7eF6F2dbbea06B3F8022D978c682a); 
    address public constant CEO = 0xdf0048DF98A749ED36553788B4b449eA7a7BAA88;
    IVAULT public constant oldVault = IVAULT(0xeB5f81A779BCcA0A19012d24156caD8f899F6452);
    uint256 public constant MULTIPLIER = 10**18;
    IBOND public bond = IBOND(0x3333e437546345F8Fd48Aa5cA8E92a77eD4b3333);
    ILEGACY public legacy = ILEGACY(0x2222223B05B5842c918a868928F57cD3A0332222);
    ISWAP public swap = ISWAP(0x55553531D05394750d60EFab7E93D73a356F5555);
    mapping(address => bool) public isArk;

    uint256 public totalAccounts;

    mapping(address => uint256) public principalBalance;
    mapping(address => uint256) public airdropBalance;
    
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public newDeposits;
    mapping(address => uint256) public out;
    mapping(address => uint256) public postTaxOut;

    mapping(address => uint256) public roi;
    mapping(address => uint256) public tax;
    mapping(address => uint256) public cwr;
    mapping(address => uint256) public maxCwr;
    mapping(address => bool) public penalized;
    mapping(address => bool) public accountReachedMaxPayout;
    mapping(address => bool) public doneCompounding;

    mapping(address => uint256) public lastAction;
    mapping(address => uint256) public compounds;
    mapping(address => uint256) public withdrawn;
    mapping(address => uint256) public airdropped;
    mapping(address => uint256) public airdroppedBefore;
    mapping(address => uint256) public airdropsReceived;
    mapping(address => uint256) public roundRobinRewards;
    mapping(address => uint256) public directRewards;
    mapping(address => uint256) public timeOfEntry;

    mapping(address => address) public referrerOf;
    mapping(address => uint256) public roundRobinPosition;

    mapping(address => address[]) public upline;
    mapping(address => mapping(address => bool)) private referrerAdded;

    mapping(uint256 => uint256) public bondLevelPrices;
    
    struct Action {
        uint256 compoundSeconds;
        uint256 withdrawSeconds;
    }

    mapping(address => Action[]) public actions;
    
///// VaultVariables    
    uint256 public roiPenalized = 5;
    uint256 public roiNormal = 20;    
    uint256 public roiReduced = 10;
    uint256 public constant maxCwrWithoutNft = 1500;
    uint256 public constant cwrLowerLimit = 750;
    uint256 public constant maxPayoutPercentage = 300;
    uint256 public maxDeposit = 4000 * MULTIPLIER;
    uint256 public minDeposit = 10 * MULTIPLIER;
    uint256 public constant maxPayoutAmount = 80000 * MULTIPLIER;

///// TimeVariables
    uint256 public constant cwrAverageTime = 14 days;
    uint256 public constant timer = 1 days;

///// TaxVariables
    uint256 public swapBuyTax = 5;
    uint256 public depositTax = 10;
    uint256 public depositReferralTax = 5;
    uint256 public buyTax = 8;
    uint256 public buyReferralTax = 5;
    uint256 public constant roundRobinTax = 5;
    uint256 public constant basicTax = 10;
    uint256 public constant taxLevelSteps = 8000 * MULTIPLIER;
    uint256 public constant maxTax = 55;
    uint256 public constant taxIncrease = 5;   

///// SparkVariables
    uint256 public sparkPotPercent = 50;
    uint256 public sparkPot;
    uint256 public totalPrizeMoneyPaid;
    uint256 public totalWinners;
    address[] public sparkPlayers;
    mapping (address => bool) public sparkPlayerAdded;

///// Events for our backend
    event NewAccountOpened(address investor, uint256 amount, uint256 timestamp);
    event DirectReferralRewardsPaid(address referrer, uint256 amount);
    event ArkBoughtWithReferral(address referrer, uint256 amount);
    event Deposit(address investor, uint256 amount);
    event SomeoneHasReachedMaxPayout(address investor);
    event SomeoneIsDoneCompounding(address investor);
    event SomeoneWasFeelingGenerous(address investor, uint256 totalAirdropAmount);
    event SparkPotToppedUp(uint256 amount, address whoWasntEligible);
    event RoundRobinReferralRewardsPaid(address referrer, uint256 amount, uint256 roundRobinPosition);
    event SomeoneJoinedTheSystem(address investor,address referrer);
    event RoiReduced(address investor);
    event RoiIncreased(address investor);
    event SomeoneWasNaughtyAndWillBePunished(address investor);
    event SomeoneIsUsingHisNftToHyperCompound(address investor, uint256 maxCwr);
    event AutomatedActionTaken(address investor, uint256 withdrawPercent, uint256 compoundPercent, uint256 airdropPercent, bool autoSell, bool autoDeposit, bool autoBond);
    event ManualActionTaken(address investor, uint256 withdrawPercent, uint256 compoundPercent, uint256 airdropPercent, bool autoSell, bool autoDeposit, bool autoBond);
    event ThingDone(address investor, uint256 rewardsAllocatedAfterTaxes, uint256 withdrawPercent, uint256 compoundPercent, uint256 airdropPercent);
    event ArkWalletSet(address arkWallet, bool status);
    event SparkWinnerPaid(address winner, uint256 prizeMoney, uint256 winnerNumber, uint256 timestamp, bool isRandom);    
    event AirDropsSent(address[] airdroppees, uint256[] amounts);
    event BnbRescued();
    event InvestorMigrated(address investor);

    modifier onlyCEO() {
        require(msg.sender == CEO, "CEO");
        _;
    }

    modifier onlyArk() {
        require(isArk[msg.sender], "ARK");
        _;
    }

    constructor () {
        bondLevelPrices[1] = 250 ether;
        bondLevelPrices[2] = 250 ether;
        bondLevelPrices[3] = 500 ether;
        bondLevelPrices[4] = 500 ether;
        bondLevelPrices[5] = 500 ether;
        bondLevelPrices[6] = 500 ether;
        bondLevelPrices[7] = 500 ether;
        bondLevelPrices[8] = 500 ether;
        bondLevelPrices[9] = 500 ether;
        bondLevelPrices[10] = 1000 ether;
        bondLevelPrices[11] = 1000 ether;
        bondLevelPrices[12] = 1000 ether;
        bondLevelPrices[13] = 1000 ether;
        bondLevelPrices[14] = 1000 ether;
        bondLevelPrices[15] = 1000 ether;
        approveContracts(address(legacy));
        approveContracts(address(swap));
        approveContracts(address(bond));
        totalPrizeMoneyPaid = oldVault.totalPrizeMoneyPaid();
        totalWinners = oldVault.totalWinners();
        isArk[CEO] = true;
        isArk[SERVER] = true;
    }

    receive() external payable {}

    function deposit(uint256 amount, address referrer) external {
        generateUpline(msg.sender, referrer);
        ARK.transferFrom(msg.sender, address(this), amount);
        amount = takeDepositTax(referrerOf[msg.sender], amount);
        doTheDeposit(msg.sender, amount);
    }

    function depositTo(address investor, uint256 amount, address referrer, bool taxFree) external onlyArk {
        depositBase(investor, amount, referrer, taxFree);
    }

    function depositToMany(address[] memory investors, uint256[] memory amounts, address referrer, bool taxFree) external onlyArk {
        for(uint256 i=0; i < investors.length; i++) depositBase(investors[i], amounts[i], referrer, taxFree);
    }

    function depositBase(address investor, uint256 amount, address referrer, bool taxFree) internal {
        generateUpline(investor, referrer);
        ARK.transferFrom(msg.sender, address(this), amount);
        if(!taxFree) amount = takeDepositTax(referrerOf[investor], amount);
        doTheDeposit(investor, amount);
    }

    function depositFor(address investor, uint256 amount, address referrer) external onlyArk returns (uint256) {
        generateUpline(investor, referrer);
        emit ArkBoughtWithReferral(referrerOf[investor], amount);
        ARK.transferFrom(msg.sender, address(this), amount);
        amount = takeDepositTaxFromBuy(referrerOf[investor], amount);
        return doTheDeposit(investor, amount);
    }

    function generateUpline(address investor, address referrer) internal {
        if(upline[investor].length == 0){
            if(referrer == investor) referrer = address(0);
            else referrerOf[investor] = referrer;
            emit SomeoneJoinedTheSystem(investor, referrer);
            createUpline(investor, referrer);
        }
    }

    function createUpline(address investor, address referrer) internal {
        referrerAdded[investor][investor] = true;
        for(uint256 i=0; i<15;i++){
            upline[investor].push(referrer);    
            if(referrer != address(0)) {
                referrerAdded[investor][referrer] = true;
                referrer = referrerOf[referrer];
                if(referrerAdded[investor][referrer]) referrer = address(0);
            }
        }
    }
    
    function doTheDeposit(address investor, uint256 amount) internal returns (uint256) {
        uint256 depositsTotal = deposits[investor] + newDeposits[investor];
        require(depositsTotal + amount <= maxDeposit, "max deposit");
        require(depositsTotal + amount >= minDeposit, "min deposit");
        _deposit(investor, amount);
        return amount;
    }

    function takeAction(uint256 withdrawPercent, uint256 compoundPercent, uint256 airdropPercent, bool autoSell, bool autoDeposit, bool autoBond) external {
        doTheThing(msg.sender, withdrawPercent, compoundPercent, airdropPercent, autoSell, autoDeposit, autoBond);
        emit ManualActionTaken(msg.sender, withdrawPercent, compoundPercent, airdropPercent, autoSell, autoDeposit, autoBond);
    }

    function airdrop(address[] memory airdroppees, uint256[] memory amounts) external {
        require(airdroppees.length == amounts.length, "length");
        require(airdroppees.length <= 200, "200");
        uint256 totalAirdropAmount = 0;
        for(uint i = 0; i < airdroppees.length; i++){
            uint256 amount = amounts[i];
            address airdroppee = airdroppees[i];
            if(airdroppee == msg.sender) continue;
            uint256 depositsTotal = deposits[airdroppee] + newDeposits[airdroppee];
            if(depositsTotal > maxDeposit) {
               amounts[i] = 0;
               continue;
            }
            if(depositsTotal + amount > maxDeposit) {
                amount = maxDeposit - depositsTotal;
                amounts[i] = amount;
            }
            _deposit(airdroppee, amount);
            airdropsReceived[airdroppee] += amount;
            airdropBalance[msg.sender] -= amount;
            totalAirdropAmount += amount;
        }
        emit SomeoneWasFeelingGenerous(msg.sender, totalAirdropAmount);
        emit AirDropsSent(airdroppees, amounts);
    }

////////////////////// SERVER FUNCTIONS /////////////////////////////////
    function takeAutomatedAction(address investor, uint256 withdrawPercent, uint256 compoundPercent, uint256 airdropPercent, bool autoSell, bool autoDeposit, bool autoBond) external onlyArk {
        doTheThing(investor, withdrawPercent, compoundPercent, airdropPercent, autoSell, autoDeposit, autoBond);
        emit AutomatedActionTaken(investor, withdrawPercent, compoundPercent, airdropPercent, autoSell, autoDeposit, autoBond);
    }

////////////////////// INTERNAL FUNCTIONS /////////////////////////////////
    function doTheThing(address investor, uint256 withdrawPercent, uint256 compoundPercent, uint256 airdropPercent, bool autoSell, bool autoDeposit, bool autoBond) internal {
        if(autoDeposit) require(!autoSell && !autoBond, "Only one");
        if(autoSell) require(!autoDeposit && !autoBond, "Only one");
        if(autoBond) require(!autoSell && !autoDeposit, "Only one");
        if(accountReachedMaxPayout[investor] || principalBalance[investor] + newDeposits[investor] < minDeposit) return;
        
        if(withdrawPercent + compoundPercent + airdropPercent != 100000) {
            withdrawPercent *= 1000;
            compoundPercent *= 1000;
            airdropPercent *= 1000;
        }

        require(withdrawPercent + compoundPercent + airdropPercent == 100000, "Not 100");
        uint256 timeSinceLastAction = block.timestamp - lastAction[investor] > timer ? timer : block.timestamp - lastAction[investor];
        lastAction[investor] = block.timestamp;
        uint256 availableReward = principalBalance[investor] * roi[investor] / 1000 * timeSinceLastAction / timer;

        uint256 maxPayout = checkForMaxPayoutPercent(investor);

        if(maxPayout < out[investor] + availableReward) availableReward = maxPayout - out[investor];

        if(doneCompounding[investor]) {
            maxPayout = maxPayoutAmount;
            withdrawPercent += compoundPercent;
            compoundPercent = 0;
        }

        if(out[investor] + availableReward > maxPayoutAmount) {
            availableReward = maxPayout - out[investor];
            accountReachedMaxPayout[investor] = true;
            emit SomeoneHasReachedMaxPayout(investor);
        }

        if(availableReward == 0) return;
        out[investor] += availableReward;
        calculateWhaleTax(investor);
        principalBalance[investor] += newDeposits[investor];
        deposits[investor] += newDeposits[investor];
        newDeposits[investor] = 0;
        uint256 taxAmount = availableReward * tax[investor] / 100;
        availableReward -= taxAmount;
        emit ThingDone(investor, availableReward, withdrawPercent, compoundPercent, airdropPercent);
        postTaxOut[investor] += availableReward;

        if(withdrawPercent > 0) {
            uint256 withdrawAmount = withdrawPercent * availableReward / 100000;
            if(autoDeposit) reDeposit(investor, withdrawAmount);
            else ARK.transfer(investor, withdrawAmount);
            if(autoSell) swap.vaultSellForBUSD(investor, withdrawAmount);
            if(autoBond) swap.vaultAddLiquidityWithArk(investor, withdrawAmount);
            withdrawn[investor] += withdrawAmount;
        }

        if(compoundPercent > 0){
            uint256 compoundAmount = compoundPercent * availableReward / 100000;
            uint256 compoundTaxAmount = taxAmount * compoundPercent / 100000;
            compound(investor, compoundAmount, compoundTaxAmount);
            compounds[investor] += compoundAmount;
        }

        if(airdropPercent > 0) {
            uint256 airdropAmount = airdropPercent * availableReward / 100000;
            airdropBalance[investor] += airdropAmount;
            airdropped[investor] += airdropAmount;
        }

        doTheMath(investor, timeSinceLastAction, withdrawPercent, compoundPercent, airdropPercent);
    }

    function _addInvestor(address investor, uint256 amount) internal {
        timeOfEntry[investor] = block.timestamp;
        cwr[investor] = 1000;
        Action memory currentAction;
        currentAction.compoundSeconds = cwrAverageTime/2;
        currentAction.withdrawSeconds = cwrAverageTime/2;
        actions[investor].push(currentAction);
        roi[investor] = roiNormal;
        maxCwr[investor] = maxCwrWithoutNft;
        lastAction[investor] = block.timestamp;
        principalBalance[investor] = amount;
        deposits[investor] = amount;
        totalAccounts++;
        emit NewAccountOpened(investor, amount, block.timestamp);
    }

    function _deposit(address investor, uint256 amount) internal {
        if (amount == 0) return;
        if (timeOfEntry[investor] == 0) _addInvestor(investor, amount);
        else newDeposits[investor] += amount;
        emit Deposit(investor, amount);
    }

    function checkForMaxPayoutPercent(address investor) internal returns (uint256) {
        uint256 maxPayout = (principalBalance[investor] + newDeposits[investor]) * maxPayoutPercentage / 100;
        if(maxPayout > maxPayoutAmount) {
            doneCompounding[investor] = true;     
            emit SomeoneIsDoneCompounding(investor);
        }
        return maxPayout;
    }

    function reDeposit(address investor, uint256 amount) internal {
        amount = takeDepositTax(referrerOf[investor], amount);
        uint256 depositsTotal = deposits[investor] + newDeposits[investor];
        require(depositsTotal + amount <= maxDeposit, "max deposit");
        _deposit(investor, amount);
        principalBalance[investor] += newDeposits[investor];
        deposits[investor] += newDeposits[investor];
        newDeposits[investor] = 0;
    }

    function compound(address investor, uint256 amount, uint256 taxAmount) internal {
        principalBalance[investor] += amount;
        uint256 roundRobinAmount = taxAmount * roundRobinTax / tax[investor];
        roundRobin(investor, roundRobinAmount);
    }

    function roundRobin(address investor, uint256 amount) internal {
        uint256 currentPosition = roundRobinPosition[investor];
        address currentRobin = upline[investor][currentPosition];
        
        if(currentRobin == address(0) || !isEligible(currentRobin,currentPosition)) {
            uint256 sparkPotAmount = amount * sparkPotPercent / 100;
            sparkPot += sparkPotAmount;
            emit SparkPotToppedUp(sparkPotAmount, currentRobin);
        }
        else {
            _deposit(currentRobin, amount);
            roundRobinRewards[currentRobin] += amount;
            emit RoundRobinReferralRewardsPaid(currentRobin, amount, roundRobinPosition[investor]);
        }
        roundRobinPosition[investor]++;
        if(roundRobinPosition[investor] > 14) roundRobinPosition[investor] = 0;
    }

////////////////////// CALCULATION FUNCTIONS /////////////////////////////////
    function calculateWhaleTax(address investor) internal {
        tax[investor] = basicTax + taxIncrease * (out[investor] / taxLevelSteps);
        if(tax[investor] > maxTax) tax[investor] = maxTax;
    } 

    function doTheMath(
        address investor,
        uint256 timeSinceLastAction,
        uint256 withdrawPercent,
        uint256 compoundPercent,
        uint256 airdropPercent
    ) internal {
        Action memory currentAction;
        currentAction.compoundSeconds = timeSinceLastAction * compoundPercent / 100000;
        currentAction.withdrawSeconds = timeSinceLastAction * (withdrawPercent + airdropPercent) / 100000;
        actions[investor].push(currentAction);
        uint256 newCwr = getRollingAverageCwr(investor,0,0,0,0);
        if(newCwr > maxCwr[investor]) updateMaxCwr(investor);
        if(compoundPercent != 0) require(newCwr <= maxCwr[investor], "CWR too high");
        cwr[investor] = newCwr;
        bool ndvNegative = withdrawn[investor] + airdropped[investor] - airdroppedBefore[investor] > deposits[investor] + newDeposits[investor] - airdropsReceived[investor];

        if(!penalized[investor] && newCwr < cwrLowerLimit && !doneCompounding[investor]) {
            penalized[investor] = true;
            roi[investor] = roiPenalized;
            emit SomeoneWasNaughtyAndWillBePunished(investor);
            return;
        }

        if(ndvNegative && roi[investor] == roiNormal) {
            emit RoiReduced(investor);
            roi[investor] = roiReduced;
            return;
        }

        if(!ndvNegative && roi[investor] == roiReduced) {
            emit RoiIncreased(investor);
            roi[investor] = roiNormal;
        }
    }

    function updateMaxCwr(address investor) internal {
        maxCwr[investor] = legacy.getCwr(investor);
        emit SomeoneIsUsingHisNftToHyperCompound(investor, maxCwr[investor]);
    }

////////////////////// TAX FUNCTIONS /////////////////////////////////
    function takeDepositTax(address referrer, uint256 amount) internal returns(uint256) {
        uint256 taxAmount = amount * depositTax / 100;
        if(referrer == address(0)) return amount - taxAmount;
        uint256 referralTax = amount * depositReferralTax / 100; 
        if(isEligible(referrer,0)) {
            _deposit(referrer, referralTax);
            directRewards[referrer] += referralTax;
            emit DirectReferralRewardsPaid(referrer, referralTax);
        }
        return amount - taxAmount;
    }

    function takeDepositTaxFromBuy(address referrer, uint256 amount) internal returns(uint256) {
        uint256 initialAmount = amount * 100 / (100 - swapBuyTax);
        uint256 taxAmount = initialAmount * buyTax / 100;
        if(referrer == address(0)) return amount - taxAmount;
        uint256 referralTax = initialAmount * buyReferralTax / 100;
        if(isEligible(referrer,0)) {
            _deposit(referrer, referralTax);
            directRewards[referrer] += referralTax;
            emit DirectReferralRewardsPaid(referrer, referralTax);
        }
        return amount - taxAmount;
    }

/////////////////// PUBLIC READ FUNCTIONS //////////////////////////////
    function getAvailableReward(address investor) public view returns(uint256) {
        uint256 timeSinceLastAction = block.timestamp - lastAction[investor] > timer ? timer : block.timestamp - lastAction[investor];
        uint256 availableReward = principalBalance[investor] * roi[investor] * timeSinceLastAction / timer / 1000;
        return availableReward;
    }

    function checkNdv(address investor) public view returns(int256) {
        int256 ndv = int256(deposits[investor]) + int256(newDeposits[investor]) + int256(airdroppedBefore[investor]) - int256(airdropsReceived[investor]) - int256(withdrawn[investor]) - int256(airdropped[investor]);
        return ndv;
    }

    function hasAccount(address investor) external view returns(bool) {
        if(principalBalance[investor] + newDeposits[investor] < minDeposit) return false;
        return true;
    }

    function isEligible(address uplineAddress, uint256 uplinePosition) public view returns(bool) {
        if(uplineAddress == address(0)) return false;
        uint256 levels = legacy.getLevels(uplineAddress);
        if(levels > uplinePosition) return true; 
        levels = addLevelsFromBond(uplineAddress, levels);
        if(levels > uplinePosition) return true;
        return false;
    }

    function addLevelsFromBond(address investor, uint256 nftLevels) public view returns (uint256) {
        uint256 bondValue = getBondValue(investor);
        if(bondValue < bondLevelPrices[1]) return nftLevels;
        uint256 currentLevel = nftLevels;
        uint256 remainingBondValue = bondValue;

        while(remainingBondValue > bondLevelPrices[currentLevel + 1]) {
            currentLevel++;
            remainingBondValue -= bondLevelPrices[currentLevel];
            if(currentLevel > 14) return 15;
        }

        return currentLevel;
    }

    function getBondValue(address investor) public view returns (uint256) {
        return calculateUsdValueOfBond(bond.getBondBalance(investor));
    }

    function calculateUsdValueOfBond(uint256 amountOfBond) public view returns(uint256) {
        return amountOfBond * BUSD.balanceOf(address(ARK_POOL)) * 2 / IBEP20(address(ARK_POOL)).totalSupply();
    }
    
    function getRollingAverageCwr(
        address investor,
        uint256 timeSinceLastAction,
        uint256 withdrawPercent,
        uint256 compoundPercent,
        uint256 airdropPercent
    ) public view returns(uint256) {
        if(withdrawPercent + compoundPercent + airdropPercent != 100000) {
            withdrawPercent *= 1000;
            compoundPercent *= 1000;
            airdropPercent *= 1000;
        }
        uint256 totalActions = actions[investor].length;
        uint256 newCompoundSeconds = timeSinceLastAction * compoundPercent / 100000;
        uint256 newWithdrawSeconds = timeSinceLastAction * (withdrawPercent + airdropPercent) / 100000;
        uint256 k;

        for(uint256 i = 1; newCompoundSeconds + newWithdrawSeconds < cwrAverageTime; i++) { 
            newCompoundSeconds += actions[investor][totalActions - i].compoundSeconds;
            newWithdrawSeconds += actions[investor][totalActions - i].withdrawSeconds;
            k++;
        }

        if(newWithdrawSeconds + newCompoundSeconds > cwrAverageTime) {
            uint256 tooMuch = newWithdrawSeconds + newCompoundSeconds - cwrAverageTime;
            uint256 oldestCompound = actions[investor][totalActions - k].compoundSeconds;
            uint256 oldestWithdraw = actions[investor][totalActions - k].withdrawSeconds;
            uint256 factor = tooMuch * 1_000_000 / (oldestCompound + oldestWithdraw);
            newCompoundSeconds -= oldestCompound * factor / 1_000_000;
            newWithdrawSeconds -= oldestWithdraw * factor / 1_000_000;
        }

        uint256 newCwr = newCompoundSeconds  * 1000 / newWithdrawSeconds;
        return newCwr;
    }

    function totalActionsOfInvestor(address investor) public view returns (uint256) {
        return actions[investor].length;
    }

/////////////////// LAUNCH FUNCTIONS //////////////////////////////
    
    function migrateAccounts(address[] memory investors) external onlyArk {
        for(uint256 i=0; i < investors.length; i++) migrate(investors[i]);
    }

    function migrate(address investor) internal {
        if(upline[investor].length == 0) {
            principalBalance[investor] = oldVault.principalBalance(investor);
            airdropBalance[investor] = oldVault.airdropBalance(investor);
            deposits[investor] = oldVault.deposits(investor);
            newDeposits[investor] = oldVault.newDeposits(investor);
            out[investor] = oldVault.out(investor);
            postTaxOut[investor] = oldVault.postTaxOut(investor);
            roi[investor] = oldVault.roi(investor);
            cwr[investor] = oldVault.cwr(investor);
            tax[investor] = oldVault.tax(investor);
            penalized[investor] = oldVault.penalized(investor);
            compounds[investor] = oldVault.compounds(investor);
            withdrawn[investor] = oldVault.withdrawn(investor);
            airdropped[investor] = oldVault.airdropped(investor);
            airdroppedBefore[investor] = airdropped[investor];
            airdropsReceived[investor] = oldVault.airdropsReceived(investor);
            roundRobinRewards[investor] = oldVault.roundRobinRewards(investor);
            directRewards[investor] = oldVault.directRewards(investor);
            timeOfEntry[investor] = oldVault.timeOfEntry(investor);
            lastAction[investor] = oldVault.lastAction(investor);
            referrerOf[investor] = oldVault.referrerOf(investor);
            roundRobinPosition[investor] = oldVault.roundRobinPosition(investor);
            totalAccounts++;
            for(uint256 j=0; j < 15; j++) upline[investor].push(oldVault.upline(investor,j));
            Action memory currentAction;
            uint256 tempCwr = cwr[investor];
            currentAction.compoundSeconds = 14 days * tempCwr / (1000 + tempCwr);
            currentAction.withdrawSeconds = 14 days * 1000 / (1000 + tempCwr);
            actions[investor].push(currentAction);
            if(isEligible(investor,0)) addPlayer(investor);
            emit InvestorMigrated(investor);
        }
    }
    
    function regenerateUpline(address investor) external onlyArk {
        address referrer = referrerOf[investor];
        delete upline[investor];
        createUpline(investor, referrer);
    }

/////////////////// ADMIN FUNCTIONS //////////////////////////////
    function setArkWallet(address arkWallet, bool status) external onlyCEO {
        isArk[arkWallet] = status;
        emit ArkWalletSet(arkWallet, status);
    }

    function terminateAccount(address investor) external onlyCEO {
        principalBalance[investor] = 0;
    }    

    function fix(address investor, address oldInvestor, uint256 correctRoi) external onlyCEO {
        deposits[investor] -= compounds[oldInvestor];
        roi[investor] = correctRoi;
    }

    function migrateCompromisedAccount(address investor, address newInvestor) external onlyCEO {
        generateUpline(newInvestor, referrerOf[investor]);
        _deposit(newInvestor, principalBalance[investor]);
        withdrawn[newInvestor] = withdrawn[investor];
        compounds[newInvestor] = compounds[investor];
        deposits[newInvestor] -= compounds[investor];
        airdropsReceived[newInvestor] = airdropsReceived[investor];
        airdropBalance[newInvestor] = airdropBalance[investor];
        out[newInvestor] = out[investor];
        principalBalance[investor] = 0;
    }

    function changeReferrer(address investor, address newReferrer) external onlyCEO {
        referrerOf[investor] = newReferrer;
        for(uint256 i = 0; i < 15; i++) referrerAdded[investor][upline[investor][i]] = false;
        delete upline[investor];
        createUpline(investor, newReferrer);
    }

    function setPenalized(address investor, bool status) external onlyCEO {
        penalized[investor] = status;
        roi[investor] = status ? roiPenalized : roiNormal;
    }

    function setLegacyAddress(address legacyAddress) external onlyCEO {
        legacy = ILEGACY(legacyAddress);
        approveContracts(legacyAddress);
    }

    function setBondAddress(address bondAddress) external onlyCEO {
        bond = IBOND(bondAddress);
        approveContracts(bondAddress);
    }
    
    function setSwapAddress(address swapAddress) external onlyCEO {
        swap = ISWAP(swapAddress);
        approveContracts(swapAddress);
    }

    function approveContracts(address externalContract) internal {
        IBEP20(ARK).approve(address(externalContract), type(uint256).max);
        IBEP20(BUSD).approve(address(externalContract), type(uint256).max);
    }

    function setSparkPotPercent(uint256 percent) external onlyCEO {
        sparkPotPercent = percent;
    }

    function setDepositTaxes(uint256 percentTax, uint256 percentReferral) external onlyCEO {
        depositTax = percentTax;
        depositReferralTax = percentReferral;
    }

    function setBuyTaxes(uint256 buyPercent, uint256 buyReferralPercent, uint256 buySwapTax) external onlyCEO {
        buyTax = buyPercent;
        buyReferralTax = buyReferralPercent;
        swapBuyTax = buySwapTax;
    }

    function setMaxAndMinDeposit(uint256 minAmount, uint256 maxAmount) external onlyCEO {
        minDeposit = minAmount * MULTIPLIER;
        maxDeposit = maxAmount * MULTIPLIER;
    }

    function setRoi(uint256 penalizedPerMille, uint256 normalPerMille, uint256 reducedPerMille) external onlyCEO {
        roiPenalized = penalizedPerMille;
        roiNormal = normalPerMille;
        roiReduced = reducedPerMille;
    }

//////////////// SPARKPOT FUNCTIONS ///////////////////////////////////////

    function addSparkPlayer(address investor) external onlyArk {
        addPlayer(investor);
    }

    function addPlayer(address investor) internal {
        if(sparkPlayerAdded[investor]) return;
        sparkPlayers.push(investor);
        sparkPlayerAdded[investor] = true;
    }    

    function drawSparkWinner(uint256 sparkPercent, uint256 mvpPercent, address mvp, uint256 tries) external onlyArk {
        uint256 prizeMoney = sparkPot * sparkPercent / 100;
        uint256 mvpPrize = sparkPot * mvpPercent / 100;
        if(mvpPrize > 0) spark(mvp, mvpPrize, false);
        uint256[] memory randomNumbers = VRF.getRandomNumbers{value: 0.002 ether}(tries, sparkPlayers.length);
        address winner = getFirstEligibleWinner(randomNumbers);
        if(winner == address(0)) return;
        else spark(winner, prizeMoney, true);
    }

    function spark(address winner, uint256 amount, bool random) internal {
        _deposit(winner, amount);
        sparkPot -= amount;
        totalPrizeMoneyPaid += amount;
        totalWinners++;
        emit SparkWinnerPaid(winner, amount, totalWinners, block.timestamp, random);
    }

    function getFirstEligibleWinner(uint256[] memory randomNumbers) internal view returns(address) {
        address candidate;
        for(uint256 i=0; i < randomNumbers.length; i++) {
            candidate = sparkPlayers[randomNumbers[i]];
            if(isEligible(candidate, 0)) return candidate;
        }
        return address(0);
    }

//////////////// EMERGENCY FUNCTIONS ///////////////////////////////////////
    function approveNewContract(address token, address approvee) external onlyCEO {
        IBEP20(token).approve(approvee, type(uint256).max);
    }

    function rescueAnyToken(address tokenToRescue, uint256 percent) external onlyCEO {
        IBEP20(tokenToRescue).transfer(msg.sender, IBEP20(tokenToRescue).balanceOf(address(this)) * percent / 100);
    }

    function rescueBnb() external onlyCEO {
        (bool success,) = address(CEO).call{value: address(this).balance}("");
        require(success, "failed");
        emit BnbRescued();
    }
}