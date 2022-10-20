// SPDX-License-Identifier: MIT
// Creator: JCBDEV (Quantum Art)
pragma solidity >=0.8.0;

/// @title Minimalist ERC2981 implementation.
/// @notice To be used within Quantum, as it was written for its needs.
/// @author JCBDEV (Quantum Art)
abstract contract ERC2981 {
    //TODO: Library for token functions
    function __dropIdOf(uint256 tokenId) private pure returns (uint128) {
        return uint128(tokenId >> 128);
    }

    /// @dev default global fee for all royalties.
    uint256 internal _royaltyFee;
    /// @dev default global recipient for all royalties.
    address internal _royaltyRecipient;

    mapping(uint128 => uint256) internal _dropRoyaltyFee;
    mapping(uint128 => address) internal _dropRoyaltyRecipient;

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        uint128 dropId = __dropIdOf(tokenId);
        uint256 dropFee = _dropRoyaltyRecipient[dropId] != address(0)
            ? _dropRoyaltyFee[dropId]
            : _royaltyFee;
        receiver = _dropRoyaltyRecipient[dropId] != address(0)
            ? _dropRoyaltyRecipient[dropId]
            : _royaltyRecipient;
        royaltyAmount = (salePrice * dropFee) / 10000;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }
}