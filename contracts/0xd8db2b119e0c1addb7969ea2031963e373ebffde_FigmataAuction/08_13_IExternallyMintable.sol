// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IExternallyMintable is IERC721 {
    /**
     * @dev Allows the minter to mint a NFT to `to`.
     */
    function mint(uint24 tokenId, address to) external;
    
    /**
     * @return If `tokenId` was already minted (ie, if it exists).
     */
    function exists(uint24 tokenId) external view returns (bool);
    
    /**
     * @dev Sets a `minter` so it can use the `mint` method.
     */
    function addMinter(address minter) external;

    /**
     * @dev Disallow `minter` from using the `mint` method.
     */
    function removeMinter(address minter) external;

    /**
     * @return If `minter` is allowed to call the `mint` function.
     */
    function isMinter(address minter) external view returns (bool);

    /**
     * @return The max supply of the token, so the auction that will
     * use it knows wheres the mints limit.
     */
    function maxSupply() external view returns (uint24);
}