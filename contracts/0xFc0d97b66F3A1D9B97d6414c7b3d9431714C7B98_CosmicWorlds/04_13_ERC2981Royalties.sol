// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './IERC2981Royalties.sol';

abstract contract ERC2981Royalties is ERC165, IERC2981Royalties {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool) {
        return interfaceId == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 value)
        public
        pure
        override
        returns (address receiver, uint256 royaltyAmount) {
        return (address(0x8c0E2ac43de845116E6c70319c4B6DB9463399C8), (value * 250) / 10000);
    }
}