// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../SandboxLimitOrderRouter.sol";

interface ISandboxLimitOrderRouter {
    ///@notice Callback function that executes a sandbox multicall and is only accessible by the limitOrderExecutor.
    ///@param sandboxMulticall - Struct containing the SandboxMulticall data. See the SandboxMulticall struct for a description of each parameter.
    function sandboxRouterCallback(
        SandboxLimitOrderRouter.SandboxMulticall calldata sandboxMulticall
    ) external;

    function executeSandboxMulticall(
        SandboxLimitOrderRouter.SandboxMulticall calldata sandboxMultiCall
    ) external;
}