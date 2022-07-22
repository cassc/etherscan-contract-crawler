// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165Model } from "./ERC165Model.sol";

abstract contract ERC165Controller is ERC165Model {
    function supportsInterface_(bytes4 interfaceId) internal view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    function _setSupportedInterfaces(bytes4[] memory interfaceIds, bool isSupported)
        internal
        virtual
    {
        unchecked {
            for (uint256 i; i < interfaceIds.length; i++) {
                _setSupportedInterface(interfaceIds[i], isSupported);
            }
        }
    }
}