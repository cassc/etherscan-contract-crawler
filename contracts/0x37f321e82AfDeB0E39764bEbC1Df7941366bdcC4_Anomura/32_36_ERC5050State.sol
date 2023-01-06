// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ERC5050StateStorage, IERC5050RegistryClient} from "./ERC5050StateStorage.sol";
import {IERC5050Sender, IERC5050Receiver, Action, Object} from "../../interfaces/IERC5050.sol";
import {IControllable} from "../../interfaces/IControllable.sol";
import {ActionsSet} from "../../common/ActionsSet.sol";

contract ERC5050State is IERC5050Receiver, IControllable {
    using ERC5050StateStorage for ERC5050StateStorage.Layout;
    using Address for address;
    using ActionsSet for ActionsSet.Set;
    
    error ZeroAddressDestination();
    error TransferToNonERC5050ReceiverImplementer();
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            _;
            return;
        }
        require(
            action.state == address(this),
            "ERC5050: invalid state"
        );
        ERC5050StateStorage.Layout storage store = ERC5050StateStorage.layout();
        require(store.receiverLock != _ENTERED, "ERC5050: no re-entrancy");
        require(
            store._receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        
        address _proxiedFromAddress;
        address expectedSender = action.to._address;
        if (expectedSender == address(0)) {
            if (action.from._address != address(0)) {
                _proxiedFromAddress = ERC5050StateStorage.getSenderProxy(action.from._address);
                expectedSender = _proxiedFromAddress;
            } else {
                expectedSender = action.user;
            }
        } else {
            expectedSender = ERC5050StateStorage.getReceiverProxy(expectedSender);
        }
        require(msg.sender == expectedSender, "ERC5050: invalid sender");
        
         if (
            action.to._address.isContract() && action.from._address.isContract()
        ) {
            bytes32 actionHash = bytes32(
                keccak256(
                    abi.encodePacked(
                        action.selector,
                        action.user,
                        action.from._address,
                        action.from._tokenId,
                        action.to._address,
                        action.to._tokenId,
                        action.state,
                        action.data,
                        nonce
                    )
                )
            );
            if(_proxiedFromAddress == address(0)) {
                _proxiedFromAddress = ERC5050StateStorage.getSenderProxy(action.from._address);
            }
            try
                IERC5050Sender(_proxiedFromAddress).isValid(actionHash, nonce)
            returns (bool ok) {
                require(ok, "ERC5050: action not validated");
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC5050: call to non ERC5050Sender");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        store.receiverLock = _ENTERED;
        _;
        store.receiverLock = _NOT_ENTERED;
    }

    function onActionReceived(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        override(IERC5050Receiver)
        onlyReceivableAction(action, nonce)
    {
        _onActionReceived(action);
    }

    function _onActionReceived(Action calldata action)
        internal
        virtual
    {
        emit ActionReceived(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    }
    
    modifier onlyCommittableAction(Action calldata action) {
        require(msg.sender == action.user, "invalid sender");
        require(address(this) == action.state, "invalid state");
        require(
            ERC5050StateStorage.layout()._receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        _;
        emit ActionReceived(
            action.selector,
            action.user,
            action.from._address,
            action.from._tokenId,
            action.to._address,
            action.to._tokenId,
            action.state,
            action.data
        );
    } 
    
    function _beforeCommitAction(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        
        // Commit action as controller on sender
        address _from = action.from._address;
        if (action.from._address != address(0)) {
            _from = ERC5050StateStorage.getSenderProxy(action.from._address);
        }
        if(_from.isContract()){
            try
                IERC5050Sender(_from).sendAction{
                    value: msg.value
                }(action)
            {} catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("call to non ERC5050Sender");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        
        // Commit action as controller on receiver
        address _to = action.to._address;
        if (action.to._address != address(0)) {
            _to = ERC5050StateStorage.getReceiverProxy(action.to._address);
        }
        if(_to.isContract()){
            try
                IERC5050Receiver(_to).onActionReceived{
                    value: msg.value
                }(action, nonce)
            {} catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("call to non ERC5050Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
    
    function commitAction(Action calldata action, uint256 nonce)
        external
        payable
        virtual
        onlyCommittableAction(action)
    {
        _beforeCommitAction(action, nonce);
    }

    function setControllerApproval(address _controller, bytes4 _action, bool _approved)
        external
        virtual
        override(IControllable)
    {
        ERC5050StateStorage.layout()._actionControllers[_controller][_action] = _approved;
        emit ControllerApproval(
            _controller,
            _action,
            _approved
        );
    }
    
    function setControllerApprovalForAll(address _controller, bool _approved)
        external
        virtual
        override(IControllable)
    {
        ERC5050StateStorage.layout()._universalControllers[_controller] = _approved;
        emit ControllerApprovalForAll(
            _controller,
            _approved
        );
    }

    function isApprovedController(address _controller, bytes4 _action)
        external
        view
        override(IControllable)
        returns (bool)
    {
        return _isApprovedController(_controller, _action);
    }

    function _isApprovedController(address _controller, bytes4 _action)
        internal
        view
        returns (bool)
    {
        ERC5050StateStorage.Layout storage store = ERC5050StateStorage.layout();
        if (store._universalControllers[_controller]) {
            return true;
        }
        return store._actionControllers[_controller][_action];
    }
    
    function receivableActions() external view override(IERC5050Receiver) returns (string[] memory) {
        return ERC5050StateStorage.layout()._receivableActions.names();
    }
    
    function _registerReceivable(string memory action) internal {
        ERC5050StateStorage.layout()._receivableActions.add(action);
    }
    
    function _setProxyRegistry(address registry) internal {
        ERC5050StateStorage.layout().proxyRegistry = IERC5050RegistryClient(registry);
    }
}