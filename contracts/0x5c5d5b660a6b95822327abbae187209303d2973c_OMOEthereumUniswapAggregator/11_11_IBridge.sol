// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IBridge {
    function callProxy() external returns (address);

    function bridgeOut(
        address token,
        uint256 amount,
        uint32 destinationDomain,
        bytes32 recipient,
        bytes calldata callData
    ) external payable;

    function bridgeIn(
        bytes calldata args,
        bytes calldata attestation
    ) external;
}