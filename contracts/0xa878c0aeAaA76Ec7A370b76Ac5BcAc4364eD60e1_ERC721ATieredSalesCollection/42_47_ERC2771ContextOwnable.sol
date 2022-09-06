// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextOwnable is Initializable, Context, Ownable {
    address public _trustedForwarder;

    function __ERC2771ContextOwnable_init(address trustedForwarder)
        internal
        onlyInitializing
    {
        __ERC2771ContextOwnable_init_unchained(trustedForwarder);
    }

    function __ERC2771ContextOwnable_init_unchained(address trustedForwarder)
        internal
        onlyInitializing
    {
        _trustedForwarder = trustedForwarder;
    }

    function setTrustedForwarder(address trustedForwarder) public onlyOwner {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}