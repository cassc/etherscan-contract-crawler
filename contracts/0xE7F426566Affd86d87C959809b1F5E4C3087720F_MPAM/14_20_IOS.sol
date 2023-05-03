//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
abstract contract IOS {
    bool public OPERATOR_FILTER_ENABLED = true;
    function __ChangeOperatorFilterState(bool State) external virtual;
}