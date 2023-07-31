// SPDX-License-Identifier: GPL-3.0
// Copyright: https://github.com/credit-cooperative/Line-Of-Credit/blob/master/COPYRIGHT.md

 pragma solidity ^0.8.16;

import {ILineFactory} from "../../interfaces/ILineFactory.sol";
import {IModuleFactory} from "../../interfaces/IModuleFactory.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {LineFactoryLib} from "../../utils/LineFactoryLib.sol";
import {ISecuredLine} from "../../interfaces/ISecuredLine.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";

/**
 * @title   - Credit Cooperative Line Factory
 * @notice  - Facotry contract to deploy SecuredLine, Spigot, and Escrow contracts.
 * @dev     - Have immutable default values for Credit Cooperative system external dependencies.
 */
contract LineFactory is ILineFactory {
    IModuleFactory immutable factory;

    uint8 constant defaultRevenueSplit = 90; // 90% to debt repayment
    uint8 constant MAX_SPLIT = 100; // max % to take
    uint32 constant defaultMinCRatio = 3000; // 30.00% minimum collateral ratio

    address public immutable arbiter;
    address public immutable oracle;
    address payable public immutable swapTarget;

    constructor(address moduleFactory, address arbiter_, address oracle_, address payable swapTarget_) {
        factory = IModuleFactory(moduleFactory);
        if (arbiter_ == address(0)) {
            revert InvalidArbiterAddress();
        }
        if (oracle_ == address(0)) {
            revert InvalidOracleAddress();
        }
        if (swapTarget_ == address(0)) {
            revert InvalidSwapTargetAddress();
        }
        arbiter = arbiter_;
        oracle = oracle_;
        swapTarget = swapTarget_;
    }

    /// see ModuleFactory.deployEscrow.
    function deployEscrow(uint32 minCRatio, address owner, address borrower) external returns (address) {
        return factory.deployEscrow(minCRatio, oracle, owner, borrower);
    }

    /// see ModuleFactory.deploySpigot.
    function deploySpigot(address owner, address operator) external returns (address) {
        return factory.deploySpigot(owner, operator);
    }

    function deploySecuredLine(address borrower, uint256 ttl) external returns (address line) {
        // deploy new modules
        address s = factory.deploySpigot(address(this), borrower);
        address e = factory.deployEscrow(defaultMinCRatio, oracle, address(this), borrower);
        uint8 split = defaultRevenueSplit; // gas savings
        line = LineFactoryLib.deploySecuredLine(oracle, arbiter, borrower, payable(swapTarget), s, e, ttl, split);
        // give modules from address(this) to line so we can run line.init()
        LineFactoryLib.transferModulesToLine(address(line), s, e);
        emit DeployedSecuredLine(address(line), s, e, swapTarget, split);
    }

    function deploySecuredLineWithConfig(CoreLineParams calldata coreParams) external returns (address line) {
        if (coreParams.revenueSplit > MAX_SPLIT) {
            revert InvalidRevenueSplit();
        }

        // deploy new modules
        address s = factory.deploySpigot(address(this), coreParams.borrower);
        address e = factory.deployEscrow(coreParams.cratio, oracle, address(this), coreParams.borrower);
        line = LineFactoryLib.deploySecuredLine(
            oracle,
            arbiter,
            coreParams.borrower,
            payable(swapTarget),
            s,
            e,
            coreParams.ttl,
            coreParams.revenueSplit
        );
        // give modules from address(this) to line so we can run line.init()
        LineFactoryLib.transferModulesToLine(address(line), s, e);
        emit DeployedSecuredLine(address(line), s, e, swapTarget, coreParams.revenueSplit);
    }

    /**
     *   @dev   We don't transfer the ownership of Escrow and Spigot internally
     *          because they aren't owned by the factory, the responsibility falls
     *          on the [owner of the line]
     *   @dev   The `cratio` in the CoreParams are not used, due to the fact
     *          they're passed in when the Escrow is created separately.
     */

    function deploySecuredLineWithModules(
        CoreLineParams calldata coreParams,
        address mSpigot,
        address mEscrow
    ) external returns (address line) {
        if (mSpigot == address(0)) {
            revert InvalidSpigotAddress();
        }

        if (mEscrow == address(0)) {
            revert InvalidEscrowAddress();
        }

        line = LineFactoryLib.deploySecuredLine(
            oracle,
            arbiter,
            coreParams.borrower,
            payable(swapTarget),
            mSpigot,
            mEscrow,
            coreParams.ttl,
            coreParams.revenueSplit
        );

        emit DeployedSecuredLine(address(line), mEscrow, mSpigot, swapTarget, coreParams.revenueSplit);


    }

    function registerSecuredLine(
        address line,
        address spigot,
        address escrow,
        address borrower,
        uint8 revenueSplit,
        uint32 minCRatio
    ) external {
        if (msg.sender != arbiter){
            revert InvalidArbiterAddress();
        }
        factory.registerEscrow(minCRatio, oracle, line, escrow);
        factory.registerSpigot(spigot, line, borrower);

        emit RegisteredLine(line, oracle, arbiter, borrower);
        emit RegisteredUpdatedStatus(line, uint256(ILineOfCredit(line).status()));
        emit RegisteredSecuredLine(line, escrow, spigot, swapTarget, revenueSplit);
    }

    /**
      @notice sets up new line based of config of old line. Old line does not need to have REPAID status for this call to succeed.
      @dev borrower must call rollover() on `oldLine` with newly created line address
      @param oldLine  - line to copy config from for new line.
      @param borrower - borrower address on new line
      @param ttl      - set total term length of line
      @return line - address of newly deployed line with oldLine config
     */

    function rolloverSecuredLine(
        address payable oldLine,
        address borrower,
        uint256 ttl
    ) external returns (address line) {
        address s = address(ISecuredLine(oldLine).spigot());
        address e = address(ISecuredLine(oldLine).escrow());
        line = LineFactoryLib.deploySecuredLine(oracle, arbiter, borrower, swapTarget, s, e, ttl, defaultRevenueSplit);
        emit DeployedSecuredLine(line, s, e, swapTarget, defaultRevenueSplit);
    }
}