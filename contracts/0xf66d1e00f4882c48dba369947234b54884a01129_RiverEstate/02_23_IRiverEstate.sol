// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

interface IRiverEstate {
    /* ================ EVENTS ================ */
    event TokenMinted(address indexed payer, uint256 indexed tokenId, uint256 eventTime);

    /* ================ VIEWS ================ */
    /**
     * @dev returns token info uri
     * @param tokenId the info token
     * @notice the token must exists
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /* ================ TRANSACTIONS ================ */
    /**
     * @dev mint with signature
     * @param tokenIds token id list
     * @param receipt the address to mint to
     * @param nonce the verson of signature
     * @param signature signature
     */
    function mintWithSignature(
        uint256[] memory tokenIds,
        address receipt,
        uint256 nonce,
        bytes memory signature
    ) external;

    /* ================ MINTER OR ADMIN ACTIONS ================ */
    /**
     * @dev mint by admin
     * @param receiver the address to mint to
     * @param tokenId token id list
     */
    function adminMint(address receiver, uint256 tokenId) external;

    /**
     * @dev batch mint by admin
     * @param receivers the address to mint to
     * @param tokenIds token id list
     */
    function adminMintBatch(address[] memory receivers, uint256[] memory tokenIds) external;

    /* ================ ADMIN ACTIONS ================ */
    /**
     * @dev reset the baseUri
     * @param newBaseURI the address to mint to
     */
    function setBaseURI(string memory newBaseURI) external;

    function pause() external;

    function unpause() external;

    function setSigner(address newSigner) external;

    function setNonce(uint256 newNonce) external;
}