// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.7;

//import "hardhat/console.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";

// describes the logic of taxes
contract TaxContract {
    using PRBMathUD60x18 for uint256;

    event OnReward(address indexed account, uint256 value); // who and how much rewards received
    event OnTaxInterval(uint256 indexed number, uint256 poolSize, uint256 totalOnAccounts); // when the tax interval was changed

    // settings
    uint256 _TaxIntervalMinutes = 10080; // taxation interval (7 days)
    uint256 _ConstantTaxPercent = 1e16; // the constant component of the tax 100%=1e18 
    uint256 _MinBalancePercentTransactionForReward = 5e15; // minimal percentage of the balance that you need to spend to get a reward
    uint256 _RewardStopAccountPercent = 1e16; // at what percentage of the total issue (except for the router), at the time of transition to the new tax interval, the reward will become 0 (the reward drops when the wallet size approaches this percentage)
    uint256 _MaxTaxPercent = 1e17; // maximum tax percentage 100%=1e18

    mapping(address => uint256) _taxGettings; // time when account was collected fee last time
    mapping(address => uint256) _LastRewardedTransactions; // when were the last transactions made that could participate in receiving rewards (see the rule of min transaction size from the size of the wallet)
    uint256 _currentTaxPool; // how much tax fee collected in this tax getting interval
    uint256 internal _lastTaxPool; // how much tax fee collected in last tax getting interval
    uint256 _lastTaxTime; // last time when tax gettings interval was switched
    uint256 _lastTotalOnAccounts; // how much was on account at the time of completion of the previous tax collection
    uint256 _givedTax; // how many taxes were distributed (distributed from the pool of past taxation)
    uint256 _TaxIntervalNumber; // current tax getting interval number

    constructor() {
        _lastTaxTime = block.timestamp;
    }

    // sets the taxation settings
    function InitializeTax(
        uint256 taxIntervalMinutes,
        uint256 constantTaxPercent,
        uint256 minBalancePercentTransactionForReward,
        uint256 rewardStopAccountPercent,
        uint256 maxTaxPercent
    ) internal {
        _TaxIntervalMinutes = taxIntervalMinutes;
        _ConstantTaxPercent = constantTaxPercent;
        _MinBalancePercentTransactionForReward = minBalancePercentTransactionForReward;
        _RewardStopAccountPercent = rewardStopAccountPercent;
        _MaxTaxPercent = maxTaxPercent;
        _lastTaxTime = block.timestamp;
    }

    // when were the last transactions made that could participate in receiving rewards (see the rule of min transaction size from the size of the wallet)
    function GetLastRewardedTransactionTime(address account)
        public
        view
        returns (uint256)
    {
        return _LastRewardedTransactions[account];
    }

    // returns the time when the specified account received the tax or 0 if it did not receive the tax
    function GetLastRewardTime(address account) public view returns (uint256) {
        return _taxGettings[account];
    }

    // how many taxes were collected during the previous tax interval
    function GetLastTaxPool() public view returns (uint256) {
        return _lastTaxPool;
    }

    // returns the time when the last change of the tax interval occurred, or 0 if there was no change yet
    function GetLastTaxPoolTime() public view returns (uint256) {
        return _lastTaxTime;
    }

    // how much was on all accounts (except for the router) at the time of changing the tax interval
    function GetLastTotalOnAccounts() public view returns (uint256) {
        return _lastTotalOnAccounts;
    }

    //returns the currently set tax interval in days
    function GetTaxIntervalMinutes() public view returns (uint256) {
        return _TaxIntervalMinutes;
    }

    // min percentage of the balance that you need to spend to get a reward 1%=1e18 
    function GetMinBalancePercentTransactionForReward()
        public
        view
        returns (uint256)
    {
        return _MinBalancePercentTransactionForReward;
    }

    // how many taxes are collected for the current tax interval
    function GetCurrentTaxPool() public view returns (uint256) {
        return _currentTaxPool;
    }

    // how many taxes were distributed (distributed from the pool of past taxation)
    function GetGivedTax() public view returns (uint256) {
        return _givedTax;
    }

    // returns the current tax interval number
    // now everything is done taking into account the fact that 0 - until the zero tax interval passes, then 1, etc
    function GetTaxIntervalNumber() public view returns (uint256) {
        return _TaxIntervalNumber;
    }

    // how much in total is there an undisclosed tax
    function GetTotalTax() public view returns (uint256) {
        return _currentTaxPool + _lastTaxPool - _givedTax;
    }

    // attempt to switch to the next tax interval
    // tokensOnAccounts - how many tokens are there in total on all accounts subject to tax distribution (all except the router)
    function TryNextTaxInterval(uint256 tokensOnAccounts) internal {
        if (block.timestamp < _lastTaxTime + _TaxIntervalMinutes * 1 minutes) return;

        //console.log("NEXT_TIME");

        // we transfer all the collected for the distribution, plus what was not distributed
        _lastTaxPool = _lastTaxPool - _givedTax;
        _lastTaxPool += _currentTaxPool;
        // we reset the collection of funds and how much was issued
        _currentTaxPool = 0;
        _givedTax = 0;
        // we remember how much money the participants have in their hands (to calculate the share of each)
        _lastTotalOnAccounts = tokensOnAccounts;
        // we write the current date when the tax interval was changed
        _lastTaxTime = block.timestamp;
        // update the counter of tax intervals
        ++_TaxIntervalNumber;
        emit OnTaxInterval(_TaxIntervalNumber, _lastTaxPool, _lastTotalOnAccounts);
    }

    // adds the amount issued from the collected pool
    // if more than _lastTaxPool is added, it will add how much is missing to _lastTaxPool
    // returns how much was added
    function AddGivedTax(uint256 amount) internal returns (uint256) {
        uint256 last = _givedTax;
        _givedTax += amount;
        if (_givedTax > _lastTaxPool) _givedTax = _lastTaxPool;
        return _givedTax - last;
    }

    // adds a tax to the tax pool
    function AddTaxToPool(uint256 tax) internal {
        _currentTaxPool += tax;
    }

    // if true, then you can get a reward for the transaction
    function IsRewardedTransaction(
        uint256 accountBalance,
        uint256 transactionAmount
    ) public view returns (bool) {
        // if there was nothing on account, then he does not receive a reward
        if (accountBalance == 0) return false;
        // how many percent of the transaction from the total account balance
        uint256 accountTransactionPercent = PRBMathUD60x18.div(
            transactionAmount,
            accountBalance
        );
        return
            accountTransactionPercent >= _MinBalancePercentTransactionForReward;
    }

    // updates information about who has received awards and how much
    // throws the event OnReward, if there was a non-zero reward
    // returns how much tax the specified account should receive
    // returns 0 - if there is no reward
    // 1 tax interval, it will return the value >0 only once
    // accountBalance -  account balance
    // taxes are not distributed in the 0 tax interval
    function UpdateAccountReward(
        address account, // account
        uint256 accountBalance, // account balance
        uint256 transactionAmount // transfer amount
    ) internal returns (uint256) {
        // limiter if the time of the last receipt of tax is greater than or equal to the time of the last transition to a new taxation cycle
        if (account == address(0)) return 0;
        // if the transaction is less than min percent, it is not considered
        if (!IsRewardedTransaction(accountBalance, transactionAmount)) {
            //console.log("is not rewarded transaction!");
            return 0;
        }
        // we remember that we have completed a transaction that can participate in the distribution of rewards
        //console.log("rewarded transaction!");
        _LastRewardedTransactions[account] = block.timestamp;
        // limiter, if the account has already received a reward
        if (_taxGettings[account] >= _lastTaxTime + 1 days) return 0;
        // if 0 is the tax interval
        if (_TaxIntervalNumber == 0) return 0;
        // don't need it?
        if (_lastTotalOnAccounts == 0) return 0;
        // everything was distributed
        if (_givedTax >= _lastTaxPool) return 0; // if you have issued more than the tax pool, then we will not issue anything further
        // we write when I received a reward (or I didn't get it, because the limiters worked)
        _taxGettings[account] = block.timestamp;

        // how much interest did the account have at the time of changing the tax interval from the entire issue
        uint256 percentOfTotal = PRBMathUD60x18.div(
            accountBalance,
            _lastTotalOnAccounts
        );

        // calculate reward
        uint256 reward = PRBMathUD60x18.mul(percentOfTotal, _lastTaxPool);

        // calculation of the multiplication ratio of the tax (the closer the account to 1% of all accounts, the smaller the coefficient of those 1% = 0 0% = 1e18)
        reward = PRBMathUD60x18.mul(
            reward,
            GetRewardDynamicKoef(accountBalance)
        );

        // we increase the counter of the issued tax
        _givedTax += reward;
        //console.log("reward=", reward);
        if (reward > 0) emit OnReward(account, reward);
        return reward;
    }

    // returns the reward coefficient
    // when 0 of the total number of accounts
    // 0 - when 1% of the selected issue (on account)
    function GetRewardDynamicKoef(uint256 accountBalance)
        public
        view
        returns (uint256)
    {
        // how much interest did the account have at the time of changing the tax interval from the entire issue
        uint256 percentOfTotal = PRBMathUD60x18.div(
            accountBalance,
            _lastTotalOnAccounts
        );

        if (percentOfTotal >= _RewardStopAccountPercent) return 0;
        return
            1e18 -
            PRBMathUD60x18.div(percentOfTotal, _RewardStopAccountPercent);
    }

    // returns the tax on the specified number of tokens
    function GetTax(
        uint256 numTokens, // how much do we transfer
        uint256 accountBalance, // the balance on the account that transfers
        uint256 totalOnAccounts // the entire issue without an router
    ) public view returns (uint256) {
        // calculating the tax
        uint256 tax = GetStaticTax(numTokens) +
            GetDynamicTax(numTokens, accountBalance, totalOnAccounts);
        // limit the tax
        uint256 maxTax = PRBMathUD60x18.mul(numTokens, _MaxTaxPercent);
        if (tax > maxTax) tax = maxTax;
        // the results
        return tax;
    }

    // returns the static amount of the transaction tax
    function GetStaticTax(
        uint256 numTokens // how much do we transfer
    ) public view returns (uint256) {
        return PRBMathUD60x18.mul(numTokens, _ConstantTaxPercent);
    }

    // returns the dynamic component of the transaction tax
    function GetDynamicTax(
        uint256 numTokens, // how much do we transfer
        uint256 accountBalance, // the balance on the account that transfers
        uint256 totalOnAccounts // the entire emission without the router
    ) public pure returns (uint256) {
        // 0 if the total emission is 0
        if (totalOnAccounts == 0) return 0;

        // calculation of the dynamic component of the tax (100% of the total token will pay 100% from the top of the transaction size)
        // transaction size factor
        uint256 transactionK = PRBMathUD60x18.div(numTokens, totalOnAccounts);
        // adding a tax
        uint256 tax = PRBMathUD60x18.mul(transactionK, numTokens);

        // calculation of the dynamic component of the tax (depending on the size of the wallet, an account of 100% of the total token will pay 100% on top)
        transactionK = PRBMathUD60x18.div(accountBalance, totalOnAccounts);
        // adding a tax
        tax += PRBMathUD60x18.mul(transactionK, numTokens);

        // the results
        return tax;
    }

    // returns the percentage of the constant component of the tax 100%=1e18 
    function GetConstantTaxPercent() public view returns (uint256) {
        return _ConstantTaxPercent;
    }

    // returns the percentage at which the dynamic reward becomes  0 1e18=100%
    function GetRewardStopAccountPercent() public view returns (uint256) {
        return _RewardStopAccountPercent;
    }

    //     // maximum tax percentage 100%=1e18 

    function GetMaxTaxPercent() public view returns (uint256) {
        return _MaxTaxPercent;
    }
}