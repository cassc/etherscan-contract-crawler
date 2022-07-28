pragma solidity 0.4.24;

import "contracts/ACL.sol";
import "contracts/lib/CallsScript.sol";
import "contracts/Kernel.sol";
import "contracts/lib/EVMScriptRegistry.sol";
import "contracts/lib/EVMScriptRegistryConstants.sol";

contract EVMScriptRegistryFactory is EVMScriptRegistryConstants {
    EVMScriptRegistry public baseReg;
    IEVMScriptExecutor public baseCallScript;

    /**
     * @notice Create a new EVMScriptRegistryFactory.
     */
    constructor() public {
        baseReg = new EVMScriptRegistry();
        baseCallScript = IEVMScriptExecutor(new CallsScript());
    }

    /**
     * @notice Install a new pinned instance of EVMScriptRegistry on `_dao`.
     * @param _dao Kernel
     * @return Installed EVMScriptRegistry
     */
    function newEVMScriptRegistry(Kernel _dao)
        public
        returns (EVMScriptRegistry reg)
    {
        bytes memory initPayload = abi.encodeWithSelector(
            reg.initialize.selector
        );
        reg = EVMScriptRegistry(
            _dao.newPinnedAppInstance(
                EVMSCRIPT_REGISTRY_APP_ID,
                baseReg,
                initPayload,
                true
            )
        );

        ACL acl = ACL(_dao.acl());

        acl.createPermission(this, reg, reg.REGISTRY_ADD_EXECUTOR_ROLE(), this);

        reg.addScriptExecutor(baseCallScript); // spec 1 = CallsScript

        // Clean up the permissions
        acl.revokePermission(this, reg, reg.REGISTRY_ADD_EXECUTOR_ROLE());
        acl.removePermissionManager(reg, reg.REGISTRY_ADD_EXECUTOR_ROLE());

        return reg;
    }
}