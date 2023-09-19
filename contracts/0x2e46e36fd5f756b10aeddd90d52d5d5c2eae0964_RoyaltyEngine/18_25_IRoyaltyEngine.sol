// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for RoyaltyEngine
 */
interface IRoyaltyEngine {
    /**
     * @notice Emits when an collection level Royalty is configured
     * @param collectionAddress contract address 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    event RoyaltiesUpdated(
        address indexed collectionAddress,
        address payable[] receivers,
        uint256[] basisPoints
    );

    /**
     * @notice Emits when an Token level Royalty is configured
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    event TokenRoyaltiesUpdated(
        address collectionAddress,
        uint256 indexed tokenId,
        address payable[] receivers,
        uint256[] basisPoints
    );
    
    /**
     * @notice Emits when address is added into Black List.
     * @param account BlackListed NFT contract address or wallet address
     * @param sender caller address
    **/
    event AddedBlacklistedAddress(
        address indexed account,
        address indexed sender
    );

    /**
     * @notice Eits when address is removed from Black List.
     * @param account BlackListed NFT contract address or wallet address
     * @param sender caller address
    **/
    event RevokedBlacklistedAddress(
        address indexed account,
        address indexed sender
    );
    
    /**
     * @notice Setting royalty for NFT Collection.
     * @param collectionAddress NFT contract address 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setRoyalty(
        address collectionAddress,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;
    
    /**
     * @notice Setting royalty for token.
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param receivers set of royalty receivers
     * @param basisPoints set of royalty Bps
     */
    function setTokenRoyalty(
        address collectionAddress,
        uint256 tokenId,
        address payable[] calldata receivers,
        uint256[] calldata basisPoints
    ) external;

    /**
     * @notice getting royalty information from Other royalty standard.
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps to calculate Shares.
    **/
    function getRoyalty(address collectionAddress, uint256 tokenId)
        external
	view
        returns (address payable[] memory receivers, uint256[] memory basisPoints);
    
    /**
     * @notice Compute royalty Shares
     * @param collectionAddress contract address 
     * @param tokenId Token Id 
     * @param amount amount involved to compute the Shares. 
     * @return receivers returns set of royalty receivers address
     * @return basisPoints returns set of Bps.
     * @return feeAmount returns set of Shares.
    **/
    function getRoyaltySplitshare(
        address collectionAddress,
        uint256 tokenId,
        uint256 amount
    )
        external
	view
        returns (
            address payable[] memory receivers,
            uint256[] memory basisPoints,
            uint256[] memory feeAmount
        );
    
    /**
     * @notice Adds address as blacklist
     * @param commonAddress user wallet address 
    **/
    function blacklistAddress(address commonAddress) external;

    /**
     * @notice revoke the blacklistedAddress
     * @param commonAddress address info
    **/
    function revokeBlacklistedAddress(address commonAddress) external;
        
    /**
     * @notice checks the blacklistedAddress
     * @param commonAddress address info
    **/
    function isBlacklistedAddress(address commonAddress)
        external
        view
        returns (bool);
}