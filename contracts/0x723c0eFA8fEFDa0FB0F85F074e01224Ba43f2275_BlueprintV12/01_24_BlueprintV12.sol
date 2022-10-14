//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "./abstract/HasSecondarySaleFees.sol";
import "./royalties/interfaces/ISplitMain.sol";
import "./common/IBlueprintTypes.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev Global instance of Async Art Blueprint NFTs
 * @author Async Art, Ohimire Labs
 */
contract BlueprintV12 is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuard
{
    using StringsUpgradeable for uint256;

    /**
     * @dev Default fee given to platform on primary sales
     */
    uint32 public defaultPlatformPrimaryFeePercentage;   

    /**
     * @dev Default fee given to artist on secondary sales
     */ 
    uint32 public defaultBlueprintSecondarySalePercentage;

    /**
     * @dev Default fee given to platoform on secondary sales
     */ 
    uint32 public defaultPlatformSecondarySalePercentage;

    /**
     * @dev Token id of last ERC721 NFT minted
     */ 
    uint64 public latestErc721TokenIndex;

    /**
     * @dev Id of last blueprint created
     */
    uint256 public blueprintIndex;

    /**
     * @dev Platform account receiving fees from primary sales
     */
    address public asyncSaleFeesRecipient;

    /**
     * @dev Account representing platform 
     */
    address public platform;

    /**
     * @dev Account able to perform actions restricted to MINTER_ROLE holder
     */
    address public minterAddress;

    /** 
     * @dev Royalty manager 
     */
    address private _splitMain;
    
    /**
     * @dev Maps NFT ids to id of associated blueprint 
     */
    mapping(uint256 => uint256) tokenToBlueprintID;

    /**
     * @dev Tracks failed transfers of native gas token 
     */
    mapping(address => uint256) failedTransferCredits;

    /**
     * @dev Stores all Blueprints 
     */
    mapping(uint256 => Blueprints) public blueprints;

    /**
     * @dev Holders of this role are given minter privileges 
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @dev Tracks state of Blueprint sale
     */
    enum SaleState {
        not_prepared,
        not_started,
        started,
        paused
    }

    /**
     * @dev Object used by contract clients to efficiently pass in desired configuration for royalties for a Blueprint
     * @param secondaryFeeRecipients Array of royalty recipients
     * @param secondaryFeeMPS Array of allocations given to each royalty recipients, where 1000000 = 100%
     * @param totalRoyaltyCutBPS Total percentage of token purchase to be sent to royalty recipients, in basis points
     * @param royaltyRecipient If/when this is not the zero address, it is used as the de-facto alternative to secondaryFeeRecipients and secondaryFeeBPS
     */
    struct SecondaryFeesInput {
        address[] secondaryFeeRecipients; 
        uint32[] secondaryFeeMPS; 
        uint32 totalRoyaltyCutBPS;
        address royaltyRecipient;
    }

    /**
     * @dev Object used by contract clients to efficiently pass in desired configuration for all fees 
     * @param primaryFeeBPS Array of allocations given to each primary fee recipient, in basis points
     * @param primaryFeeRecipients Array of primary fee recipients
     * @param secondaryFeesInput Contains desired configuration for royalties
     * @param deploySplit If true, function taking FeesInput instance will deploy a royalty split 
     */
    struct FeesInput {
        uint32[] primaryFeeBPS;
        address[] primaryFeeRecipients;
        SecondaryFeesInput secondaryFeesInput;
        bool deploySplit; 
    } 

    /**
     * @dev Object stored per Blueprint defining fee recipients and allocations
     * @param primaryFeeRecipients Array of primary fee recipients
     * @param primaryFeeBPS Array of allocations given to each primary fee recipient, in basis points
     * @param royaltyRecipient Address to receive total share of royalties. Expected to be royalty split or important account
     * @param totalRoyaltyCutBPS Total percentage of token purchase to be sent to royalty recipients, in basis points
     */
    struct Fees {
        address[] primaryFeeRecipients;
        uint32[] primaryFeeBPS;
        address royaltyRecipient;
        uint32 totalRoyaltyCutBPS;
    }

    /**
     * @dev Blueprint
     * @param mintAmountArtist Amount of NFTs of Blueprint mintable by artist
     * @param mintAmountArtist Amount of NFTs of Blueprint mintable by platform 
     * @param capacity Number of NFTs in Blueprint 
     * @param erc721TokenIndex Token ID of last NFT minted for Blueprint
     * @param maxPurchaseAmount Max number of NFTs purchasable in a single transaction
     * @param saleEndTimestamp Timestamp when the sale ends 
     * @param price Price per NFT in Blueprint
     * @param tokenUriLocked If the token metadata isn't updatable 
     * @param artist Artist of Blueprint
     * @param ERC20Token Address of ERC20 currency required to buy NFTs, can be zero address if expected currency is native gas token 
     * @param baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param merkleroot Root of Merkle tree holding whitelisted accounts 
     * @param saleState State of sale
     * @param feeRecipientInfo Object containing primary and secondary fee configuration
     */ 
    struct Blueprints {
        uint32 mintAmountArtist;
        uint32 mintAmountPlatform;
        uint64 capacity;
        uint64 erc721TokenIndex;
        uint64 maxPurchaseAmount;
        uint128 saleEndTimestamp;
        uint128 price;
        bool tokenUriLocked;        
        address artist;
        address ERC20Token;
        string baseTokenUri;
        bytes32 merkleroot;
        SaleState saleState;    
        Fees feeRecipientInfo;
    }

    /**
     * @dev Emitted when blueprint seed is revealed
     * @param blueprintID ID of blueprint
     * @param randomSeed Revealed seed
     */
    event BlueprintSeed(uint256 blueprintID, string randomSeed);

    /**
     * @dev Emitted when NFTs of a blueprint are minted
     * @param blueprintID ID of blueprint
     * @param artist Blueprint artist
     * @param purchaser Purchaser of NFTs
     * @param tokenId NFT minted
     * @param newCapacity New capacity of tokens left in blueprint 
     * @param seedPrefix Seed prefix hash
     */
    event BlueprintMinted(
        uint256 blueprintID,
        address artist,
        address purchaser,
        uint128 tokenId,
        uint64 newCapacity,
        bytes32 seedPrefix
    );

    /**
     * @dev Emitted when blueprint is prepared
     * @param blueprintID ID of blueprint
     * @param artist Blueprint artist
     * @param capacity Number of NFTs in blueprint
     * @param blueprintMetaData Blueprint metadata uri
     * @param baseTokenUri Blueprint's base token uri. Token uris are a result of the base uri concatenated with token id 
     */
    event BlueprintPrepared(
        uint256 blueprintID,
        address artist,
        uint64 capacity,
        string blueprintMetaData,
        string baseTokenUri
    );
    
    /**
     * @dev Emitted when blueprint sale is started
     * @param blueprintID ID of blueprint
     */
    event SaleStarted(uint256 blueprintID);

    /**
     * @dev Emitted when blueprint sale is paused
     * @param blueprintID ID of blueprint
     */
    event SalePaused(uint256 blueprintID);

    /**
     * @dev Emitted when blueprint sale is unpaused
     * @param blueprintID ID of blueprint
     */
    event SaleUnpaused(uint256 blueprintID);

    /**
     * @dev Emitted when blueprint token uri is updated 
     * @param blueprintID ID of blueprint
     * @param newBaseTokenUri New base uri 
     */
    event BlueprintTokenUriUpdated(uint256 blueprintID, string newBaseTokenUri);

    /**
     * @dev Checks blueprint sale state
     * @param _blueprintID ID of blueprint 
     */
    modifier isBlueprintPrepared(uint256 _blueprintID) {
        require(
            blueprints[_blueprintID].saleState != SaleState.not_prepared,
            "!prepared"
        );
        _;
    }

    /**
     * @dev Checks if blueprint sale is ongoing
     * @param _blueprintID ID of blueprint 
     */
    modifier isSaleOngoing(uint256 _blueprintID) {
        require(_isSaleOngoing(_blueprintID), "!ongoing");
        _;
    }

    /**
     * @dev Checks if quantity of NFTs is available for purchase in blueprint
     * @param _blueprintID ID of blueprint 
     * @param _quantity Quantity of NFTs being checked 
     */ 
    modifier isQuantityAvailableForPurchase(
        uint256 _blueprintID,
        uint32 _quantity
    ) {
        require(
            blueprints[_blueprintID].capacity >= _quantity,
            "quantity >"
        );
        _;
    }

    /**
     * @dev Checks if sale is still valid, given the sale end timestamp 
     * @param _saleEndTimestamp Sale end timestamp 
     */ 
    modifier isSaleEndTimestampCurrentlyValid(
        uint128 _saleEndTimestamp
    ) {
        require(_isSaleEndTimestampCurrentlyValid(_saleEndTimestamp), "ended");
        _;
    }

    /**
     * @dev Initialize the implementation 
     * @param name_ Contract name
     * @param symbol_ Contract symbol
     * @param blueprintV12Admins Administrative accounts  
     * @param splitMain Royalty manager
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        IBlueprintTypes.Admins calldata blueprintV12Admins,
        address splitMain
    ) public initializer {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(name_, symbol_);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, blueprintV12Admins.platform);
        _setupRole(MINTER_ROLE, blueprintV12Admins.minter);

        platform = blueprintV12Admins.platform;
        minterAddress = blueprintV12Admins.minter;

        defaultPlatformPrimaryFeePercentage = 2000; // 20%

        defaultBlueprintSecondarySalePercentage = 750; // 7.5%
        defaultPlatformSecondarySalePercentage = 250; // 2.5%

        asyncSaleFeesRecipient = blueprintV12Admins.asyncSaleFeesRecipient;
        _splitMain = splitMain;
    }

    /**
     * @dev Validates that sale is still ongoing
     * @param _blueprintID Blueprint ID 
     */
    function _isSaleOngoing(uint256 _blueprintID)
        internal
        view
        returns (bool)
    {
        return blueprints[_blueprintID].saleState == SaleState.started && _isSaleEndTimestampCurrentlyValid(blueprints[_blueprintID].saleEndTimestamp);
    }

    /**
     * @dev Checks if user whitelisted for presale purchase 
     * @param _blueprintID ID of blueprint 
     * @param _whitelistedQuantity Purchaser's requested quantity. Validated against merkle tree
     * @param proof Corresponding proof for purchaser in merkle tree 
     */ 
    function _isWhitelistedAndPresale(
        uint256 _blueprintID,
        uint32 _whitelistedQuantity,
        bytes32[] calldata proof
    )
        internal
        view
        returns (bool)
    {
        return (_isBlueprintPreparedAndNotStarted(_blueprintID) && proof.length != 0 && _verify(_leaf(msg.sender, uint256(_whitelistedQuantity)), blueprints[_blueprintID].merkleroot, proof));
    }

    /**
     * @dev Checks if sale is still valid, given the sale end timestamp 
     * @param _saleEndTimestamp Sale end timestamp 
     */  
    function _isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp)
        internal
        view
        returns (bool)
    {
        return _saleEndTimestamp > block.timestamp || _saleEndTimestamp == 0;
    }

    /**
     * @dev Checks that blueprint is prepared but sale for it hasn't started 
     * @param _blueprintID ID of blueprint 
     */
    function _isBlueprintPreparedAndNotStarted(uint256 _blueprintID)
        internal
        view
        returns (bool)
    {
        return blueprints[_blueprintID].saleState == SaleState.not_started;
    }

    /**
     * @dev Checks that the recipients and allocations arrays of royalties are valid  
     * @param _feeRecipients Fee recipients
     * @param _feeBPS Allocations in percentages for fee recipients (basis points)
     */ 
    function feeArrayDataValid(
        address[] memory _feeRecipients,
        uint32[] memory _feeBPS
    ) internal pure returns (bool) {
        require(
            _feeRecipients.length == _feeBPS.length,
            "invalid"
        );
        uint32 totalPercent;
        for (uint256 i; i < _feeBPS.length; i++) {
            totalPercent = totalPercent + _feeBPS[i];
        }
        require(totalPercent <= 10000, "bps >");
        return true;
    }

    /**
     * @dev Sets values after blueprint preparation
     * @param _blueprintID Blueprint ID
     * @param _blueprintMetaData Blueprint metadata uri 
     */
    function setBlueprintPrepared(
        uint256 _blueprintID,
        string memory _blueprintMetaData
    ) internal {
        blueprints[_blueprintID].saleState = SaleState.not_started;
        //assign the erc721 token index to the blueprint
        blueprints[_blueprintID].erc721TokenIndex = latestErc721TokenIndex;
        uint64 _capacity = blueprints[_blueprintID].capacity;
        latestErc721TokenIndex += _capacity;
        blueprintIndex++;

        emit BlueprintPrepared(
            _blueprintID,
            blueprints[_blueprintID].artist,
            _capacity,
            _blueprintMetaData,
            blueprints[_blueprintID].baseTokenUri
        );
    }

    /**
     * @dev Sets the ERC20 token value of a blueprint
     * @param _blueprintID Blueprint ID 
     * @param _erc20Token ERC20 token being set
     */
    function setErc20Token(uint256 _blueprintID, address _erc20Token) internal {
        if (_erc20Token != address(0)) {
            blueprints[_blueprintID].ERC20Token = _erc20Token;
        }
    }

    /**
     * @dev Sets up most blueprint parameters 
     * @param _blueprintID Blueprint ID 
     * @param _erc20Token ERC20 currency 
     * @param _baseTokenUri Base token uri for blueprint
     * @param _merkleroot Root of merkle tree allowlist
     * @param _mintAmountArtist Amount that artist can mint of blueprint
     * @param _mintAmountPlatform Amount that platform can mint of blueprint 
     * @param _maxPurchaseAmount Max amount of NFTs purchasable in one transaction
     * @param _saleEndTimestamp When the sale ends
     */
    function _setupBlueprint(
        uint256 _blueprintID,
        address _erc20Token,
        string memory _baseTokenUri,
        bytes32 _merkleroot,
        uint32 _mintAmountArtist,
        uint32 _mintAmountPlatform,
        uint64 _maxPurchaseAmount,
        uint128 _saleEndTimestamp
    )   internal 
        isSaleEndTimestampCurrentlyValid(_saleEndTimestamp)
    {
        setErc20Token(_blueprintID, _erc20Token);

        blueprints[_blueprintID].baseTokenUri = _baseTokenUri;

        if (_merkleroot != 0) {
            blueprints[_blueprintID].merkleroot = _merkleroot;
        }

        blueprints[_blueprintID].mintAmountArtist = _mintAmountArtist;
        blueprints[_blueprintID].mintAmountPlatform = _mintAmountPlatform;

        if (_maxPurchaseAmount != 0) {
            blueprints[_blueprintID].maxPurchaseAmount = _maxPurchaseAmount;
        }
        
        if (_saleEndTimestamp != 0) {
            blueprints[_blueprintID].saleEndTimestamp = _saleEndTimestamp;
        }
    }

    
    /** 
     * @dev Prepare the blueprint (this is the core operation to set up a blueprint)
     * @param _artist Artist address
     * @param config Object containing values required to prepare blueprint
     * @param feesInput Initial primary and secondary fees config
     */ 
    function prepareBlueprint(
        address _artist,
        IBlueprintTypes.BlueprintPreparationConfig calldata config,
        FeesInput calldata feesInput
    )   external 
        onlyRole(MINTER_ROLE)
    {
        uint256 _blueprintID = blueprintIndex;
        blueprints[_blueprintID].artist = _artist;
        blueprints[_blueprintID].capacity = config._capacity;
        blueprints[_blueprintID].price = config._price;

        _setupBlueprint(
            _blueprintID,
            config._erc20Token,
            config._baseTokenUri,
            config._merkleroot,
            config._mintAmountArtist,
            config._mintAmountPlatform,
            config._maxPurchaseAmount,
            config._saleEndTimestamp
        ); 

        setBlueprintPrepared(_blueprintID, config._blueprintMetaData);
        setFeeRecipients(_blueprintID, feesInput);
    }

    /**
     * @dev Update a blueprint's artist
     * @param _blueprintID Blueprint ID 
     * @param _newArtist New artist
     */
    function updateBlueprintArtist (
        uint256 _blueprintID,
        address _newArtist
    ) external onlyRole(MINTER_ROLE) {
        blueprints[_blueprintID].artist = _newArtist;
    }

    /**
     * @dev Update a blueprint's capacity
     * @param _blueprintID Blueprint ID 
     * @param _newCapacity New capacity
     * @param _newLatestErc721TokenIndex Newly adjusted last ERC721 token id 
     */
    function updateBlueprintCapacity (
        uint256 _blueprintID,
        uint64 _newCapacity,
        uint64 _newLatestErc721TokenIndex
    ) external onlyRole(MINTER_ROLE) {
        require(blueprints[_blueprintID].capacity > _newCapacity, "cap >");

        blueprints[_blueprintID].capacity = _newCapacity;

        latestErc721TokenIndex = _newLatestErc721TokenIndex;
    }

    /**
     * @dev Set the primary and secondary fees config of a blueprint
     * @param _blueprintID Blueprint ID
     * @param _feesInput Fees config 
     */
    function setFeeRecipients(
        uint256 _blueprintID,
        FeesInput memory _feesInput
    ) public onlyRole(MINTER_ROLE) {
        require(
            blueprints[_blueprintID].saleState != SaleState.not_prepared,
            "!prepared"
        );
        require(
            feeArrayDataValid(_feesInput.primaryFeeRecipients, _feesInput.primaryFeeBPS),
            "primary"
        ); 

        SecondaryFeesInput memory secondaryFeesInput = _feesInput.secondaryFeesInput;

        Fees memory feeRecipientInfo = Fees(
            _feesInput.primaryFeeRecipients,
            _feesInput.primaryFeeBPS,
            secondaryFeesInput.royaltyRecipient, 
            secondaryFeesInput.totalRoyaltyCutBPS
        );

        // if pre-existing split isn't passed in, deploy it and set it. 
        if (_feesInput.deploySplit) {
            feeRecipientInfo.royaltyRecipient = ISplitMain(_splitMain).createSplit(
                secondaryFeesInput.secondaryFeeRecipients, 
                secondaryFeesInput.secondaryFeeMPS, 
                0, 
                address(0) // immutable split
            );
        } 
        
        blueprints[_blueprintID].feeRecipientInfo = feeRecipientInfo;
    }

    /**
     * @dev Begin a blueprint's sale
     * @param blueprintID Blueprint ID 
     */
    function beginSale(uint256 blueprintID)
        external
        onlyRole(MINTER_ROLE)
        isSaleEndTimestampCurrentlyValid(blueprints[blueprintID].saleEndTimestamp) 
    {
        require(
            blueprints[blueprintID].saleState == SaleState.not_started,
            "started"
        );
        blueprints[blueprintID].saleState = SaleState.started;
        emit SaleStarted(blueprintID);
    }

    /**
     * @dev Pause a blueprint's sale
     * @param blueprintID Blueprint ID 
     */
    function pauseSale(uint256 blueprintID)
        external
        onlyRole(MINTER_ROLE)
        isSaleOngoing(blueprintID)
    {
        blueprints[blueprintID].saleState = SaleState.paused;
        emit SalePaused(blueprintID);
    }

    /**
     * @dev Unpause a blueprint's sale
     * @param blueprintID Blueprint ID 
     */
    function unpauseSale(uint256 blueprintID) external onlyRole(MINTER_ROLE) isSaleEndTimestampCurrentlyValid(blueprints[blueprintID].saleEndTimestamp) {
        require(
            blueprints[blueprintID].saleState == SaleState.paused,
            "!paused"
        );
        blueprints[blueprintID].saleState = SaleState.started;
        emit SaleUnpaused(blueprintID);
    }

    /**
     * @dev Update a blueprint's merkle tree root 
     * @param blueprintID Blueprint ID 
     * @param oldProof Old proof for leaf being updated, used for validation 
     * @param remainingWhitelistAmount Remaining whitelist amount of NFTs 
     */
    function _updateMerkleRootForPurchase(
        uint256 blueprintID,
        bytes32[] memory oldProof,
        uint32 remainingWhitelistAmount
    ) 
        internal
    {
        bool[] memory proofFlags = new bool[](oldProof.length);
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _leaf(msg.sender, uint256(remainingWhitelistAmount));
        blueprints[blueprintID].merkleroot = MerkleProof.processMultiProof(oldProof, proofFlags, leaves);
    }

    /**
     * @dev Purchase NFTs of a blueprint to a recipient address
     * @param blueprintID Blueprint ID
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     * @param nftRecipient Recipient of minted NFTs
     */
    function purchaseBlueprintsTo(
        uint256 blueprintID,
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof,
        address nftRecipient
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(blueprintID, purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(blueprintID, whitelistedQuantity, proof)) {
            require(purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            _updateMerkleRootForPurchase(blueprintID, proof, whitelistedQuantity - purchaseQuantity);
        } else {
            require(_isSaleOngoing(blueprintID), "unavailable");
        }

        require(
            blueprints[blueprintID].maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprints[blueprintID].maxPurchaseAmount,
            "> maxPurchaseAmount"
        );

        address artist = blueprints[blueprintID].artist;
        _confirmPaymentAmountAndSettleSale(
            blueprintID,
            purchaseQuantity,
            tokenAmount,
            artist
        );
        _mintQuantity(blueprintID, purchaseQuantity, nftRecipient);
    }

    /**
     * @dev Purchase NFTs of a blueprint to the sender
     * @param blueprintID Blueprint ID
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     */ 
    function purchaseBlueprints(
        uint256 blueprintID,
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(blueprintID, purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(blueprintID, whitelistedQuantity, proof)) {
            require(purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            _updateMerkleRootForPurchase(blueprintID, proof, whitelistedQuantity - purchaseQuantity);
        } else {
            require(_isSaleOngoing(blueprintID), "unavailable");
        }

        require(
            blueprints[blueprintID].maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprints[blueprintID].maxPurchaseAmount,
            "> maxPurchaseAmount"
        );

        address artist = blueprints[blueprintID].artist;
        _confirmPaymentAmountAndSettleSale(
            blueprintID,
            purchaseQuantity,
            tokenAmount,
            artist
        );
        _mintQuantity(blueprintID, purchaseQuantity, msg.sender);
    }

    /**
     * @dev Lets the artist of a blueprint mint NFTs of the blueprint
     * @param blueprintID Blueprint ID
     * @param quantity How many NFTs to mint
     */
    function artistMint(
        uint256 blueprintID,
        uint32 quantity
    )
        external
        nonReentrant 
    {
        require(
            _isBlueprintPreparedAndNotStarted(blueprintID) || _isSaleOngoing(blueprintID),
            "not pre/public sale"
        );
        require(
            minterAddress == msg.sender ||
                blueprints[blueprintID].artist == msg.sender,
            "unauthorized"
        );

        if (minterAddress == msg.sender) {
            require(
                quantity <= blueprints[blueprintID].mintAmountPlatform,
                "quantity >"
            );
            blueprints[blueprintID].mintAmountPlatform -= quantity;
        } else if (blueprints[blueprintID].artist == msg.sender) {
            require(
                quantity <= blueprints[blueprintID].mintAmountArtist,
                "quantity >"
            );
            blueprints[blueprintID].mintAmountArtist -= quantity;
        }
        _mintQuantity(blueprintID, quantity, msg.sender);
    }

    /**
     * @dev Mint a quantity of NFTs of a blueprint to a recipient 
     * @param _blueprintID Blueprint ID
     * @param _quantity Quantity to mint
     * @param _nftRecipient Recipient of minted NFTs
     */
    function _mintQuantity(uint256 _blueprintID, uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprints[_blueprintID].erc721TokenIndex;
        uint64 newCap = blueprints[_blueprintID].capacity;
        for (uint16 i; i < _quantity; i++) {
            require(newCap > 0, "quantity > cap");
            
            _mint(_nftRecipient, newTokenId + i);
            tokenToBlueprintID[newTokenId + i] = _blueprintID;

            bytes32 prefixHash = keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.coinbase,
                    newCap
                )
            );
            emit BlueprintMinted(
                _blueprintID,
                blueprints[_blueprintID].artist,
                _nftRecipient,
                newTokenId + i,
                newCap,
                prefixHash
            );
            --newCap;
        }

        blueprints[_blueprintID].erc721TokenIndex += _quantity;
        blueprints[_blueprintID].capacity = newCap;
    }

    /**
     * @dev Pay for minting NFTs 
     * @param _blueprintID Blueprint ID 
     * @param _quantity Quantity of NFTs to purchase
     * @param _tokenAmount Payment amount provided
     * @param _artist Artist of blueprint
     */
    function _confirmPaymentAmountAndSettleSale(
        uint256 _blueprintID,
        uint32 _quantity,
        uint256 _tokenAmount,
        address _artist
    ) internal {
        address _erc20Token = blueprints[_blueprintID].ERC20Token;
        uint128 _price = blueprints[_blueprintID].price;
        if (_erc20Token == address(0)) {
            require(_tokenAmount == 0, "tokenAmount != 0");
            require(
                msg.value == _quantity * _price,
                "$ != expected"
            );
            _payFeesAndArtist(_blueprintID, _erc20Token, msg.value, _artist);
        } else {
            require(msg.value == 0, "eth value != 0");
            require(
                _tokenAmount == _quantity * _price,
                "$ != expected"
            );

            IERC20(_erc20Token).transferFrom(
                msg.sender,
                address(this),
                _tokenAmount
            );
            _payFeesAndArtist(_blueprintID, _erc20Token, _tokenAmount, _artist);
        }
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * @dev Create a merkle tree with address: quantity pairs as the leaves.
     *      The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     * @param account Minting account being verified
     * @param quantity Quantity to mint, being verified
     */
    function _leaf(address account, uint256 quantity)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, quantity));
    }

    /**
     * @dev Verify a leaf's inclusion in a merkle tree with its root and corresponding proof
     * @param leaf Leaf to verify
     * @param merkleroot Merkle tree's root
     * @param proof Corresponding proof for leaf
     */
    function _verify(
        bytes32 leaf,
        bytes32 merkleroot,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @dev Update blueprint's token uri
     * @param blueprintID Blueprint ID
     * @param newBaseTokenUri New base token uri to update to
     */
    function updateBlueprintTokenUri(
        uint256 blueprintID,
        string memory newBaseTokenUri
    ) external onlyRole(MINTER_ROLE) isBlueprintPrepared(blueprintID) {
        require(
            !blueprints[blueprintID].tokenUriLocked,
            "locked"
        );

        blueprints[blueprintID].baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(blueprintID, newBaseTokenUri);
    }

    /**
     * @dev Lock blueprint's token uri (from changing)
     * @param blueprintID Blueprint ID
     */ 
    function lockBlueprintTokenUri(uint256 blueprintID)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isBlueprintPrepared(blueprintID)
    {
        require(
            !blueprints[blueprintID].tokenUriLocked,
            "locked"
        );

        blueprints[blueprintID].tokenUriLocked = true;
    }

    /**
     * @dev Return token's uri
     * @param tokenId ID of token to return uri for
     * @return Token uri, constructed by taking base uri of blueprint corresponding to token, and concatenating token id
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "token dne"
        );

        string memory baseURI = blueprints[tokenToBlueprintID[tokenId]].baseTokenUri;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        "/",
                        tokenId.toString(),
                        "/",
                        "token.json"
                    )
                )
                : "";
    }

    /**
     * @dev Reveal blueprint's seed by emitting public event 
     * @param blueprintID Blueprint ID
     * @param randomSeed Revealed seed 
     */
    function revealBlueprintSeed(uint256 blueprintID, string memory randomSeed)
        external
        onlyRole(MINTER_ROLE)
        isBlueprintPrepared(blueprintID)
    {
        emit BlueprintSeed(blueprintID, randomSeed);
    }

    /**
     * @dev Set the contract-wide recipient of primary sale feess
     * @param _asyncSaleFeesRecipient New async sale fees recipient 
     */
    function setAsyncFeeRecipient(address _asyncSaleFeesRecipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        asyncSaleFeesRecipient = _asyncSaleFeesRecipient;
    }

    /**
     * @dev Change the default percentage of primary sales sent to platform
     * @param _basisPoints New default platform primary fee percentage (in basis points)
     */    
    function changeDefaultPlatformPrimaryFeePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints <= 10000);
        defaultPlatformPrimaryFeePercentage = _basisPoints;
    }

    /**
     * @dev Change the default secondary sale percentage sent to artist and others 
     * @param _basisPoints New default secondary fee percentage (in basis points)
     */    
    function changeDefaultBlueprintSecondarySalePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_basisPoints + defaultPlatformSecondarySalePercentage <= 10000);
        defaultBlueprintSecondarySalePercentage = _basisPoints;
    }

    /**
     * @dev Change the default secondary sale percentage sent to platform 
     * @param _basisPoints New default secondary fee percentage (in basis points)
     */  
    function changeDefaultPlatformSecondarySalePercentage(uint32 _basisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _basisPoints + defaultBlueprintSecondarySalePercentage <= 10000
        );
        defaultPlatformSecondarySalePercentage = _basisPoints;
    }

    /**
     * @dev Update contract-wide platform address, and DEFAULT_ADMIN role ownership
     * @param _platform New platform address
     */   
    function updatePlatformAddress(address _platform)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @dev Update contract-wide minter address, and MINTER_ROLE role ownership
     * @param newMinterAddress New minter address
     */ 
    function updateMinterAddress(address newMinterAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, newMinterAddress);

        revokeRole(MINTER_ROLE, minterAddress);
        minterAddress = newMinterAddress;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    /**
     * @dev Pay primary fees owed to primary fee recipients
     * @param _blueprintID Blueprint ID 
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     * @param _artist Artist being paid
     */
    function _payFeesAndArtist(
        uint256 _blueprintID,
        address _erc20Token,
        uint256 _amount,
        address _artist
    ) internal {
        address[] memory _primaryFeeRecipients = getPrimaryFeeRecipients(
            _blueprintID
        );
        uint32[] memory _primaryFeeBPS = getPrimaryFeeBps(_blueprintID);
        uint256 feesPaid;

        for (uint256 i; i < _primaryFeeRecipients.length; i++) {
            uint256 fee = (_amount * _primaryFeeBPS[i])/10000;
            feesPaid = feesPaid + fee;
            _payout(_primaryFeeRecipients[i], _erc20Token, fee);
        }
        if (_amount - feesPaid > 0) {
            _payout(_artist, _erc20Token, (_amount - feesPaid));
        }
    }

    /**
     * @dev Simple payment function to pay an amount of currency to a recipient
     * @param _recipient Recipient of payment 
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     */
    function _payout(
        address _recipient,
        address _erc20Token,
        uint256 _amount
    ) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            (bool success, ) = payable(_recipient).call{
                value: _amount,
                gas: 20000
            }("");
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                failedTransferCredits[_recipient] =
                    failedTransferCredits[_recipient] +
                    _amount;
            }
        }
    }

    /**
     * @dev When a native gas token payment fails, credits are stored so that the would-be recipient can withdraw them later.
     *      Withdraw failed credits for a recipient
     * @param recipient Recipient owed some amount of native gas token   
     */
    function withdrawAllFailedCredits(address payable recipient) external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "!credits");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = recipient.call{value: amount, gas: 20000}(
            ""
        );
        require(successfulWithdraw, "failed");
    }

    /**
     * @dev Get primary fee recipients of a blueprint 
     * @param id Blueprint ID
     */
    function getPrimaryFeeRecipients(uint256 id)
        public
        view
        returns (address[] memory)
    {
        if (blueprints[id].feeRecipientInfo.primaryFeeRecipients.length == 0) {
            address[] memory primaryFeeRecipients = new address[](1);
            primaryFeeRecipients[0] = (asyncSaleFeesRecipient);
            return primaryFeeRecipients;
        } else {
            return blueprints[id].feeRecipientInfo.primaryFeeRecipients;
        }
    }

    /**
     * @dev Get primary fee bps (allocations) of a blueprint 
     * @param id Blueprint ID
     */
    function getPrimaryFeeBps(uint256 id)
        public
        view
        returns (uint32[] memory)
    {
        if (blueprints[id].feeRecipientInfo.primaryFeeBPS.length == 0) {
            uint32[] memory primaryFeeBPS = new uint32[](1);
            primaryFeeBPS[0] = defaultPlatformPrimaryFeePercentage;

            return primaryFeeBPS;
        } else {
            return blueprints[id].feeRecipientInfo.primaryFeeBPS;
        }
    }

    /**
     * @dev Get secondary fee recipients of a token 
     * @param tokenId Token ID
     */
    function getFeeRecipients(uint256 tokenId)
        public
        view
        override
        returns (address[] memory)
    {
        address[] memory feeRecipients = new address[](1);
        feeRecipients[0] = blueprints[tokenToBlueprintID[tokenId]].feeRecipientInfo.royaltyRecipient;
        return feeRecipients;
    }

    /**
     * @dev Get secondary fee bps (allocations) of a token 
     * @param tokenId Token ID
     */
    function getFeeBps(uint256 tokenId)
        public
        view
        override
        returns (uint32[] memory)
    {
        uint32[] memory feeBPS  = new uint32[](1);
        feeBPS[0] = blueprints[tokenToBlueprintID[tokenId]].feeRecipientInfo.totalRoyaltyCutBPS;
        return feeBPS; 
    }

    ////////////////////////////////////
    /// Required function overide //////
    ////////////////////////////////////

    /**
     * @dev Override isApprovedForAll to also let the DEFAULT_ADMIN_ROLE move tokens
     * @param account Account holding tokens being moved
     * @param operator Operator moving tokens
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(account, operator) ||
            hasRole(DEFAULT_ADMIN_ROLE, operator);
    }

    /**
     * @dev ERC165 - Validate that the contract supports a interface
     * @param interfaceId ID of interface being validated 
     * @return Returns true if contract supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC165StorageUpgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(HasSecondarySaleFees).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }
}