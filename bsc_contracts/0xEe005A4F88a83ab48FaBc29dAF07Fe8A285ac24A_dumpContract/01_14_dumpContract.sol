//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
import "./Interfaces.sol";
import "./Storage.sol";

interface tLPToken{
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);    
    function transfer(address to, uint value) external returns (bool);
}

interface migrateContract{
      struct migration {
          address user;
          uint amount;
          uint holdback;
          uint depositDate;
          uint discount;
          uint discountValidTo;    
          uint accumulatedRewards;    
      }

      function receiveTranslog(transHolders calldata _th) external;
      function migrationReceive(migration memory _user) external;
}

contract dumpContract is Storage, Ownable, AccessControl {
  event sdTransactionLog(bool _deposit, uint amount, uint timestamp, address account);
  event sdHolder(uint i, address _user, uint amount, uint holdback, uint depositDate, uint discount, uint discountValidTo, uint accumulatedRewards, uint _pos);
  event sdLiquidityReceived(uint _amount);

  error sdFunctionLocked();
  struct transLog {
    bool deposit;
    uint amount;
    uint timestamp;
    address account;
  }

  modifier allowAdmin() {
    if (!(hasRole(DEFAULT_ADMIN_ROLE,msg.sender) || owner() == msg.sender)) revert sdFunctionLocked();
    _;
  }

  function addMigrator(address _address) public allowAdmin {
    _setupRole(DEFAULT_ADMIN_ROLE,_address);
  }

  function lpContract() public view returns (address) {
    return iData.lpContract;
  }

  function migrate() public allowAdmin {
    for(uint i = 0; i < mHolders.transactionLog.length; i++) {
      if(mHolders.transactionLog[i].deposit) {
        mHolders.iHolders[mHolders.transactionLog[i].account].amount += mHolders.transactionLog[i].amount;
      } else {
        mHolders.iHolders[mHolders.transactionLog[i].account].amount = 0;
      }
    }

    for(uint i = 0; i < mHolders.iQueue.length; i++) {
      address _user = mHolders.iQueue[i];
      if(mHolders.iHolders[_user].amount > 0) {
        sHolders memory holder = mHolders.iHolders[_user];

        emit sdHolder(i, _user, holder.amount, holder.holdback, holder.depositDate, holder.discount, holder.discountValidTo, holder.accumulatedRewards, holder._pos);
      }
    }
    emit sdLiquidityReceived(0);
  }

  function dumpTest() public allowAdmin {
    dump(address(0),true);
  }

  function dump(address _to, bool _same) public allowAdmin {
    // if (this.logic_contract != dumpContract(_to).logic_contract) _to = address(0);
    
    if (_to != address(0) && _same && iData.lpContract != dumpContract(_to).lpContract()) revert ("lpContract mismatch");
    if (!_same) setMigrator(_to);
    
    for (uint i = 0; i < mHolders.iQueue.length; i++) {
      address _user = mHolders.iQueue[i];
      sHolders memory holder = mHolders.iHolders[_user];
      if (_to != address(0)) 
        if (_same) 
          dumpContract(_to).receive_user(_user,holder);
        else {
            migrateContract(_to).migrationReceive(migrateContract.migration(
                _user,
                holder.amount,
                holder.holdback,
                holder.depositDate,
                holder.discount,
                holder.discountValidTo,
                holder.accumulatedRewards
            ));
        }

      emit sdHolder(i, _user, holder.amount, holder.holdback, holder.depositDate, holder.discount, holder.discountValidTo, holder.accumulatedRewards, holder._pos);
    }

    for(uint i = 0; i < mHolders.transactionLog.length; i++) {
      if (_to != address(0) && mHolders.transactionLog[i].account != address(0)) 
        if (_same) 
          dumpContract(_to).receive_translog(mHolders.transactionLog[i]);
        else
          migrateContract(_to).receiveTranslog(mHolders.transactionLog[i]);

      emit sdTransactionLog(mHolders.transactionLog[i].deposit,mHolders.transactionLog[i].amount, mHolders.transactionLog[i].timestamp, mHolders.transactionLog[i].account);
    }


    if (_to != address(0)) {
      uint _lpbal = transferLiquidity(_to);
      if (_lpbal > 0) {
        if (_same) {
          dumpContract(_to).depositLiquidity();
          dumpContract(_to).setPoolTotal(iData.poolTotal,iData.dust, iData.lastProcess, iData.lastDiscount);
        }
        else {
          migrateContract(_to).migrationReceive(migrateContract.migration(address(0),0,0,0,0,0,0));
        }
      }
    }
    if (_same) dumpContract(_to).reset_logic();
  }

  ///@notice - set contract to allow migrations
  function setMigrator(address _addr) internal {
      // use delegate call as only "god" user can call the migrateFrom function
      (bool success, ) = _addr.call(abi.encodeWithSignature("migrateTo(address,uint256)", address(this),iData.lastProcess));
      require(success,"Migrator not setup!!");
  }

  function reset_logic() public allowAdmin {
    logic_contract = iBeacon(beaconContract).getExchange("MULTIEXCHANGEPOOLED");
  }

  function receive_translog(transHolders calldata _th) public allowAdmin{
    transHolders memory _tmp;
    _tmp.deposit = _th.deposit;
    _tmp.amount = _th.amount;
    _tmp.account = _th.account;
    _tmp.timestamp = _th.timestamp;

    if (_th.deposit)
      iData.depositTotal += _th.amount;
    else
      iData.withdrawTotal += _th.amount;

    mHolders.transactionLog.push(_tmp);    
  }
  function receive_user(address _user, sHolders calldata _holder) public allowAdmin {
    mHolders.iQueue.push(_user);
    mHolders.iHolders[_user].amount = _holder.amount;
    mHolders.iHolders[_user].holdback = _holder.holdback;
    mHolders.iHolders[_user].depositDate = _holder.depositDate;
    mHolders.iHolders[_user].discount = _holder.discount;
    mHolders.iHolders[_user].discountValidTo = _holder.discountValidTo;
    mHolders.iHolders[_user].accumulatedRewards = _holder.accumulatedRewards;
    mHolders.iHolders[_user]._pos = mHolders.iQueue.length-1;

    iData.poolTotal += _holder.amount;
  }

  function transferLiquidity(address _contract) private returns (uint _lpBal){
    (_lpBal,) = iMasterChef(exchangeInfo.chefContract).userInfo(iData.poolId,address(this));
    iMasterChef(exchangeInfo.chefContract).withdraw(iData.poolId,_lpBal);
    tLPToken(iData.lpContract).transfer(_contract,_lpBal);
  }

  function setPoolTotal(uint _amount, uint _dust, uint _lastProcess, uint _lastDiscount) public allowAdmin {
    iData.poolTotal = _amount;
    iData.dust = _dust;
    iData.lastProcess = _lastProcess;
    iData.lastDiscount = _lastDiscount;    
  }

  function depositLiquidity() public allowAdmin {
    uint _lpBal =tLPToken(iData.lpContract).balanceOf(address(this));
    emit sdLiquidityReceived(_lpBal);

    iMasterChef(exchangeInfo.chefContract).deposit(iData.poolId,_lpBal);
 }

  // function buildTransactionLog() private returns (transLog[] memory) {
  //   transLog[] memory _log = new transLog[](mHolders.transactionLog.length );
  //   uint cnt;

  //   for(uint i = 0; i < mHolders.dHolders.length; i++) {
  //     _log[cnt].deposit = true;
  //     _log[cnt].amount = mHolders.dHolders[i].amount;
  //     _log[cnt].timestamp = mHolders.dHolders[i].timestamp;
  //     _log[cnt].account = mHolders.dHolders[i].account;
  //     cnt++;
  //   }

  //   for(uint i = 0; i < mHolders.wHolders.length; i++) {
  //     uint found_pos = cnt;

  //     for(uint pos = 0; pos<cnt; pos++) {
  //       if (mHolders.wHolders[i].timestamp < _log[pos].timestamp) {
  //         for(uint t = cnt-1;t>pos;t--) {
  //           transLog[] memory _tmpLog = new transLog[](1);
  //           _tmpLog[0] = _log[t];
  //           _log[t+1] = _tmpLog[0];

  //           found_pos = t;            
  //         } 
  //       }
  //     }
      
  //     transLog[] memory _tmp = new transLog[](1);

  //     _tmp[0].deposit = false;
  //     _tmp[0].amount = mHolders.wHolders[i].amount;
  //     _tmp[0].timestamp = mHolders.wHolders[i].timestamp;
  //     _tmp[0].account = mHolders.wHolders[i].account;

  //     _log[found_pos] = _tmp[0];
  //     cnt++;
  //   }

  //   for(uint i = 0; i < cnt; i++ ){
  //     emit sdTransactionLog(_log[i].deposit,_log[i].amount,_log[i].timestamp,_log[i].account);
  //   }
  //   return _log;
  // }
}