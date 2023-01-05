// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {IKOAccessControlsLookup} from "./interfaces/IKOAccessControlsLookup.sol";

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Admin multi-call forwarder - only KO admins and approved callers can leverage this contract
/// @dev KO Admin manages approved trigger accounts
///      Trigger accounts can forward onto other contracts with in the KO ecosystem
///      Based on prior art from MarkerDao and OpenZeppelin
contract KOAdminMulticallForwarder is Pausable {

    // Arbitrary payload for external calls
    struct Call {
        address target;
        bytes callData;
    }

    event TriggerAccountUpdated(address _triggerAccount, bool _enabled);
    event TargetFunctionSelectorUpdated(address _target, bytes4 _selector, bool _enabled);

    event MulticallTriggered(uint256 _blockNumber, address _target, bytes _callData, bytes _result);

    modifier whenApprovedTriggerAccount() {
        require(
            triggerAccounts[_msgSender()] || koAccessControls.hasContractRole(_msgSender())
        , "Trigger account not allowed");
        _;
    }

    modifier onlyKOAdmin() {
        require(koAccessControls.hasAdminRole(_msgSender()), "Sender must be an admin");
        _;
    }

    // List of trigger accounts which can trigger multi-call
    mapping(address => bool) public triggerAccounts;

    // Map of targets to allowed function selectors
    mapping(address => mapping(bytes4 => bool)) public targetFunctionSelector;

    // KO access controls
    IKOAccessControlsLookup public koAccessControls;

    constructor(IKOAccessControlsLookup _koAccessControls) {
        koAccessControls = _koAccessControls;
    }

    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicalls(Call[] calldata calls)
    external
    whenNotPaused
    whenApprovedTriggerAccount
    returns (uint256 blockNumber, bytes[] memory results) {
        // Record blockNumber number when executed
        blockNumber = block.number;

        // Return any results - this could be empty
        results = new bytes[](calls.length);

        // For each call fire and record
        for (uint256 i = 0; i < calls.length; i++) {

            bytes calldata callData = calls[i].callData;
            address target = calls[i].target;

            // Get the function selector from the forwarding call data params - ensure its allowed
            require(targetFunctionSelector[target][bytes4(callData)], "Target function selector not allowed");

            // Address utils will revert if one txs fails
            results[i] = Address.functionCall(target, callData);

            // Fire event for results set and caller
            emit MulticallTriggered(blockNumber, target, callData, results[i]);
        }
    }

    //////////////////////
    /// Admin functions //
    //////////////////////

    /// @dev Allows control of additional trigger accounts
    /// @dev Only callable from KO admin
    function setTriggerAccount(address _triggerAccount, bool _enabled)
    onlyKOAdmin
    external {
        // Toggle accounts on and off
        triggerAccounts[_triggerAccount] = _enabled;

        // Fire event so we can index these things if needed
        emit TriggerAccountUpdated(_triggerAccount, _enabled);
    }

    /// @dev Allows control of enabled target function selectors
    /// @dev Only callable from KO admin
    function setTargetFunctionSelector(address _target, bytes4 _selector, bool _enabled)
    onlyKOAdmin
    external {
        // Toggle accounts on and off
        targetFunctionSelector[_target][_selector] = _enabled;

        // Fire event so we can index these things if needed
        emit TargetFunctionSelectorUpdated(_target, _selector, _enabled);
    }

    function pause() public onlyKOAdmin {
        super._pause();
    }

    function unpause() public onlyKOAdmin {
        super._unpause();
    }

    /// @dev Allows for the ability to extract stuck ERC20 tokens and Ether
    /// @dev Only callable from KO admin
    function recoverTokens(address _tokenAddress, uint256 _amount, address _withdrawalAccount)
    onlyKOAdmin
    external {
        // Pass zero address to withdraw stuck ETH
        if (_tokenAddress == address(0x0)) {
            (bool success,) = _withdrawalAccount.call{value : _amount}("");
            require(success, "Unable to send recipient ETH");
        } else {
            IERC20(_tokenAddress).transfer(_withdrawalAccount, _amount);
        }
    }

}