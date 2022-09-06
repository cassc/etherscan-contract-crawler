pragma solidity 0.4.24;

import "contracts/lib/AppStorage.sol";
import "contracts/lib/Initializable.sol";
import "contracts/lib/IEVMScriptExecutor.sol";
import "contracts/lib/IEVMScriptRegistry.sol";
import "contracts/lib/KernelNamespaceConstants.sol";
import "contracts/lib/EVMScriptRegistryConstants.sol";

contract EVMScriptRunner is
    AppStorage,
    Initializable,
    EVMScriptRegistryConstants,
    KernelNamespaceConstants
{
    string private constant ERROR_EXECUTOR_UNAVAILABLE =
        "EVMRUN_EXECUTOR_UNAVAILABLE";
    string private constant ERROR_PROTECTED_STATE_MODIFIED =
        "EVMRUN_PROTECTED_STATE_MODIFIED";

    /* This is manually crafted in assembly
    string private constant ERROR_EXECUTOR_INVALID_RETURN = "EVMRUN_EXECUTOR_INVALID_RETURN";
    */

    event ScriptResult(
        address indexed executor,
        bytes script,
        bytes input,
        bytes returnData
    );

    function getEVMScriptExecutor(bytes _script)
        public
        view
        returns (IEVMScriptExecutor)
    {
        return
            IEVMScriptExecutor(
                getEVMScriptRegistry().getScriptExecutor(_script)
            );
    }

    function getEVMScriptRegistry() public view returns (IEVMScriptRegistry) {
        address registryAddr = kernel().getApp(
            KERNEL_APP_ADDR_NAMESPACE,
            EVMSCRIPT_REGISTRY_APP_ID
        );
        return IEVMScriptRegistry(registryAddr);
    }

    function runScript(
        bytes _script,
        bytes _input,
        address[] _blacklist
    ) internal isInitialized protectState returns (bytes) {
        IEVMScriptExecutor executor = getEVMScriptExecutor(_script);
        require(address(executor) != address(0), ERROR_EXECUTOR_UNAVAILABLE);

        bytes4 sig = executor.execScript.selector;
        bytes memory data = abi.encodeWithSelector(
            sig,
            _script,
            _input,
            _blacklist
        );

        bytes memory output;
        assembly {
            let success := delegatecall(
                gas, // forward all gas
                executor, // address
                add(data, 0x20), // calldata start
                mload(data), // calldata length
                0, // don't write output (we'll handle this ourselves)
                0 // don't write output
            )

            output := mload(0x40) // free mem ptr get

            switch success
            case 0 {
                // If the call errored, forward its full error data
                returndatacopy(output, 0, returndatasize)
                revert(output, returndatasize)
            }
            default {
                switch gt(returndatasize, 0x3f)
                case 0 {
                    mstore(
                        output,
                        0x08c379a000000000000000000000000000000000000000000000000000000000
                    )
                    mstore(
                        add(output, 0x04),
                        0x0000000000000000000000000000000000000000000000000000000000000020
                    )
                    mstore(
                        add(output, 0x24),
                        0x000000000000000000000000000000000000000000000000000000000000001e
                    )
                    mstore(
                        add(output, 0x44),
                        0x45564d52554e5f4558454355544f525f494e56414c49445f52455455524e0000
                    )

                    revert(output, 100)
                }
                default {
                    let copysize := sub(returndatasize, 0x20)
                    returndatacopy(output, 0x20, copysize)

                    mstore(0x40, add(output, copysize))
                }
            }
        }

        emit ScriptResult(address(executor), _script, _input, output);

        return output;
    }

    modifier protectState() {
        address preKernel = address(kernel());
        bytes32 preAppId = appId();
        _; // exec
        require(address(kernel()) == preKernel, ERROR_PROTECTED_STATE_MODIFIED);
        require(appId() == preAppId, ERROR_PROTECTED_STATE_MODIFIED);
    }
}