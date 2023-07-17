// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRoledPausable {
    event PauserProposed(address indexed currentPauser, address indexed pendingPauser);
    event PauserUpdated(address indexed pendingPauser);
    event Paused();
    event Unpaused();

    error ContractIsPaused();
    error NotPauser();
    error NotPendingPauser();

    function updatePauser(address _newPauser) external;

    function acceptPauser() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool value);

    function pauser() external view returns (address value);

    function pendingPauser() external view returns (address value);
}