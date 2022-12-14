// SPDX-License-Identifier: MIT
// Copyright 2021 David Huber (@cxkoda)

pragma solidity >=0.8.0 <0.9.0;

import "./IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @notice ERC2981 royalty info base contract
 * @dev Implements `supportsInterface`
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}