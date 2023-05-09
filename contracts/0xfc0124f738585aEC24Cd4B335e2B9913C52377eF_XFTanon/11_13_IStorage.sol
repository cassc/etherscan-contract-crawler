// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface for Storage.sol contract
 */
interface IStorage {
    
    function store(address depositor, bytes calldata encryptedNote, bytes32 _passwordHash) external;

    function xcrypt(bytes memory note, bytes32 key) external view returns (bytes memory);
}