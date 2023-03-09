// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// @dev: Contract used to add ERC2981 Support to ERC721 or ERC1155
abstract contract ERC2981Support is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    // @inherit from ERC165:
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