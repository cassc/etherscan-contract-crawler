// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev an upgradeable-compatible way to set a mutable token URI. 
 */
abstract contract MutableTokenURIUpgradeable is Initializable {
    
    string public tokenBaseUri;

    function __MutableTokenURI_init(string memory uri) internal onlyInitializing {
        __MutableTokenURI_init_unchained(uri);
    }

    function __MutableTokenURI_init_unchained(string memory uri) internal onlyInitializing {
        tokenBaseUri = uri;
    }

    /**
     * @dev Update {tokenBaseUri}
     */
    function _updateTokenBaseUri(string memory newURI) internal {
        tokenBaseUri = newURI;
    }

    uint256[49] private __gap;
}