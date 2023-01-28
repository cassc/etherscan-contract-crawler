// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../common/CommonBridge.sol";
import "../checks/CheckUntrustless2.sol";


contract BSC_BscBridge is CommonBridge, CheckUntrustless2 {

    function initialize(
        CommonStructs.ConstructorArgs calldata args
    ) public initializer {
        __CommonBridge_init(args);
    }

    function upgrade(
        address[] calldata _watchdogs,
        address _fee_provider,
        address mpcRelay,
        address oldDefaultAdmin,
        address oldRelay
    ) public {
        require(msg.sender == address(this), "This method require multisig");

        // add DEFAULT_ADMIN_ROLE to multisig
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // revoke RELAY_ROLE from old relay
        revokeRole(RELAY_ROLE, oldRelay);

        // new roles for untrustless mpc
        _setupRoles(WATCHDOG_ROLE, _watchdogs);
        _setupRole(FEE_PROVIDER_ROLE, _fee_provider);
        _setupRole(RELAY_ROLE, mpcRelay);

        // revoke DEFAULT_ADMIN_ROLE from deployer
        revokeRole(DEFAULT_ADMIN_ROLE, oldDefaultAdmin);
    }

    function submitTransferUntrustless(uint eventId, CommonStructs.Transfer[] calldata transfers) public onlyRole(RELAY_ROLE) whenNotPaused {
        checkEventId(eventId);
        emit TransferSubmit(eventId);
        lockTransfers(transfers, eventId);
    }
}