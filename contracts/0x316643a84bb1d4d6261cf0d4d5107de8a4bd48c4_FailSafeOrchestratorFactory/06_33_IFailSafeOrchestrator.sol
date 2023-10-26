// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFailSafeOrchestrator {
    function authzCheck(
        bytes32 root,
        address caller,
        bytes32[] memory proof
    ) external pure returns (bool authorized);

    function blockSkewDelta() external pure returns (uint);
    function gasToken() external view returns (address);

    function recomputeAndRecoverSigner(
        address erc20Addr,
        address emergencyWallet,
        uint amount,
        uint expiryBlockNum,
        uint count,
        bytes memory signature
    ) external pure returns (address);
}