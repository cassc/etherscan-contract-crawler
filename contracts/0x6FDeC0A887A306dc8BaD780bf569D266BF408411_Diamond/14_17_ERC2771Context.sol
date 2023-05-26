// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ERC2771ContextStorage.sol";
import "./ERC2771ContextInternal.sol";
import "./IERC2771Context.sol";

/**
 * @title ERC2771 Context
 * @notice Provides view functions about configured trusted forwarder according to EIP-2771.
 *
 * @custom:type eip-2535-facet
 * @custom:category Meta Transactions
 * @custom:provides-interfaces IERC2771Context
 */
contract ERC2771Context is IERC2771Context, ERC2771ContextInternal {
    using ERC2771ContextStorage for ERC2771ContextStorage.Layout;

    function trustedForwarder() external view override returns (address) {
        return ERC2771ContextStorage.layout().trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _isTrustedForwarder(forwarder);
    }
}