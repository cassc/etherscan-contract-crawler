// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/


/// @title EIP-5050 Action Controller
interface IControllable {
    
    /// @notice Enable or disable approval for a third party ("controller") to force
    ///  handling of a given action without performing EIP-5050 validity checks.
    /// @dev Emits the ControllerApproval event. The contract MUST allow
    ///  an unbounded number of controllers per action.
    /// @param _controller Address to add to the set of authorized controllers
    /// @param _action Selector of the action for which the controller is approved / disapproved
    /// @param _approved True if the controller is approved, false to revoke approval
    function setControllerApproval(address _controller, bytes4 _action, bool _approved)
        external;

    /// @notice Enable or disable approval for a third party ("controller") to force
    ///  action handling without performing EIP-5050 validity checks. 
    /// @dev Emits the ControllerApproval event. The contract MUST allow
    ///  an unbounded number of controllers per action.
    /// @param _controller Address to add to the set of authorized controllers
    /// @param _approved True if the controller is approved, false to revoke approval
    function setControllerApprovalForAll(address _controller, bool _approved)
        external;

    /// @notice Query if an address is an authorized controller for a given action.
    /// @param _controller The trusted third party address that can force action handling
    /// @param _action The action selector to query against
    /// @return True if `_controller` is an approved operator for `_account`, false otherwise
    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        returns (bool);
    
    /// @dev This emits when a controller is enabled or disabled for the given
    ///  action. The controller can force `action` handling on the emitting contract, 
    ///  bypassing the standard EIP-5050 validity checks.
    event ControllerApproval(
        address indexed _controller,
        bytes4 indexed _action,
        bool _approved
    );
    
    /// @dev This emits when a controller is enabled or disabled for all actions.
    ///  Disabling all action approval for a controller does not override explicit action
    ///  action approvals. Controller's approved for all actions can force action handling 
    ///  on the emitting contract for any action.
    event ControllerApprovalForAll(
        address indexed _controller,
        bool _approved
    );
}