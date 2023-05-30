// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDelegationRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);
}