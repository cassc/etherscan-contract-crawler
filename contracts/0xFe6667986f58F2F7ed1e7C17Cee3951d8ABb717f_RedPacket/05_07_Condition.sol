// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.17;

interface ICondition {
    /**
     * Approve a withdraw operation by:
     * - redpacketContract: contract address of red-packet.
     * - redpacketId: red-packet id.
     * - operator: address of user who is trying to withdraw.
     */
    function check(
        address redpacketContract,
        uint256 redpacketId,
        address operator
    ) external view returns (bool);
}