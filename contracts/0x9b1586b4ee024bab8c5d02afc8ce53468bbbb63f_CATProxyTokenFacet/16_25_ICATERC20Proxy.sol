// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICATERC20Proxy {
    function initialize(
        uint16 chainId,
        address nativeToken,
        address wormhole,
        uint8 finality
    ) external;

    /**
     * @dev To bridge tokens to other chains.
     */
    function bridgeOut(
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce
    ) external payable returns (uint64 sequence);

    function bridgeIn(bytes memory encodedVm) external returns (bytes memory);
}