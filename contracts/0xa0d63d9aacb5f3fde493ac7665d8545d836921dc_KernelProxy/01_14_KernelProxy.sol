pragma solidity 0.4.24;

import "contracts/lib/IKernel.sol";
import "contracts/lib/IKernelEvents.sol";
import "contracts/lib/KernelStorage.sol";
import "contracts/lib/KernelAppIds.sol";
import "contracts/lib/KernelNamespaceConstants.sol";
import "contracts/lib/IsContract.sol";
import "contracts/lib/DepositableDelegateProxy.sol";

contract KernelProxy is
    IKernelEvents,
    KernelStorage,
    KernelAppIds,
    KernelNamespaceConstants,
    IsContract,
    DepositableDelegateProxy
{
    /**
     * @dev KernelProxy is a proxy contract to a kernel implementation. The implementation
     *      can update the reference, which effectively upgrades the contract
     * @param _kernelImpl Address of the contract used as implementation for kernel
     */
    constructor(IKernel _kernelImpl) public {
        require(isContract(address(_kernelImpl)));
        apps[KERNEL_CORE_NAMESPACE][KERNEL_CORE_APP_ID] = _kernelImpl;

        // Note that emitting this event is important for verifying that a KernelProxy instance
        // was never upgraded to a malicious Kernel logic contract over its lifespan.
        // This starts the "chain of trust", that can be followed through later SetApp() events
        // emitted during kernel upgrades.
        emit SetApp(KERNEL_CORE_NAMESPACE, KERNEL_CORE_APP_ID, _kernelImpl);
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return UPGRADEABLE;
    }

    /**
     * @dev ERC897, the address the proxy would delegate calls to
     */
    function implementation() public view returns (address) {
        return apps[KERNEL_CORE_NAMESPACE][KERNEL_CORE_APP_ID];
    }
}