// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IMVHQ is
    IERC721
{

    /// @notice this function will burn keys minted from this address
    /// @dev it will not work with legacy keys
    /// @param tokenId_ the key's tokenId
    function burn(uint256 tokenId_) external;

    function burnBatch(address tokensOwner_, uint256[] calldata tokenIds_) external;
    function mint(address address_) external;
    /*
        View Functions
    */
    /// @notice check whether an address meets the whale requirement
    /// @param address_ the address to check
    /// @return whether the address is a whale
    function isWhale(address address_) external view returns (bool);

    /// @notice Check whether a key has been flagged
    /// @param tokenId_ the key's token id
    function isKeyFlagged(uint256 tokenId_) external view returns (bool);

    /// @notice Check whether an address has been flagged
    /// @param address_ the address
    function isAddressFlagged(address address_) external view returns (bool);

    function whaleRequirement() external view returns (uint256);
}