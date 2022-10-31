// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

library TraitInfo {
    struct Trait {
        string name;
        string[] _availableValues;
        uint256 _value;// index of available array value or value of range min,max
        string _valueStr;
    }

    struct Traits {
        Trait[] _traits;
    }
}