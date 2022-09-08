//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.0;
import "../interfaces/AppStorage.sol";
import "../interfaces/Interfaces.sol";
import "./LibDiamond.sol";

// import "hardhat/console.sol";
///@title poolUtil.sol
///@author Derrick Bradbury ([email protected])
///@dev Library to handle staked pool and distribute rewards amongst stakeholders
library sdPoolUtil {
    event addFunds_evt(address _user, uint _amount);
    event requestFunds_evt(uint _amount);
    event sendHoldback_evt(address _to, uint _amount);
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
    ///@param _s - AppStorage structure
    ///@param _amount - amount to add for user into staking
    ///@return Amount to be invested
    ///@dev Emits addFunds_evt to notify funds being added
    function initDeposit(AppStorage storage _s, uint _amount, address _user) internal returns (uint) {
        require(!_s.paused,"Deposits are Paused");

        if(_s.iHolders[_user].depositDate == 0) {
            _s.iQueue.push(_user);
            _s.iHolders[_user]._pos = _s.iQueue.length-1;
        }

        if (_user != address(0)) {
            (uint fee,) = iBeacon(_s.iData.beaconContract).getFee('DEFAULT','DEPOSITFEE',address(_user));
            if (fee > 0) {
                    uint feeAmount = ((_amount * fee)/100e18);
                    _amount = _amount - feeAmount;
                    payable(_s.iData.feeCollector).transfer(feeAmount);
                    emit sdFeeSent(_user, "DEPOSITFEE", feeAmount,_amount);
            }
        }
        return _amount;
    }

    ///@notice Adds funds to user account, and creates entry in transaction log    
    ///@param _s - AppStorage structure
    ///@param _amount amount to add to user account
    ///@param _user user account to add funds to
    function addFunds(AppStorage storage _s, uint _amount, address _user) internal {
        transHolders memory _tmp;
        _tmp.deposit = true;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;

        _s.transactionLog.push(_tmp);
        _s.iHolders[_user].depositDate = block.timestamp>_s.iData.lastProcess?block.timestamp:_s.iData.lastProcess; //set users last deposit date
        _s.iHolders[_user].amount += _amount; //add funds to user account

        _s.iData.depositTotal += _amount;

        emit addFunds_evt(_user, _amount);

    }
    ///@notice Request funds from a held pool
    ///@dev Overloads requestFunds to request funds from a held pool without adding the user
    ///@param _s  -AppStorage structure
    ///@param _amount - amount to request from staking pool
    ///@return Amount passed in

    function requestFunds(AppStorage storage _s, uint _amount) internal returns (uint) {
        return requestFunds(_s, msg.sender, _amount);
    }

    ///@notice User can request funds to be withdrawn, amount put into queue
    ///@param _s - AppStorage structure
    ///@param _amount of stake amount to be sent back for user
    ///@dev Emits requestFunds_evt to notify funds being added
    ///@dev if 0 amount is passed in, all requests for user are removed
    function requestFunds(AppStorage storage _s,address _user, uint _amount) internal returns (uint _returnAmount) {
        require(!_s.paused,"Withdrawals are Paused");
        require(_amount <= _s.iHolders[_user].amount,"Insufficent Funds");
        if (_amount == 0) _amount = _s.iHolders[_user].amount;

        transHolders memory _tmp;
        _tmp.deposit = false;
        _tmp.amount = _amount;
        _tmp.account = _user;
        _tmp.timestamp = block.timestamp;
        
        _s.transactionLog.push(_tmp);

        _s.iHolders[_user].amount -= _amount;
        _s.iData.withdrawTotal += _amount;

        _returnAmount = _amount;
        emit requestFunds_evt(_amount);
    }

    ///@notice Function calculates share percentage for particular user
    ///@param _s - AppStorage structure
    ///@param _user - address of user to calculate
    ///@param _liquidate - calculate for liquidation
    ///@return _units - returns units based on current blance and total deposits and withdrawals
    function calcUnits(AppStorage storage _s, address _user, bool _liquidate) internal view returns (uint _units) {        
        uint _time = block.timestamp - _s.iData.lastProcess; // time since last harvest
        _time = _time > 0 ? _time : 1; // if difference is 0 set it to 1
        
        uint _amt = _s.iHolders[_user].amount * _time; // Current Users Balance
        
        uint _pt;// Pool Total
        
        if (!_liquidate) {            
            _pt = (_s.iData.poolTotal + _s.iData.depositTotal) * _time; // if pool total is 0 set it to total deposits - withdrawals
            
            //Calculate time based balance only when distributing rewards
            for (uint d = _s.transactionLog.length; d>0; d--) { //work transaction queue backwards
                transHolders memory _tmp = _s.transactionLog[d-1];
                if (_tmp.timestamp == 0) continue;     

                if (_tmp.deposit) {                        
                    uint _debitTime = _tmp.timestamp - _s.iData.lastProcess; //difference between deposit and last harvest user NOT in pool                    
                    uint _debitAmount = _tmp.amount * _debitTime; // Amount user was not in pool

                    _pt -= _debitAmount; // Subtract from total pool amount
                    
                    if (_tmp.account == _user) {
                        _amt -= _debitAmount; // Subtract from current users balance
                    }
                }
                else {
                    uint _creditTime = _tmp.timestamp - _s.iData.lastProcess; //Time the user was in the pool
                    uint _creditAmount = _tmp.amount * _creditTime; // Amount user was in pool

                    _pt += _creditAmount; // Add time in pool to pool total
                    
                    if (_tmp.account == _user) 
                        _amt += _creditAmount; //Add time in pool to user
                }
            }
        }
        else {
            _pt = ((_s.iData.poolTotal +_s.iData.depositTotal) - _s.iData.withdrawTotal) * _time; // Pool Total
        }
                  
        _units = _pt > 0 ? (_amt*(10**18)) / _pt : 0;
        if (_units > 1*10**18) _units = 1*10**18;

        return _units;
    }

    function commitTransactions(AppStorage storage _s) internal {
        for (uint i = 0; i < _s.transactionLog.length;i++){
            transHolders memory _tmp = _s.transactionLog[i];
            if (_tmp.timestamp == 0) continue;
            if (_tmp.deposit) {
                _s.iHolders[_tmp.account].depositDate = _tmp.timestamp;
                _s.iData.depositTotal -= _tmp.amount;
                _s.iData.poolTotal += _tmp.amount;
            }
            else {
                _s.iData.withdrawTotal -= _tmp.amount;
                _s.iData.poolTotal -= _tmp.amount;
                
                if (_s.iHolders[_tmp.account].amount == 0) {
                    if (_s.iQueue.length > 1) {
                        uint _pos = _s.iHolders[_tmp.account]._pos;
                        address _user = _s.iQueue[_s.iQueue.length-1];
                        _s.iQueue[_pos] = _user;
                        _s.iHolders[_user]._pos = _pos;
                        _s.iQueue.pop();
                    }

                    delete _s.iHolders[_tmp.account];
                }
            }
        }
        delete _s.transactionLog;
    }

    ///@notice Function will distribute BNB to stakeholders based on stake
    ///@param _s - AppStorage structure
    ///@param _amount contains BNB to be distributed to stakeholders based on stake, and amount of reward token to for recording.
    ///@return _feeAmount - amount of BNB recovered in fees
    ///@dev emits "distContribTotal_evt" total amount distributed
    ///@dev will revert with math error if more stake is allocated than was supplied in _amount parameter
    function distContrib(AppStorage storage _s, uint[2] memory _amount) internal returns (uint _feeAmount, uint _sendAmount, sendQueue[] memory _send) {        
        if (_amount[0] > 0) {
            uint _totalDist = 0;
            
            (uint fee,) = iBeacon(_s.iData.beaconContract).getFee('DEFAULT','HARVEST',address(0));  // Get the fee without any discounts  

            bool check_fee;
            {// Stack control
                uint last_discount =  iBeacon(_s.iData.beaconContract).getDataUint('LASTDISCOUNT'); // Get the timestamp of the last discount applied from the beacon
                check_fee = (last_discount >= _s.iData.lastDiscount)?true:false;
                if (check_fee) _s.iData.lastDiscount = last_discount;
            }
            _send = new sendQueue[](_s.iQueue.length);
            uint cnt;
            for(uint i = 0; i < _s.iQueue.length;i++) {
                address _user = _s.iQueue[i];
                
                // (uint _units, uint share, uint feeAmount) = calcAmount(_self,_holders,[_user,_beacon], [_amount[0],_amount[1],fee],check_fee);
                (uint[4] memory _rv) = calcAmount(_s,_user, [_amount[0],_amount[1],fee],check_fee);
                if (_rv[3] > 0){
                    _send[cnt++] = sendQueue(_user, _rv[3]);
                    _sendAmount += _rv[3];
                } 
                if (_s.iHolders[_user].amount > 0) _totalDist += _rv[1];
                _feeAmount += _rv[2];
            }
            
            _s.iData.poolTotal += _totalDist;
            require(_amount[0] >= _totalDist,"Distribution failed");
            emit distContribTotal_evt(_totalDist,_amount[0]);

            _s.iData.dust += _amount[0] - _totalDist;
        }
        // commit funds to the pool
        commitTransactions(_s);
    }

    ///@notice due to stack limits, this function is broken out of the distContrib function looop
    ///@param _s - AppStorage structure
    ///@param _user - address of user to caluclate
    ///@param _amt contains _amount, _rewardToken, and fee due to stack limitations
    ///@param check_fee bool - true if discount should be looked up
    ///@return _rv - _units, share, feeAmount - due to stack limitations
    ///@dev emits "distContrib_evt" for each distribution to user
    ///@dev emits "sendHoldback_evt" if holdback for user is requested

    function calcAmount(AppStorage storage _s,address _user, uint[3] memory _amt, bool check_fee) internal returns (uint[4] memory _rv) {
        //Since user cannot call this function, and parent functions (harvest, and system_liquidate) lock to prevent re-execution,  re-enterancy is not a concern
        //_addr[1] = _s.iData.beaconContract;
        uint discount; 

        uint _amount = _amt[0];
        uint _rewardToken = _amt[1];
        uint fee = _amt[2];
        
        if (check_fee) {    // If there are new discounts, force a check
            uint expires;
            (discount, expires) = iBeacon(_s.iData.beaconContract).getDiscount(_user);
            if (discount > 0) {
                _s.iHolders[_user].discount = discount;
                _s.iHolders[_user].discountValidTo = expires;
            }
        } else { // otherwise use the last discount stored in contract
            // If discountValidTo is 0, it measns it's permanant. If amount is 0 it doesn't matter, as it won't be applied
            discount = (_s.iHolders[_user].discountValidTo <= block.timestamp) ? _s.iHolders[_user].discount : 0;                
        } 

        _rv[0] = calcUnits(_s, _user,false);  // _units or % of reward distribution
        _rv[1] = (_amount * _rv[0])/1e18; // share of bnb to be distributed to user
        _rv[2] = ((_rv[1] * fee)/100e18); // calculate fee amount

        if (discount>0) _rv[2] = _rv[2] - (_rv[2] *(discount/100) / (10**18)); // apply discount if applicable

        _rv[1] = _rv[1] - _rv[2]; // subtract fee from share

        { // stack control
            if (_s.iHolders[_user].holdback > 0) {
                uint holdback = ((_rv[1] * (_s.iHolders[_user].holdback/100))/1e18); //calculate holdback based on users requested amount
                if (_rv[1] >= holdback){
                    _rv[1] = _rv[1] - holdback; //remove holdback from users share
                    _rv[3] = holdback;
                    emit sendHoldback_evt(_user, holdback);
                }
            }
        }
        
        if (_s.iHolders[_user].amount > 0) { // check if the user has already liquidated
            _s.iHolders[_user].amount += _rv[1]; // add share to user's total share
            uint tokenShare = ((_rewardToken * _rv[0])/1e18); // calculate share of reward token to be distributed to user based on units
            _s.iHolders[_user].accumulatedRewards += tokenShare - ((tokenShare * fee)/100e18);
        }
        else { // If liquidated send share back to user
            // payable(_user).transfer(_rv[1]);
            _rv[3] += _rv[1];
        }
        emit distContrib_evt(_user, _rv[0], _rv[1], _rv[2]);
    }


    ///@notice Function will iterate through staked holders and add up total stake and compare to what contract thinks exists
    ///@param _s - AppStorage structure
    ///@return Calculated total, Recorded Pool Tota, Recorded deposit total, recorded withdraw total
    ///@return Contract Pool Total
    function auditHolders(AppStorage storage _s) public view returns (uint,uint,uint,uint) {
        uint _total = 0;
        for(uint i = _s.iQueue.length; i > 0;i--){
            address _user = _s.iQueue[i-1];
            _total += _s.iHolders[_user].amount;
        }                    
        // _s.iData.dust += 1;

        return (_total, _s.iData.poolTotal , _s.iData.depositTotal, _s.iData.withdrawTotal);
    }

    ///@notice Returns user info based on pool info
    ///@param _s - AppStorage structure
    ///@param _user Address of user
    ///@return _amount Amount of Units held by user
    ///@return _depositDate Date of last deposit
    ///@return _units Number of units held by user
    ///@return _accumulatedRewards Number of units accumulated by user

    function getUserInfo(AppStorage storage _s, address _user) public view returns (uint _amount, uint _depositDate, uint _units, uint _accumulatedRewards) {
        _units = calcUnits(_s, _user,false);        
        // (uint _lpBal,) = iMasterChef(chefContract).userInfo(_s.iData.poolId,address(this));
        // uint _units_amount = calcUnits(_self, _holders, _user,true); // _units_amount must return not based on time in pool, but overall total        
        // _amount = (_lpBal * _units_amount)/1e18;

        _amount = _s.iHolders[_user].amount;

        _depositDate = _s.iHolders[_user].depositDate;
        _accumulatedRewards = _s.iHolders[_user].accumulatedRewards;
    }


    ///@notice Get last deposit date for a user
    ///@param _s - AppStorage structure
    ///@param _user Address of user
    ///@return _depositDate Date of last deposit
    function getLastDepositDate(AppStorage storage _s, address _user) public view returns (uint _depositDate) {
        _depositDate = _s.iHolders[_user].depositDate;
    }

    ///@notice Remove specified liquidity from the pool
    ///@param _units percent of total liquidity to remove
    ///@return amountTokenA of liquidity removed (Token A)
    ///@return amountTokenB of liquidity removed (Token B)
    function removeLiquidity(AppStorage storage _s,  uint _units, bool _withdraw) external returns (uint amountTokenA, uint amountTokenB){
        (uint _lpBal,) = iMasterChef(_s.exchangeInfo.chefContract).userInfo(_s.iData.poolId,address(this));
        if (_units != 0) {
            _lpBal = (_units * _lpBal)/1e18;
            if(_lpBal == 0) revert sdInsufficentFunds();
        }

        uint deadline = block.timestamp + DEPOSIT_HOLD;
        if (_withdraw) {
            iMasterChef(_s.exchangeInfo.chefContract).withdraw(_s.iData.poolId,_lpBal);
        }
        
        _lpBal = ERC20(_s.iData.lpContract).balanceOf(address(this));

        if (_s.iData.token0 == WBNB_ADDR || _s.iData.token1 == WBNB_ADDR) {
            (amountTokenA, amountTokenB) = iRouter(_s.exchangeInfo.routerContract).removeLiquidityETH(_s.iData.token0==WBNB_ADDR?_s.iData.token1:_s.iData.token0,_lpBal,0,0,address(this), deadline);
            (amountTokenA, amountTokenB) = _s.iData.token0 == WBNB_ADDR ? (amountTokenB, amountTokenA) : (amountTokenA, amountTokenB); // returns eth to amountTokenB
        }
        else
            (amountTokenA, amountTokenB) = iRouter(_s.exchangeInfo.routerContract).removeLiquidity(_s.iData.token0,_s.iData.token1,_lpBal,0,0,address(this), deadline);

        return (amountTokenA, amountTokenB);
    }

    //@notice helper function to add liquidity to the pool
    ///@param _s - AppStorage structure
    //@param _amount0 - amount of token0 to add to the pool
    //@param _amount1 - amount of token1 to add to the pool    
    ///@return liquidity - amount of liquidity added to the pool
    function addLiquidity(AppStorage storage _s,uint amount0, uint amount1, bool _deposit) external returns (uint liquidity){
        uint amountA;
        uint amountB;

        if (_s.iData.token1 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(_s.exchangeInfo.routerContract).addLiquidityETH{value: amount1}(_s.iData.token0, amount0, 0,0, address(this), block.timestamp);
        }
        else if (_s.iData.token0 == WBNB_ADDR) {
            (amountA, amountB, liquidity) = iRouter(_s.exchangeInfo.routerContract).addLiquidityETH{value: amount0}(_s.iData.token1, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(_s.exchangeInfo.routerContract).addLiquidity(_s.iData.token0, _s.iData.token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }
        if (_deposit) {
            iMasterChef(_s.exchangeInfo.chefContract).deposit(_s.iData.poolId,liquidity);
            emit sdLiquidityProvided(amountA, amountB, liquidity);
        }
    }


    ///@notice take amountIn for path[0] and swap for token1
    ///@param amountIn amount of path[0]
    ///@param path token path required for swap 
    ///@return resulting amount of path[1] swapped 
    function swap(AppStorage storage _s,uint amountIn, address[2] memory path) external returns (uint){
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

        if (_s.exchangeInfo.intermediateToken != address(0)) {
            intermediateToken = _s.exchangeInfo.intermediateToken;
            pathLength = 3;
        }
        else {
            if (_s.intToken0 != address(0) && (path[0] == _s.iData.token0 || path[1] == _s.iData.token0)) {
                pathLength = 3;
                intermediateToken = _s.intToken0;
            }

            if (_s.intToken1 != address(0) && (path[0] == _s.iData.token1 || path[1] == _s.iData.token1)) {
                pathLength = 3;
                intermediateToken = _s.intToken1;
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
            amounts = iRouter(_s.exchangeInfo.routerContract).swapExactTokensForETH(amountIn, 0,  swapPath, address(this), deadline);
        } else if (path[0] == WBNB_ADDR && _cBalance >= amountIn) {
            amounts = iRouter(_s.exchangeInfo.routerContract).swapExactETHForTokens{value: amountIn}(0,swapPath,address(this),deadline);
        }
        else {
            amounts = iRouter(_s.exchangeInfo.routerContract).swapExactTokensForTokens(amountIn, 0,swapPath,address(this),deadline);
        }
        emit Swap(path[0], path[path.length-1],amounts[0], amounts[amounts.length-1]);
        return amounts[amounts.length-1];
    }
    
    function revertShares(AppStorage storage _s) internal returns (uint _total_base_sent) {
        uint _total_base = address(this).balance;
        //loop through owners and send shares to them
        for (uint i = _s.iQueue.length; i > 0; i--) {
            address _user = _s.iQueue[i-1];
            uint _units = calcUnits(_s,_user,true);
            uint _refund = (_units * _total_base)/1e18;
            _total_base_sent += _refund;
            _s.iHolders[_user].amount = 0;
            payable(_user).transfer(_refund);

            delete _s.iHolders[_user];
            _s.iQueue.pop();
            
            emit sdLiquidated(_user,_refund, _units);
        }
        _s.iData.poolTotal = 0;
        _s.iData.depositTotal = 0;
        _s.iData.withdrawTotal = 0;
    }    
}