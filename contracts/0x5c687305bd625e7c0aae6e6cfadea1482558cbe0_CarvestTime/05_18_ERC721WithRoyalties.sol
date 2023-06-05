// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IERC2981Royalties.sol';
import './IRaribleSecondarySales.sol';

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
contract ERC721WithRoyalties is IERC2981Royalties, IRaribleSecondarySales {
    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IRaribleSecondarySales).interfaceId;
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    function _setRoyaltiesRecipient(address recipient) internal {
        _royaltiesRecipient = recipient;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }

    /// @inheritdoc	IRaribleSecondarySales
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        returns (address payable[] memory recipients)
    {
        // using ERC2981 implementation to get the recipient & amount
        (address recipient, uint256 amount) = royaltyInfo(tokenId, 10000);
        if (amount != 0) {
            recipients = new address payable[](1);
            recipients[0] = payable(recipient);
        }
    }

    /// @inheritdoc	IRaribleSecondarySales
    function getFeeBps(uint256 tokenId)
        public
        view
        override
        returns (uint256[] memory fees)
    {
        // using ERC2981 implementation to get the amount
        (, uint256 amount) = royaltyInfo(tokenId, 10000);
        if (amount != 0) {
            fees = new uint256[](1);
            fees[0] = amount;
        }
    }
}