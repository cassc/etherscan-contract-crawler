// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IZerionDNA is IERC721Metadata {
    /**
     * @notice Mints one token
     */
    function mint() external;

    /**
     * @notice Pause minting of NFT
     *
     * Requirements:
     *
     * - can be called by the owner
     * - the contract should not be paused
     */
    function pause() external;

    /**
     * @notice Resume minting of NFT
     *
     * Requirements:
     *
     * - can be called by the owner
     * - the contract should be paused
     */
    function unpause() external;

    /**
     * @notice Set new prefix of each tokenURI
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Set new collection metadata URI
     *
     * Requirements:
     *
     * - can be called by the owner
     */
    function setContractURI(string memory newContractURI) external;

    /**
     * @notice Total amount of minted NFTs
     */
    function totalSupply() external view returns (uint256);
}