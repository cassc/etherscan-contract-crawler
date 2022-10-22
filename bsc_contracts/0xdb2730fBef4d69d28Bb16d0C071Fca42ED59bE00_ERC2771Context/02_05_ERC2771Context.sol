// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC2771ContextStorage.sol";
import "./ERC2771ContextInternal.sol";
import "./IERC2771Context.sol";

contract ERC2771Context is IERC2771Context, ERC2771ContextInternal {
    using ERC2771ContextStorage for ERC2771ContextStorage.Layout;

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _isTrustedForwarder(forwarder);
    }
}