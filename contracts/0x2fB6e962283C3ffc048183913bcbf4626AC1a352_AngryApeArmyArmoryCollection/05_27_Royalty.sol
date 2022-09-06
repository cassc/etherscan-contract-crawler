// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981.sol";

abstract contract Royalty is ERC165, IERC2981 {
    address public royaltyReceiver;
    uint32 public royaltyBasisPoints; // A integer representing 1/100th of 1% (fixed point with 100 = 1.00%)

    function _setRoyaltyReceiver(address receiver_) internal {
        royaltyReceiver = receiver_;
    }

    function _setRoyaltyBasisPoints(uint32 basisPoints_)
        internal
    {
        royaltyBasisPoints = basisPoints_;
    }

    function royaltyInfo(uint256, uint256 salePrice_)
        public
        view
        virtual
        override
        returns (address receiver, uint256 amount)
    {
        // All tokens return the same royalty amount to the receiver
        uint256 royaltyAmount = (salePrice_ * royaltyBasisPoints) / 10000; // Normalises in basis points reference. (10000 = 100.00%)
        return (royaltyReceiver, royaltyAmount);
    }

    // Compulsory overrides
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