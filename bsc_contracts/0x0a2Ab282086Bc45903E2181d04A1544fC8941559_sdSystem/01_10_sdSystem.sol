//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;

import "../interfaces/AppStorage.sol";
import "../interfaces/Interfaces.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/sdPoolUtil.sol";

///@title simpleDefi.sol
///@author Derrick Bradbury ([email protected])
///@notice Common simpleDefi functions not specific to pool/solo contracts
contract sdSystem  {
    AppStorage internal s;

    event sdFeeSent(address _user, bytes16 _type, uint amount,uint total);
    event sdLiquidated(address _user, uint256 _amount, uint _units);
    event sdLiquidatedPool(uint256 poolId, uint256 amount);
    event sdLiquidityProvided(uint256 lpOut);
    event sdSwapPool(address _from, address _to, uint amount, address user);
    event sendFunds_evt(address _to, uint _amount);

    error sdFunctionLocked();
    error sdInsufficentFunds();
    error sdLiquidationTooSoon();

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

    function liquidate() external {
        uint _rval = performLiquidation(msg.sender,true);
        if (_rval == 0) revert sdInsufficentFunds();
    }
    ///@notice Administrative force remove funds from current pool and send to user
    ///@param _user address to remove funds from pool 
    function admin_liquidate(address _user) external allowAdmin {
        performLiquidation(_user,true);
    }

    ///@notice Internal processing of liquidation
    ///@param _user address of user to remove funds from pool
    ///@param _sendfunds bool if true funds are sent to user
    ///@return uint amount of funds removed from pool
    function performLiquidation(address _user, bool _sendfunds) internal lockFunction returns (uint) {    
        if (sdPoolUtil.getLastDepositDate(s, _user) + DEPOSIT_HOLD > block.timestamp) revert sdLiquidationTooSoon();
        if ( s.iHolders[_user].amount == 0) return 0;

        uint _units = sdPoolUtil.calcUnits(s,_user, true);
        uint total;

        if (_units > 0) {
            sdPoolUtil.requestFunds(s, _user, 0); // 0 i request everything
            (uint amount0, uint amount1) = sdPoolUtil.removeLiquidity(s, _units,true); //remove liquidity from pool

            (address t0, address t1) = s.iData.token0 < s.iData.token1 ? (s.iData.token0, s.iData.token1) : (s.iData.token1, s.iData.token0); // sort tokens from removeLiquidity to match amount0 and amount1
            
            total += swap(amount0,t0,WBNB_ADDR);
            total += swap(amount1,t1,WBNB_ADDR);                       
            
            uint64 minDepositTime = iBeacon(s.iData.beaconContract).getConst('DEFAULT','MINDEPOSITTIME');
            if (minDepositTime > 0 && (block.timestamp - s.iHolders[_user].depositDate) <= minDepositTime) {
                (uint fee,) = iBeacon(s.iData.beaconContract).getFee('DEFAULT','LIQUIDATIONFEE',address(_user));
                uint feeAmount = ((total * fee)/100e18);
                total -= feeAmount;
                payable(s.iData.feeCollector).transfer(feeAmount);
                emit sdFeeSent(_user, "LIQUIDATIONFEE", feeAmount,total);
            }

            if (_sendfunds) {
                payable(address(_user)).transfer(total);
                emit sdLiquidated(_user, total,_units);
            }
        }
        return total;
    }

    ///@notice remove funds from all users in  current pool and send to user
    function system_liquidate() external allowAdmin lockFunction {
        if (s.liquidationFee == false) {
            s.lastGas += iBeacon(s.iData.beaconContract).getConst('DEFAULT','LIQUIDATIONGAS');
            s.liquidationFee = true;
        }
        do_harvest(0);

        sdPoolUtil.removeLiquidity(s,0,true);
        revertBalance();  
            
        emit sdLiquidatedPool(s.iData.poolId, sdPoolUtil.revertShares(s));
    }

    ///@notice Harvest reward from current pool, and distribute to users
    ///@dev Records gas used for recovery on next run
    function harvest() external lockFunction allowAdmin {
        uint startGas = gasleft() + 21000 + 7339;
        uint allocPoint;
        if (s.exchangeInfo.psV2)
            (,,allocPoint,,) = iMasterChefv2(s.exchangeInfo.chefContract).poolInfo(s.iData.poolId);
        else
            (, allocPoint,,) = iMasterChef(s.exchangeInfo.chefContract).poolInfo(s.iData.poolId);

        if (allocPoint == 0) {
            s.lastGas += iBeacon(s.iData.beaconContract).getConst('DEFAULT','LIQUIDATIONGAS');
            s.liquidationFee = true;
        }
        do_harvest(1);               
        // addFunds(address(this).balance,address(0),true);
        s.lastGas = startGas - gasleft();
    }

    ///@notice Perform actual harvest, distributrion does not re-invest
    ///@param revert_trans - if 1 revert transactino if no pending cake, otherwise just return 0
    function do_harvest(uint revert_trans) private returns (uint) {    
        uint pendingCake = getPendingReward();
        if (pendingCake == 0) { //if no pending cake revert or return 0 depending on requiremnts
            if (revert_trans == 1) {
                revert sdInsufficentFunds();
            }
            else {
                    return 0;
            }
        }
        uint _bal = address(this).balance; //Get balance before any distribution fees
        
        iMasterChef(s.exchangeInfo.chefContract).deposit(s.iData.poolId,0); //do the harvest
        pendingCake = ERC20(s.exchangeInfo.rewardToken).balanceOf(address(this)); //get balance of pending cake

        uint reward = swap(pendingCake,s.exchangeInfo.rewardToken, WBNB_ADDR); //change into BNB
        uint gasRecovery = (s.lastGas * tx.gasprice); //Calculate gasRecovery in BNB from current gasprice

        // If the reward is < than the gasRecovery, cover gas recovery fees, this should be avoided by setting a high threshold for harvests
        if (gasRecovery > reward) { 
            gasRecovery = reward;
        }
        emit sdFeeSent(address(0),"GASRECOVERY", gasRecovery,reward);
            
        uint finalReward = reward - gasRecovery; //calculate the final reward after gas recovery
        if (finalReward > 0 ) {
            // convert reward into LP tokens to distribute
            uint rewardLP = addFunds(finalReward,address(0), false);

            // Using the LP Tokens, distribute the reward to all accounts. 
            (uint feeAmount, uint sendAmount, sendQueue[] memory _send) = sdPoolUtil.distContrib(s, [rewardLP, pendingCake]);

            //Calculate the amount of LP Tokens left to be staked
            rewardLP = rewardLP - feeAmount - sendAmount;

            //Stake the remaining LP tokens in the pool
            iMasterChef(s.exchangeInfo.chefContract).deposit(s.iData.poolId,rewardLP);
            emit sdLiquidityProvided(rewardLP);

            // Remove the FEE amount left over and convert to BNB
            sdPoolUtil.removeLiquidity(s, feeAmount, false);
            revertBalance();
            //process SendQueue
            if (sendAmount > 0 ) {
                uint _units = (sendAmount * 1e18)/(feeAmount + sendAmount); //calculate percentage of fee/send 
                uint _sBal = (address(this).balance * _units)/1e18; // from balance to be sent as fees, calculate the amount to be sent back to users

                for (uint i = 0;i< _send.length;i++) {
                    if (_send[i].user == address(0)) break; //if user is blank, it is the last one
                    
                    uint _amount = (_sBal * ((_send[i].amount * 1e18)/sendAmount))/1e18; //calculate amount to be sent back to user.

                    payable(_send[i].user).transfer(_amount);
                    emit sendFunds_evt(_send[i].user, _amount);
                }
            }
        }
        else {
            //If there is no harvest, commit all pending transactions.
            sdPoolUtil.commitTransactions(s);
        }


        //Calculate the fee from the opening balance, and the current balance
        uint _cBal = address(this).balance;
        _bal = _cBal > _bal?_cBal - _bal:_cBal;
        if(_bal > 0) {
            //send the fee to the collector
            payable(address(s.iData.feeCollector)).transfer(_bal);
            emit sdFeeSent(address(0), "HARVESTFEE", _bal,pendingCake);
        }

        s.iData.lastProcess = block.timestamp;

        return finalReward;
    }

    //@notice Function to revert token to base token 
    //@return amount of token reverted
    function revertBalance() internal {
        uint _rewards = ERC20(s.exchangeInfo.rewardToken).balanceOf(address (this));
        if (_rewards > 0 ){
            swap(_rewards, s.exchangeInfo.rewardToken,WBNB_ADDR);
        }

        uint _lpTokens = ERC20(s.iData.lpContract).balanceOf(address (this));
        if (_lpTokens > 0 ){
            sdPoolUtil.removeLiquidity(s, _lpTokens, false);
        }

        (uint _bal0, uint _bal1) = (ERC20(s.iData.token0).balanceOf(address(this)),ERC20(s.iData.token1).balanceOf(address(this)));
        
        if (s.iData.token0 != WBNB_ADDR && _bal0 > 0) {
            swap(_bal0, s.iData.token0,WBNB_ADDR);
        }
        
        if (s.iData.token1 != WBNB_ADDR && _bal1 > 0) {
            swap(_bal1, s.iData.token1,WBNB_ADDR);
        }
    }   

    ///@notice admin function to send back a token to a user
    ///@param token address of token to be sent
    ///@param _to_user address of user to be refunded
    ///@param _amount amount to send, must be < than token balance
    function rescueToken(address token, address _to_user,uint _amount) external allowAdmin{
        if (token == WBNB_ADDR && address(this).balance >= _amount) {
           payable(_to_user).transfer(_amount);
           return;
        }        

        uint _bal = ERC20(token).balanceOf(address(this));
        if(_amount > _bal) revert sdInsufficentFunds();
        ERC20(token).transfer(_to_user,_amount);
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


    ///@notice Get pending total pending reward for pool
    ///@dev set to private to avoid confilict with public facet sdData
    ///@return uint256 total pending reward
    function getPendingReward() private view returns (uint) {    
        (, bytes memory data) = s.exchangeInfo.chefContract.staticcall(abi.encodeWithSignature(s.exchangeInfo.pendingCall, s.iData.poolId,address(this)));

        return data.length==0?0:abi.decode(data,(uint256)) + ERC20(s.exchangeInfo.rewardToken).balanceOf(address(this));
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

    ///@notice remove funds from current pool and deposit into external pool
    ///@param _contract address of external pool
    function swapPool(address _contract) external {
        //liquidate current user and do not send funds
        uint _amount = performLiquidation(msg.sender,false);
        
        emit sdSwapPool(address(this), _contract, _amount,msg.sender);
        simpleDefi(payable(_contract)).deposit{value: _amount}(msg.sender);
    }
   
}