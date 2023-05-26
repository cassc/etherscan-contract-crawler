// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract RoyaltyInfo is IERC2981, ERC165 {
    uint96 private constant FEE_DENOMINATOR = 10000;

    address private _receiver;
    uint96 private _fraction;

    event SetRoyaltyInfo(
        address indexed previousReceiver,
        address indexed newReceiver,
        uint96 previousFraction,
        uint96 newFraction
    );

    constructor(address newReceiver, uint96 newFraction) {
        _setRoyaltyInfo(newReceiver, newFraction);
    }

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

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        if (_receiver == address(0x0)) {
            return (address(this), 0);
        } else if (_fraction == 0 || salePrice == 0) {
            return (_receiver, 0);
        }
        return (_receiver, (salePrice * _fraction) / FEE_DENOMINATOR);
    }

    function _setRoyaltyInfo(address newReceiver, uint96 newFraction) internal {
        require(
            newFraction <= FEE_DENOMINATOR,
            "fraction will exceed salePrice"
        );
        address previousReceiver = _receiver;
        uint96 previousFraction = _fraction;
        _receiver = newReceiver;
        _fraction = newFraction;
        emit SetRoyaltyInfo(
            previousReceiver,
            _receiver,
            previousFraction,
            _fraction
        );
    }
}