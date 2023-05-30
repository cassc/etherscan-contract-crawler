// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../Royalties/ERC2981/IERC2981Royalties.sol';
import '../Royalties/RaribleSecondarySales/IRaribleSecondarySales.sol';

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
contract ERC721WithRoyalties is IERC2981Royalties, IRaribleSecondarySales {
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

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256)
        public
        view
        virtual
        override
        returns (address _receiver, uint256 _royaltyAmount)
    {
        _receiver = address(this);
        _royaltyAmount = 0;
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