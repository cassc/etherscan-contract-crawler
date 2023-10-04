//SPDX-License-Identifier: MIT
/**
 * @title DelegateCashEnabled
 * @author @brougkr
 * @notice For Easily Integrating `delegate.cash`
 */
pragma solidity 0.8.19;
abstract contract DelegateCashEnabled
{
    address private constant _DN = 0x00000000000076A84feF008CDAbe6409d2FE638B;
    IDelegation public constant DelegateCash = IDelegation(_DN);
}

interface IDelegation
{
    /**
     * @dev Returns If A Vault Has Delegated To The Delegate
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);
}