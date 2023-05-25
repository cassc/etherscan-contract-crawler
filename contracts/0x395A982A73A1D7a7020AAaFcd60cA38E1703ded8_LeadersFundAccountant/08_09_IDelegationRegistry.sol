// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IDelegationRegistry {
    /**
    * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
    * @param delegate The hotwallet to act on your behalf
    * @param contract_ The address for the contract you're delegating
    * @param vault The cold wallet who issued the delegation
    */
    function checkDelegateForContract(address delegate, address vault, address contract_) external view returns (bool);
}