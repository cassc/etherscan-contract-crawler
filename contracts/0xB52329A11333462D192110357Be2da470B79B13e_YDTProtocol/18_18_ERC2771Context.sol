// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./../interfaces/IYDT.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;
    event ChangeTrustedForwarder(address indexed trustedForwarder);
    IYDT public ydt;

    constructor(address trustedForwarder, address _ydt) {
        _trustedForwarder = trustedForwarder;
        ydt = IYDT(_ydt);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function setTrustedForwarder(address forwarder) public virtual {
        require(forwarder != address(0), "Forwarder cannot be zero address");
        require(ydt.isAdmin(msg.sender), "Only Admin can call this function");
        _trustedForwarder = forwarder;
        emit ChangeTrustedForwarder(forwarder);
    }
}