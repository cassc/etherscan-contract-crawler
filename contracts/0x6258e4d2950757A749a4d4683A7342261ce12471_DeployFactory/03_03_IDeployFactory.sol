// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IDeployFactory {

    // @notice Deploy to deterministic addresses without an initcode factor.
    // @author Import from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
    // @param salt - the bytes to deterministic address
    // @param creationCode - code to be deployed, include the init parameters.
    // @param value - native value when calling to deploy
    function deploy(bytes32 salt, bytes memory creationCode, uint256 value) external;

    // @notice Get the deterministic addresses.
    // @param salt - the bytes to deterministic address
    function getAddress(bytes32 salt) external view returns (address);
}