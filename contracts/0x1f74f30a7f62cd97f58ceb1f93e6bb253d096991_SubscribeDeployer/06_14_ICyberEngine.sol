// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ICyberEngineEvents } from "./ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

/**
 * @title ICyberEngine
 * @author CyberConnect
 */
interface ICyberEngine is ICyberEngineEvents {
    /**
     * @notice Initialize the CyberEngine.
     *
     * @param params The params for init.
     */
    function initialize(DataTypes.InitParams calldata params) external;

    /**
     * @notice Collect an CyberAccount's essence, content or w3st.
     *
     * @param params The params for collect.
     * @param data The collect data for pre process.
     * @return uint256 The collected nft id.
     */
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata data
    ) external returns (uint256);

    /**
     * @notice Subscribe to a CyberAccount.
     *
     * @param account The account to subscribe.
     * @param to The address that will receive the subscription.
     * @return uint256 The new token id.
     */
    function subscribe(
        address account,
        address to
    ) external payable returns (uint256);

    /**
     * @notice Register an essence.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @return uint256 The new essence count.
     */
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Register subscription.
     *
     * @param params The params for registration.
     */
    function registerSubscription(
        DataTypes.RegisterSubscriptionParams calldata params
    ) external;

    /**
     * @notice Set subscription data.
     *
     * @param account The account to set.
     * @param uri The uri to set.
     * @param recipient The recipient to set.
     * @param pricePerSub The price per subscription to set.
     * @param dayPerSub The day per subscription to set.
     */
    function setSubscriptionData(
        address account,
        string calldata uri,
        address recipient,
        uint256 pricePerSub,
        uint256 dayPerSub
    ) external;

    /**
     * @notice Publish a content.
     *
     * @param params The params for publishing content.
     * @param initData The registration initial data.
     * @return uint256 The new token id.
     */
    function publishContent(
        DataTypes.PublishContentParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Share a content, comment or another share.
     *
     * @param params The params for sharing.
     * @return uint256 The new token id.
     */
    function share(
        DataTypes.ShareParams calldata params
    ) external returns (uint256);

    /**
     * @notice Comment a content, comment or share.
     *
     * @param params The params for commenting content.
     * @param initData The registration initial data.
     * @return uint256 The new token id.
     */
    function comment(
        DataTypes.CommentParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Issue a w3st.
     *
     * @param params The params for issuing w3st.
     * @param initData The registration initial data.
     * @return uint256 The new token id.
     */
    function issueW3st(
        DataTypes.IssueW3stParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Gets the Essence NFT token URI.
     *
     * @param account The account address.
     * @param essenceId The Essence ID.
     * @return string The Essence NFT token URI.
     */
    function getEssenceTokenURI(
        address account,
        uint256 essenceId
    ) external view returns (string memory);

    /**
     * @notice Gets the Essence NFT transferability.
     *
     * @param account The account address.
     * @param essenceId The Essence ID.
     */
    function getEssenceTransferability(
        address account,
        uint256 essenceId
    ) external view returns (bool);

    /**
     * @notice Sets essence data.
     *
     * @param account The account address.
     * @param essenceId The essence ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setEssenceData(
        address account,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Gets the Essence NFT address.
     *
     * @param account The account address.
     * @param essenceId The Essence ID.
     * @return address The Essence NFT address.
     */
    function getEssenceAddr(
        address account,
        uint256 essenceId
    ) external view returns (address);

    /**
     * @notice Gets the Essence NFT middleware.
     *
     * @param account The account address.
     * @param essenceId The Essence ID.
     * @return address The Essence NFT middleware.
     */
    function getEssenceMw(
        address account,
        uint256 essenceId
    ) external view returns (address);

    /**
     * @notice Gets how many Essence NFTs the account registered.
     *
     * @param account The account address.
     * @return uint256 The Essence NFT count.
     */
    function getEssenceCount(address account) external view returns (uint256);

    /**
     * @notice Sets content data.
     *
     * @param account The account address.
     * @param tokenId The content tokenId.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setContentData(
        address account,
        uint256 tokenId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets w3st data.
     *
     * @param account The account address.
     * @param tokenId The w3st tokenId.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setW3stData(
        address account,
        uint256 tokenId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Gets the Content NFT token URI.
     *
     * @param account The account address.
     * @param tokenId The Content NFT ID.
     * @return string The Content NFT token URI.
     */
    function getContentTokenURI(
        address account,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @notice Gets the Content NFT address.
     *
     * @param account The account address.
     * @return address The Content NFT address.
     */
    function getContentAddr(address account) external view returns (address);

    /**
     * @notice Gets the Content NFT transferability.
     *
     * @param account The account address.
     * @param tokenId The Content NFT ID.
     */
    function getContentTransferability(
        address account,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Gets the Content source info.
     *
     * @param account The account address.
     * @param tokenId The Content NFT ID.
     * @return address The source content owner.
     * @return uint256 The source content token ID.
     */
    function getContentSrcInfo(
        address account,
        uint256 tokenId
    ) external view returns (address, uint256);

    /**
     * @notice Gets the Content NFT middleware.
     *
     * @param account The account address.
     * @param tokenId The Content NFT ID.
     * @return address The Content NFT middleware.
     */
    function getContentMw(
        address account,
        uint256 tokenId
    ) external view returns (address);

    /**
     * @notice Gets how many Content NFTs the account registered.
     *
     * @param account The account address.
     * @return uint256 The Content NFT count.
     */
    function getContentCount(address account) external view returns (uint256);

    /**
     * @notice Gets the w3st NFT token URI.
     *
     * @param account The account address.
     * @param tokenId The w3st NFT ID.
     * @return string The w3st NFT token URI.
     */
    function getW3stTokenURI(
        address account,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @notice Gets the w3st NFT address.
     *
     * @param account The account address.
     * @return address The w3st NFT address.
     */
    function getW3stAddr(address account) external view returns (address);

    /**
     * @notice Gets the w3st NFT transferability.
     *
     * @param account The account address.
     * @param tokenId The w3st NFT ID.
     */
    function getW3stTransferability(
        address account,
        uint256 tokenId
    ) external view returns (bool);

    /**
     * @notice Gets the w3st NFT middleware.
     *
     * @param account The account address.
     * @param tokenId The w3st NFT ID.
     * @return address The w3st NFT middleware.
     */
    function getW3stMw(
        address account,
        uint256 tokenId
    ) external view returns (address);

    /**
     * @notice Gets how many w3st NFTs the account registered.
     *
     * @param account The account address.
     * @return uint256 The w3st NFT count.
     */
    function getW3stCount(address account) external view returns (uint256);

    /**
     * @notice Gets if the account approved the operator to publish/set Content, Comment, Share, W3st, Subscription in the protocol.
     * @param account The account address.
     * @param operator The operator address.
     */
    function getOperatorApproval(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice Sets if the account approves the operator to publish/set Content, Comment, Share, W3st, Subscription in the protocol.
     * @param operator The operator address.
     * @param approved The approval status.
     */
    function setOperatorApproval(address operator, bool approved) external;

    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param account The account address.
     */
    function getSubscriptionTokenURI(
        address account
    ) external view returns (string memory);

    /**
     * @notice Gets the Subscription recipient address.
     *
     * @param account The account address.
     * @return address The Subscription recipient address.
     */
    function getSubscriptionRecipient(
        address account
    ) external view returns (address);

    /**
     * @notice Gets the Subscription price per subscription.
     *
     * @param account The account address.
     * @return uint256 The Subscription price per subscription.
     */
    function getSubscriptionPricePerSub(
        address account
    ) external view returns (uint256);

    /**
     * @notice Gets the Subscription day per subscription.
     *
     * @param account The account address.
     * @return uint256 The Subscription day per subscription.
     */
    function getSubscriptionDayPerSub(
        address account
    ) external view returns (uint256);

    /**
     * @notice Gets the Subscribe NFT address.
     *
     * @param account The account address.
     * @return address The Subscribe NFT address.
     */
    function getSubscriptionAddr(
        address account
    ) external view returns (address);

    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     */
    function version() external pure returns (uint256);
}