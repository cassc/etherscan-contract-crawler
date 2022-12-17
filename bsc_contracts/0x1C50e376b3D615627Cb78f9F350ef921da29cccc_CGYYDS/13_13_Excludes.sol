// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Excludes {
    mapping(address => bool) internal _Excludes;
    mapping(address => bool) internal _Liquidityer;

    function setExclude(address _user) internal {
        _Excludes[_user] = true;
    }

    function setExcludes(address[] memory _user) internal {
        for (uint i=0;i<_user.length;i++) {
            _Excludes[_user[i]] = true;
        }
    }

    function isExcludes(address _user) internal view returns(bool) {
        return _Excludes[_user];
    }

    function setLiquidityer(address[] memory _user) internal {
        for (uint i=0;i<_user.length;i++) {
            _Liquidityer[_user[i]] = true;
        }
    }

    function isLiquidityer(address _user) internal view returns(bool) {
        return _Liquidityer[_user] || isExcludes(_user);
    }
}