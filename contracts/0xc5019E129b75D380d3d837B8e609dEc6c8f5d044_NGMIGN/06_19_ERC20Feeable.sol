// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Rebaseable.sol";
import "./Ownable.sol";
import "../libraries/EnumerableSet.sol";
import "./Killable.sol";

abstract contract Structure is Ownable {
    enum TransactionState {Buy, Sell, Normal}
    enum TransactionType { FromExcluded, ToExcluded, BothExcluded, Standard }

    struct TState {
        address target;
        TransactionState state;
    }

}

abstract contract FeeStructure is Structure, Killable {

    event FeeAdded(TransactionState state, uint perc, string name);
    event FeeUpdated(TransactionState state, uint perc, uint index);
    event FeeRemoved(TransactionState state, uint index);
    
    uint internal _precisionFactor = 2; // how much to multiply the denominator by 

    mapping(TransactionState => uint[]) fees;

    mapping(TransactionState => uint) activeFeeCount;

    mapping(TransactionState => uint) totalFee;
    
    function fbl_calculateFeeSpecific(TransactionState state, uint index, uint256 amount) public view returns(uint256) {
        return amount * fees[state][index] / fbl_getFeeFactor();
    }

    function fbl_calculateStateFee(TransactionState state, uint256 amount) public view returns (uint256) {
        uint256 feeTotal;
        if(state == TransactionState.Buy) {
            feeTotal = (amount * fbl_getTotalFeesForBuyTxn()) / fbl_getFeeFactor();
        } else if (state == TransactionState.Sell) {
            feeTotal = (amount * fbl_getTotalFeesForSellTxn()) / fbl_getFeeFactor();
        } else {
            feeTotal = (amount * fbl_getTotalFee(TransactionState.Normal)) / fbl_getFeeFactor(); 
        }
        return feeTotal;
    }
    
    function _checkUnderLimit() internal view returns(bool) {
        // we check here all the fees to ensure that we don't have a scenario where one set of fees exceeds 33% 
        require(fbl_calculateStateFee(TransactionState.Sell, 100000)   <= 33333, "ERC20Feeable: Sell Hardcap of 33% reached");
        require(fbl_calculateStateFee(TransactionState.Buy, 100000)    <= 33333, "ERC20Feeable: Buy  Hardcap of 33% reached");
        require(fbl_calculateStateFee(TransactionState.Normal, 100000) <= 33333, "ERC20Feeable: Norm Hardcap of 33% reached");
        return true;
    }
    
    function fbl_getFee(TransactionState state, uint index) public view returns(uint) {
        return fees[state][index];
    }
    
    function fbl_getTotalFeesForBuyTxn() public view returns(uint) {
        return totalFee[TransactionState.Normal] + totalFee[TransactionState.Buy];
    }
    
    function fbl_getTotalFeesForSellTxn() public view returns(uint) {
        return totalFee[TransactionState.Normal] + totalFee[TransactionState.Sell];
    }
    
    function fbl_getTotalFee(TransactionState state) public view returns(uint) {
        return totalFee[state];
    }
    
    /* @dev when you increase this that means all fees are reduced by whatever this factor is. 
    *  eg. 2% fee, 1 dF = 2% fee 
    *  vs  2% fee  2 dF = 0.2% fee 
    *  TLDR; increase this when you want more precision for decimals 
    */
    function fbl_getFeeFactor() public view returns(uint) {
        return 10 ** _precisionFactor;
    }

    // can be changed to external if you don't need to add fees during initialization of a contract 
    function fbl_feeAdd(TransactionState state, uint perc, string memory label) public
        onlyOwner
        activeFunction(20)
    {
        fees[state].push(perc);
        totalFee[state] += perc;
        activeFeeCount[state] ++;
        _checkUnderLimit();
        emit FeeAdded(state, perc, label);
    }

    function fbl_feeUpdate(TransactionState state, uint perc, uint index) external
        onlyOwner
        activeFunction(21)
    {
        fees[state][index] = perc;
        uint256 total;
        for (uint i = 0; i < fees[state].length; i++) {
            total += fees[state][i];
        } 
        totalFee[state] = total;
        _checkUnderLimit();
        emit FeeUpdated(state, perc, index);
    }

    /* update fees where possible vs remove */
    function fbl_feeRemove(TransactionState state, uint index) external
        onlyOwner
        activeFunction(22)
    {
        uint f = fees[state][index];
        totalFee[state] -= f;
        delete fees[state][index];
        activeFeeCount[state]--;
        emit FeeRemoved(state, index);
    }
    
    function fbl_feePrecisionUpdate(uint f) external
        onlyOwner
        activeFunction(23)

    {
        require(f != 0, "can't divide by 0");
        _precisionFactor = f;
        _checkUnderLimit();
    }

}

abstract contract TransactionStructure is Structure {

    /*
    * @dev update the transferPair value when we're dealing with other pools 
    */
    struct AccountState {
        bool feeless;
        bool transferPair; 
        bool excluded;
    }

    mapping(address => AccountState) internal _accountStates;

    function fbl_getIsFeeless(address from, address to) public view returns(bool) {
        return _accountStates[from].feeless || _accountStates[to].feeless;
    }

    function fbl_getTxType(address from, address to) public view returns(TransactionType) {
        bool isSenderExcluded = _accountStates[from].excluded;
        bool isRecipientExcluded = _accountStates[to].excluded;
        if (!isSenderExcluded && !isRecipientExcluded) {
            return TransactionType.Standard;
        } else if (isSenderExcluded && !isRecipientExcluded) {
            return TransactionType.FromExcluded;
        } else if (!isSenderExcluded && isRecipientExcluded) {
            return TransactionType.ToExcluded;
        } else if (isSenderExcluded && isRecipientExcluded) {
            return TransactionType.BothExcluded;
        } else {
            return TransactionType.Standard;
        }
    }

    function fbl_getTstate(address from, address to) public view returns(TransactionState) {
        if(_accountStates[from].transferPair == true) {
            return TransactionState.Buy;
        } else if(_accountStates[to].transferPair == true) {
            return TransactionState.Sell;
        } else {
            return TransactionState.Normal;
        }
    }

    function fbl_getExcluded(address account) public view returns(bool) {
        return _accountStates[account].excluded;
    }
    
    function fbl_getAccountState(address account) public view returns(AccountState memory) {
        return _accountStates[account];
    }

    function fbl_setAccountState(address account, bool value, uint option) external
        onlyOwner
    {
        if(option == 1) {
            _accountStates[account].feeless = value;
        } else if(option == 2) {
            _accountStates[account].transferPair = value;
        } else if(option == 3) {
            _accountStates[account].excluded = value;
        }
    }
}

/*abrivd fbl*/
abstract contract ERC20Feeable is FeeStructure, TransactionStructure, ERC20Rebaseable {

    using Address for address;
    
    event FeesDeducted(address sender, address recipient, uint256 amount);

    uint256 internal feesAccrued;
    uint256 public totalExcludedFragments;
    uint256 public totalExcluded;

    mapping(address => uint256) internal feesAccruedByUser;

    EnumerableSet.AddressSet excludedAccounts;

    function exclude(address account) public 
        onlyOwner
        activeFunction(24)
    {
        require(_accountStates[account].excluded == false, "Account is already excluded");
        _accountStates[account].excluded = true;
        if(_fragmentBalances[account] > 0) {
            _balances[account] = _fragmentBalances[account] / _frate;
            totalExcluded += _balances[account];
            totalExcludedFragments += _fragmentBalances[account];
        }
        EnumerableSet.add(excludedAccounts, account);
        _frate = fragmentsPerToken();
    }

    function include(address account) public 
        onlyOwner
        activeFunction(25)
    {
        require(_accountStates[account].excluded == true, "Account is already included");
        _accountStates[account].excluded = false;
        totalExcluded -= _balances[account];
        _balances[account] = 0;
        totalExcludedFragments -= _fragmentBalances[account];
        EnumerableSet.remove(excludedAccounts, account);
        _frate = fragmentsPerToken();
    }

    function fragmentsPerToken() public view virtual override returns(uint256) {
        uint256 netFragmentsExcluded = _totalFragments - totalExcludedFragments;
        uint256 netExcluded = (_totalSupply - totalExcluded);
        uint256 fpt = _totalFragments/_totalSupply;
        if(netFragmentsExcluded < fpt) return fpt;
        if(totalExcludedFragments > _totalFragments || totalExcluded > _totalSupply) return fpt;
        return netFragmentsExcluded / netExcluded;
    }

    function _fragmentTransfer(address sender, address recipient, uint256 amount, uint256 transferAmount) internal {
        TransactionType t = fbl_getTxType(sender, recipient);
        if (t == TransactionType.ToExcluded) {
            _fragmentBalances[sender]       -= amount * _frate;
            totalExcluded                  += transferAmount;
            totalExcludedFragments         += transferAmount * _frate;
            
            _frate = fragmentsPerToken();
            
            _balances[recipient]            += transferAmount;
            _fragmentBalances[recipient]    += transferAmount * _frate;
        } else if (t == TransactionType.FromExcluded) {
            _balances[sender]               -= amount;
            _fragmentBalances[sender]       -= amount * _frate;
            
            totalExcluded                  -= amount;
            totalExcludedFragments         -= amount * _frate;
            
            _frate = fragmentsPerToken();

            _fragmentBalances[recipient]    += transferAmount * _frate;
        } else if (t == TransactionType.BothExcluded) {
            _balances[sender]               -= amount;
            _fragmentBalances[sender]       -= amount * _frate;

            _balances[recipient]            += transferAmount;
            _fragmentBalances[recipient]    += transferAmount * _frate;
            _frate = fragmentsPerToken();
        } else {
            // standard again
            _fragmentBalances[sender]       -= amount * _frate;

            _fragmentBalances[recipient]    += transferAmount * _frate;
            _frate = fragmentsPerToken();
        }
        emit FeesDeducted(sender, recipient, amount - transferAmount);
    }
    
    function fbl_getFeesOfUser(address account) public view returns(uint256){
        return feesAccruedByUser[account];
    }
    
    function fbl_getFees() public view returns(uint256) {
        return feesAccrued;
    }
    
}