//SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.7;
import "../Interfaces.sol";

library slotsLib {
    struct slotStorage {
        uint poolId;
        string exchangeName;
        address lpContract;
        address token0;
        address token1;
    }

    struct sSlots {
        uint64 poolId;
        string exchangeName;
        address lpContract;
        address token0;
        address token1;
        address chefContract;
        address routerContract;
        address rewardToken;
        string pendingCall;
        address intermediateToken;
        
    }

    uint64 constant MAX_SLOTS = 100;

    error RequiredParameter(string param);
    error InactivePool(uint _poolID);
    error MaxSlots();
    error SlotOutOfBounds();
    event SlotsUpdated();
    event SlotsNew(uint _pid, string _exchange);


    ///@notice Add a new exchange/pool to slot pool
    ///@param _poolId The pool ID
    ///@param _exchangeName Exchange name
    ///@param slots current pool of slots
    ///@param beaconContract Address of the beacon contract
    ///@return new position in slot pool    
    function addSlot(uint64 _poolId, string memory _exchangeName, slotStorage[] storage slots,address beaconContract) internal returns (uint64) {
        uint64 _slotId = find_slot(_poolId, _exchangeName, slots);
        if (_slotId != MAX_SLOTS+1) return _slotId;

        if (slots.length+1 >= MAX_SLOTS) revert MaxSlots();
        updateSlot(MAX_SLOTS+1,_poolId,_exchangeName,slots,beaconContract);
        emit SlotsNew(_poolId,_exchangeName);
        return uint64(slots.length - 1);
    }

    ///@notice switch slots between two pools
    ///@param _fromPoolId The from pool ID
    ///@param _fromExchangeName The from exchange name
    ///@param _toPoolId The to pool ID
    ///@param _toExchangeName The to exchange name
    ///@param slots current pool of slots
    ///@param beaconContract Address of the beacon contract
    ///@return Current slots Pool
    function swapSlot(uint _fromPoolId, string memory _fromExchangeName, uint _toPoolId, string memory _toExchangeName, slotStorage[] storage slots, address beaconContract) internal returns (sSlots memory) {
        uint64 _fromSlotId = find_slot(_fromPoolId, _fromExchangeName, slots);
        if (_fromSlotId == MAX_SLOTS) revert InactivePool(_fromPoolId);
        return updateSlot(_fromSlotId, _toPoolId, _toExchangeName, slots, beaconContract);
    }


    ///@notice update slotid with new pool and exchange
    ///@param _slotId The slot ID
    ///@param _poolId The pool ID
    ///@param _exchangeName The exchange name
    ///@param slots current pool of slots
    ///@param beaconContract Address of the beacon contract
    ///@return Current slots Pool
    function updateSlot(uint64 _slotId, uint _poolId, string memory _exchangeName, slotStorage[] storage slots, address beaconContract) internal returns (sSlots memory) {
        
        if (_slotId != MAX_SLOTS+1 && keccak256(bytes(slots[_slotId].exchangeName)) != keccak256(bytes(_exchangeName))) {
            bool _found;
            for(uint i = 0; i < slots.length; i++) {
                if (keccak256(bytes(slots[i].exchangeName)) == keccak256(bytes(_exchangeName)) && i != _poolId) {
                    _found = true;
                    break;
                }
            }
            if (!_found) {
                iBeacon.sExchangeInfo memory old_exchangeInfo = iBeacon(beaconContract).getExchangeInfo(_exchangeName);
                address _oldLpContract;
                if (old_exchangeInfo.psV2){
                    _oldLpContract = iMasterChefv2(old_exchangeInfo.chefContract).lpToken(_poolId);
                }
                else {
                    (_oldLpContract,,,) = iMasterChef(old_exchangeInfo.chefContract).poolInfo(_poolId);
                }
                ERC20(old_exchangeInfo.rewardToken).approve(old_exchangeInfo.routerContract,0);

                ERC20(slots[_slotId].token0).approve(old_exchangeInfo.routerContract,0);
                ERC20(slots[_slotId].token1).approve(old_exchangeInfo.routerContract,0);
                iLPToken(_oldLpContract).approve(old_exchangeInfo.chefContract,0);        
                iLPToken(_oldLpContract).approve(old_exchangeInfo.routerContract,0);                            
            }
        }

        iBeacon.sExchangeInfo memory exchangeInfo = iBeacon(beaconContract).getExchangeInfo(_exchangeName);
        address _lpContract;
        uint _alloc;

        if (exchangeInfo.psV2) {
            _lpContract = iMasterChefv2(exchangeInfo.chefContract).lpToken(_poolId);
            (,,_alloc,,) = iMasterChefv2(exchangeInfo.chefContract).poolInfo(_poolId);
        }
        else {
            (_lpContract, _alloc,,) = iMasterChef(exchangeInfo.chefContract).poolInfo(_poolId);
        }

        if (_lpContract == address(0)) revert RequiredParameter("_lpContract");
        if (_alloc == 0) revert InactivePool(_poolId);

        if (_slotId == MAX_SLOTS+1) {
            slots.push(slotStorage(_poolId,_exchangeName,_lpContract, iLPToken(_lpContract).token0(),iLPToken(_lpContract).token1()));
            _slotId = uint64(slots.length - 1);
        } else {
            if (_slotId >= slots.length) revert SlotOutOfBounds();
            slots[_slotId] = slotStorage(_poolId,_exchangeName,_lpContract, iLPToken(_lpContract).token0(),iLPToken(_lpContract).token1());
        }     

        
        if (ERC20(exchangeInfo.rewardToken).allowance(address(this), exchangeInfo.routerContract) == 0) {
            ERC20(exchangeInfo.rewardToken).approve(exchangeInfo.routerContract,MAX_INT);
        }

        ERC20(slots[_slotId].token0).approve(exchangeInfo.routerContract,MAX_INT);
        ERC20(slots[_slotId].token1).approve(exchangeInfo.routerContract,MAX_INT);
        iLPToken(_lpContract).approve(exchangeInfo.chefContract,MAX_INT);        
        iLPToken(_lpContract).approve(exchangeInfo.routerContract,MAX_INT);                            

        emit SlotsUpdated();
        return sSlots(uint64(slots[_slotId].poolId),slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,exchangeInfo.chefContract,exchangeInfo.routerContract,exchangeInfo.rewardToken,exchangeInfo.pendingCall,exchangeInfo.intermediateToken);
    }

    ///@notice Remove slot from pool
    ///@param _poolId The pool ID
    ///@param _exchangeName The exchange name
    ///@param slots current pool of slots
    ///@return New length of the slots pool
    function removeSlot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots) internal returns (uint) {
        uint _slotId = find_slot(_poolId,_exchangeName,slots);
        if (_slotId >= slots.length) revert SlotOutOfBounds();
        if (slots.length>1) {
            slots[_slotId] = slots[slots.length-1];
        }
        
        slots.pop();

        emit SlotsUpdated();
        return slots.length;
    }

    ///@notice locate slotid using name and exchange
    ///@param _poolId The pool ID
    ///@param _exchangeName The exchange name
    ///@param slots current pool of slots
    ///@return slotid from slot pool
    function find_slot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots) private view returns (uint64){
        for(uint64 i = 0;i<slots.length;i++) {
            if (slots[i].poolId == _poolId && keccak256(bytes(slots[i].exchangeName)) == keccak256(bytes(_exchangeName))) { //this is to get around storage type differences...
                return i;
            }
        }
        return MAX_SLOTS+1;
    }

    ///@notice return slot information baesd on poolid and exchange
    ///@param _poolId The pool ID
    ///@param _exchangeName The exchange name
    ///@param slots current pool of slots
    ///@return slot sturcture
    function getSlot(uint _poolId, string memory _exchangeName, slotStorage[] storage slots, address beaconContract) internal view returns (sSlots memory) {
        uint64 _slotId = find_slot(_poolId,_exchangeName,slots);
        if (_slotId == MAX_SLOTS+1) return (sSlots(_slotId,"",address(0),address(0),address(0),address(0),address(0),address(0),"",address(0)));
        iBeacon.sExchangeInfo memory exchangeInfo = iBeacon(beaconContract).getExchangeInfo(slots[_slotId].exchangeName);

        return sSlots(uint64(slots[_slotId].poolId),slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,exchangeInfo.chefContract,exchangeInfo.routerContract,exchangeInfo.rewardToken,exchangeInfo.pendingCall,exchangeInfo.intermediateToken);
    }    

    ///@notice when depositing, check if new slot needs to be created before updating
    ///@param _poolId The pool ID
    ///@param _exchangeName The exchange name
    ///@param slots current pool of slots
    ///@param beaconContract Address of the beacon contract
    ///@return slot structure
    function getDepositSlot(uint64 _poolId, string memory _exchangeName, slotStorage[] storage slots, address beaconContract) internal returns (sSlots memory) {
        uint64 _slotId = find_slot(_poolId,_exchangeName,slots);
        if (_slotId == MAX_SLOTS+1) {
            emit SlotsNew(_poolId, _exchangeName);
            return updateSlot(uint64(slotsLib.MAX_SLOTS+1), _poolId, _exchangeName, slots, beaconContract);
        }
        else {
            iBeacon.sExchangeInfo memory exchangeInfo = iBeacon(beaconContract).getExchangeInfo(_exchangeName);
            return sSlots(uint64(slots[_slotId].poolId),slots[_slotId].exchangeName,slots[_slotId].lpContract, slots[_slotId].token0,slots[_slotId].token1,exchangeInfo .chefContract,exchangeInfo.routerContract,exchangeInfo.rewardToken,exchangeInfo.pendingCall,exchangeInfo.intermediateToken);
        }
    }    
}