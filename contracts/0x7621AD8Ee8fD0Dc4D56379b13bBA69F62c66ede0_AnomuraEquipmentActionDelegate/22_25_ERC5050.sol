// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

/*********************************************************************************************\
* Author: Hypervisor <[email protected]> (https://twitter.com/0xalxi)
* EIP-5050 Interactive NFTs with Modular Environments: https://eips.ethereum.org/EIPS/eip-5050
/*********************************************************************************************/

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ERC5050Storage} from "./ERC5050Storage.sol";
import {IERC5050Sender, IERC5050Receiver, Action, Object} from "../interfaces/IERC5050.sol";
import {IControllable} from "../interfaces/IControllable.sol";
import {IERC5050RegistryClient} from "../interfaces/IERC5050RegistryClient.sol";
import {ActionsSet} from "../common/ActionsSet.sol";

contract ERC5050 is IERC5050Sender, IERC5050Receiver, IControllable {
    using ERC5050Storage for ERC5050Storage.Layout;
    using Address for address;
    using ActionsSet for ActionsSet.Set;
    
    error ZeroAddressDestination();
    error TransferToNonERC5050ReceiverImplementer();
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    
    function sendAction(Action memory action)
        external
        payable
        virtual
        override(IERC5050Sender) onlySendableAction(action)
    {
        _sendAction(action);
    }

    function _sendAction(Action memory action) internal {
        if (!_isApprovedController(msg.sender, action.selector)) {
            bool toIsContract = action.to._address.isContract();
            bool stateIsContract = action.state.isContract();
            address next;
            if (toIsContract) {
                next = action.to._address;
            } else if (stateIsContract) {
                next = action.state;
            }
            if (toIsContract && stateIsContract) {
                ERC5050Storage.layout()._validate(action);
            }
            if(next != address(0)){
                next = ERC5050Storage.getReceiverProxy(next);
            }
            if (next.isContract()) {
                try
                    IERC5050Receiver(next).onActionReceived{value: msg.value}(
                        action,
                        ERC5050Storage.layout().nonce
                    )
                {} catch Error(string memory err) {
                    revert(err);
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert TransferToNonERC5050ReceiverImplementer();
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }
        emit SendAction(
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
    
    function isValid(bytes32 actionHash, uint256 nonce)
        external
        view
        override(IERC5050Sender)
        returns (bool)
    {
        return ERC5050Storage.layout().isValid(actionHash, nonce);
    }
    
    modifier onlySendableAction(Action memory action) {
        if (_isApprovedController(msg.sender, action.selector)) {
            _;
            return;
        }
        ERC5050Storage.Layout storage store = ERC5050Storage.layout();
        require(store.senderLock != _ENTERED, "ERC5050: no re-entrancy");
        require(
            store._sendableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        require(
            _isApprovedOrSelf(action.user, action.selector),
            "ERC5050: unapproved sender"
        );
        require(
            action.from._address == address(this) ||
                ERC5050Storage.getSenderProxy(action.from._address) == address(this),
            "ERC5050: invalid from address"
        );
        store.senderLock = _ENTERED;
        _;
        store.senderLock = _NOT_ENTERED;
    }
    
    function _isApprovedOrSelf(address account, bytes4 action)
        internal
        view
        returns (bool)
    {
        return (msg.sender == account ||
            isApprovedForAllActions(account, msg.sender) ||
            getApprovedForAction(account, action) == msg.sender);
    }

    modifier onlyReceivableAction(Action calldata action, uint256 nonce) {
        if (_isApprovedController(msg.sender, action.selector)) {
            _;
            return;
        }
        require(
            action.to._address == address(this) ||
                ERC5050Storage.getReceiverProxy(action.to._address) == address(this),
            "ERC5050: invalid receiver"
        );
        ERC5050Storage.Layout storage store = ERC5050Storage.layout();
        require(store.receiverLock != _ENTERED, "ERC5050: no re-entrancy");
        require(
            store._receivableActions.contains(action.selector),
            "ERC5050: invalid action"
        );
        
        if (action.from._address != address(0)) {
            require(
                action.from._address == msg.sender ||
                    ERC5050Storage.getSenderProxy(action.from._address) == msg.sender,
                "ERC5050: invalid sender"
            );
        } else {
            require(
                action.user == msg.sender,
                "ERC5050: invalid sender"
            );
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
        _onActionReceived(action, nonce);
    }

    function _onActionReceived(Action calldata action, uint256 nonce)
        internal
        virtual
    {
        if (action.state != address(0) && action.state != address(this) 
            && !_isApprovedController(msg.sender, action.selector)) {
            require(action.state.isContract(), "ERC5050: invalid state");
            try
                IERC5050Receiver(action.state).onActionReceived{
                    value: msg.value
                }(action, nonce)
            {} catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC5050: call to non ERC5050Receiver");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
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
    
    function approveForAction(
        address _account,
        bytes4 _action,
        address _approved
    ) public virtual override(IERC5050Sender) returns (bool) {
        require(_approved != _account, "ERC5050: approve to caller");

        require(
            msg.sender == _account ||
                isApprovedForAllActions(_account, msg.sender),
            "ERC5050: approve caller is not account nor approved for all"
        );

        ERC5050Storage.layout().actionApprovals[_account][_action] = _approved;
        emit ApprovalForAction(_account, _action, _approved);

        return true;
    }

    function setApprovalForAllActions(address _operator, bool _approved)
        public
        virtual
        override(IERC5050Sender)
    {
        require(msg.sender != _operator, "ERC5050: approve to caller");

        ERC5050Storage.layout().operatorApprovals[msg.sender][_operator] = _approved;

        emit ApprovalForAllActions(msg.sender, _operator, _approved);
    }

    function getApprovedForAction(address _account, bytes4 _action)
        public
        view
        override(IERC5050Sender)
        returns (address)
    {
        return ERC5050Storage.layout().actionApprovals[_account][_action];
    }

    function isApprovedForAllActions(address _account, address _operator)
        public
        view
        override(IERC5050Sender)
        returns (bool)
    {
        return ERC5050Storage.layout().operatorApprovals[_account][_operator];
    }

    function setControllerApproval(address _controller, bytes4 _action, bool _approved)
        external
        virtual
        override(IControllable)
    {
        ERC5050Storage.layout()._actionControllers[_controller][_action] = _approved;
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
        ERC5050Storage.layout()._universalControllers[_controller] = _approved;
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
        ERC5050Storage.Layout storage store = ERC5050Storage.layout();
        if (store._universalControllers[_controller]) {
            return true;
        }
        return store._actionControllers[_controller][_action];
    }
    
    function receivableActions() external view override(IERC5050Receiver) returns (string[] memory) {
        return ERC5050Storage.layout()._receivableActions.names();
    }
    
    function sendableActions() external view override(IERC5050Sender) returns (string[] memory) {
        return ERC5050Storage.layout()._receivableActions.names();
    }
    
    function _setProxyRegistry(address registry) internal {
        ERC5050Storage.layout().proxyRegistry = IERC5050RegistryClient(registry);
    }
    
    function _registerAction(string memory action) internal {
        ERC5050Storage.layout()._receivableActions.add(action);
        ERC5050Storage.layout()._sendableActions.add(action);
    }
    
    function _registerReceivable(string memory action) internal {
        ERC5050Storage.layout()._receivableActions.add(action);
    }
    
    function _registerSendable(string memory action) internal {
        ERC5050Storage.layout()._sendableActions.add(action);
    }
    
    function _registerAsSenderProxy(address _sender) internal {
        ERC5050Storage.layout().proxiedSender = _sender;
    }
    
    function _registerAsReceiverProxy(address _receiver) internal {
        ERC5050Storage.layout().proxiedReceiver = _receiver;
    }
}