// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IConfigContract {
    function getIsEnabled(address tokenContract) external view returns (bool);
    function getAllTokenContractsDisabled() external view returns (bool);
    function getCanDestroyContract() external view returns (bool);
    function getTokenContractDisabled(address tokenContract) external view returns (bool);
    function getAdmin() external view returns (address);
    function validateRecoveredSignatureAddress(address recoveredAddress) external view returns (bool);
    function canRemoveFromSale(address sender) external view returns (bool);
    function canSetShares(address sender) external view returns (bool);
    function canMint(address sender) external view returns (bool);
    function getAddress(string calldata contractName) external view returns (address);
}