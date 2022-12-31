// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Data.sol";

library UpdateData {
    struct Event {
        uint256 amount;
        uint256 index;
    }

    struct PendingRequest {
        Data.State state;
        uint256 amount;
        uint256 listPointer;
    }

    uint256 public constant MAX_INDEX_EVENT = 1e18;

    function searchIndexEvent(Event[] memory _data, uint256 _indexEvent) 
        internal pure returns (uint256 _index) {
        _index = MAX_INDEX_EVENT;
        if ( _data.length > 0){
            for (uint256 i = 0; i< _data.length; i++){
                if (_data[i].index == _indexEvent){
                    return i;
                }
            }   
        }          
    }

    function getTotalValueUntilLastEvent(Event[] memory _data, uint256 _indexEvent) 
        internal pure returns (uint256 _totalValue){ 
        if (_data.length > 0){
            for (uint256 i = 0; i < _data.length; i++){
                if (_data[i].index < _indexEvent){
                    _totalValue +=  _data[i].amount;
                }
            }
        }
    }

    function updateEventData(Event[] storage _data, uint256 _amount, 
        uint256 _indexEvent, uint256 _tolerance) internal {  
        uint256 _size = _data.length; 
        uint256 _availableAmount = getTotalValueUntilLastEvent(_data, _indexEvent);
        if (_amount > 0){
            require (_availableAmount >= _amount, "Formation.Fi: no available amount");
            uint256 _localAmount;
            uint256 k = 0; 
            Event memory _event;
            for (uint256 i = 0; i < _size ; i++){
                _event = _data[k];
                if (_event.index < _indexEvent){
                        _localAmount = Math.min(_amount, _event.amount);
                        _data[k].amount -= _localAmount;
                    _amount -= _localAmount;
                    if ((_data[k].amount <= _tolerance )){
                        deleteEventData(_data, k);
                    }
                    else {
                        k = k+1;
                    }
                    if (_amount == 0){
                        break;
                    }    
                }
            }
        }
    }
    function deleteEventData(Event[] storage _data, uint256 _index) 
        internal {
        require( _index <= _data.length - 1,
            "Formation.Fi: out of range");
        for (uint256 i = _index; i< _data.length; i++){
            if ( i+1 <= _data.length - 1){
                _data[i] = _data[i+1];
            }
        }
        _data.pop();   
    }

    function updatePendingRequestData(PendingRequest storage _pendingRequest, Event[] storage _data,
        address[] storage _usersOnPending, address _account, uint256 _amount, 
        uint256 _indexEvent, uint256 _tolerance, bool _isAddCase, bool _isCancel) internal {

        uint256 _index = searchIndexEvent(_data,  _indexEvent);
        if (_isAddCase){
            if (_pendingRequest.amount == 0){
                _pendingRequest.state = Data.State.PENDING;
                _pendingRequest.listPointer = _usersOnPending.length;
                _usersOnPending.push(_account);
            }
            _pendingRequest.amount +=  _amount;
            if (_index < MAX_INDEX_EVENT){
                _data[_index].amount += _amount;
            }
            else {
                _data.push(Event(_amount, _indexEvent));
            }

        }

        else {
            require(_pendingRequest.amount >= _amount, 
                "Formation.Fi: amount exceeds balance");
            _pendingRequest.amount = _pendingRequest.amount - _amount;
            if (_isCancel){
                require (((_index < MAX_INDEX_EVENT) && (_data[_index].amount >= _amount)), 
                    "Formation.Fi: Request is on processing");
                _data[_index].amount -= _amount;
                if (_data[_index].amount == 0){
                    deleteEventData(_data, _index);
                }
            }
            else {
                updateEventData(_data,  _amount, _indexEvent, _tolerance);
            }
        }
    }

    function deletePendingRequestData( address[] storage _usersOnPending, 
        uint256 _index) internal  returns (address _lastUser){
        _lastUser =  _usersOnPending[_usersOnPending.length - 1];
        _usersOnPending[_index] = _lastUser ;
        _usersOnPending.pop(); 
    }
   
}