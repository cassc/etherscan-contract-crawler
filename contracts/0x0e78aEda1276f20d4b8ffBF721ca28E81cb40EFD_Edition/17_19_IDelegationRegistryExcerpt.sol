// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.18;

/**
 * @title A partial interface taken from the IDelegationRegistry provided under
 *  the CC0-1.0 Creative Commons license by delegate.cash
 */
interface IDelegationRegistry {
    function checkDelegateForContract(
        address delegate,
        address vault,
        address contract_
    ) external returns (bool);
}