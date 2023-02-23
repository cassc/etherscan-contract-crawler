pragma solidity ^0.6.12;
// SPDX-License-Identifier: MIT

import "./Strings.sol";

library Utils {
    using Strings for string;
    function getPayable2(address _account) internal pure returns(address payable) {
        return(address(uint160(_account)));
    }

    function getVersionElements(string memory _version) internal pure returns(uint[] memory) {
        uint[] memory _result = new uint[](3);
        bool _found;
        uint _pos1;
        uint _pos2;
        (_found, _pos1) = _version.strPos(".", 1);
        if (_found) {
            _found = false;
            _result[0] = _version.substr(0,_pos1).strToUint();
            (_found, _pos2) = _version.strPos(".", 2);
            if (_found) {
                _result[1] = _version.substr(_pos1+1, _pos2-_pos1-1).strToUint();
                _result[2] = _version.substr(_pos2+1, _version.len()).strToUint();
            }
            else
                _result[1] = _version.substr(_pos1+1, _version.len()).strToUint();
        }
        else 
            _result[0] = _version.strToUint();
        return(_result);
    }

    function compareVersion(string memory _v1, string memory _v2) internal pure returns(bool) {
        uint[] memory _vv1 = getVersionElements(_v1);
        uint[] memory _vv2 = getVersionElements(_v2);
        return(_vv2[0] >= _vv1[0] && _vv2[1] >= _vv1[1] && _vv2[2] > _vv1[2] );
    }

    function deleteArrayElement(uint[] storage _array, uint _content) internal returns(bool) {
        bool found = false;
        for (uint i = 0; i < _array.length; i++) {
            if (_array[i] == _content) {
                deleteArrayElementByIndex(_array, i);
                found = true;
                break;
            }
        }
        return(found);
    }

    function deleteArrayElementByIndex(uint[] storage _array, uint _index) internal {
        require(_index < _array.length);
        for (uint i = _index; i < _array.length-1; i++) 
            _array[i] = _array[i+1];
        _array.pop();
    }

}