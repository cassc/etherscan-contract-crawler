// SPDX-License-Identifier: MIT
//
// EIP-2981: NFT Royalty Standard
// https://eips.ethereum.org/EIPS/eip-2981
//
// Derived from OpenZeppelin Contracts (token/common/ERC2981.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/common/ERC2981.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165
//       |
//  OpenERC2981 —— IERC2981 —— IOpenReceiverInfos
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC2981.sol";
import "OpenNFTs/contracts/interfaces/IOpenReceiverInfos.sol";

abstract contract OpenERC2981 is IERC2981, IOpenReceiverInfos, OpenERC165 {
    uint256 internal _mintPrice;
    ReceiverInfos internal _defaultRoyalty;
    mapping(uint256 => ReceiverInfos) internal _tokenRoyalty;

    uint96 internal constant _MAX_FEE = 10_000;

    modifier notTooExpensive(uint256 price) {
        /// otherwise may overflow
        require(price < 2 ** 128, "Too expensive");
        _;
    }

    modifier lessThanMaxFee(uint256 fee) {
        require(fee <= _MAX_FEE, "Royalty fee exceed price");
        _;
    }

    function royaltyInfo(uint256 tokenID, uint256 price)
        public
        view
        override (IERC2981)
        notTooExpensive(price)
        returns (address receiver, uint256 royaltyAmount)
    {
        ReceiverInfos memory royalty = _tokenRoyalty[tokenID];

        if (royalty.account == address(0)) {
            royalty = _defaultRoyalty;
        }

        royaltyAmount = _calculateAmount(price, royalty.fee);

        /// MINIMAL royaltyAmount
        if (royalty.minimum > 0) {
            /// with zero price, token owner can bypass royalties...
            /// SO set a minimumRoyaltyAmount calculated on mintPrice (than can only be modified by collection owner)
            /// BUT collection owner can higher too much mintPrice making fees too high
            /// SO moreover store a minimumRoyaltyAmount per token defined during mint, or last transfer

            /// MIN(royalty.minimum, defaultRoyaltyAmount)
            uint256 defaultRoyaltyAmount = _calculateAmount(_mintPrice, royalty.fee);
            uint256 minimumRoyaltyAmount =
                royalty.minimum < defaultRoyaltyAmount ? royalty.minimum : defaultRoyaltyAmount;

            /// MAX(normalRoyaltyAmount, minimumRoyaltyAmount)
            royaltyAmount =
                royaltyAmount < minimumRoyaltyAmount ? minimumRoyaltyAmount : royaltyAmount;
        }

        return (royalty.account, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function _calculateAmount(uint256 price, uint96 fee) internal pure returns (uint256) {
        return (price * fee) / _MAX_FEE;
    }
}