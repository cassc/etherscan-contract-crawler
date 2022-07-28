pragma solidity 0.4.24;

import "contracts/lib/IACL.sol";
import "contracts/lib/IKernelEvents.sol";
import "contracts/lib/IVaultRecoverable.sol";

// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IKernelEvents, IVaultRecoverable {
    function acl() public view returns (IACL);

    function hasPermission(
        address who,
        address where,
        bytes32 what,
        bytes how
    ) public view returns (bool);

    function setApp(
        bytes32 namespace,
        bytes32 appId,
        address app
    ) public;

    function getApp(bytes32 namespace, bytes32 appId)
        public
        view
        returns (address);
}