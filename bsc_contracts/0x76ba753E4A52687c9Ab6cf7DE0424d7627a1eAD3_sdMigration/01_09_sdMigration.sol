//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;

import "../interfaces/AppStorage.sol";
import "../interfaces/Interfaces.sol";
import "../libraries/LibDiamond.sol";

///@title simpleDefi.sol
///@author Derrick Bradbury ([email protected])
///@notice Common simpleDefi functions not specific to pool/solo contracts
interface tLPToken{
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);    
    function transfer(address to, uint value) external returns (bool);
}
contract sdMigration {
    AppStorage internal s;

    event sdSetMigration(address _address);
    event sdTransactionLog(bool _deposit, uint amount, uint timestamp, address account);
    event sdHolder(address _user, uint amount, uint holdback, uint depositDate, uint discount, uint discountValidTo, uint accumulatedRewards, uint _pos);
    event sdLiquidityReceived(uint _amount);

    error sdInvalidAddress(address _address);
    error sdContractInitialized();

    struct simpleMigration {
        address user;
        uint amount;
    }

    struct migration {
        address user;
        uint amount;
        uint holdback;
        uint depositDate;
        uint discount;
        uint discountValidTo;    
        uint accumulatedRewards;    
    }

    modifier godUser {
        require(s.godUsers[msg.sender] == true, "Locked function");
        _;
    }

    modifier migrator {
        if(msg.sender != s.migrateFrom) revert sdInvalidAddress(msg.sender);
        _;
    }

    ///@notice Sets contract to receive migrations from source contract
    ///@param _fromContract contract to accept connections from
    function migrateTo(address _fromContract, uint _lastProcess) public returns (bool){ 
        if(!s.godUsers[tx.origin]) revert sdInvalidAddress(_fromContract);
        if(_fromContract == address(0)) revert sdInvalidAddress(_fromContract);
        if(s.iQueue.length > 0) revert sdContractInitialized();

        s.migrateFrom = _fromContract;
        s.iData.lastProcess = _lastProcess;
        emit sdSetMigration(_fromContract);
        return true;
    }


    ///@notice send full migration to destination contract
    ///@param _addr contract to send data to
    ///@param _sendLP flag to transfer LP balance from farm
    ///@param _setMigrator flag to set migration address in destination contract

    function migrationSend(address _addr, bool _sendLP, bool _setMigrator) public godUser {
        if (_setMigrator) setMigrator(_addr);
        for(uint i =0; i < s.iQueue.length;i++) {
            address _tmp = s.iQueue[i];
            if (_tmp == address(0)) continue;        
            sHolders memory _holder = s.iHolders[_tmp];
            sdMigration(_addr).migrationReceive(migration(
                _tmp,
                _holder.amount,
                _holder.holdback,
                _holder.depositDate,
                _holder.discount,
                _holder.discountValidTo,
                _holder.accumulatedRewards
            ));
            s.iHolders[_tmp].amount = 0;
        }
        dumpTranslog(_addr);
        if(_sendLP) transferLiquidity(_addr);
        sdMigration(_addr).migrationReceive(migration(address(0),0,0,0,0,0,0));
        updatePoolTotal();
    }

    ///@notice send partial migration to destination contract
    ///@param _addr contract to send data to
    ///@param _sendLP flag to transfer LP balance from farm
    ///@param _setMigrator flag to set migration address in destination contract
    function migrationSimpleSend(address _addr, bool _sendLP, bool _setMigrator) public godUser {
        if (_setMigrator) setMigrator(_addr);
        for(uint i =0; i < s.iQueue.length;i++) {
            if (s.iQueue[i] == address(0)) continue;
            sdMigration(_addr).simpleMigrationReceive(simpleMigration(s.iQueue[i],s.iHolders[s.iQueue[i]].amount));
            s.iHolders[s.iQueue[i]].amount = 0;
        }
        // Indicate last record has been sent, and clear out migration address
        dumpTranslog(_addr);
        if(_sendLP) transferLiquidity(_addr);
        sdMigration(_addr).simpleMigrationReceive(simpleMigration(address(0),0));
        updatePoolTotal();
    }

    ///@notice receive full migration from source contract
    ///@param _user - full migration structure
    function migrationReceive(migration memory _user) public  migrator {
        addUser(_user);
    }

    ///@notice receive partial migration from source contract
    ///@param _user - full migration structure
    function simpleMigrationReceive(simpleMigration memory _user) public migrator {
        addUser(migration(
            _user.user,
            _user.amount,
            0,
            0,
            0,
            0,
            0
        ));
    }

    ///@notice receive transaction log from source contract, and store locally
    function receiveTranslog(transHolders calldata _th) public migrator{
        if (_th.deposit)
            s.iData.depositTotal += _th.amount;
        else
            s.iData.withdrawTotal += _th.amount;

        s.transactionLog.push(_th);    
    }

    ///@notice update internal pool total with balance of LP tokens from masterchef contract
    function updatePoolTotal() internal {
        (uint _bal,) =  iMasterChef(s.exchangeInfo.chefContract).userInfo(s.iData.poolId,address(this));
        s.iData.poolTotal = _bal;
    }

    

    ///@notice - set contract to allow migrations
    function setMigrator(address _addr) internal {
        // use delegate call as only "god" user can call the migrateFrom function
        (bool success, ) = _addr.delegatecall(abi.encodeWithSignature("migrateTo(address,uint256)", address(this),s.iData.lastProcess));
        if (!success) revert sdInvalidAddress(_addr);
    }

    ///@notice - send transaction log to external contract
    ///@param _addr - contract to send log to
    function dumpTranslog(address _addr) internal {
        for(uint i = 0; i < s.transactionLog.length; i++) {
            if (_addr != address(0) && s.transactionLog[i].account != address(0)) sdMigration(_addr).receiveTranslog(s.transactionLog[i]);
            emit sdTransactionLog(s.transactionLog[i].deposit,s.transactionLog[i].amount, s.transactionLog[i].timestamp, s.transactionLog[i].account);
        }
    }

    ///@notice - transfer current liquidity from current contract to destination contract
    ///@param _addr - contract ot send liquidity to
    function transferLiquidity(address _addr) private returns (uint _lpBal){
        (_lpBal,) = iMasterChef(s.exchangeInfo.chefContract).userInfo(s.iData.poolId,address(this));
        iMasterChef(s.exchangeInfo.chefContract).withdraw(s.iData.poolId,_lpBal);
        tLPToken(s.iData.lpContract).transfer(_addr,_lpBal);
    }


    ///@notice - add user to current contract's structure, if user && amount is 0 remove the migrateFrom to finish off the contract.
    ///@param _user - structure of user "account" added to contract
    ///@dev - address of 0 & amount of 0 triggers a wrapup of migration
    function addUser(migration memory _user) internal {
        if (_user.user == address(0) && _user.amount == 0) {
            s.migrateFrom = address(0);
            uint _lpBal = tLPToken(s.iData.lpContract).balanceOf(address(this));
            emit sdLiquidityReceived(_lpBal);
            iMasterChef(s.exchangeInfo.chefContract).deposit(s.iData.poolId,_lpBal);
            updatePoolTotal();
        }
        else {
            s.iQueue.push(_user.user);
            s.iHolders[_user.user] = sHolders(
                _user.amount,
                _user.holdback,
                _user.depositDate,
                _user.discount,
                _user.discountValidTo,
                _user.accumulatedRewards,
                s.iQueue.length - 1
            );

            emit sdHolder(_user.user, _user.amount, _user.holdback, _user.depositDate, _user.discount, _user.discountValidTo, _user.accumulatedRewards, s.iQueue.length-1);
        }
    }
}