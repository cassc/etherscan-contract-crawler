// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
* @title Interface that can be used to interact with the Pausable contract.
*/
interface IPausable {
    function pause() external;
    function unpause() external;
    function paused() external view returns (bool);
}