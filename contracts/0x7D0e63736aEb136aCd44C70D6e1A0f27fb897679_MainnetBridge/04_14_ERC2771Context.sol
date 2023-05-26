// This code was taken from the chainbridge-solidity project listed below,
// licensed under MIT. Slight modifications (downgraded to 0.6.0), branched from
// the v4.0.1 tag. 
// 
// https://github.com/OpenZeppelin/openzeppelin-contracts/

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/utils/Context.sol";

/*
 * @dev Context variant with ERC2771 support.
 */
contract ERC2771Context is Context {
    address immutable _trustedForwarder;

    constructor(address trustedForwarder) internal {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns(bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override(Context) returns (address payable sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly { sender := shr(96, calldataload(sub(calldatasize(), 20))) }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override(Context) returns (bytes memory) {
        if (isTrustedForwarder(msg.sender)) {
            return bytes(msg.data[:msg.data.length-20]);
        } else {
            return super._msgData();
        }
    }
}