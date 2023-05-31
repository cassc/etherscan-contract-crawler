// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Royalties/ERC2981/ERC2981Royalties.sol';
import '../Royalties/RaribleSecondarySales/IRaribleSecondarySales.sol';

import '../Royalties/FoundationSecondarySales/IFoundationSecondarySales.sol';
import './IERC721WithRoyalties.sol';

/// @dev This is a contract used for royalties on various platforms
/// @author Simon Fremaux (@dievardump)
contract ERC721WithRoyalties is ERC2981Royalties {
    /// see	IRaribleSecondarySales
    function getFeeRecipients(uint256 tokenId)
        public
        view
        returns (address payable[] memory recipients)
    {
        // using ERC2981 implementation to get the recipient & amount
        (address recipient, uint256 amount) = _getTokenRoyalty(tokenId);
        if (amount != 0) {
            recipients = new address payable[](1);
            recipients[0] = payable(recipient);
        }
    }

    /// see	IRaribleSecondarySales
    function getFeeBps(uint256 tokenId)
        public
        view
        returns (uint256[] memory fees)
    {
        // using ERC2981 implementation to get the amount
        (, uint256 amount) = _getTokenRoyalty(tokenId);
        if (amount != 0) {
            fees = new uint256[](1);
            fees[0] = amount;
        }
    }

    // see IFoundationSecondarySales
    function getFees(uint256 tokenId)
        external
        view
        virtual
        returns (address payable[] memory recipients, uint256[] memory fees)
    {
        // using ERC2981 implementation to get the recipient & amount
        (address recipient, uint256 amount) = _getTokenRoyalty(tokenId);
        if (amount != 0) {
            recipients = new address payable[](1);
            recipients[0] = payable(recipient);

            fees = new uint256[](1);
            fees[0] = amount;
        }
    }
}