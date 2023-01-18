// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721A} from "erc721a/contracts/ERC721A.sol";

/// @title ERC721AMeta
/// @author dev by @dievardump
/// @notice makes some data of ERC721A publicly available
abstract contract ERC721AMeta is ERC721A {
    /// @notice how many items have been minted
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Returns the number of tokens minted by `account`.
    /// @param account the account
    /// @return the number of items minted
    function numberMinted(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    /// @notice Returns a `tokenId` extra data
    /// @param tokenId the toke id
    /// @return the extraData
    function extraData(uint256 tokenId) public view returns (uint24) {
        return _exists(tokenId) ? _ownershipOf(tokenId).extraData : _ownershipAt(tokenId).extraData;
    }
}