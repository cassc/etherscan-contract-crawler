// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;
import "IDappGuardRegistry.sol";
import "IDappGuard.sol";
import "AccessManager.sol";

contract DappGuardRegistry is IDappGuardRegistry, AccessManager {
    mapping(address => address) public dappGuards;

    constructor(IRoleRegistry _roleRegistry) {
        setRoleRegistry(_roleRegistry);
    }

    function setDappGuardForGameContract(
        address gameContract,
        address dappGuardContract
    ) external override onlyRole(Roles.DAPP_GUARD) {
        require(
            dappGuards[gameContract] == address(0),
            "DappGuard already set!"
        );
        dappGuards[gameContract] = dappGuardContract;
    }

    function updateDappGuardForGameContract(
        address gameContract,
        address dappGuardContract
    ) external override onlyRole(Roles.DAPP_GUARD) {
        removeDappGuardForGameContract(gameContract);
        dappGuards[gameContract] = dappGuardContract;
    }

    function getDappGuardForGameContract(address gameContract)
        external
        view
        override
        returns (address)
    {
        return dappGuards[gameContract];
    }

    function isWhitelistedGameContract(address gameContract)
        external
        view
        override
        returns (bool)
    {
        return dappGuards[gameContract] != address(0);
    }

    function removeDappGuardForGameContract(address gameContract)
        public
        override
        onlyRole(Roles.DAPP_GUARD)
    {
        require(
            dappGuards[gameContract] != address(0),
            "DappGuard already set!"
        );
        IDappGuard(dappGuards[gameContract]).kill();
        dappGuards[gameContract] = address(0);
    }
}