// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {RuleBase} from "./RuleBase.sol";
import {RuleChecker} from "./RuleChecker.sol";

/// @author pintak.eth
/// @title Rule contract, that allows to initiate forwarding txs only by authorized sender
contract AuthorizedSenderRule is RuleChecker, RuleBase {
    address public immutable authorizedSender;

    error NotAuthorized();

    constructor(address _authorizedSender, address _forwarderImplementation) RuleBase(_forwarderImplementation) {
        require(_authorizedSender != address(0), "zero address");
        authorizedSender = _authorizedSender;
    }

    modifier onlyAuthorizedSender() {
        if (authorizedSender != msg.sender) {
            revert NotAuthorized();
        }
        _;
    }

    /// @inheritdoc RuleBase
    function _exec(address, uint256 value, address dest)
        internal
        view
        override
        onlyAuthorizedSender
        returns (address d, uint256 v)
    {
        d = dest;
        v = value;
    }

    /// @inheritdoc RuleBase
    function _execERC20(address, address, uint256 value, address dest)
        internal
        view
        override
        onlyAuthorizedSender
        returns (address d, uint256 v)
    {
        d = dest;
        v = value;
    }

    /// @inheritdoc RuleBase
    function _execERC721(address, address, uint256, address dest)
        internal
        view
        override
        onlyAuthorizedSender
        returns (address d)
    {
        d = dest;
    }

    /// @inheritdoc RuleBase
    function _execERC1155(address, address, uint256, uint256 value, address dest)
        internal
        view
        override
        onlyAuthorizedSender
        returns (address d, uint256 v)
    {
        d = dest;
        v = value;
    }
}