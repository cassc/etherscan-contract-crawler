pragma solidity 0.8.9;

import {IModuleFactory} from "../../interfaces/IModuleFactory.sol";

import {Spigot} from "../spigot/Spigot.sol";
import {Escrow} from "../escrow/Escrow.sol";

/**
  @author - Mo
*/
contract ModuleFactory is IModuleFactory {
    /**
     * see Spigot.constructor
     * @notice - Deploys a Spigot module that can be used in a LineOfCredit
     */
    function deploySpigot(address owner, address operator) external returns (address module) {
        module = address(new Spigot(owner, operator));
        emit DeployedSpigot(module, owner, operator);
    }

    /**
     * see Escrow.constructor
     * @notice - Deploys an Escrow module that can be used in a LineOfCredit
     */
    function deployEscrow(
        uint32 minCRatio,
        address oracle,
        address owner,
        address borrower
    ) external returns (address module) {
        module = address(new Escrow(minCRatio, oracle, owner, borrower));
        emit DeployedEscrow(module, minCRatio, oracle, owner);
    }
}