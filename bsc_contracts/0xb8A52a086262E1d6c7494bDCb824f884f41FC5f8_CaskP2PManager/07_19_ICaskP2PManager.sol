// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskP2PManager {

    function registerP2P(bytes32 _p2pId) external;

    /** @dev Emitted when manager parameters are changed. */
    event SetParameters();

}