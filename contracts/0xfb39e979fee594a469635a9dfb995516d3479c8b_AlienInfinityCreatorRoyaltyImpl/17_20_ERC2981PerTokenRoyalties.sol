// SPDX-License-Identifier: MIT
// https://github.com/dievardump/EIP2981-implementation/blob/main/contracts/ERC2981PerTokenRoyalties.sol
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981PerTokenRoyalties is ERC2981Base {
    uint256 public constant percentBase = 1e4;
    RoyaltyInfo _royaltyInfo;

    /// @dev Sets token royalties
    /// @param royaltyInfo.recipient recipient of the royalties
    /// @param royaltyInfo.royalAmount percentage (using 4 decimals - 10000 = 100, 0 = 0)
    function _setTokenRoyalty(RoyaltyInfo memory royaltyInfo) internal {
        //percentBase = 1e4, so 1e4 : 100% Percent
        require(
            royaltyInfo.royalAmount <= percentBase,
            "ERC2981Royalties: Too high"
        );
        _royaltyInfo = royaltyInfo;
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 value
    )
        external
        view
        override
        returns (address recipient, uint256 royaltyAmount)
    {
        return (
            _royaltyInfo.recipient,
            (_royaltyInfo.royalAmount * value) / percentBase
        );
    }
}