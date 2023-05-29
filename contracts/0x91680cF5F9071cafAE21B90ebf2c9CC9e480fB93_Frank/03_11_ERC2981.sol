// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity >=0.8.0;

abstract contract ERC2981 {

    /// @dev one global fee for all royalties.
    uint256 internal _royaltyFee;
    /// @dev one global recipient for all royalties.
    address internal _royaltyRecipient;

    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = _royaltyRecipient;
        royaltyAmount = (salePrice * _royaltyFee) / 10000;
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x2a55205a; // ERC165 Interface ID for ERC2981
    }

}