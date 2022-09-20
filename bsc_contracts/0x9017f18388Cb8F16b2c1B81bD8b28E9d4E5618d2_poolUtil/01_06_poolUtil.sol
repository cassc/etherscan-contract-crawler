//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;
import "../Interfaces.sol";

// import "hardhat/console.sol";
///@title poolUtil.sol
///@author Derrick Bradbury ([email protected])
///@dev Library to handle staked pool and distribute rewards amongst stakeholders
library poolUtil {
    event addFunds_evt(address _user, uint _amount);
    event requestFunds_evt(uint _amount);
    event sendFunds_evt(address _to, uint _amount);
    // event sendHoldback_evt(address _to, uint _amount);
    event distContrib_evt(address _to_, uint _units, uint _amount, uint _feeAmount);
    event distContribTotal_evt(uint _total, uint _amount);
    event commitFunds_evt(uint _amount);
    event liquidateFunds_evt(uint _total, uint _amount);
    event returnDeposits_evt(uint _total, uint _amount);
    event Swap(address _from, address _to, uint amountIn, uint amountOut);
    event sdFeeSent(address _user, bytes16 _type, uint amount, uint total);
    event sdInitialized(uint64 poolId, address lpContract);
    event sdLiquidated(address _user, uint256 _amount, uint _units);

    event sdLiquidityProvided(uint256 amount0, uint256 amount1, uint256 lpOut);
    event sdDepositFee(address _user, uint _amount);
    error sdInsufficentFunds();
    error sdBeaconNotConfigured();
    error sdLPContractRequired();
    error sdPoolNotActive();


    ///@notice Add funds to a held pool from a user
    ///@param _self stHolders structure from main contract
    ///@param _amount amount to add for user into staking
    ///@return Amount to be invested
    ///@dev Emits addFunds_evt to notify funds being added
    function initDeposit(address _beacon, address feeCollector, stData storage _self, stHolders storage _holders, uint _amount, address _user) internal returns (uint) {
        require(!_self.paused,"Deposits are Paused");

        if(_holders.iHolders[_user].depositDate == 0) {
            _holders.iQueue.push(_user);
            _holders.iHolders[_user]._pos = _holders.iQueue.length-1;
        }

        if (_user != address(0)) {
            (uint fee,) = iBeacon(_beacon).getFee('DEFAULT','DEPOSITFEE',address(_user));
            if (fee > 0) {
                    uint feeAmount = ((_amount * fee)/100e18);
                    _amount = _amount - feeAmount;
                    payable(feeCollector).transfer(feeAmount);
                    emit sdFeeSent(_user, "DEPOSITFEE", feeAmount,_amount);
            }
        }
        return _amount;
    }

    ///@notice Adds funds to user account, and creates entry in transaction log    
    ///@param _self contains iData structure, system info
    ///@param _holders contains mHolders structure, user info
    ///@param _amount amount to add to user account
    ///@param _user user account to add funds to
    function addFunds(stData storage _self, stHolders storage _holders, uint _amount, address _user) internal {
        transHolders memory _tmp;
        _tmp.deposit = true;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;

        _holders.transactionLog.push(_tmp);
        _holders.iHolders[_user].depositDate = block.timestamp>_self.lastProcess?block.timestamp:_self.lastProcess; //set users last deposit date
        _holders.iHolders[_user].amount += _amount; //add funds to user account

        _self.depositTotal += _amount;

        emit addFunds_evt(_user, _amount);

    }
    ///@notice Request funds from a held pool
    ///@dev Overloads requestFunds to request funds from a held pool without adding the user
    ///@param _self stHolders structure from main contract
    ///@param _amount amount to request from staking pool
    ///@return Amount passed in

    function requestFunds(stData storage _self, stHolders storage _holders, uint _amount) internal returns (uint) {
        return requestFunds(_self, _holders, msg.sender, _amount);
    }

    ///@notice User can request funds to be withdrawn, amount put into queue
    ///@param _self stHolders structure from main contract
    ///@param _amount of stake amount to be sent back for user
    ///@dev Emits requestFunds_evt to notify funds being added
    ///@dev if 0 amount is passed in, all requests for user are removed
    function requestFunds(stData storage _self, stHolders storage _holders,address _user, uint _amount) internal returns (uint _returnAmount) {
        require(!_self.paused,"Withdrawals are Paused");
        require(_amount <= _holders.iHolders[_user].amount,"Insufficent Funds");
        if (_amount == 0) _amount = _holders.iHolders[_user].amount;

        transHolders memory _tmp;
        _tmp.deposit = false;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;
        
        _holders.transactionLog.push(_tmp);

        _holders.iHolders[_user].amount -= _amount;
        _self.withdrawTotal += _amount;

        _returnAmount = _amount;
        emit requestFunds_evt(_amount);
    }

    ///@notice Function calculates share percentage for particular user
    ///@param _self stHolders structure from main contract
    ///@param _user address of user to calculate
    ///@return _units - returns units based on current blance and total deposits and withdrawals
    function calcUnits(stData storage _self, stHolders storage _holders, address _user, bool _liquidate) internal view returns (uint _units) {        
        uint _time = block.timestamp - _self.lastProcess; // time since last harvest
        _time = _time > 0 ? _time : 1; // if difference is 0 set it to 1
        
        uint _amt = _holders.iHolders[_user].amount * _time; // Current Users Balance
        
        uint _pt;// Pool Total
        
        if (!_liquidate) {            
            _pt = (_self.poolTotal + _self.depositTotal) * _time; // if pool total is 0 set it to total deposits - withdrawals
            
            //Calculate time based balance only when distributing rewards
            for (uint d = _holders.transactionLog.length; d>0; d--) { //work transaction queue backwards
                transHolders memory _tmp = _holders.transactionLog[d-1];
                if (_tmp.timestamp == 0) continue;     

                if (_tmp.deposit) {                        
                    uint _debitTime = _tmp.timestamp - _self.lastProcess; //difference between deposit and last harvest user NOT in pool                    
                    uint _debitAmount = _tmp.amount * _debitTime; // Amount user was not in pool

                    _pt -= _debitAmount; // Subtract from total pool amount
                    
                    if (_tmp.account == _user) {
                        _amt -= _debitAmount; // Subtract from current users balance
                    }
                }
                else {
                    uint _creditTime = _tmp.timestamp - _self.lastProcess; //Time the user was in the pool
                    uint _creditAmount = _tmp.amount * _creditTime; // Amount user was in pool

                    _pt += _creditAmount; // Add time in pool to pool total
                    
                    if (_tmp.account == _user) 
                        _amt += _creditAmount; //Add time in pool to user
                }
            }
        }
        else {
            _pt = ((_self.poolTotal +_self.depositTotal) - _self.withdrawTotal) * _time; // Pool Total
        }
                  
        _units = _pt > 0 ? (_amt*(10**18)) / _pt : 0;
        if (_units > 1*10**18) _units = 1*10**18;

        return _units;
    }

    ///@notice commits transactions to the different accounts
    ///@param _self contains iData structure, system info
    ///@param _holders contains mHolders structure, user info

    function commitTransactions(stData storage _self, stHolders storage _holders) internal {
        for (uint i = 0; i < _holders.transactionLog.length;i++){
            transHolders memory _tmp = _holders.transactionLog[i];
            if (_tmp.timestamp == 0) continue;
            if (_tmp.deposit) {
                _holders.iHolders[_tmp.account].depositDate = _tmp.timestamp;
                _self.depositTotal -= _tmp.amount;
                _self.poolTotal += _tmp.amount;
            }
            else {
                _self.withdrawTotal -= _tmp.amount;
                _self.poolTotal -= _tmp.amount;
                
                if (_holders.iHolders[_tmp.account].amount == 0) {
                    if (_holders.iQueue.length > 1) {
                        uint _pos = _holders.iHolders[_tmp.account]._pos;
                        address _user = _holders.iQueue[_holders.iQueue.length-1];
                        _holders.iQueue[_pos] = _user;
                        _holders.iHolders[_user]._pos = _pos;
                        _holders.iQueue.pop();
                    }

                    delete _holders.iHolders[_tmp.account];
                }
            }
        }
        delete _holders.transactionLog;
    }

    ///@notice Function will distribute BNB to stakeholders based on stake
    ///@return _feeAmount - amount of BNB recovered in fees
    ///@param _self contains iData structure, system info
    ///@param _holders contains mHolders structure, user info
    ///@param _amount contains BNB to be distributed to stakeholders based on stake, and amount of reward token to for recording.
    ///@dev emits "distContribTotal_evt" total amount distributed
    ///@dev will revert with math error if more stake is allocated than was supplied in _amount parameter
    function distContrib(stData storage _self, stHolders storage _holders, uint[2] memory _amount, address _beacon) internal returns (uint _feeAmount) {        
        if (_amount[0] > 0) {
            uint _totalDist = 0;
            
            (uint fee,) = iBeacon(_beacon).getFee('DEFAULT','HARVEST',address(0));  // Get the fee without any discounts  

            bool check_fee;
            {// Stack control
                uint last_discount =  iBeacon(_beacon).getDataUint('LASTDISCOUNT'); // Get the timestamp of the last discount applied from the beacon
                check_fee = (last_discount >= _self.lastDiscount)?true:false;
                if (check_fee) _self.lastDiscount = last_discount;
            }

            for(uint i = 0; i < _holders.iQueue.length;i++) {
                address _user = _holders.iQueue[i];
                
                // (uint _units, uint share, uint feeAmount) = calcAmount(_self,_holders,[_user,_beacon], [_amount[0],_amount[1],fee],check_fee);
                (uint[3] memory _rv) = calcAmount(_self,_holders,[_user,_beacon], [_amount[0],_amount[1],fee],check_fee);
                if (_holders.iHolders[_user].amount > 0) _totalDist += _rv[1];
                _feeAmount += _rv[2];

            }
            
            _self.poolTotal += _totalDist;
            require(_amount[0] >= _totalDist,"Distribution failed");
            emit distContribTotal_evt(_totalDist,_amount[0]);

            _self.dust += _amount[0] - _totalDist;
        }
        // commit funds to the pool
        commitTransactions(_self,_holders);
    }

    ///@notice due to stack limits, this function is broken out of the distContrib function looop
    ///@return _rv - _units, share, feeAmount - due to stack limitations
    ///@param _self stHolders structure from main contract
    ///@param _holders stHolders structure from main contract
    ///@param _addr contains _user and _beacon due to stack limitations
    ///@param _amt contains _amount, _rewardToken, and fee due to stack limitations
    ///@param check_fee bool - true if discount should be looked up
    ///@dev emits "distContrib_evt" for each distribution to user
    ///@dev emits "sendHoldback_evt" if holdback for user is requested
    ///@dev emits "sendFunds_evt" if user has liquidated and final distribution is being sent

    function calcAmount(stData storage _self, stHolders storage _holders, address[2] memory _addr, uint[3] memory _amt, bool check_fee) internal returns (uint[3] memory _rv) {
        //Since user cannot call this function, and parent functions (harvest, and system_liquidate) lock to prevent re-execution,  re-enterancy is not a concern
        uint discount; 

        address _user = _addr[0];
        uint _amount = _amt[0];
        uint _rewardToken = _amt[1];
        uint fee = _amt[2];
        
        if (check_fee) {    // If there are new discounts, force a check
            uint expires;
            (discount, expires) = iBeacon(_addr[1]).getDiscount(_user);
            if (discount > 0) {
                _holders.iHolders[_user].discount = discount;
                _holders.iHolders[_user].discountValidTo = expires;
            }
        } else { // otherwise use the last discount stored in contract
            // If discountValidTo is 0, it measns it's permanant. If amount is 0 it doesn't matter, as it won't be applied
            discount = (_holders.iHolders[_user].discountValidTo <= block.timestamp) ? _holders.iHolders[_user].discount : 0;                
        } 

        _rv[0] = calcUnits(_self, _holders, _user,false);  // _units or % of reward distribution
        _rv[1] = (_amount * _rv[0])/1e18; // share of bnb to be distributed to user
        _rv[2] = ((_rv[1] * fee)/100e18); // calculate fee amount

        if (discount>0) _rv[2] = _rv[2] - (_rv[2] *(discount/100) / (10**18)); // apply discount if applicable

        _rv[1] = _rv[1] - _rv[2]; // subtract fee from share

        // { // stack control
        //     if (_holders.iHolders[_user].holdback > 0) {
        //         uint holdback = ((_rv[1] * (_holders.iHolders[_user].holdback/100))/1e18); //calculate holdback based on users requested amount
        //         if (_rv[1] >= holdback){
        //             _rv[1] = _rv[1] - holdback; //remove holdback from users share
        //             payable(_user).transfer(holdback);
        //             emit sendHoldback_evt(_user, holdback);
        //         }
        //     }
        // }
        
        if (_holders.iHolders[_user].amount > 0) { // check if the user has already liquidated
            _holders.iHolders[_user].amount += _rv[1]; // add share to user's total share
            uint tokenShare = ((_rewardToken * _rv[0])/1e18); // calculate share of reward token to be distributed to user based on units
            _holders.iHolders[_user].accumulatedRewards += tokenShare - ((tokenShare * fee)/100e18);
        }
        emit distContrib_evt(_user, _rv[0], _rv[1], _rv[2]);
    }


    ///@notice Function will iterate through staked holders and add up total stake and compare to what contract thinks exists
    ///@param _self stHolders structure from main contract
    ///@return Calculated total
    ///@return Contract Pool Total
    function auditHolders(stData storage _self, stHolders storage _holders) public view returns (uint,uint,uint,uint) {
        uint _total = 0;
        for(uint i = _holders.iQueue.length; i > 0;i--){
            address _user = _holders.iQueue[i-1];
            _total += _holders.iHolders[_user].amount;
        }                    
        // _self.dust += 1;

        return (_total, _self.poolTotal , _self.depositTotal, _self.withdrawTotal);
    }

    ///@notice Returns user info based on pool info
    ///@param _self stHolders structure from main contract
    ///@param _user Address of user
    ///@return _amount Amount of Units held by user
    ///@return _depositDate Date of last deposit
    ///@return _units Number of units held by user
    ///@return _accumulatedRewards Number of units accumulated by user

    function getUserInfo(stData storage _self, stHolders storage _holders, address _user) public view returns (uint _amount, uint _depositDate, uint _units, uint _accumulatedRewards) {
        _units = calcUnits(_self, _holders, _user,false);        
        // (uint _lpBal,) = iMasterChef(chefContract).userInfo(_self.poolId,address(this));
        // uint _units_amount = calcUnits(_self, _holders, _user,true); // _units_amount must return not based on time in pool, but overall total        
        // _amount = (_lpBal * _units_amount)/1e18;

        _amount = _holders.iHolders[_user].amount;

        _depositDate = _holders.iHolders[_user].depositDate;
        _accumulatedRewards = _holders.iHolders[_user].accumulatedRewards;
    }


    ///@notice Get last deposit date for a user
    ///@param _holders stHolders structure from main contract
    ///@param _user Address of user
    ///@return _depositDate Date of last deposit
    function getLastDepositDate(stHolders storage _holders, address _user) public view returns (uint _depositDate) {
        _depositDate = _holders.iHolders[_user].depositDate;
    }

    ///@notice Remove specified liquidity from the pool
    ///@param _units percent of total liquidity to remove
    ///@return amountTokenA of liquidity removed (Token A)
    ///@return amountTokenB of liquidity removed (Token B)
    function removeLiquidity(stData storage iData, iBeacon.sExchangeInfo memory exchangeInfo,  uint _units, bool _withdraw) external returns (uint amountTokenA, uint amountTokenB){
        (uint _lpBal,) = iMasterChef(exchangeInfo.chefContract).userInfo(iData.poolId,address(this));
        if (_units != 0) {
            _lpBal = (_units * _lpBal)/1e18;
            if(_lpBal == 0) revert sdInsufficentFunds();
        }

        uint deadline = block.timestamp + DEPOSIT_HOLD;
        if (_withdraw) {
            iMasterChef(exchangeInfo.chefContract).withdraw(iData.poolId,_lpBal);
        }
        
        _lpBal = ERC20(iData.lpContract).balanceOf(address(this));

        if (iData.token0 == WBNB_ADDR || iData.token1 == WBNB_ADDR) {
            (amountTokenA, amountTokenB) = iRouter(exchangeInfo.routerContract).removeLiquidityETH(iData.token0==WBNB_ADDR?iData.token1:iData.token0,_lpBal,0,0,address(this), deadline);
            (amountTokenA, amountTokenB) = iData.token0 == WBNB_ADDR ? (amountTokenB, amountTokenA) : (amountTokenA, amountTokenB); // returns eth to amountTokenB
        }
        else
            (amountTokenA, amountTokenB) = iRouter(exchangeInfo.routerContract).removeLiquidity(iData.token0,iData.token1,_lpBal,0,0,address(this), deadline);

        return (amountTokenA, amountTokenB);
    }

    //@notice helper function to add liquidity to the pool
    //@param _amount0 amount of token0 to add to the pool
    //@param _amount1 amount of token1 to add to the pool    
    function addLiquidity(stData storage iData, iBeacon.sExchangeInfo memory exchangeInfo,uint amount0, uint amount1, bool _deposit) external returns (uint liquidity){
        uint amountA;
        uint amountB;

        if (iData.token1 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(exchangeInfo.routerContract).addLiquidityETH{value: amount1}(iData.token0, amount0, 0,0, address(this), block.timestamp);
        }
        else if (iData.token0 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(exchangeInfo.routerContract).addLiquidityETH{value: amount0}(iData.token1, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(exchangeInfo.routerContract).addLiquidity(iData.token0, iData.token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }
        if (_deposit) {
            iMasterChef(exchangeInfo.chefContract).deposit(iData.poolId,liquidity);
            emit sdLiquidityProvided(amountA, amountB, liquidity);
        }
    }


    ///@notice take amountIn for path[0] and swap for token1
    ///@param amountIn amount of path[0]
    ///@param path token path required for swap 
    ///@return resulting amount of path[1] swapped 
    function swap(iBeacon.sExchangeInfo memory exchangeInfo,stData memory iData,uint amountIn, address[2] memory path, address[2] memory intToken) external returns (uint){
        if(amountIn == 0) revert sdInsufficentFunds();

        uint _cBalance = address(this).balance;
        if (path[0] == WBNB_ADDR && path[path.length-1] == WBNB_ADDR) {
            if (ERC20(WBNB_ADDR).balanceOf(address(this)) >= amountIn) {
                iWBNB(WBNB_ADDR).withdraw(amountIn);
                _cBalance = address(this).balance;
            }
            if (amountIn > _cBalance) revert sdInsufficentFunds();
            return amountIn;
        }

        uint pathLength = 2;
        address intermediateToken;

        if (exchangeInfo.intermediateToken != address(0)) {
            intermediateToken = exchangeInfo.intermediateToken;
            pathLength = 3;
        }
        else {
            if (intToken[0] != address(0) && (path[0] == iData.token0 || path[1] == iData.token0)) {
                pathLength = 3;
                intermediateToken = intToken[0];
            }

            if (intToken[1] != address(0) && (path[0] == iData.token1 || path[1] == iData.token1)) {
                pathLength = 3;
                intermediateToken = intToken[1];
            }

            if (path[0] == intermediateToken || path[1] == intermediateToken) {
                pathLength = 2;
                intermediateToken = address(0);
            }
        }

        address[] memory swapPath = new address[](pathLength);

        if (pathLength == 2) {
            swapPath[0] = path[0];
            swapPath[1] = path[1];
        }
        else {
            swapPath[0] = path[0];
            swapPath[1] = intermediateToken;
            swapPath[2] = path[1];
        }

        uint[] memory amounts;


        if (path[0] == WBNB_ADDR && ERC20(WBNB_ADDR).balanceOf(address(this)) >= amountIn) {
            iWBNB(WBNB_ADDR).withdraw(amountIn);
            _cBalance = address(this).balance;
        }
        uint deadline = block.timestamp + 600; 

        if (path[path.length - 1] == WBNB_ADDR) {
            amounts = iRouter(exchangeInfo.routerContract).swapExactTokensForETH(amountIn, 0,  swapPath, address(this), deadline);
        } else if (path[0] == WBNB_ADDR && _cBalance >= amountIn) {
            amounts = iRouter(exchangeInfo.routerContract).swapExactETHForTokens{value: amountIn}(0,swapPath,address(this),deadline);
        }
        else {
            amounts = iRouter(exchangeInfo.routerContract).swapExactTokensForTokens(amountIn, 0,swapPath,address(this),deadline);
        }
        emit Swap(path[0], path[path.length-1],amounts[0], amounts[amounts.length-1]);
        return amounts[amounts.length-1];
    }
    
    function initializePool(uint64 _poolId, address _beacon, string memory _exchangeName) internal returns (iBeacon.sExchangeInfo memory exchangeInfo, stData memory iData) {
        exchangeInfo = iBeacon(_beacon).getExchangeInfo(_exchangeName);
        if (exchangeInfo.chefContract == address(0)) revert sdBeaconNotConfigured();

        address _lpContract;
        uint _alloc;

        if (exchangeInfo.psV2) {
            _lpContract = iMasterChefv2(exchangeInfo.chefContract).lpToken(_poolId);
            (,,_alloc,,) = iMasterChefv2(exchangeInfo.chefContract).poolInfo(_poolId);
        }
        else {
            (_lpContract, _alloc,,) = iMasterChef(exchangeInfo.chefContract).poolInfo(_poolId);
        }
        
        if(_lpContract == address(0)) revert sdLPContractRequired();
        if(_alloc == 0) revert sdPoolNotActive();

        iData.poolId = _poolId;
        iData.lpContract =  _lpContract;
        iData.token0 = iLPToken(_lpContract).token0();
        iData.token1 = iLPToken(_lpContract).token1();

        ERC20(iData.token0).approve(exchangeInfo.routerContract,MAX_INT);
        ERC20(iData.token1).approve(exchangeInfo.routerContract,MAX_INT);
        ERC20(exchangeInfo.rewardToken).approve(exchangeInfo.routerContract,MAX_INT);
        
        iLPToken(_lpContract).approve(exchangeInfo.chefContract,MAX_INT);        
        iLPToken(_lpContract).approve(exchangeInfo.routerContract,MAX_INT);        
        emit sdInitialized(_poolId,_lpContract);
    }

    function revertShares(stData storage iData, stHolders storage mHolders) internal returns (uint _total_base_sent) {
        uint _total_base = address(this).balance;
        //loop through owners and send shares to them
        for (uint i = mHolders.iQueue.length; i > 0; i--) {
            address _user = mHolders.iQueue[i-1];
            uint _units = poolUtil.calcUnits(iData, mHolders,_user,true);
            uint _refund = (_units * _total_base)/1e18;
            _total_base_sent += _refund;
            mHolders.iHolders[_user].amount = 0;
            payable(_user).transfer(_refund);

            delete mHolders.iHolders[_user];
            mHolders.iQueue.pop();
            
            emit sdLiquidated(_user,_refund, _units);
        }
        iData.poolTotal = 0;
        iData.depositTotal = 0;
        iData.withdrawTotal = 0;
    }    
}