// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IRecoverable.sol";

interface INftCollection is IERC721Enumerable, IRecoverable {
    /**
     * @dev Returns the max total supply
     */
    function maxSupply() external view returns (uint256);

    /**
     * @dev Mint NFTs from the NFT contract.
     */
    function mint(address _to, uint256 _tokenId) external;

    /**
     * @dev It transfers the ownership of the NFT contract
     * to a new address.
     */
    function transferOwnership(address _newOwner) external;

    /**
     * @notice Allows the owner to lock the NFT contract
     * @dev Callable by owner
     */
    function lock() external;

    /**
     * @notice Allows the owner to set the base URI to be used for all token IDs on the NFT contract
     * @param _uri: base URI
     * @dev Callable by owner
     */
    function setBaseURI(string memory _uri) external;

    /**
     * @notice Allows the owner to set the contracy URI to be used
     * @param _uri: contract URI
     * @dev Callable by owner
     */
    function setContractURI(string memory _uri) external;
}