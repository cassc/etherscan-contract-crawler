// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC2981Support.sol";

// Contract to extend functionality for minter to specify royalty for each tokenId minted:
abstract contract ERC2981RoyaltiesPerToken is ERC2981Support {
    // tokenId mapped to its individual specified royalty:
    mapping(uint256 => RoyaltyInfo) internal royalties;

    /// @dev Sets token royalties
    /// @param _tokenId the token id fir which we register the royalties
    /// @param _recipient recipient of the royalties
    /// @param _royaltyValue percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function setTokenRoyalty(
        uint256 _tokenId,
        address _recipient,
        uint256 _royaltyValue
    ) internal {
        require(_royaltyValue <= 10000, "ERC2981Royalties: Invalid Range");
        royalties[_tokenId] = RoyaltyInfo(_recipient, uint24(_royaltyValue));
    }

    // @inherit from IERC2981:
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        public
        view
        virtual
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalty = royalties[_tokenId];
        receiver = royalty.recipient;
        royaltyAmount = (_value * royalty.amount) / 10000;
    }
}