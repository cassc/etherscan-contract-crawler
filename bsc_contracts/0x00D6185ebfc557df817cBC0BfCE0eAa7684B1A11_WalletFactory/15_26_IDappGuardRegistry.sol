// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

// Registry of all currently used DappGuard contracts
interface IDappGuardRegistry {
    function setDappGuardForGameContract(
        address gameContract,
        address dappGuardContract
    ) external;

    function updateDappGuardForGameContract(
        address gameContract,
        address dappGuardContract
    ) external;

    function removeDappGuardForGameContract(address gameContract) external;

    function getDappGuardForGameContract(address gameContract)
        external
        view
        returns (address);

    // Function to check if the gameContract is whitelisted
    function isWhitelistedGameContract(address gameContract)
        external
        view
        returns (bool);
}