// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IChangeableVariables {
    event AddressChanged(string fieldName, address previousAddress, address newAddress);
    event ValueChanged(string fieldName, uint previousValue, uint newValue);
    event StringValueChanged(string fieldName, string previousValue, string newValue);
    event BoolValueChanged(string fieldName, bool previousValue, bool newValue);
}