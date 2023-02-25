// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./lib/IDelegationRegistry.sol";
import "./lib/ICryptoPunks.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BTCInscriber is Ownable {
    ICryptoPunks cryptoPunks = ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /// @dev mapping of addresses to flag if they are an inscription servicer, allows for future expansion
    mapping(address => bool) public inscriptionServices;

    /// @dev struct containing registry information for each inscription request
    struct InscribedNFT {
        address collectionAddress;
        uint256 tokenId;
        address inscribedBy;
        uint96 registryLockTime;
        bytes32 btcTransactionHash;
        string btcAddress;
    }

    /// @dev helper struct for getTokensOwnedByCollection
    struct TokenStatus {
        address collectionAddress;
        uint256 tokenId;
        uint256 inscriptionIndex;
    }

    /// @dev mapping of inscription index to inscription data
    mapping(uint256 => InscribedNFT) public inscribedNFTs;
    /// @dev mapping of collection address & token id to index of the inscribed NFT
    mapping(address => mapping(uint256 => uint256)) public nftToInscriptionIndex;
    /// @dev current index for inscription data
    uint256 private currentInscriptionIndex = 1;

    /// @dev Time period after last update of BTC transaction hash after which the provenance record becomes immutable
    uint256 public registryLockPeriod = 7 days;

    /// @dev Fee for registration only, caller provides the BTC transaction hash of a previously inscribed item
    uint256 public registerOnlyFee = 0.025 ether;
    /**
      * @dev Base fee for inscription service, assumes NFT image file will be reduced to 390,000 bytes
      *      This fee is discounted by the amount in the inscriptionDiscount mapping for each collection. 
      *      This fee is set high intentionally to discourage use by owners in collections that have not
      *      been indexed and set up for the inscription service while maintaining its openness for all users.
      */  
    uint256 public inscriptionBaseFee = 0.50 ether;
    /// @dev Discount amount set by inscription service for NFTs that are known to be under 390,000 bytes
    mapping(address => uint256) public inscriptionDiscount;

    /// @dev Thrown when attempting to inscribe an NFT that the msg.sender does not own
    error NotOwnerOrDelegate();
    /// @dev Thrown when attempting to inscribe an NFT without providing sufficient payment
    error InsufficientPayment();
    /// @dev Thrown when an address other than inscriptionService attempts to update a tx hash
    error NotInscriptionService();
    /// @dev Thrown when the registry service tries to update an item past the lock period
    error InscriptionLocked();
    /**
     * @dev Thrown when attempting to update the BTC destination address on an item that has already
     *      been inscribed or when trying to initiate a new inscription on an item already inscribed.
     */
    error AlreadyInscribed();
    /// @dev Thrown when attempting to update an inscription for an NFT that has not been inscribed
    error InvalidInscriptionIndex();
    /// @dev Thrown when attempting to execute a batch transaction with array lengths that do not match
    error ArrayLengthMismatch();
    /// @dev Thrown when attempting to withdraw funds to owner wallet and the withdraw call fails
    error WithdrawFailed();
    /// @dev Thrown when value received exceeds cost for register/inscription and the refund call fails
    error RefundFailed();

    event InscribeRequest(address indexed collectionAddress, uint256 indexed tokenId, address indexed inscribedBy, string inscribeTo);
    event UpdateBTCAddress(address indexed collectionAddress, uint256 indexed tokenId, address indexed inscribedBy, string inscribeTo);
    event Inscribed(address indexed collectionAddress, uint256 indexed tokenId, bytes32 btcTransactionHash);

    modifier onlyInscriptionService() {
        if(!inscriptionServices[msg.sender]) { revert NotInscriptionService(); }
        _;
    }

    constructor(address _inscriptionService) {
        inscriptionServices[_inscriptionService] = true;
    }

    /**
        INSCRIPTION FUNCTIONS
     */

    /**
     * @notice allows token owner to initiate an inscription of their NFT to BTC
     *         logs collectionAddress, tokenId, and address to send to then emits
     *         event for the inscription service to pick up
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcAddress the address to send the BTC inscription to
     */
    function inscribeNFT(address collectionAddress, uint256 tokenId, string calldata btcAddress) external payable {
        refundIfOver(_inscribe(collectionAddress, tokenId, btcAddress));
    }

    /**
     * @notice allows token owner to initiate an inscription of their NFT to BTC
     *         logs collectionAddress, tokenId, and address to send to then emits
     *         event for the inscription service to pick up
     * @param collectionAddresses array of addresses for the NFT collections being registered
     * @param tokenIds array of token ids of the NFTs being registered
     * @param btcAddresses array of BTC addresses to send the inscribed NFTs to
     */
    function inscribeNFTBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, string[] calldata btcAddresses) external payable {
        if(collectionAddresses.length != tokenIds.length || tokenIds.length != btcAddresses.length) { revert ArrayLengthMismatch(); }
        uint256 totalInscriptionCost = 0;
        for(uint256 i = 0;i < collectionAddresses.length;) {
            unchecked {
                totalInscriptionCost += _inscribe(collectionAddresses[i], tokenIds[i], btcAddresses[i]);
                ++i;
            }
        }
        refundIfOver(totalInscriptionCost);
    }

    /**
     * @notice allows token owner to update the BTC address that their inscription will be sent to, used when
     *         an invalid BTC address was supplied in the original transaction. No fee collected. Address may
     *         be overwritten by the inscription service if the transaction was already initiated prior to 
     *         updateBTCAddress being called.
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcAddress the address to send the BTC inscription to
     */
    function updateBTCAddress(address collectionAddress, uint256 tokenId, string calldata btcAddress) external {
        address tokenOwner = getOwner(collectionAddress, tokenId);
        uint256 inscriptionIndex = nftToInscriptionIndex[collectionAddress][tokenId];
        if(inscriptionIndex == 0) { revert InvalidInscriptionIndex(); }
        InscribedNFT memory _inscription = inscribedNFTs[inscriptionIndex];

        if(!isOwnerOrDelegate(tokenOwner, msg.sender, collectionAddress, tokenId)) { revert NotOwnerOrDelegate(); }
        if(_inscription.btcTransactionHash != bytes32(0)) { revert AlreadyInscribed(); }

        _inscription.inscribedBy = tokenOwner;
        _inscription.btcAddress = btcAddress;

        inscribedNFTs[inscriptionIndex] = _inscription;

        emit UpdateBTCAddress(collectionAddress, tokenId, tokenOwner, btcAddress);
    }

    /**
     * @notice allows token owner to update the BTC address that their inscription will be sent to, used when
     *         an invalid BTC address was supplied in the original transaction. No fee collected. Address may
     *         be overwritten by the inscription service if the transaction was already initiated prior to 
     *         updateBTCAddress being called.
     * @param collectionAddresses array of addresses for the NFT collections being registered
     * @param tokenIds array of token ids of the NFTs being registered
     * @param btcAddresses array of BTC addresses to send the inscribed NFTs to
     */
    function updateBTCAddressBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, string[] calldata btcAddresses) external {
        if(collectionAddresses.length != tokenIds.length || tokenIds.length != btcAddresses.length) { revert ArrayLengthMismatch(); }
        for(uint256 i = 0;i < collectionAddresses.length;) {
            this.updateBTCAddress(collectionAddresses[i], tokenIds[i], btcAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice allows token owner to register an item that has already been inscribed on BTC, small fee collected for
     *         operation of the registry website
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcTransactionHash the transaction hash of the BTC transaction where the item was inscribed
     */
    function registerInscription(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash) external payable {
        refundIfOver(_register(collectionAddress, tokenId, btcTransactionHash));
    }

    /**
     * @notice allows token owner to batch register items that have already been inscribed on BTC, small fee collected for
     *         operation of the registry website
     * @param collectionAddresses array of addresses for the NFT collections being registered
     * @param tokenIds array of token ids of the NFTs being registered
     * @param btcTransactionHashes array of transaction hashes of the BTC transactions where the NFTs were inscribed
     */
    function registerInscriptionBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, bytes32[] calldata btcTransactionHashes) external payable {
        if(collectionAddresses.length != tokenIds.length || tokenIds.length != btcTransactionHashes.length) { revert ArrayLengthMismatch(); }
        uint256 totalRegistrationCost = 0;
        for(uint256 i = 0;i < collectionAddresses.length;) {
            unchecked {
                totalRegistrationCost += _register(collectionAddresses[i], tokenIds[i], btcTransactionHashes[i]);
                ++i;
            }
        }
        refundIfOver(totalRegistrationCost);
    }

    /**
     * @notice called by inscription service to update the transaction hash from BTC once the NFT has been
     *         inscribed.
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcTransactionHash the transaction hash of the BTC transaction where the item was inscribed
     * @param btcAddress the address the inscription was sent to, this could differ from existing inscribeTo
     *                   when the owner attempted to update the inscription after the inscription service 
     *                   had already begun the inscription process.
     */
    function updateTransactionHash(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash, string calldata btcAddress) external onlyInscriptionService {
        _updateTransactionHash(collectionAddress, tokenId, btcTransactionHash, btcAddress);
    }

    /**
     * @notice called by inscription service to update the transaction hash from BTC once the NFT has been
     *         inscribed.
     * @param collectionAddresses array of addresses for the NFT collections being registered
     * @param tokenIds array of token ids of the NFTs being registered
     * @param btcTransactionHashes array of transaction hashes of the BTC transactions where the NFTs were inscribed
     * @param btcAddresses array of addresses the inscriptions were sent to, this could differ from existing inscribeTo
     *                     when the owner attempted to update the inscription after the inscription service 
     *                     had already begun the inscription process.
     */
    function updateTransactionHashBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, bytes32[] calldata btcTransactionHashes, string[] calldata btcAddresses) external onlyInscriptionService {
        if(collectionAddresses.length != tokenIds.length || tokenIds.length != btcTransactionHashes.length || btcTransactionHashes.length != btcAddresses.length) { revert ArrayLengthMismatch(); }
        for(uint256 i = 0;i < collectionAddresses.length;) {
            _updateTransactionHash(collectionAddresses[i], tokenIds[i], btcTransactionHashes[i], btcAddresses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
        INTERNAL FUNCTIONS
     */

    /**
     * @notice allows token owner to initiate an inscription of their NFT to BTC
     *         logs collectionAddress, tokenId, and address to send to then emits
     *         event for the inscription service to pick up
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcAddress the address to send the BTC inscription to
     */
    function _inscribe(address collectionAddress, uint256 tokenId, string calldata btcAddress) internal returns(uint256 inscriptionCost) {
        address tokenOwner = getOwner(collectionAddress, tokenId);
        uint256 inscriptionIndex = nftToInscriptionIndex[collectionAddress][tokenId];

        if(!isOwnerOrDelegate(tokenOwner, msg.sender, collectionAddress, tokenId)) { revert NotOwnerOrDelegate(); }
        if(inscriptionIndex != 0) { revert AlreadyInscribed(); }
        inscriptionCost = inscriptionBaseFee - inscriptionDiscount[collectionAddress];

        InscribedNFT memory _inscription;
        _inscription.collectionAddress = collectionAddress;
        _inscription.tokenId = tokenId;
        _inscription.inscribedBy = tokenOwner;
        _inscription.btcAddress = btcAddress;

        nftToInscriptionIndex[collectionAddress][tokenId] = currentInscriptionIndex;
        inscribedNFTs[currentInscriptionIndex] = _inscription;

        unchecked {
            ++currentInscriptionIndex;
        }

        emit InscribeRequest(collectionAddress, tokenId, tokenOwner, btcAddress);
    }

    /**
     * @notice internal function to register an inscription for an item already inscribed to BTC
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcTransactionHash the transaction hash of the BTC transaction where the item was inscribed
     */
    function _register(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash) internal returns(uint256 registrationCost) {
        address tokenOwner = getOwner(collectionAddress, tokenId);
        uint256 inscriptionIndex = nftToInscriptionIndex[collectionAddress][tokenId];

        if(!isOwnerOrDelegate(tokenOwner, msg.sender, collectionAddress, tokenId)) { revert NotOwnerOrDelegate(); }
        if(inscriptionIndex != 0) { revert AlreadyInscribed(); }
        registrationCost = registerOnlyFee;

        InscribedNFT memory _inscription;
        _inscription.collectionAddress = collectionAddress;
        _inscription.tokenId = tokenId;
        _inscription.inscribedBy = tokenOwner;
        _inscription.btcTransactionHash = btcTransactionHash;
        _inscription.registryLockTime = uint96(block.timestamp + registryLockPeriod);

        nftToInscriptionIndex[collectionAddress][tokenId] = currentInscriptionIndex;
        inscribedNFTs[currentInscriptionIndex] = _inscription;

        unchecked {
            ++currentInscriptionIndex;
        }

        emit Inscribed(collectionAddress, tokenId, btcTransactionHash);
    }

    /**
     * @notice internal function to update the transaction hash from BTC once the NFT has been inscribed.
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     * @param btcTransactionHash the transaction hash of the BTC transaction where the item was inscribed
     * @param btcAddress the address the inscription was sent to, this could differ from existing inscribeTo
     *                   when the owner attempted to update the inscription after the inscription service 
     *                   had already begun the inscription process.
     */
    function _updateTransactionHash(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash, string calldata btcAddress) internal {
        uint256 inscriptionIndex = nftToInscriptionIndex[collectionAddress][tokenId];
        if(inscriptionIndex == 0) { revert InvalidInscriptionIndex(); }
        InscribedNFT memory _inscription = inscribedNFTs[inscriptionIndex];

        if(block.timestamp > _inscription.registryLockTime) {
            _inscription.registryLockTime = uint96(block.timestamp + registryLockPeriod);
        } else if(_inscription.registryLockTime < block.timestamp) {
            revert InscriptionLocked();
        }

        _inscription.btcTransactionHash = btcTransactionHash;
        _inscription.btcAddress = btcAddress;

        inscribedNFTs[inscriptionIndex] = _inscription;

        emit Inscribed(collectionAddress, tokenId, btcTransactionHash);
    }

    /**
        OWNER FUNCTIONS
     */

    /**
     * @dev Sets an address as an allowed inscription service
     * @param _inscriptionService the address of the account to flag
     * @param _isService flag on whether or not account is an inscription service
     */
    function setInscriptionService(address _inscriptionService, bool _isService) external onlyOwner {
        inscriptionServices[_inscriptionService] = _isService;
    }

    /**
     * @dev Sets a discount on a collection that is known to be less than 390,000 bytes
     * @param collectionAddress address of the collection to set a discount on
     * @param _discount the amount of the discount, must be less than base fee
     */
    function setInscriptionDiscount(address collectionAddress, uint256 _discount) external onlyOwner {
        inscriptionDiscount[collectionAddress] = _discount;
    }

    /**
     * @dev Sets the base fees for the inscription service and registration only
     * @param _inscriptionBaseFee the base fee for the inscription service
     * @param _registrationOnlyFee the fee for only registering an inscription
     */
    function setInscriptionBaseFees(uint256 _inscriptionBaseFee, uint256 _registrationOnlyFee) external onlyOwner {
        inscriptionBaseFee = _inscriptionBaseFee;
        registerOnlyFee = _registrationOnlyFee;
    }

    /**
     * @dev Sets the lock period after which no updates can be made to the BTC tx hash
     *      this allows for a short period to update any inscription errors before locking
     *      the item in the registry.
     * @param _registryLockPeriod amount of time, in seconds, to allow for updates to BTC tx hash
     */
    function setRegistryLockPeriod(uint256 _registryLockPeriod) external onlyOwner {
        registryLockPeriod = _registryLockPeriod;
    }

    /**
     *   @dev Withdraws minting funds from contract
     */
    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        if(!sent) { revert WithdrawFailed(); }
    }

    /**
        HELPER FUNCTIONS
     */

    /**
     * @notice Refund for overpayment on rental and purchases
     * @param price cost of the transaction
     */
    function refundIfOver(uint256 price) private {
        if(msg.value < price) { revert InsufficientPayment(); }
        if (msg.value > price) {
            (bool sent, ) = payable(msg.sender).call{value: (msg.value - price)}("");
            if(!sent) { revert RefundFailed(); }
        }
    }

    /**
     * @notice check to see if operator is owner or delegate via delegate cash
     * @param tokenOwner the owner of the token
     * @param operator the address of the account to check for access
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     */
    function isOwnerOrDelegate(
        address tokenOwner,
        address operator,
        address collectionAddress,
        uint256 tokenId
    ) internal view returns (bool) {
        return (operator == tokenOwner ||
            delegateCash.checkDelegateForToken(
                    operator,
                    tokenOwner,
                    collectionAddress,
                    tokenId
                ));
    }

    /**
     * @notice get owner of NFT, uses CryptoPunk interface if collection address is CryptoPunks
     *         otherwise, uses IERC721
     * @param collectionAddress the address of the NFT collection
     * @param tokenId the tokenId of the NFT
     */
    function getOwner(
        address collectionAddress,
        uint256 tokenId
    ) internal view returns (address) {
        if(collectionAddress == address(cryptoPunks)) {
            return cryptoPunks.punkIndexToAddress(tokenId);
        } else {
            return IERC721(collectionAddress).ownerOf(tokenId);
        }
    }

    /**
     * @notice get a list of all inscriptions for the msg.sender, including via delegation
     *         intended for off-chain usage, do not call on-chain
     * @param tokenOwner owner of delegate of wallet that initiated the inscription
     */
    function inscriptionsByOwner(address tokenOwner) external view returns(InscribedNFT[] memory _inscriptions) {
        InscribedNFT[] memory tmpInscriptions = new InscribedNFT[](10000);
        InscribedNFT memory tmpInscription;
        uint256 tmpIndex = 0;
        for(uint256 i = 1;i < currentInscriptionIndex;) {
            tmpInscription = inscribedNFTs[i];
            if(isOwnerOrDelegate(tmpInscription.inscribedBy, tokenOwner, tmpInscription.collectionAddress, tmpInscription.tokenId)) {
                tmpInscriptions[tmpIndex] = tmpInscription;
                unchecked {
                    ++tmpIndex;
                }
            }
            unchecked {
                ++i;
            }
        }

        _inscriptions = new InscribedNFT[](tmpIndex);
        for(uint256 i = 0;i < tmpIndex;) {
            _inscriptions[i] = tmpInscriptions[i];

            unchecked {
                ++i;
            }
        }

        return _inscriptions;
    }

    /**
     * @notice get all inscriptions, filters for collection address, pending/complete, sort order and max records
     *         intended for off-chain usage, do not call on-chain
     * @param collectionAddress the address of the NFT collection
     * @param includePending whether or not to include pending inscriptions in results
     * @param includeCompleted whether or not to include completed inscriptions in results
     * @param sortNewestFirst sort order for inscriptions
     * @param maxRecords max number of inscription records to return
     */
    function allInscriptions(address collectionAddress, bool includePending, bool includeCompleted, bool sortNewestFirst, uint256 maxRecords) external view returns(InscribedNFT[] memory _inscriptions) {
        InscribedNFT[] memory tmpInscriptions = new InscribedNFT[](10000);
        InscribedNFT memory tmpInscription;
        uint256 tmpIndex = 0;
        for(uint256 i = 1;i < currentInscriptionIndex;) {
            tmpInscription = inscribedNFTs[(sortNewestFirst ? currentInscriptionIndex - i : i)];
            if(((includePending && tmpInscription.btcTransactionHash == bytes32(0)) || 
               (includeCompleted && tmpInscription.btcTransactionHash != bytes32(0))) &&
               (collectionAddress == address(0) || collectionAddress == tmpInscription.collectionAddress)) {
                tmpInscriptions[tmpIndex] = tmpInscription;
                unchecked {
                    ++tmpIndex;
                }
                if(tmpIndex == maxRecords) { break; }
            }
            unchecked {
                ++i;
            }
        }

        _inscriptions = new InscribedNFT[](tmpIndex);
        for(uint256 i = 0;i < tmpIndex;) {
            _inscriptions[i] = tmpInscriptions[i];

            unchecked {
                ++i;
            }
        }

        return _inscriptions;
    }

    /**
     * @notice get all NFTs owned by user, including those from a delegated cold wallet
     *         intended for off-chain usage, do not call on-chain
     * @param collectionAddress the address of the NFT collection
     * @param operator address of the user, could be a hot wallet delegated from cold wallet
     * @param startTokenId token id to start search at
     * @param endTokenId token id to end search at
     */
    function getTokensOwnedByCollection(address collectionAddress, address operator, uint256 startTokenId, uint256 endTokenId) external view returns(TokenStatus[] memory tokens) {
        TokenStatus[] memory tmpTokens = new TokenStatus[](5000);

        uint256 statusIndex = 0;
        address tokenOwner;
        for(uint256 tokenId = startTokenId;tokenId < endTokenId;) {
            if(collectionAddress == address(cryptoPunks)) {
                try cryptoPunks.punkIndexToAddress(tokenId) returns (address result) { tokenOwner = result; } catch { tokenOwner = address(0); }
            } else {
                try IERC721(collectionAddress).ownerOf(tokenId) returns (address result) { tokenOwner = result; } catch { tokenOwner = address(0); }
            }
            if(tokenOwner != address(0)) {
                if(isOwnerOrDelegate(tokenOwner, operator, collectionAddress, tokenId)) {
                    TokenStatus memory tmpToken;
                    tmpToken.collectionAddress = collectionAddress;
                    tmpToken.tokenId = tokenId;
                    tmpToken.inscriptionIndex = nftToInscriptionIndex[collectionAddress][tokenId];
                    tmpTokens[statusIndex] = tmpToken;
                    unchecked {
                        ++statusIndex;
                    }
                }
            }
            unchecked {
                ++tokenId;
            }
        }

        tokens = new TokenStatus[](statusIndex);
        for(uint256 i = 0;i < tokens.length;i++) {
            tokens[i] = tmpTokens[i];
        }

        return tokens;
    }
}