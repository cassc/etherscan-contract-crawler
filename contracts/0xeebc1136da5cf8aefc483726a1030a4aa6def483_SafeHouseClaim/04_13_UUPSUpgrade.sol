// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, ERC1967_PROXY_STORAGE_SLOT} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @title Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external virtual {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();

        return ERC1967_PROXY_STORAGE_SLOT;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade() internal virtual;
}