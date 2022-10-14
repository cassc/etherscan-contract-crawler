// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title IAirdropReceiver
 * @author NFTfi
 * @dev
 */
interface IAirdropReceiverFactory {
    function createAirdropReceiver(address _to) external returns (address, uint256);
}