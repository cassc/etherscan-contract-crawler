// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./InterfaceSupportTokenManager.sol";
import "./interfaces/ITokenManagerEditions.sol";

/**
 * @author [email protected]
 * @notice Abstract contract to be inherited by all valid editions token managers
 */
abstract contract InterfaceSupportEditionsTokenManager is InterfaceSupportTokenManager {
    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(InterfaceSupportTokenManager)
        returns (bool)
    {
        return
            interfaceId == type(ITokenManagerEditions).interfaceId ||
            InterfaceSupportTokenManager.supportsInterface(interfaceId);
    }
}