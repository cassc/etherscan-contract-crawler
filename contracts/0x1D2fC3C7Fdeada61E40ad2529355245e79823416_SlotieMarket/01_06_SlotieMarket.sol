// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface ISlotieAssetManager {
     function transferERC721(
        address asset,
        address sender,
        address recipient,
        uint256 tokenId
    ) external;
    function transferERC20(
        address asset,
        address sender,
        address recipient,
        uint256 amount
    ) external;
    function transferETH(
        address recipient,
        uint256 amount
    ) external payable;
}

contract SlotieMarket is Ownable, Pausable {
    using ECDSA for bytes32;

    /// +++++++++++++++++++++++++
    /// @notice STORAGE VARIABLES
    /// +++++++++++++++++++++++++

    ISlotieAssetManager public slotieAssetManager;

    /// @notice The accepted collections in the marketplace
    mapping(address => bool) public supportedCollections;

    /// @notice Maps a listing signature to its valid state
    mapping(bytes => bool) public isListingDropped;

    /// @notice Maps an offer signature to its valid state
    mapping(bytes => bool) public isOfferDropped;

    /// @notice Identifier used to identify listing signatures
    bytes32 public listingSignatureIdentifier = keccak256("SLOTIE-LISTING");

    /// @notice Identifier used to identify offer signatures
    bytes32 public offerSignatureIdentifier = keccak256("SLOTIE-OFFER");

    /// @notice Address of Slotie platform fee receiver
    address public platformFeeReceiver;

    /// @notice Platform fee multiplier denoted in 100_000
    uint256 public platformFeeMultiplier;

    address public WETH;

    /// ++++++++++++++
    /// @notice EVENTS
    /// ++++++++++++++

    /// @dev Emits when a listing is matched
    /// @param collection The nft collection
    /// @param seller The creator of the listing
    /// @param recipient The user matching the listing
    /// @param tokenId The token id of the listed nft
    /// @param expiration The expiration timestamp of the listing
    /// @param ethAmount The payment value of the NFT
    /// @param randomSalt The random salt used to create the listing signature
    /// @param signatureHash The hash of the listing signature
    event BoughtListing(
        address collection,
        address seller,
        address recipient,
        uint tokenId,  
        uint expiration,
        uint ethAmount, 
        bytes32 randomSalt,
        bytes32 signatureHash

    );

     /// @dev Emits when an offer is matched
    /// @param collection The nft collection
    /// @param seller The creator of the listing
    /// @param recipient The user matching the listing
    /// @param tokenId The token id of the listed nft
    /// @param expiration The expiration timestamp of the listing
    /// @param ethAmount The payment value of the NFT
    /// @param randomSalt The random salt used to create the offer signature
    /// @param signatureHash The hash of the listing signature
    event BidAccepted(
        address collection,
        address seller,
        address recipient,
        uint tokenId,
        uint expiration,
        uint ethAmount, 
        bytes32 randomSalt,
        bytes32 signatureHash
    );

    /// @dev Emits when a listing is dropped
    /// @param signatureHash The hash of the listing signature
    event Delist(
        bytes32 signatureHash
    );

    /// @dev Emits when an offer is dropped
    /// @param signatureHash The hash of the listing signature
    event WithdrawBid(
        bytes32 signatureHash
    );

    /**
     * @notice Constructor
     */
    constructor(
        address _weth,
        address _feeReceiver,
        uint256 _feeMultiplier,
        address slotie,
        address slotieJunior
    ) {
        WETH = _weth;
        platformFeeReceiver = _feeReceiver;
        platformFeeMultiplier = _feeMultiplier;
        supportedCollections[slotie] = true;
        supportedCollections[slotieJunior] = true;
    }

    /// ++++++++++++++++++++++++++++++
    /// @notice SIGNATURE VERIFICATION
    /// ++++++++++++++++++++++++++++++

    function createSignedMessage(bytes memory encodedData) internal pure returns (bytes32) {
        return keccak256(encodedData).toEthSignedMessageHash();
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function requireValidListingSignature(
        address seller,
        address collectionIdentifier,
        uint tokenId,
        uint256 listingExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) internal view {
        bytes32 message = createSignedMessage(
            abi.encodePacked(
                listingSignatureIdentifier,
                collectionIdentifier,
                tokenId,
                listingExpirationTimestamp,
                ethAmount,
                randomSalt
            )
        );
        address signer = recoverSigner(message, signature);
        require(signer == seller, "Invalid listing signature");
    }

    function requireValidOfferSignature(
        address buyer,
        address collectionIdentifier,
        uint tokenId,
        uint256 offerExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) internal view {
        bytes32 message = createSignedMessage(
            abi.encodePacked(
                offerSignatureIdentifier,
                collectionIdentifier,
                tokenId,
                offerExpirationTimestamp,
                ethAmount,
                randomSalt
            )
        );
        address signer = recoverSigner(message, signature);
        require(signer == buyer, "Invalid offer signature");
    }


    /// ++++++++++++++
    /// @notice CHECKS
    /// ++++++++++++++

    /**
     * @notice Checks if a collection is supported in the marketplace
     *
     * @dev Reverts if collection is not supported
     *
     * @param collection An address representing the collection to check
     */
    modifier onlySupportedCollections(address collection) {
        require(supportedCollections[collection], "Collection not supported");
        _;
    }

    /// +++++++++++++++++++++++++
    /// @notice PRIVATE FUNCTIONS
    /// +++++++++++++++++++++++++
    
    /**
     * @notice Computes the royalty on an arbitrary token amount.
     *
     * @param value An integer representing the token value
     * @param multiplier An integer representing the royalty percentage
     *
     * @return royalty The royalty amount
     */
    function computeRoyalty(uint value, uint multiplier) private pure returns (uint) {
        return value * multiplier / 100_000;
    }

    /**
     * @notice Executes a payment of an accepted currency.
     *
     * @param collection An address representing the nft collection.
     * Used to determine royalties data
     * @param sender The address of the paying wallet
     * @param recipient The address of the receiving wallet
     * @param amount The transfer amount
     */
    function payWithWETHApplyingRoyalties(
        address collection,
        address sender, 
        address recipient, 
        uint amount 
    ) private {
        uint256 totalRoyalties;
        if (platformFeeMultiplier > 0) {
            uint256 platformAmount = computeRoyalty(amount, platformFeeMultiplier);
            slotieAssetManager.transferERC20(WETH, sender, platformFeeReceiver, platformAmount);
            totalRoyalties += platformAmount;
        }

        amount = amount - totalRoyalties;
        slotieAssetManager.transferERC20(WETH, sender, recipient, amount);
    }

    /**
     * @notice Executes a payment of eth.
     *
     * @param collection An address representing the nft collection.
     * Used to determine royalties data
     * @param recipient The address of the receiving wallet
     * @param amount The transfer amount
     */
    function payWithEthApplyingRoyalties(
        address collection, 
        address recipient, 
        uint amount
    ) private {
        uint256 totalRoyalties;
        if (platformFeeMultiplier > 0) {
            uint256 platformAmount = computeRoyalty(amount, platformFeeMultiplier);
            slotieAssetManager.transferETH{ value: platformAmount }(platformFeeReceiver, platformAmount);
            totalRoyalties += platformAmount;
        }

        amount = amount - totalRoyalties;
        slotieAssetManager.transferETH{ value: amount }(recipient, amount);
    }

    /// ++++++++++++++++++++++++++++
    /// @notice MANAGEMENT FUNCTIONS
    /// ++++++++++++++++++++++++++++

    /**
     * @notice Allows owner to change the paused state of the marketplace
     *
     * @param _isActive A boolean representing the paused state of the contract.
     */
    function setActive(bool _isActive) external onlyOwner {
        if (_isActive) {           
            Pausable._unpause();
        } else {
            Pausable._pause();
        }
    }

    function setSlotieAssetManager(address manager) external onlyOwner {
        require(manager != address(0), "Invalid address");
        require(address(slotieAssetManager) == address(0), "SlotieAssetManager already set");
        slotieAssetManager = ISlotieAssetManager(manager);
    }

    function setPlatformFeeReceiver(address receiver) external onlyOwner {
        require(receiver != address(0), "Invalid address");
        platformFeeReceiver = receiver;
    }

    function setPlatformFeeMultiplier(uint multiplier) external onlyOwner {
        require(multiplier <= 100_000, "Invalid multiplier");
        platformFeeMultiplier = multiplier;
    }

    /// ++++++++++++++++++++++++++++++
    /// @notice LISTINGS
    /// ++++++++++++++++++++++++++++++

    /**
     * @notice Allows a user to delist their NFT
     *
     * @param collectionIdentifier The address of the slotie or slotie junior collection    
     * @param tokenId The id of the nft being bought
     * @param listingExpirationTimestamp The timestamp where the listing are invalid
     * @param ethAmount The amounts of eth paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The listing signature
     */
    function delist(
        address collectionIdentifier,
        uint256 tokenId,
        uint256 listingExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) external 
      whenNotPaused
    {
        /// @dev Checks
        require(!isListingDropped[signature], "Listing inactive");
        requireValidListingSignature(
            msg.sender,
            collectionIdentifier,
            tokenId,
            listingExpirationTimestamp,
            ethAmount,
            randomSalt,
            signature
        );
        
        /// @dev Effects
        isListingDropped[signature] = true;

        emit Delist(
            keccak256(signature)
        );
    }

    /**
     * @notice Allows a user to buy a listed NFT
     *
     * @dev Called by buyer
     *
     * @param collectionIdentifier The address of the NFT's collection
     * @param seller The address of the user created the listing
     * @param tokenId The id of the nft being bought
     * @param listingExpirationTimestamp The timestamp where the listing is invalid
     * @param ethAmount The amount of currency paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The listing signature
     */
    function buySingleListing(
        address collectionIdentifier,
        address seller,
        uint tokenId,
        uint256 listingExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) public 
      payable 
      whenNotPaused 
      onlySupportedCollections(collectionIdentifier) {
        /// @dev Checks
        require(!isListingDropped[signature], "Listing inactive");
        require(msg.value >= ethAmount, "Insufficient payment");   
        require(listingExpirationTimestamp == 0 || listingExpirationTimestamp > block.timestamp, "Listing expired");               
        require(msg.sender != seller, "Cannot buy from self");
        requireValidListingSignature(
            seller,
            collectionIdentifier,
            tokenId,
            listingExpirationTimestamp,
            ethAmount,
            randomSalt,
            signature
        );

        /// @dev Effects
        isListingDropped[signature] = true;

        /// @dev Interactions
        payWithEthApplyingRoyalties(
            collectionIdentifier, 
            seller, 
            ethAmount 
        );
        slotieAssetManager.transferERC721(
            collectionIdentifier,
            seller,
            msg.sender, 
            tokenId
        );

        emit BoughtListing(
            collectionIdentifier, 
            seller,  
            msg.sender, 
            tokenId, 
            listingExpirationTimestamp,
            ethAmount,
            randomSalt,
            keccak256(signature)
        );
    }

    /// +++++++++++++++++++++++++
    /// @notice OFFERS
    /// +++++++++++++++++++++++++

    
    /**
     * @notice Allows a user to withdraw one or more bids
     *
     * @param collectionIdentifier The address of the NFT's collections
     * @param tokenId The ids of the nfts being bought
     * @param offerExpirationTimestamp The timestamps where the offers are invalid
     * @param ethAmount The amounts of currency paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The offer signatures
     */
    function withdrawBid(
        address collectionIdentifier,
        uint tokenId,
        uint256 offerExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) external 
      whenNotPaused 
    {
        /// @dev Checks
        require(supportedCollections[collectionIdentifier], "Collection not supported");
        require(!isOfferDropped[signature], "Listing inactive");
        requireValidOfferSignature(
            msg.sender,
            collectionIdentifier,
            tokenId,
            offerExpirationTimestamp,
            ethAmount,
            randomSalt,
            signature
        );
        
        /// @dev Effects
        isOfferDropped[signature] = true;

        emit WithdrawBid(
            keccak256(signature)
        );
    }

    /**
     * @notice Allows a user to accept a bid on their NFT
     *
     * @dev Called by seller
     *
     * @param collectionIdentifier The address of the NFT's collection
     * @param buyer The address of the user that the offer
     * @param tokenId The id of the nft being bought
     * @param offerExpirationTimestamp The timestamp where the offer is invalid
     * @param ethAmount The amount of currency paid
     * @param randomSalt A random salt to prevent replay attacks
     * @param signature The offer signature
     */
    function acceptBid(
        address collectionIdentifier,
        address buyer,
        uint tokenId,
        uint256 offerExpirationTimestamp,
        uint256 ethAmount,
        bytes32 randomSalt,
        bytes memory signature
    ) external 
      whenNotPaused
      onlySupportedCollections(collectionIdentifier)
    {
        /// @dev Checks
        require(!isOfferDropped[signature], "Offer inactive");
        require(offerExpirationTimestamp == 0 || offerExpirationTimestamp > block.timestamp, "Offer expired");
        require(msg.sender != buyer, "Cannot buy from self");
        requireValidOfferSignature(
                buyer,
                collectionIdentifier,
                tokenId,
                offerExpirationTimestamp,
                ethAmount,
                randomSalt,
                signature
        );

        /// @dev Effects
        isOfferDropped[signature] = true;

        /// @dev Interactions
        payWithWETHApplyingRoyalties(
            WETH,
            buyer, 
            msg.sender, 
            ethAmount
         );

        slotieAssetManager.transferERC721(
            collectionIdentifier,
            msg.sender,
            buyer, 
            tokenId
        );

        emit BidAccepted(
            collectionIdentifier, 
            msg.sender,  
            buyer, 
            tokenId, 
            offerExpirationTimestamp,
            ethAmount,
            randomSalt,
            keccak256(signature)
        );
    }
}