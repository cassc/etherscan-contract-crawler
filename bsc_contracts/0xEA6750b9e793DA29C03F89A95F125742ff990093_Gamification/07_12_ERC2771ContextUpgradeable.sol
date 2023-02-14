// SPDX-License-Identifier: GPL-3.0-or-later

// OpenZeppelin Contracts v4.3.2 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.4;

// import {Initializable} from "../proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/**
 * @dev Context variant with ERC2771 support.
 */
// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    // address public trustedForwarder;
    mapping(address=>bool) public isTrustedForwarder;

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        isTrustedForwarder[tForwarder] = true;
    }

    function addOrRemovetrustedForwarder(address _forwarder, bool status) public  virtual  {
        require( isTrustedForwarder[_forwarder] != status, "same satus");
        isTrustedForwarder[_forwarder] = status;
    }



    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}