//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;

import "../interfaces/AppStorage.sol";
import "../interfaces/Interfaces.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/sdPoolUtil.sol";

///@title simpleDefi.sol
///@author Derrick Bradbury ([email protected])
///@notice Common simpleDefi functions not specific to pool/solo contracts
contract sdDepositFunds  {
    AppStorage internal s;

    event sdFeeSent(address _user, bytes16 _type, uint amount, uint total);
    event addFunds_evt(address _user, uint _amount);
    event sdDeposit(uint amount);

    error sdFunctionLocked();
    error sdDepositNotAllowed();
    error sdInsufficentFunds();

    modifier allowAdmin() {
        if(!s.adminUsers[msg.sender]) {
            LibDiamond.enforceIsContractOwner();
        }
        _;
    }
    ///@notice Prevent function from being run twice
    modifier lockFunction() {
        if (s._locked == true) revert sdFunctionLocked();
        s._locked = true;
        _;
        s._locked = false;
    }

    ///@notice Add depoist to specific user
    ///@dev called during the swap pool function
    ///@param _user address of user to add
    ///@dev emits "sdDeposit" with amount deposited 
    function deposit(address _user) public payable lockFunction {
        if (s.paused == true) revert sdDepositNotAllowed();
        if(msg.value < 1e16) revert sdInsufficentFunds(); //prevent an attack with tiny amounts
        
        sdPoolUtil.addFunds(s, addFunds(msg.value,_user,true),_user);
 
        emit sdDeposit(msg.value);
    }


    ///@notice Add funds to user
    ///@dev uses msg.value and msg.sender to add deposit
    function deposit() external payable {
        deposit(msg.sender);
    }


    ///@notice Add funds to a held pool from a user
    ///@param _amount amount to add for user into staking
    ///@param _user user account to add funds to
    ///@return Amount to be invested
    ///@dev Emits addFunds_evt to notify funds being added
    function initDeposit(uint _amount, address _user) internal returns (uint) {
        require(!s.iData.paused,"Deposits are Paused");

        if(s.iHolders[_user].depositDate == 0) {
            s.iQueue.push(_user);
            s.iHolders[_user]._pos = s.iQueue.length-1;
        }

        if (_user != address(0)) {
            (uint fee,) = iBeacon(s.iData.beaconContract).getFee('DEFAULT','DEPOSITFEE',address(_user));

            if (fee > 0) {
                    uint feeAmount = ((_amount * fee)/100e18);
                    _amount = _amount - feeAmount;
                    payable(s.iData.feeCollector).transfer(feeAmount);
                    emit sdFeeSent(_user, "DEPOSITFEE", feeAmount,_amount);
            }
        }
        return _amount;
    }

    ///@notice Invest funds into pool
    ///@param inValue amount of money to add into the external pool
    ///@dev take in BNB, split it across the 2 tokens and add the liquidity

    function addFunds(uint inValue, address _user, bool _deposit) private returns (uint liquidity){
        if(inValue <= 10) revert sdInsufficentFunds();
        uint split;
        uint amount0;
        uint amount1;
        if (s.iData.lastProcess == 0) s.iData.lastProcess = block.timestamp;

        if (_user != address(0)) {
            inValue = sdPoolUtil.initDeposit(s, inValue,_user);
        }

        if (s.iData.token0 == WBNB_ADDR || s.iData.token1 == WBNB_ADDR) {
            split = inValue/2;
            amount0 = (s.iData.token0 != WBNB_ADDR) ? swap(split,WBNB_ADDR,s.iData.token0) : split;    
            amount1 = (s.iData.token1 != WBNB_ADDR) ? swap(split,WBNB_ADDR,s.iData.token1) : split;
        }
        else {
            amount0 = swap(inValue,WBNB_ADDR,s.iData.token0);    
            split = amount0/2;
            split = split - ((split*(s.SwapFee/100))/1e8);                 
            amount1 = swap(split,s.iData.token0,s.iData.token1);
            amount0 = split;
        }

        liquidity = sdPoolUtil.addLiquidity(s,amount0,amount1,_deposit);
    }


    ///@notice Adds funds to user account, and creates entry in transaction log    
    ///@param _amount amount to add to user account
    ///@param _user user account to add funds to
    function addFunds(uint _amount, address _user) internal {
        transHolders memory _tmp;
        _tmp.deposit = true;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;

        s.transactionLog.push(_tmp);
        s.iHolders[_user].depositDate = block.timestamp>s.iData.lastProcess?block.timestamp:s.iData.lastProcess; //set users last deposit date
        s.iHolders[_user].amount += _amount; //add funds to user account

        s.iData.depositTotal += _amount;

        emit addFunds_evt(_user, _amount);
    }

    ///@notice take amountIn for _token0 and swap for _token1
    ///@param amountIn amount of _token0
    ///@param _token0 address of first token (amountIn source)
    ///@param _token1 address of destination token
    ///@dev generates path, and passes of to overloaded swap function
    ///@return resulting amount of token1 swapped 
    function swap(uint amountIn, address _token0, address _token1) internal returns (uint){
        return sdPoolUtil.swap(s, amountIn,[_token0,_token1]);
    }

}