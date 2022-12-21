//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;
import "./Interfaces.sol";
import "./Storage.sol";

contract combineApp is Storage, Ownable, AccessControl {
    event sdDeposit(uint amount);
    event sdHoldBack(uint amount, uint total);
    event sdFeeSent(address _user, bytes16 _type, uint amount,uint total);
    event sdNewPool(uint64 oldPool, string oldExchange, uint newPool, string newExchange, uint amount);
    event sdLiquidityProvided(uint256 farmIn, uint256 wethIn, uint256 lpOut);
    event sdInitialized(uint64 poolId, address lpContract);
    event sdInitialize(uint64 _poolId, address _beacon, string _exchangeName, address _owner);
    // event sdHarvesterAdd(address _harvester);
    // event sdHarvesterRemove(address _harvester);
    event sdRescueToken(address _token,uint _amount);
    event sdLiquidated(uint _amount);
    event sdSetHoldback(uint _holdback);
    event sdRemoved(uint _removed);
    error sdLocked();
    error sdInitializedError();
    error sdInsufficentBalance();
    error sdRequiredParameter(string param);
    error sdInsufficentFunds();

    modifier lockFunction() {
        if (_locked) revert sdLocked();
        _locked = true;
        _;
        _locked = false;
    }
     
    modifier allowAdmin() {
        if (!(hasRole(HARVESTER,msg.sender) || owner() == msg.sender)) revert sdLocked();
        _;
    }
    ///@notice Initialize the proxy contract
    ///@param _poolId the id of the pool
    ///@param _beacon the address of the beacon contract
    ///@param _exchangeName name of the exchange to lookup on beacon
    ///@param _owner the address of the owner
    function initialize(uint64 _poolId, address _beacon, string memory _exchangeName, address _owner) public onlyOwner payable {
        if (_initialized) revert sdInitializedError();
        _initialized = true;
        beaconContract = _beacon;

        address harvester = iBeacon(beaconContract).getAddress("HARVESTER");
        feeCollector = iBeacon(beaconContract).getAddress("FEECOLLECTOR");
        (SwapFee,) = iBeacon(beaconContract).getFee(_exchangeName,"SWAPFEE",address(0)); //SWAP FEE is 1e8

        _setupRole(HARVESTER, harvester);
        _setupRole(DEFAULT_ADMIN_ROLE,owner());

        holdBack = 0; 
        
        setup(_poolId, _exchangeName);
        transferOwnership(_owner);
        revision = 1;
        
        emit sdInitialize(_poolId, _beacon,_exchangeName,_owner);
    }

    // ///@notice Add harvester permission to contract
    // ///@param _address address of user to add as harvester
    // function addHarvester(address _address) external onlyOwner {
    //     _setupRole(HARVESTER,_address);
    //     emit sdHarvesterAdd(_address);
    // }

    // ///@notice Remove user as harvester
    // ///@param _address address of user to remove as harvester
    // function removeHarvester(address _address) external onlyOwner{
    //     revokeRole(HARVESTER,_address);
    //     emit sdHarvesterRemove(_address);
    // }

    ///@notice create slot for new pool
    ///@param _poolId id of new pool
    ///@param _exchangeName name of exchange to lookup on beacon
    function setup(uint64 _poolId, string memory _exchangeName) private  {
        slotsLib.sSlots memory _slot = slotsLib.updateSlot(uint64(slotsLib.MAX_SLOTS+1),_poolId,_exchangeName, slots, beaconContract);

        if (msg.value > 0) {
            addFunds(_slot, msg.value,true);
            emit sdDeposit(msg.value);
        }
        emit sdInitialized(_poolId,_slot.lpContract);
    }
    
    ///@notice default receive function
    receive() external payable {}


    //@notice Add funds to specified pool and exhange
    ///@param _poolId id of pool to add funds to
    ///@param _exchangeName name of exchange to lookup on beacon
    function deposit(uint64 _poolId, string memory _exchangeName) external payable  {
        slotsLib.sSlots memory _slot = slotsLib.getDepositSlot(_poolId, _exchangeName,slots, beaconContract);
        uint deposit_amount = msg.value;
        uint pendingReward_val =  pendingReward(_slot);
        if (pendingReward_val > 0) {
            deposit_amount = deposit_amount + do_harvest(_slot, 0);
        }
        addFunds(_slot, deposit_amount,true);
        emit sdDeposit(deposit_amount);
    }

    ///@notice Swap funds from one pool/exchnage to another pool/exchange
    ///@param _fromPoolId id of pool to swap from
    ///@param _fromExchangeName name of exchange to lookup in slots
    ///@param _toPoolId id of pool to swap to
    ///@param _toExchangeName name of exchange to lookup in slots
    function swapPool(uint64 _fromPoolId, string memory _fromExchangeName, uint64 _toPoolId, string memory _toExchangeName) public allowAdmin {
        if(_fromPoolId == _toPoolId && keccak256(bytes(_fromExchangeName)) == keccak256(bytes(_toExchangeName))) revert sdRequiredParameter("New pool required");
        (uint _bal, slotsLib.sSlots memory _slot) = doSwap(_fromPoolId, _fromExchangeName);
        
        _slot = slotsLib.swapSlot(_fromPoolId, _fromExchangeName,_toPoolId, _toExchangeName,slots, beaconContract);
        addFunds(_slot,_bal,false);
        emit sdNewPool(_fromPoolId,_fromExchangeName, _toPoolId,_toExchangeName, _bal);
    }

    ///@notice Swap funds from one pool/exchnage to another pool/exchange in a different contract
    ///@param _toContract the address of the contract to swap to
    ///@param _fromPoolId id of pool to swap from
    ///@param _fromExchangeName name of exchange to lookup in slots
    ///@param _toPoolId id of pool to swap to
    ///@param _toExchangeName name of exchange to lookup in slots
    function swapContractPool(uint64 _fromPoolId, string memory _fromExchangeName, address _toContract, uint64 _toPoolId, string memory _toExchangeName) external allowAdmin {
        //liquidate current user and do not send funds
        if(_fromPoolId == _toPoolId && keccak256(bytes(_fromExchangeName)) == keccak256(bytes(_toExchangeName))) revert sdRequiredParameter("New pool required");

        (uint _bal, ) = doSwap(_fromPoolId, _fromExchangeName);

        iSimpleDefiSolo(payable(_toContract)).deposit{value: _bal}(_toPoolId,_toExchangeName);
    }

    ///@notice Performs common swap function
    ///@param _fromPoolId id of pool to swap from
    ///@param _fromExchangeName name of exchange to lookup in slots
    ///@return _bal the amount of funds to send to the new pool
    ///@return _slot the new slot

    function doSwap(uint64 _fromPoolId, string memory _fromExchangeName) private returns (uint, slotsLib.sSlots memory) {
        slotsLib.sSlots memory _slot = getSlot(_fromPoolId, _fromExchangeName);
                
        removeLiquidity(_slot);
        revertBalance(_slot);
        
        uint _bal = address(this).balance;
        if (_bal==0) revert sdInsufficentBalance();
        return (_bal, _slot);
    }


    ///@notice get pending rewards on a specific pool/exchange
    ///@param _poolId id of pool to get pending rewards on
    ///@param _exchangeName name of exchange to lookup in slots
    ///@return pending rewards 
    function pendingReward(uint64 _poolId, string memory _exchangeName) public view returns (uint) {        
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        if (_slot.poolId == slotsLib.MAX_SLOTS + 1) return 0;
        return pendingReward(_slot);
    }

    ///@notice get pending rewards on a specific slot id
    ///@param _slot slot to get pending rewards on
    ///@return pending rewards 
    function pendingReward(slotsLib.sSlots memory _slot) private view returns (uint) {
        (, bytes memory data) = _slot.chefContract.staticcall(abi.encodeWithSignature(_slot.pendingCall, _slot.poolId,address(this)));
        uint pendingReward_val = data.length==0?0:abi.decode(data,(uint256));
        if (pendingReward_val == 0) {
            pendingReward_val += ERC20(_slot.rewardToken).balanceOf(address(this));
        }
        return pendingReward_val;
    }

    ///@notice liquidate funds on a specific pool/exchange
    ///@param _poolId id of pool to liquidate
    ///@param _exchangeName name of exchange to lookup in slots    
    function liquidate(uint64 _poolId, string memory _exchangeName) public onlyOwner lockFunction {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        do_harvest(_slot, 0);
        removeLiquidity(_slot);
        revertBalance(_slot);        
        uint _total = address(this).balance;
        slotsLib.removeSlot(_slot.poolId, _slot.exchangeName,slots);

        _total = sendFee("SOLOLIQUIDATE",_total,0);

        payable(owner()).transfer(_total);
        emit sdLiquidated(_total);
    }
    
    ///@notice set holdback on rewards to be sent back to user
    ///@param _holdback amount of rewards to hold back
    function setHoldBack(uint64 _holdback) external onlyOwner {
        holdBack = _holdback;
        emit sdSetHoldback(_holdback);
    }
    
    ///@notice send holdback funds to user (BNB Balance)
    function sendHoldBack() external onlyOwner lockFunction{
        uint bal = address(this).balance;
        if (bal == 0) revert sdInsufficentBalance();
        payable(owner()).transfer(bal);
        emit sdHoldBack(bal,bal);
    }
    
    ///@notice Manually perform a harvest on a specific pool/exchange
    ///@param _poolId id of pool to harvest on
    ///@param _exchangeName name of exchange to lookup in slots
    function harvest(uint64  _poolId, string memory _exchangeName) public lockFunction allowAdmin {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        uint64 _offset = iBeacon(beaconContract).getConst('DEFAULT','HARVESTSOLOGAS');
        uint startGas = gasleft() + 21000 + _offset;
        uint split = do_harvest(_slot, 1);
        
        addFunds(_slot, split,false);
        if (msg.sender != owner()) {
            lastGas = startGas - gasleft();
        }
    }
    
    ///@notice helper function to return balance of 2 tokens in a pool
    ///@param _slot slot to get balance of
    ///@return _bal0 of tokens of token0 from pool
    ///@return _bal1 of tokens of token1 from pool
    function tokenBalance(slotsLib.sSlots memory _slot) private view returns (uint _bal0,uint _bal1) {
        _bal0 = ERC20(_slot.token0).balanceOf(address(this));
        _bal1 = ERC20(_slot.token1).balanceOf(address(this));
    }    
    
    ///@notice helper function to return balance of specified token from contract to the user
    ///@param token address of token to recover
    function rescueToken(address token) external onlyOwner{
        uint _bal = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(owner(),_bal);
        emit sdRescueToken(token,_bal);
    }

    ///@notice Internal funciton to add funds to a specified slot
    ///@param _slot slot to add funds to
    ///@param inValue amount of funds to add
    function addFunds(slotsLib.sSlots memory _slot, uint inValue, bool _depositFee) private  {
        if (inValue==0) revert sdInsufficentBalance();
        if (_depositFee) {
            inValue = sendFee("DEPOSIT",inValue,0);
        }

        uint amount0;
        uint amount1;
        uint split;

        if (_slot.token0 == WBNB_ADDR || _slot.token1 == WBNB_ADDR) {
            split = (inValue*50)/100;        
            amount0 = (_slot.token0 != WBNB_ADDR) ? swap(_slot,split,WBNB_ADDR,_slot.token0) : split;    
            amount1 = (_slot.token1 != WBNB_ADDR) ? swap(_slot,split,WBNB_ADDR, _slot.token1) : split;
        }
        else {
            amount0 = swap(_slot, inValue,WBNB_ADDR,_slot.token0);    
            split = (amount0*50)/100;  
            split = split - ((split*SwapFee)/1e10); 
            amount1 = swap(_slot, split,_slot.token0,_slot.token1);
        }

        addLiquidity(_slot,amount0,amount1);
    }

    ///@notice Internal function to add liquidity to a pool
    ///@dev amount0 and amount1 should be the same value (converted to/from BNB)
    ///@param _slot slot to add liquidity to
    ///@param amount0 amount of liquidity to add of token0
    ///@param amount1 amount of liquidity to add of token1
    function addLiquidity(slotsLib.sSlots memory _slot, uint amount0, uint amount1) private {
        uint amountA;
        uint amountB;
        uint liquidity;
                

        if (_slot.token1 == WBNB_ADDR || _slot.token0 == WBNB_ADDR) {
            (amount0,amount1) = _slot.token0 == WBNB_ADDR?(amount0,amount1):(amount1,amount0);
            address token = _slot.token0 == WBNB_ADDR?_slot.token1:_slot.token0;
            (amountA, amountB, liquidity) = iRouter(_slot.routerContract).addLiquidityETH{value: amount0}(token, amount1, 0,0, address(this), block.timestamp);
        }
        else {
            ( amountA,  amountB, liquidity) = iRouter(_slot.routerContract).addLiquidity(_slot.token0, _slot.token1, amount0, amount1, 0, 0, address(this), block.timestamp);
        }

        iMasterChef(_slot.chefContract).deposit(_slot.poolId,liquidity);
        emit sdLiquidityProvided(amountA, amountB, liquidity);
    }
    
    ///@notice Internal function to swap 2 tokens
    ///@param _slot slot to swap tokens on
    ///@param amountIn amount of tokens to swap
    ///@param _token0 address of tokens to swap
    ///@param _token1 address of tokens to swap
    ///@return amountOut amount of tokens swapped
    function swap(slotsLib.sSlots memory _slot, uint amountIn, address _token0, address _token1) private returns (uint){
        if (amountIn == 0) revert sdInsufficentBalance();

        uint pathLength = (_slot.intermediateToken != address(0) && _token0 != _slot.intermediateToken && _token1 != _slot.intermediateToken) ? 3 : 2;
        address[] memory swapPath = new address[](pathLength);
        
        swapPath[0] = _token0;
        swapPath[pathLength-1] = _token1;
        if (pathLength == 3) {
            swapPath[1] = _slot.intermediateToken;
        }

        uint _cBalance = address(this).balance;
        if (swapPath[0] == WBNB_ADDR && swapPath[pathLength-1] == WBNB_ADDR) {
            if (ERC20(WBNB_ADDR).balanceOf(address(this)) >= amountIn) {
                iWBNB(WBNB_ADDR).withdraw(amountIn);
                _cBalance = address(this).balance;
            }
            if (amountIn > address(this).balance) revert sdInsufficentFunds();
            return amountIn;
        }

        uint[] memory amounts;

        uint deadline = block.timestamp + 600;

        if (swapPath[0] == WBNB_ADDR && ERC20(WBNB_ADDR).balanceOf(address(this)) >= amountIn) {
            iWBNB(WBNB_ADDR).withdraw(amountIn);
            _cBalance = address(this).balance;
        }

        if (swapPath[pathLength - 1] == WBNB_ADDR) {
            amounts = iRouter(_slot.routerContract).swapExactTokensForETH(amountIn, 0,  swapPath, address(this), deadline);
        } else if (swapPath[0] == WBNB_ADDR && _cBalance >= amountIn) {
            amounts = iRouter(_slot.routerContract).swapExactETHForTokens{value: amountIn}(0,swapPath,address(this),deadline);
        }
        else {
            amounts = iRouter(_slot.routerContract).swapExactTokensForTokens(amountIn, 0,swapPath,address(this),deadline);
        }
        return amounts[pathLength-1];
    }
    

    ///@notice Internal function to harvest spool
    ///@param _slot slot to harvest
    ///@param revert_trans (0 - return 0 on failure, 1 - revert on failure)
    ///@return finalReward  Final amount of reward returned.
    function do_harvest(slotsLib.sSlots memory _slot,uint revert_trans) private returns (uint) {
        uint pendingCake = 0;
        pendingCake = pendingReward(_slot);
        if (pendingCake == 0) {
            if (revert_trans == 1) {
                revert sdInsufficentBalance();
            }
            else {
                    return 0;
            }
        }
        
        iMasterChef(_slot.chefContract).deposit(_slot.poolId,0);
        pendingCake = ERC20(_slot.rewardToken).balanceOf(address(this));

        pendingCake = swap(_slot, pendingCake,_slot.rewardToken, WBNB_ADDR);
        
        uint finalReward = sendFee('HARVEST',pendingCake, ((lastGas * tx.gasprice))); // lastGas is here in case 3rd party harvester is used, should normally be 0
        
        if (holdBack > 0) {
            uint holdbackAmount = (finalReward * holdBack)/1e20;
            finalReward = finalReward - holdbackAmount;
            payable(owner()).transfer(holdbackAmount);
            emit sdHoldBack(holdbackAmount,finalReward);

        }
        return finalReward;
    }
    
    ///@notice Internal function to remove liquididty from pool
    ///@param _slot slot to remove liquidity from
    function removeLiquidity(slotsLib.sSlots memory _slot) private {
        uint amountTokenA;
        uint amountTokenB;
        uint deadline = block.timestamp + 600;

        (uint _lpBal,) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
        iMasterChef(_slot.chefContract).withdraw(_slot.poolId,_lpBal);
        
        uint _removed = ERC20(_slot.lpContract).balanceOf(address(this));
        emit sdRemoved(_removed);
        
        (address token0,address token1) = _slot.token0==WBNB_ADDR?(_slot.token1,_slot.token0):(_slot.token0,_slot.token1);

        if (token1 == WBNB_ADDR)
            (amountTokenA, amountTokenB) = iRouter(_slot.routerContract).removeLiquidityETH(token0,_removed,0,0,address(this), deadline);
        else
            (amountTokenA, amountTokenB) = iRouter(_slot.routerContract).removeLiquidity(token0,token1,_removed,0,0,address(this), deadline);
    }

    ///@notice Internal function to convert token0/token1 to BNB/Base Token
    ///@param _slot slot to convert
    function revertBalance(slotsLib.sSlots memory _slot) private {
        uint amount0 = 0;

        uint _rewards = ERC20(_slot.rewardToken).balanceOf(address (this));
        if (_rewards > 0 ){
            amount0 = swap(_slot, _rewards, _slot.rewardToken, WBNB_ADDR);
        }

        (uint _bal0, uint _bal1) = tokenBalance(_slot);
        
        if (_bal0 > 0) {
            amount0 += swap(_slot, _bal0, _slot.token0, WBNB_ADDR);
        }
        
        if (_bal1 > 0) {
            amount0 += swap(_slot, _bal1, _slot.token1, WBNB_ADDR);
        }
    }
    
    ///@notice returns status of pool on specific pool/exchange
    ///@param _poolId pool to get info from
    ///@param _exchangeName name of exchange to lookup in slots
    ///@return masterchef balance 0
    ///@return masterchef balance 1
    ///@return token0 balance
    ///@return token1 balance
    ///@return contract balance of rewward token
    ///@return total of BNB
    function userInfo(uint64  _poolId, string memory _exchangeName) public view allowAdmin returns (uint,uint,uint,uint,uint,uint) {
        slotsLib.sSlots memory _slot = getSlot(_poolId, _exchangeName);
        // bitflip = !bitflip;
        if (_slot.lpContract == address(0))  return (0,0,0,0,0,0);
        
        (uint a, uint b) = iMasterChef(_slot.chefContract).userInfo(_slot.poolId,address(this));
        (uint c, uint d) = tokenBalance(_slot);
        uint e = ERC20(_slot.rewardToken).balanceOf(address(this));
        uint f = address(this).balance;
        return (a,b,c,d,e,f);
    }

    ///@notice Internal function to handle fees for specific type
    ///@param _type type of fee
    ///@param _total amount of fee
    ///@param  _extra fee to add (such as gas fee)
    ///@return _total amount of fee sent
    function sendFee(string memory _type, uint _total, uint _extra) private returns (uint){
        (uint feeAmt,) = iBeacon(beaconContract).getFee('DEFAULT',_type,owner());
        uint feeAmount = ((_total * feeAmt)/100e18) + _extra;
        if (feeAmount > _total) feeAmount = _total; // required to recover fee
        uint _bal = address(this).balance;

        if(feeAmount > 0 && _bal > feeAmount) {
            if (feeAmount > _total) {
                feeAmount = _total;
                _total = 0;
            }
            else {
                _total = _total - feeAmount;
            }
            payable(address(feeCollector)).transfer(feeAmount);
            bytes memory _t = bytes(_type);
            emit sdFeeSent(owner(), bytes16(_t), feeAmount,_total);
        }
        return _total;
    }

    ///@notice Public function to get slot for pool/exchange
    ///@param _poolId pool to get info from
    ///@param _exchangeName name of exchange to lookup in slots
    ///@return slot info
    function getSlot(uint64 _poolId, string memory _exchangeName) public view returns (slotsLib.sSlots memory) {
        return slotsLib.getSlot(_poolId, _exchangeName, slots, beaconContract);
    }
}