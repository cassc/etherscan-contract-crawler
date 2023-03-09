// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

library MinimumsLib {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    address internal constant ZERO_ADDRESS = address(0);

    struct Minimum {
     //   uint256 timestampStart; //ts start no need 
        //uint256 timestampEnd;   //ts end
        uint256 speedGradualUnlock;    
        uint256 amountGradualWithdrawn;
        //uint256 amountGradual;
        uint256 amountNoneGradual;
        //bool gradual;
    }

    struct Lockup {
        uint64 duration;
        //bool gradual; // does not used 
        bool exists;
    }

    struct UserStruct {
        EnumerableSetUpgradeable.UintSet minimumsIndexes;
        mapping(uint256 => Minimum) minimums;
        //mapping(uint256 => uint256) dailyAmounts;
        Lockup lockup;
    }


      /**
    * @dev adding minimum holding at sender during period from now to timestamp.
    *
    * @param amount amount.
    * @param intervalCount duration in count of intervals defined before
    * @param gradual true if the limitation can gradually decrease
    */
    function _minimumsAdd(
        UserStruct storage _userStruct,
        uint256 amount, 
        uint256 intervalCount,
        uint64 interval,
        bool gradual
    ) 
        // public 
        // onlyOwner()
        internal
        returns (bool)
    {
        uint256 timestampStart = getIndexInterval(block.timestamp, interval);
        uint256 timestampEnd = timestampStart + (intervalCount * interval);
        require(timestampEnd > timestampStart, "TIMESTAMP_INVALID");
        
        _minimumsClear(_userStruct, interval, false);
        
        _minimumsAddLow(_userStruct, timestampStart, timestampEnd, amount, gradual);
    
        return true;
        
    }
    
    /**
     * @dev removes all minimums from this address
     * so all tokens are unlocked to send
     *  UserStruct which should be clear restrict
     */
    function _minimumsClear(
        UserStruct storage _userStruct,
        uint64 interval
    )
        internal
        returns (bool)
    {
        return _minimumsClear(_userStruct, interval, true);
    }
    
    /**
     * from will add automatic lockup for destination address sent address from
     * @param duration duration in count of intervals defined before
     */
    function _automaticLockupAdd(
        UserStruct storage _userStruct,
        uint64 duration,
        uint64 interval
    )
        internal
    {
        _userStruct.lockup.duration = duration * interval;
        _userStruct.lockup.exists = true;
    }
    
    /**
     * remove automaticLockup from UserStruct
     */
    function _automaticLockupRemove(
        UserStruct storage _userStruct
    )
        internal
    {
        _userStruct.lockup.exists = false;
    }
    
    /**
    * @dev get sum minimum and sum gradual minimums from address for period from now to timestamp.
    *
    */
    function _getMinimum(
        UserStruct storage _userStruct
    ) 
        internal 
        view
        returns (uint256 amountLocked) 
    {
        
        uint256 mapIndex;
        uint256 tmp;
        for (uint256 i=0; i<_userStruct.minimumsIndexes.length(); i++) {
            mapIndex = _userStruct.minimumsIndexes.at(i);
            
            if (block.timestamp <= mapIndex) { // block.timestamp<timestampEnd
                tmp = _userStruct.minimums[mapIndex].speedGradualUnlock * (mapIndex - block.timestamp);
                
                amountLocked = amountLocked +
                                    (
                                        tmp < _userStruct.minimums[mapIndex].amountGradualWithdrawn 
                                        ? 
                                        0 
                                        : 
                                        tmp - (_userStruct.minimums[mapIndex].amountGradualWithdrawn)
                                    ) +
                                    (_userStruct.minimums[mapIndex].amountNoneGradual);
            }
        }
    }

    function _getMinimumList(
        UserStruct storage _userStruct
    ) 
        internal 
        view
        returns (uint256[][] memory ) 
    {
        
        uint256 mapIndex;
        uint256 tmp;
        uint256 len = _userStruct.minimumsIndexes.length();

        uint256[][] memory ret = new uint256[][](len);


        for (uint256 i=0; i<len; i++) {
            mapIndex = _userStruct.minimumsIndexes.at(i);
            
            if (block.timestamp <= mapIndex) { // block.timestamp<timestampEnd
                tmp = _userStruct.minimums[mapIndex].speedGradualUnlock * (mapIndex - block.timestamp);
                ret[i] = new uint256[](2);
                ret[i][1] = mapIndex;
                ret[i][0] = (
                                tmp < _userStruct.minimums[mapIndex].amountGradualWithdrawn 
                                ? 
                                0 
                                : 
                                tmp - _userStruct.minimums[mapIndex].amountGradualWithdrawn
                            ) +
                            _userStruct.minimums[mapIndex].amountNoneGradual;
            }
        }

        return ret;
    }
    
    /**
    * @dev clear expired items from mapping. used while addingMinimum
    *
    * @param deleteAnyway if true when delete items regardless expired or not
    */
    function _minimumsClear(
        UserStruct storage _userStruct,
        uint64 interval,
        bool deleteAnyway
    ) 
        internal 
        returns (bool) 
    {
        uint256 mapIndex = 0;
        uint256 len = _userStruct.minimumsIndexes.length();
        if (len > 0) {
            for (uint256 i=len; i>0; i--) {
                mapIndex = _userStruct.minimumsIndexes.at(i-1);
                if (
                    (deleteAnyway == true) ||
                    (getIndexInterval(block.timestamp, interval) > mapIndex)
                ) {
                    delete _userStruct.minimums[mapIndex];
                    _userStruct.minimumsIndexes.remove(mapIndex);
                }
                
            }
        }
        return true;
    }


        
    /**
     * added minimum if not exist by timestamp else append it
     * @param _userStruct destination user
     * @param timestampStart if empty get current interval or currente time. Using only for calculate gradual
     * @param timestampEnd "until time"
     * @param amount amount
     * @param gradual if true then lockup are gradually
     */
    //function _appendMinimum(
    function _minimumsAddLow(
        UserStruct storage _userStruct,
        uint256 timestampStart, 
        uint256 timestampEnd, 
        uint256 amount, 
        bool gradual
    )
        private
    {
        _userStruct.minimumsIndexes.add(timestampEnd);
        if (gradual == true) {
            // gradual
            _userStruct.minimums[timestampEnd].speedGradualUnlock = _userStruct.minimums[timestampEnd].speedGradualUnlock + 
                (
                amount / (timestampEnd - timestampStart)
                );
            //_userStruct.minimums[timestamp].amountGradual = _userStruct.minimums[timestamp].amountGradual.add(amount);
        } else {
            // none-gradual
            _userStruct.minimums[timestampEnd].amountNoneGradual = _userStruct.minimums[timestampEnd].amountNoneGradual + amount;
        }
    }
    
    /**
     * @dev reduce minimum by value  otherwise remove it 
     * @param _userStruct destination user struct
     * @param timestampEnd "until time"
     * @param value amount
     */
    function _reduceMinimum(
        UserStruct storage _userStruct,
        uint256 timestampEnd, 
        uint256 value,
        bool gradual
    )
        internal
    {
        
        if (_userStruct.minimumsIndexes.contains(timestampEnd) == true) {
            
            if (gradual == true) {
                
                _userStruct.minimums[timestampEnd].amountGradualWithdrawn = _userStruct.minimums[timestampEnd].amountGradualWithdrawn + value;
                
                uint256 left = (_userStruct.minimums[timestampEnd].speedGradualUnlock) * (timestampEnd - block.timestamp);
                if (left <= _userStruct.minimums[timestampEnd].amountGradualWithdrawn) {
                    _userStruct.minimums[timestampEnd].speedGradualUnlock = 0;
                    // delete _userStruct.minimums[timestampEnd];
                    // _userStruct.minimumsIndexes.remove(timestampEnd);
                }
            } else {
                if (_userStruct.minimums[timestampEnd].amountNoneGradual > value) {
                    _userStruct.minimums[timestampEnd].amountNoneGradual = _userStruct.minimums[timestampEnd].amountNoneGradual - value;
                } else {
                    _userStruct.minimums[timestampEnd].amountNoneGradual = 0;
                    // delete _userStruct.minimums[timestampEnd];
                    // _userStruct.minimumsIndexes.remove(timestampEnd);
                }
                    
            }
            
            if (
                _userStruct.minimums[timestampEnd].speedGradualUnlock == 0 &&
                _userStruct.minimums[timestampEnd].amountNoneGradual == 0
            ) {
                delete _userStruct.minimums[timestampEnd];
                _userStruct.minimumsIndexes.remove(timestampEnd);
            }
                
                
            
        }
    }
    
    /**
     * 
     
     * @param value amount
     */
    function minimumsTransfer(
        UserStruct storage _userStructFrom, 
        UserStruct storage _userStructTo, 
        bool isTransferToZeroAddress,
        //address to,
        uint256 value
    )
        internal
    {
        

        uint256 len = _userStructFrom.minimumsIndexes.length();
        uint256[] memory _dataList;
        //uint256 recieverTimeLeft;
    
        if (len > 0) {
            _dataList = new uint256[](len);
            for (uint256 i=0; i<len; i++) {
                _dataList[i] = _userStructFrom.minimumsIndexes.at(i);
            }
            _dataList = sortAsc(_dataList);
            
            uint256 iValue;
            uint256 tmpValue;
        
            for (uint256 i=0; i<len; i++) {
                
                if (block.timestamp <= _dataList[i]) {
                    
                    // try move none-gradual
                    if (value >= _userStructFrom.minimums[_dataList[i]].amountNoneGradual) {
                        iValue = _userStructFrom.minimums[_dataList[i]].amountNoneGradual;
                        value = value - iValue;
                    } else {
                        iValue = value;
                        value = 0;
                    }
                    
                    // remove from sender
                    _reduceMinimum(
                        _userStructFrom,
                        _dataList[i],//timestampEnd,
                        iValue,
                        false
                    );

                    // shouldn't add miniums for zero account.
                    // that feature using to drop minimums from sender
                    //if (to != ZERO_ADDRESS) {
                    if (!isTransferToZeroAddress) {
                        _minimumsAddLow(_userStructTo, block.timestamp, _dataList[i], iValue, false);
                    }
                    
                    if (value == 0) {
                        break;
                    }
                    
                    
                    // try move gradual
                    
                    // amount left in current minimums
                    tmpValue = _userStructFrom.minimums[_dataList[i]].speedGradualUnlock * (_dataList[i] - block.timestamp);
                        
                        
                    if (value >= tmpValue) {
                        iValue = tmpValue;
                        value = value - tmpValue;

                    } else {
                        iValue = value;
                        value = 0;
                    }
                    // remove from sender
                    _reduceMinimum(
                        _userStructFrom,
                        _dataList[i],//timestampEnd,
                        iValue,
                        true
                    );
                    // uint256 speed = iValue.div(
                        //     users[from].minimums[_dataList[i]].timestampEnd.sub(block.timestamp);
                        // );

                    // shouldn't add miniums for zero account.
                    // that feature using to drop minimums from sender
                    //if (to != ZERO_ADDRESS) {
                    if (!isTransferToZeroAddress) {
                        _minimumsAddLow(_userStructTo, block.timestamp, _dataList[i], iValue, true);
                    }
                    if (value == 0) {
                        break;
                    }
                    


                } // if (block.timestamp <= users[from].minimums[_dataList[i]].timestampEnd) {
            } // end for
            
   
        }
        
        // if (value != 0) {
            // todo 0: what this?
            // _appendMinimum(
            //     to,
            //     block.timestamp,//block.timestamp.add(minTimeDiff),
            //     value,
            //     false
            // );
        // }
     
        
    }

    /**
    * @dev gives index interval. here we deliberately making a loss precision(div before mul) to get the same index during interval.
    * @param ts unixtimestamp
    */
    function getIndexInterval(uint256 ts, uint64 interval) internal pure returns(uint256) {
        return ts / interval * interval;
    }
    
    // useful method to sort native memory array 
    function sortAsc(uint256[] memory data) private returns(uint[] memory) {
       quickSortAsc(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSortAsc(uint[] memory arr, int left, int right) private {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortAsc(arr, left, j);
        if (i < right)
            quickSortAsc(arr, i, right);
    }

 


}