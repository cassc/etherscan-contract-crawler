// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {RuleBase} from "./RuleBase.sol";
import {RuleChecker} from "./RuleChecker.sol";

/// @author pintak.eth
/// @title Rule contract, that allows to forward coins only to whitelisted address
contract WhitelistedAddressRule is RuleChecker, RuleBase {
    address public immutable whitelisted;

    constructor(address _whitelisted, address _forwarderImplementation) RuleBase(_forwarderImplementation) {
        require(_whitelisted != address(0), "zero address");
        whitelisted = _whitelisted;
    }

    /// @inheritdoc RuleBase
    function _exec(address, uint256 value, address) internal view override returns (address d, uint256 v) {
        d = whitelisted;
        v = value;
    }

    /// @inheritdoc RuleBase
    function _execERC20(address, address, uint256 value, address)
        internal
        view
        override
        returns (address d, uint256 v)
    {
        d = whitelisted;
        v = value;
    }

    /// @inheritdoc RuleBase
    function _execERC721(address, address, uint256, address) internal view override returns (address d) {
        d = whitelisted;
    }

    /// @inheritdoc RuleBase
    function _execERC1155(address, address, uint256, uint256 value, address)
        internal
        view
        override
        returns (address d, uint256 v)
    {
        d = whitelisted;
        v = value;
    }
}