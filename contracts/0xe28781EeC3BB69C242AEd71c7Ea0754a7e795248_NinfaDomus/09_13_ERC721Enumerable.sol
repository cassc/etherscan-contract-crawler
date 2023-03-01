/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC721.sol";

/*************************************************************
 * @title ERC721Enumerable                                   *
 *                                                           *
 * @dev This implements an optional extension of {ERC721}    *
 *      defined in the EIP that adds enumerability of all    *
 *      the token ids in the contract as well as all token   *
 *      ids owned by each account.                           *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/
abstract contract ERC721Enumerable is ERC721 {
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) external view returns (uint256) {
        require(_owner == ownerOf(_index));
        return _index;
    }

    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256) {
        return _owners.length;
    }

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256) {
        require(_exists(_index));
        return _index;
    }
}