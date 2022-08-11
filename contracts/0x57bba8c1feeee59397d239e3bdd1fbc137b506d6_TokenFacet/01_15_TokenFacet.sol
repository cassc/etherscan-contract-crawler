// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";
import {IToken} from "../interfaces/IToken.sol";
import {LibStrings} from "../libraries/LibStrings.sol";

contract TokenFacet is Base, IToken {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return s.nftStorage.nextTokenId - s.nftStorage.startingTokenId - s.nftStorage.burnCounter;
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
        if (!exists(_tokenId)) revert QueryNonExistentToken();
        return bytes(s.nftStorage.baseURI).length > 0 ? s.nftStorage.baseURI : "";
    }

    /// @notice Verify whether a token exists and has not been burned
    /// @param _tokenId The token id
    /// @return bool
    function exists(uint256 _tokenId) public view returns (bool) {
        return (!s.nftStorage.burnedTokens[_tokenId] && s.nftStorage.tokenOwners[_tokenId] != address(0));
    }
}