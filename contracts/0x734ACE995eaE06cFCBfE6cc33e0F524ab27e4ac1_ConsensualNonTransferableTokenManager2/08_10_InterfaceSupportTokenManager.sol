// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./interfaces/ITokenManager.sol";
import "../utils/ERC165/IERC165.sol";

/**
 * @author [email protected]
 * @notice Abstract contract to be inherited by all valid token managers
 */
abstract contract InterfaceSupportTokenManager {
    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(ITokenManager).interfaceId || _supportsERC165Interface(interfaceId);
    }

    /**
     * @notice Used to show support for IERC165, without inheriting contract from IERC165 implementations
     */
    function _supportsERC165Interface(bytes4 interfaceId) internal pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}