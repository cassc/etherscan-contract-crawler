// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IL2StateReceiver {
    /**
     * @notice Called by exit helper when state is received from L2
     * @param sender Address of the sender on the child chain
     * @param data Data sent by the sender
     */
    function onL2StateReceive(uint256 id, address sender, bytes calldata data) external;
}