//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IERC721MintableBurnable is IERC721Upgradeable {
    /**
     *  @notice Mints `tokenId` and transfers it to `to`.
     *  @param to recipient of the token
     *  @param tokenId ID of the token
     */
    function mint(address to, uint256 tokenId) external;

    /**
     *  @dev Destroys `tokenId`. For owner or by approval to transfer.
     *       The approval is cleared when the token is burned.
     *  @param tokenId ID of the token
     */
    function burn(uint256 tokenId) external;
}