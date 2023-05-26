// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @dev This implements EIP-2981 for ERC721 or ERC1155 contracts.
 */
abstract contract ERC2981 is IERC2981 {
    struct Royalty {
        address recipient; // Recipient address of the royalties
        uint24  points;    // Percentage points (10000 = 100%, 250 = 2.5%, 0 = 0%)
    }

    Royalty private _royalty;

    /**
     *  @dev Set the royalties information.
     *  @param recipient Recipient address of the royalties
     *  @param value     Percentage points (10000 = 100%, 250 = 2.5%, 0 = 0%)
     */
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "ERC2981: Royalty value too high.");
        _royalty = Royalty(recipient, uint24(value));
    }

    function getRoyaltyRecipient() external view returns (address) {
        Royalty memory royalty = _royalty;

        return royalty.recipient;
    }

    function getRoyaltyPoints() external view returns (uint24) {
        Royalty memory royalty = _royalty;

        return royalty.points;
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256, uint256 value) external view override returns (address receiver, uint256 royaltyAmount) {
        Royalty memory royalty = _royalty;
        receiver = royalty.recipient;
        royaltyAmount = (value * royalty.points) / 10000;

        return (receiver, royaltyAmount);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}