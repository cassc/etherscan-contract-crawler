// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface ISignersRepository {
    event SignerAdded(address, address);
    event SignerRemoved(address, address);


    function containsSigner(address) external view returns (bool);
    function containsSigners(address[] calldata) external view returns (bool);
    function signersLength() view external returns (uint256);
    function setupSigner(address) external;
}