// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.7;

//mport "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "contracts/TaxContract.sol";

// describes the Limbo of the contract
contract LimboContract is ERC20, TaxContract {
    using PRBMathUD60x18 for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // settings
    uint256 constant LIMBO_MINING_ITERATIONS = 10; // maximum number of Limbo mining iterations per transaction
    uint256 constant MIN_BALANCE_ON_LIMBO = 777; // min account balance when in Limbo
    uint256 constant TAX_ITERATIONS_FOR_LIMBO_DETECT = 12; // how many tax intervals should be missed for the account to get in Limbo
    uint256 constant LIMBO_BACK_KOEF = 10e18; // the coefficient; the bigger wallet will be restored slower 

    // Limbo events
    event OnAddLimbo(address indexed account, uint256 count); // who went to the Limbo and for how long
    event OnLimboRestore(address indexed account, uint256 value); // who and how many recovered from it
    event OnLimboState(address indexed account, bool value); // who and what ia their Limbo state(in limbo/not in limbo)
    event OnLimboMining(address indexed account, uint256 value); // who is going to be found

    address[] _SetOfAccounts; // an array of all accounts, for iterations of Limbo mining
    mapping(address => bool) _existInSet; // if true, the address was added to the set of all accounts
    uint256 _limboMiningPos = 0; // the position of the mining algorithm in the list of all known accounts
    uint256 _limboTotal; // total Limbo of all accounts
    mapping(address => uint256) _limbo; // key = account, value - how much was burned in Limbo
    mapping(address => bool) _limboState; // if true, then the account is in Limbo (it is not possible to say unequivocally about the state of limbo from the limbo column - maybe the acc is being restored at the moment)
    mapping(address => uint256) _personalLimbo; // amounts to burn when limit of tokens on account is reached

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    // makes an attempt to send a certain amount of token to Limbo
    // returns how many tokens were burned in Limbo
    // the miner does not mine itself
    function LimboMining(address miner, uint256 burnCount)
        internal
        returns (uint256)
    {
        // if there were no tax intervals then Limbo is not available
        if (GetTaxIntervalNumber() < TAX_ITERATIONS_FOR_LIMBO_DETECT) return 0;
        // determine the number of mining iterations
        uint256 miningCount = LIMBO_MINING_ITERATIONS + 1; // counter of remaining iterations
        uint256 startPos = _limboMiningPos; // start position
        uint256 burnInLimbo = 0; // how much burnt in limbo
        // start the mining cycle miningCount times
        while (--miningCount > 0 && burnInLimbo < burnCount) {
            // we take the account address
            address adr = _SetOfAccounts[_limboMiningPos];
            // make sure it will not mine itself
            if (adr == miner) {
                _limboMiningPos++;
                continue;
            }
            // processing accounts that are in limbo
            if (IsNeedAccountInLimbo(adr))
                burnInLimbo += AddLimboToAccount(adr, burnCount - burnInLimbo);
            // cutter if everything that needs to be burned (so that the trail of the account is not searched until this one is burned)
            if (burnInLimbo >= burnCount) break;
            // go to next iteration
            _limboMiningPos++;
            if (_limboMiningPos >= _SetOfAccounts.length) _limboMiningPos = 0;
            // if the same position taken (bypassed everyone), then we stop the cycle
            if (_limboMiningPos == startPos) break;
        }
        if (burnInLimbo > 0) emit OnLimboMining(miner, burnInLimbo);
        return burnInLimbo;
    }

    // adds a limbo to the account, the specified max amount of the token
    // returns how much was added
    // if the account was added to the Limbo, then _limboState[account] = true; (it is marked as an account located in Limbo)
    function AddLimboToAccount(address account, uint256 maxCount)
        internal
        returns (uint256)
    {
        // we determine how much can be added to the Limbo
        uint256 canAddToLimbo = GetMaxAddToLimbo(account);
        // if the request to add more than the max value, then we adjust the request
        if (maxCount > canAddToLimbo) maxCount = canAddToLimbo;
        // limiter if nothing is added to the Limbo
        if (maxCount == 0) return 0;
        // inform that the account is in the Limbo
        if (!_limboState[account]) {
            _limboState[account] = true;
            emit OnLimboState(account, true);
        }
        // we are writing a new amount of Limbo on the account
        _limbo[account] = _limbo[account] + maxCount;
        // adding total limbo
        _limboTotal += maxCount;
        // burn
        _burn(account, maxCount);
        // we inform you that the account has true Limbo state
        emit OnAddLimbo(account, maxCount);
        // we output the result - how much was added to the Limbo
        return maxCount;
    }

    // performs recovery from Limbo for the specified max amount of token
    // returns how much was restored from limbo
    // if at least something from the Limbo was returned, the account state will change to the state outside of Limbo ( _limboState[account] = false)
    function LimboRestore(address account, uint256 maxCount)
        internal
        returns (uint256)
    {
        // we take the size of the Limbo on the account
        uint256 accountLimbo = _limbo[account];
        // limiter if there is no limbo or the request is 0 (nothing is restored)
        if (accountLimbo == 0 || maxCount == 0) return 0;
        // if the request for a refund is greater than the limit on the acc then we adjust the request
        if (maxCount > accountLimbo) maxCount = accountLimbo;
        // we inform you that the account has false Limbo state
        if (_limboState[account]) {
            _limboState[account] = false;
            emit OnLimboState(account, false);
        }
        // we are writing a new amount of the Limbo on the account
        _limbo[account] = accountLimbo - maxCount;
        // taking away the total Limbo
        _limboTotal -= maxCount;
        // mint to account
        _mint(account, maxCount);
        // when account leaves the Limbo
        emit OnLimboRestore(account, maxCount);
        // we output the results - how much was restored from the Limbo
        return maxCount;
    }

    // attempt to get a reward and get out of the Limbo
    // you can't pass the address of the router here
    function TryGetRewardAndLimboOut(
        address account, // account
        uint256 transactionAmount // transaction size
    ) internal {
        // limiter
        if (account == address(0)) return;
        // we take the reward from the tax pool
        uint256 reward = UpdateAccountReward(
            account,
            balanceOf(account),
            transactionAmount
        );
        // we get a reward
        if (reward != 0) _mint(account, reward);

        // we determine how much is need to be returned from the Limbo
        uint256 limboRestore = PRBMathUD60x18.mul(
            reward + transactionAmount,
            LIMBO_BACK_KOEF
        );
        // limbo account size limiter
        uint256 accountLimbo = _limbo[account];
        if (limboRestore > accountLimbo) limboRestore = accountLimbo;
        // we take as much as we can from the pool
        limboRestore = AddGivedTax(limboRestore);
        // we return from the Limbo as much as possible from this amount
        LimboRestore(account, limboRestore);
    }

    // makes an attempt to set an account to the list of known ones, for mining Limbo
    // 0 address will not be added
    function TryAddToAccountList(address account) internal {
        if (account == address(0) || _existInSet[account]) return;
        _existInSet[account] = true;
        _SetOfAccounts.push(account);
    }

    // returns how much can be sent to the Limbo for the specified account
    function GetMaxAddToLimbo(address account) public view returns (uint256) {
        if (account == address(0)) return 0;
        // we take the current balance
        uint256 balance = balanceOf(account);
        // if the balance is less than min possible
        if (balance <= MIN_BALANCE_ON_LIMBO) return 0;
        // if the balance is more than mines possible
        return balance - MIN_BALANCE_ON_LIMBO;
    }

    // returns the minimum balance of the account
    function GetMinBalanceOnLimbo() public pure returns (uint256) {
        return MIN_BALANCE_ON_LIMBO;
    }

    // checks whether the account needs to go to the Limbo
    // the account is not necessarily in the Limbo - this only indicates that it can be mined and go to the Limbo
    function IsNeedAccountInLimbo(address account) public view returns (bool) {
        // if the account must be in limbo
        if (account == address(0)) return false;
        if (GetTaxIntervalNumber() < TAX_ITERATIONS_FOR_LIMBO_DETECT)
            return false;
        // if the intervals are more than critical, then it should be in Limbo
        return
            GetLastRewardedTransactionTime(account) +
                (GetTaxIntervalMinutes() * 1 minutes) *
                TAX_ITERATIONS_FOR_LIMBO_DETECT <
            GetLastTaxPoolTime();
    }

    function IsAccountInLimbo(address account) public view returns (bool) {
        // is the account in Limbo?
        if (account == address(0)) return false;
        return _limboState[account];
    }

    // returns the total Limbo of the contract
    function GetLimboTotal() public view returns (uint256) {
        return _limboTotal;
    }

    // returns the total Limbo for the account
    function GetLimbo(address account) public view returns (uint256) {
        return _limbo[account];
    }

    // returns the Limbo state for the account
    function GetLimboState(address account) public view returns (bool) {
        return _limboState[account];
    }

    // returns the number of intarvals of taxation you need to skip to get to the Limbo
    function GetTaxIterationsForLimboDetect() public pure returns (uint256) {
        return TAX_ITERATIONS_FOR_LIMBO_DETECT;
    }
}