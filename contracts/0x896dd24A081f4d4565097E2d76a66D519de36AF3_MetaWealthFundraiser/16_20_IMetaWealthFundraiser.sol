// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

interface IMetaWealthFundraiser {
    struct CampaignInstance {
        address owner;
        uint64 sharesToSell;
        uint32 investFee;
        address receiverWallet;
        uint64 reservedShares;
        address raiseCurrency;
        uint64 remainingShares;
        uint256 sharePrice;
        uint64 expirationTimestamp;
    }

    /// @notice Fired when a campaign is started
    /// @param owner is the address of campaign starter
    /// @param collection is the NFT collection address
    /// @param tokenId is the id of the NFT for which funds are raised
    /// @param sharesToSell is the amount of shares the campaign is offering
    /// @param sharePrice is the goal of the raise for this campaign
    /// @param raiseCurrency is the ERC20 currency the funds are being raised in
    event CampaignStarted(
        address indexed owner,
        address indexed collection,
        uint256 indexed tokenId,
        uint64 sharesToSell,
        uint256 sharePrice,
        address raiseCurrency,
        address receiverWallet,
        uint64 reservedShares,
        uint64 expirationTimestamp
    );
    event CampaignExpirationChanged(
        address indexed operator,
        address indexed collection,
        uint256 indexed tokenId,
        uint64 newExpirationTimestamp,
        uint64 prevExpirationTimestamp
    );

    /// @notice Fired when a campaign receives investment
    /// @param investor is the address of campaign starter
    /// @param collection is the NFT collection address
    /// @param tokenId is the id of the NFT for which funds are raised
    /// @param amount is the amount invested
    /// @param raiseCompleted is the boolean representing whether the raise completed after this investment
    event InvestmentReceived(
        address investor,
        address indexed collection,
        uint256 indexed tokenId,
        uint256 amount,
        bool raiseCompleted
    );

    /// @notice Fired when the owner cancels an ongoing campaign
    /// @param collection is the NFT collection address
    /// @param tokenId is the id of the NFT for which funds were being raised
    event CampaignCancelled(
        address indexed owner,
        address indexed collection,
        uint256 indexed tokenId
    );
    event CampaignCompleted(
        address indexed owner,
        address indexed collection,
        uint256 indexed tokenId
    );
    event ERC20Released(
        address indexed operator,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /// @notice Starts a new fundraiser capmaign
    /// @param collection is the NFT collection address of which an asset is being put up for raise
    /// @param tokenId is the NFT id within the collection above
    /// @param sharesToSell is the number of shares NFT's owner'd like to sell
    /// @param reservedShares is the shares reserved for receiverWallet
    /// @param sharePrice is the ERC20 currency that the raise is being held in
    /// @param receiverWallet receives all raised money and reservedShares
    /// @param raiseCurrency is the ERC20 currency that the raise is being held in
    /// @param _merkleProof is the sender's proof of being KYC'd
    /// @dev The function should immediately transfer the asset to the contract itself
    function startCampaign(
        address collection,
        uint256 tokenId,
        uint64 sharesToSell,
        uint64 reservedShares,
        uint256 sharePrice,
        address receiverWallet,
        address raiseCurrency,
        uint64 campaignDuration,
        bytes32[] memory _merkleProof
    ) external;

    /// @notice Retrieves an active campaign from the contract
    /// @param collection is the NFT collection address
    /// @param tokenId is the NFT id within the collection above
    /// @return campaign is the tuple containing raise information
    function getCampaign(
        address collection,
        uint256 tokenId
    ) external view returns (CampaignInstance memory campaign);

    /// @notice Retrieves all the investors for a specific fundraise
    /// @param collection is the NFT collection address
    /// @param tokenId is the NFT id within the collection above
    /// @return investors is the list of addresses that have invested in the project
    function getInvestors(
        address collection,
        uint256 tokenId
    ) external view returns (address[] memory investors);

    /// @notice Allows users to invest into ongoing campaigns
    /// @param collection is the collection address of the collection whose asset is being invested for
    /// @param tokenId is the NFT ID within that collection
    /// @param numberShares amount of shares user'd like to buy
    /// @param _userMerkleProof is the proof of message sender being KYC'd in MetaWealth
    /// @dev The function should immediately transfer ERC20 currency into the contract itself
    function invest(
        address collection,
        uint256 tokenId,
        uint64 numberShares,
        bytes32[] memory _userMerkleProof
    ) external;

    /// @notice Allows campaign starter AND MetaWealth moderator to cancel an ongoing raise
    /// @param collection is the NFT collection address
    /// @param tokenId is the token ID within that collection
    /// @param _merkleProof is the proof of message sender being KYC'd in platform
    /// @dev This function should return the investments AND the starter's NFT back to them
    function cancelRaise(
        address collection,
        uint256 tokenId,
        bytes32[] memory _merkleProof
    ) external;

    /// @notice Retrieves investment of a specific campaign for the wallet
    /// @param wallet is the user's wallet address
    /// @param collection is the address of NFT collection
    /// @param tokenId is the id of the token within collection
    /// @return investment is the amount invested by the user;
    function getWalletInvestment(
        address wallet,
        address collection,
        uint256 tokenId
    ) external view returns (uint256 investment);
}