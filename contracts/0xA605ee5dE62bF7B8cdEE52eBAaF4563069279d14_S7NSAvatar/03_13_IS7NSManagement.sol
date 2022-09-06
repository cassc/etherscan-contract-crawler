// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

/**
   @title IS7NSManagement contract
   @dev Provide interfaces that allow interaction to S7NSManagement contract
*/
interface IS7NSManagement {
    function treasury() external view returns (address);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function paymentTokens(address _token) external view returns (bool);
    function halted() external view returns (bool);
}