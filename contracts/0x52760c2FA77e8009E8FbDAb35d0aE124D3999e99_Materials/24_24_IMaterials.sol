// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IMaterials {

    // Custom error definitions
    error NotOwner();
    error IncorrectProof();
    error NoTokenIdsSpecified();
    error NoRecipients();
    error InvalidStageTime();

    event NewSecondaryRoyalties(address secondaryRoyaltyReceiver, uint96 newRoyaltyValue);
    
    /**
     * @dev Store all sale stage parameters
     */
    struct SaleStage {
        uint256 startTime;
        bytes32 merkleRoot;
    }

    /**
     * @dev Sets the new secondary royalty receiver and royalty percentage fee.
     *
     * Requirements:
     * - `msg.sender` must be the contract owner.
     *
     * @param newSecondaryRoyaltyReceiver the address of the new secondary royalty receiver.
     * @param newRoyaltyValue the new royalty value.
     */
    function changeSecondaryRoyaltyReceiver(
        address newSecondaryRoyaltyReceiver,
        uint96 newRoyaltyValue
    ) external;

    /**
     * @dev Retrieve the URI for a given token ID.
     *
     * @param id the token ID.
     * @return the URI of the given token ID.
     */
    function uri(uint256 id) external view returns (string memory);

    /**
     * @dev Set the Sale Stage for a given sale ID
     *
     * Requirements:
     * - `msg.sender` must be the contract owner.
     *
     * @param id the sale ID.
     * @param stage the sale stage data for the ID
     */
    function setSaleStage(uint256 id, SaleStage memory stage) external;

    /**
     * @dev Set the URI for a given token ID.
     *
     * Requirements:
     * - `msg.sender` must be the contract owner.
     *
     * @param id the token ID.
     * @param newURI the new URI for the given token ID.
     */
    function setUri(uint256 id, string memory newURI) external;

    /**
     * @dev Pauses minting.
     *
     * Requirements:
     * - `msg.sender` must be the contract owner.
     */
    function pause() external;

    /**
     * @dev Unpauses minting.
     *
     * Requirements:
     * - `msg.sender` must be the contract owner.
     */
    function unpause() external;

    /**
     * @dev Burn a set of hounds to redeem a material.
     *
     * @param tokenIds the IDs of the tokens to burn.
     * @param saleId the ID of the sale.
     * @param _merkleProof the Merkle proof for the address and the ID of the sale.
     */
    function burn2Redeem(uint256[] memory tokenIds, uint256 saleId, bytes32[] calldata _merkleProof) external;

    /**
     * @dev Airdrop the 5th material to a set of VIPs.
     *
     * Requirements:
     * - `msg.sender` must be the contract owner.
     *
     * @param VIPs the addresses of the VIPs.
     * @param amount the amount to airdrop to each VIP.
     */
    function VIPAirdrop(address[] memory VIPs, uint256 amount) external;

    /**
     * @dev Verify if a given interface is supported.
     *
     * @param interfaceId the ID of the interface.
     * @return true if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}