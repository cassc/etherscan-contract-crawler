// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981.sol";

abstract contract Royalty is Ownable, ERC165, IERC2981 {
    address public royaltyReceiver;
    uint32 public royaltyBasisPoints; // A integer representing 1/100th of 1% (fixed point with 100 = 1.00%)

    constructor(address _receiver, uint32 _basisPoints) {
        royaltyReceiver = _receiver;
        royaltyBasisPoints = _basisPoints;
    }

    function setRoyaltyReceiver(address _receiver) external virtual onlyOwner {
        royaltyReceiver = _receiver;
    }

    function setRoyaltyBasisPoints(uint32 _basisPoints)
        external
        virtual
        onlyOwner
    {
        royaltyBasisPoints = _basisPoints;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        public
        view
        virtual
        override
        returns (address receiver, uint256 amount)
    {
        // All tokens return the same royalty amount to the receiver
        uint256 _royaltyAmount = (_salePrice * royaltyBasisPoints) / 10000; // Normalises in basis points reference. (10000 = 100.00%)
        return (royaltyReceiver, _royaltyAmount);
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