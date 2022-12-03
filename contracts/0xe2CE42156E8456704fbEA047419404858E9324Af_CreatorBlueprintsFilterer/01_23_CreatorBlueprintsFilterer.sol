//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "../../abstract/HasSecondarySaleFees.sol";
import "../../common/IBlueprintTypes.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IOperatorFilterRegistry} from "../OperatorFilterer/operatorFilterRegistry/IOperatorFilterRegistry.sol";

/**
 * @dev Async Art Blueprint NFT contract with true creator provenance
 * @author Async Art, Ohimire Labs 
 */
contract CreatorBlueprintsFilterer is
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
     * @dev First token ID of the next Blueprint to be prepared
     */ 
    uint64 public latestErc721TokenIndex;

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
     * @dev Blueprint artist 
     */
    address public artist;
    
    /**
     * @dev Tracks failed transfers of native gas token 
     */
    mapping(address => uint256) failedTransferCredits;

    /**
     * @dev Blueprint, core object of contract
     */
    Blueprints public blueprint;

    /**
     * @dev Royalty config 
     */
    RoyaltyParameters public royaltyParameters;

    /**
     * @dev Contract-level metadata 
     */
    string public contractURI; 

    /**
     * @dev Holders of this role are given minter privileges 
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /*  
     * @dev A mapping from whitelisted addresses to amout of pre-sale blueprints purchased
     * @dev This is seperate from the Blueprint struct because it was introduced as part of an upgrade, and needs to be placed at the end of storage to avoid overwriting.
     */
     mapping(address => uint32) whitelistedPurchases;
    
    /**
     * @dev A registry to check for blacklisted operator addresses. Used to only permit marketplaces enforcing creator royalites if desired
     */
    IOperatorFilterRegistry public operatorFilterRegistry;

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
     * @dev Object holding royalty data
     * @param split Royalty splitter receiving royalties
     * @param royaltyCutBPS Total percentage of token sales sent to split, in basis points 
     */
    struct RoyaltyParameters {
        address split;
        uint32 royaltyCutBPS;
    }

    /**
     * @dev Blueprint
     * @param mintAmountArtist Amount of NFTs of Blueprint mintable by artist
     * @param mintAmountPlatform Amount of NFTs of Blueprint mintable by platform 
     * @param capacity Number of NFTs in Blueprint 
     * @param erc721TokenIndex First token ID of the next Blueprint to be prepared
     * @param maxPurchaseAmount Max number of NFTs purchasable in a single transaction
     * @param saleEndTimestamp Timestamp when the sale ends 
     * @param price Price per NFT in Blueprint
     * @param tokenUriLocked If the token metadata isn't updatable 
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
        address ERC20Token;
        string baseTokenUri;
        bytes32 merkleroot;
        SaleState saleState;    
        IBlueprintTypes.PrimaryFees feeRecipientInfo;
    }

    /**
     * @dev Creator config of contract
     * @param name Contract name
     * @param symbol Contract symbol
     * @param contractURI Contract-level metadata 
     * @param artist Blueprint artist
     */
    struct CreatorBlueprintsInput {
        string name;
        string symbol;
        string contractURI;
        address artist;
    }

    /**
     * @dev Emitted when blueprint seed is revealed
     * @param randomSeed Revealed seed
     */
    event BlueprintSeed(string randomSeed);

    /**
     * @dev Emitted when NFTs of blueprint are minted
     * @param artist Blueprint artist
     * @param purchaser Purchaser of NFTs
     * @param tokenId NFT minted
     * @param newCapacity New capacity of tokens left in blueprint 
     * @param seedPrefix Seed prefix hash
     */
    event BlueprintMinted(
        address artist,
        address purchaser,
        uint128 tokenId,
        uint64 newCapacity,
        bytes32 seedPrefix
    );

    /**
     * @dev Emitted when blueprint is prepared
     * @param artist Blueprint artist
     * @param capacity Number of NFTs in blueprint
     * @param blueprintMetaData Blueprint metadata uri
     * @param baseTokenUri Blueprint's base token uri. Token uris are a result of the base uri concatenated with token id 
     */ 
    event BlueprintPrepared(
        address artist,
        uint64 capacity,
        string blueprintMetaData,
        string baseTokenUri
    );

    /**
     * @dev Emitted when blueprint sale is started
     */
    event SaleStarted();

    /**
     * @dev Emitted when blueprint sale is paused
     */
    event SalePaused();

    /**
     * @dev Emitted when blueprint sale is unpaused
     */
    event SaleUnpaused();

    /**
     * @dev Emitted when blueprint token uri is updated 
     * @param newBaseTokenUri New base uri 
     */
    event BlueprintTokenUriUpdated(string newBaseTokenUri);

    /**
     * @dev Checks blueprint sale state
     */
    modifier isBlueprintPrepared() {
        require(
            blueprint.saleState != SaleState.not_prepared,
            "!prepared"
        );
        _;
    }

    /**
     * @dev Checks if blueprint sale is ongoing
     */
    modifier isSaleOngoing() {
        require(_isSaleOngoing(), "!ongoing");
        _;
    }

    /**
     * @dev Checks if quantity of NFTs is available for purchase in blueprint
     * @param _quantity Quantity of NFTs being checked 
     */ 
    modifier isQuantityAvailableForPurchase(
        uint32 _quantity
    ) {
        require(
            blueprint.capacity >= _quantity,
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
     * @dev Validates royalty parameters. Allow null-equivalent values for certain use-cases
     * @param _royaltyParameters Royalty parameters 
     */
    modifier validRoyaltyParameters(
        RoyaltyParameters calldata _royaltyParameters
    ) {
        require(_royaltyParameters.royaltyCutBPS <= 10000);
        _;
    }

    /**
     * @dev Iniitalize the implementation 
     * @param creatorBlueprintsInput Core parameters for contract initialization 
     * @param creatorBlueprintsAdmins Administrative accounts 
     * @param _royaltyParameters Initial royalty settings 
     * @param extraMinter Additional address to give minter role
     */
    function initialize(
        CreatorBlueprintsInput calldata creatorBlueprintsInput,
        IBlueprintTypes.Admins calldata creatorBlueprintsAdmins,
        RoyaltyParameters calldata _royaltyParameters,
        address extraMinter
    ) public initializer validRoyaltyParameters(_royaltyParameters) {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(creatorBlueprintsInput.name, creatorBlueprintsInput.symbol);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, creatorBlueprintsAdmins.platform);
        _setupRole(MINTER_ROLE, creatorBlueprintsAdmins.minter);
        if (extraMinter != address(0)) {
            _setupRole(MINTER_ROLE, extraMinter);
        }

        platform = creatorBlueprintsAdmins.platform;
        minterAddress = creatorBlueprintsAdmins.minter;
        artist = creatorBlueprintsInput.artist;

        defaultPlatformPrimaryFeePercentage = 2000; // 20%

        asyncSaleFeesRecipient = creatorBlueprintsAdmins.asyncSaleFeesRecipient;
        contractURI = creatorBlueprintsInput.contractURI; 
        royaltyParameters = _royaltyParameters;

        operatorFilterRegistry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
        operatorFilterRegistry.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    }

    /**
     * @dev Validates that sale is still ongoing
     */
    function _isSaleOngoing()
        internal
        view
        returns (bool)
    {
        return blueprint.saleState == SaleState.started && _isSaleEndTimestampCurrentlyValid(blueprint.saleEndTimestamp);
    }

    /**
     * @dev Checks if user whitelisted for presale purchase
     * @param _whitelistedQuantity Purchaser's requested quantity. Validated against merkle tree
     * @param proof Corresponding proof for purchaser in merkle tree 
     */ 
    function _isWhitelistedAndPresale(
        uint32 _whitelistedQuantity,
        bytes32[] calldata proof
    )
        internal
        view
        returns (bool)
    {
        return (_isBlueprintPreparedAndNotStarted() && proof.length != 0 && _verify(_leaf(msg.sender, uint256(_whitelistedQuantity)), blueprint.merkleroot, proof));
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
     */
    function _isBlueprintPreparedAndNotStarted()
        internal
        view
        returns (bool)
    {
        return blueprint.saleState == SaleState.not_started;
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
     * @param _blueprintMetaData Blueprint metadata uri 
     */
    function setBlueprintPrepared(
        string memory _blueprintMetaData
    ) internal {
        blueprint.saleState = SaleState.not_started;
        //assign the erc721 token index to the blueprint
        blueprint.erc721TokenIndex = latestErc721TokenIndex;
        uint64 _capacity = blueprint.capacity;
        latestErc721TokenIndex += _capacity;

        emit BlueprintPrepared(
            artist,
            _capacity,
            _blueprintMetaData,
            blueprint.baseTokenUri
        );
    }

    /**
     * @dev Sets the ERC20 token value of a blueprint
     * @param _erc20Token ERC20 token being set
     */ 
    function setErc20Token(address _erc20Token) internal {
        if (_erc20Token != address(0)) {
            blueprint.ERC20Token = _erc20Token;
        }
    }

    /**
     * @dev Sets up most blueprint parameters 
     * @param _erc20Token ERC20 currency 
     * @param _baseTokenUri Base token uri for blueprint
     * @param _merkleroot Root of merkle tree allowlist
     * @param _mintAmountArtist Amount that artist can mint of blueprint
     * @param _mintAmountPlatform Amount that platform can mint of blueprint 
     * @param _maxPurchaseAmount Max amount of NFTs purchasable in one transaction
     * @param _saleEndTimestamp When the sale ends
     */
    function _setupBlueprint(
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
        setErc20Token(_erc20Token);

        blueprint.baseTokenUri = _baseTokenUri;

        if (_merkleroot != 0) {
            blueprint.merkleroot = _merkleroot;
        }

        blueprint.mintAmountArtist = _mintAmountArtist;
        blueprint.mintAmountPlatform = _mintAmountPlatform;

        if (_maxPurchaseAmount != 0) {
            blueprint.maxPurchaseAmount = _maxPurchaseAmount;
        }
        
        if (_saleEndTimestamp != 0) {
            blueprint.saleEndTimestamp = _saleEndTimestamp;
        }
    }

    /** 
     * @dev Prepare the blueprint (this is the core operation to set up a blueprint)
     * @param config Object containing values required to prepare blueprint
     * @param _feeRecipientInfo Primary and secondary fees config
     */  
    function prepareBlueprint(
        IBlueprintTypes.BlueprintPreparationConfig calldata config,
        IBlueprintTypes.PrimaryFees calldata _feeRecipientInfo
    )   external 
        onlyRole(MINTER_ROLE)
    {
        require(blueprint.saleState == SaleState.not_prepared, "already prepared");
        blueprint.capacity = config._capacity;
        blueprint.price = config._price;

        _setupBlueprint(
            config._erc20Token,
            config._baseTokenUri,
            config._merkleroot,
            config._mintAmountArtist,
            config._mintAmountPlatform,
            config._maxPurchaseAmount,
            config._saleEndTimestamp
        );

        setBlueprintPrepared(config._blueprintMetaData);
        setFeeRecipients(_feeRecipientInfo);
    }

    /**
     * @dev Update a blueprint's artist
     * @param _newArtist New artist
     */
    function updateBlueprintArtist (
        address _newArtist
    ) external onlyRole(MINTER_ROLE) {
        artist = _newArtist;
    }

    /**
     * @dev Update a blueprint's merkleroot
     * @param _newMerkleroot New merkleroot
     */
    function updateBlueprintMerkleroot (
        bytes32 _newMerkleroot
    ) external onlyRole(MINTER_ROLE) {
        blueprint.merkleroot = _newMerkleroot;
    }

    /**
     * @dev Update a blueprint's capacity 
     * @param _newCapacity New capacity
     * @param _newLatestErc721TokenIndex Newly adjusted last ERC721 token id 
     */
    function updateBlueprintCapacity (
        uint64 _newCapacity,
        uint64 _newLatestErc721TokenIndex
    ) external onlyRole(MINTER_ROLE) {
        require(blueprint.capacity > _newCapacity, "New cap too large");

        blueprint.capacity = _newCapacity;

        latestErc721TokenIndex = _newLatestErc721TokenIndex;
    }

    /**
     * @dev Set the primary fees config of blueprint
     * @param _feeRecipientInfo Fees config 
     */
    function setFeeRecipients(
        IBlueprintTypes.PrimaryFees memory _feeRecipientInfo
    ) public onlyRole(MINTER_ROLE) {
        require(
            blueprint.saleState != SaleState.not_prepared,
            "never prepared"
        );
        if (feeArrayDataValid(_feeRecipientInfo.primaryFeeRecipients, _feeRecipientInfo.primaryFeeBPS)) {
            blueprint.feeRecipientInfo = _feeRecipientInfo;
        }
    }

    /**
     * @dev Begin blueprint's sale
     */
    function beginSale()
        external
        onlyRole(MINTER_ROLE)
        isSaleEndTimestampCurrentlyValid(blueprint.saleEndTimestamp) 
    {
        require(
            blueprint.saleState == SaleState.not_started,
            "sale started or not prepared"
        );
        blueprint.saleState = SaleState.started;
        emit SaleStarted();
    }

    /**
     * @dev Pause blueprint's sale
     */
    function pauseSale()
        external
        onlyRole(MINTER_ROLE)
        isSaleOngoing()
    {
        blueprint.saleState = SaleState.paused;
        emit SalePaused();
    }

    /**
     * @dev Unpause blueprint's sale
     */
    function unpauseSale() external onlyRole(MINTER_ROLE) isSaleEndTimestampCurrentlyValid(blueprint.saleEndTimestamp) {
        require(
            blueprint.saleState == SaleState.paused,
            "!paused"
        );
        blueprint.saleState = SaleState.started;
        emit SaleUnpaused();
    }

    /**
     * @dev Purchase NFTs of blueprint to a recipient address
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     * @param nftRecipient Recipient of minted NFTs
     */
    function purchaseBlueprintsTo(
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof,
        address nftRecipient
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(whitelistedQuantity, proof)) {
            require(whitelistedPurchases[msg.sender] + purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            whitelistedPurchases[msg.sender] += purchaseQuantity;
        } else {
            require(_isSaleOngoing(), "unavailable");
        }

        require(
            blueprint.maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprint.maxPurchaseAmount,
            "cannot buy > maxPurchaseAmount in one tx"
        );

        _confirmPaymentAmountAndSettleSale(
            purchaseQuantity,
            tokenAmount,
            artist
        );
        _mintQuantity(purchaseQuantity, nftRecipient);
    }

    /**
     * @dev Purchase NFTs of blueprint to the sender
     * @param purchaseQuantity How many NFTs to purchase 
     * @param whitelistedQuantity How many NFTS are whitelisted for the blueprint 
     * @param tokenAmount Payment amount 
     * @param proof Merkle tree proof 
     */ 
    function purchaseBlueprints(
        uint32 purchaseQuantity,
        uint32 whitelistedQuantity,
        uint256 tokenAmount,
        bytes32[] calldata proof
    )
        external
        payable
        nonReentrant
        isQuantityAvailableForPurchase(purchaseQuantity)
    {
        if (_isWhitelistedAndPresale(whitelistedQuantity, proof)) {
            require(whitelistedPurchases[msg.sender] + purchaseQuantity <= whitelistedQuantity, "> whitelisted amount");
            whitelistedPurchases[msg.sender] += purchaseQuantity;
        } else {
            require(_isSaleOngoing(), "unavailable");
        }

        require(
            blueprint.maxPurchaseAmount == 0 ||
                purchaseQuantity <= blueprint.maxPurchaseAmount,
            "cannot buy > maxPurchaseAmount in one tx"
        );

        _confirmPaymentAmountAndSettleSale(
            purchaseQuantity,
            tokenAmount,
            artist
        );

        _mintQuantity(purchaseQuantity, msg.sender);
    }

    /**
     * @dev Lets the artist mint NFTs of the blueprint
     * @param quantity How many NFTs to mint
     */
    function artistMint(
        uint32 quantity
    )
        external
        nonReentrant 
    {
        address _artist = artist; // cache
        require(
            _isBlueprintPreparedAndNotStarted() || _isSaleOngoing(),
            "not pre/public sale"
        );
        require(
            minterAddress == msg.sender ||
                _artist == msg.sender,
            "unauthorized"
        );

        if (minterAddress == msg.sender) {
            require(
                quantity <= blueprint.mintAmountPlatform,
                "quantity >"
            );
            blueprint.mintAmountPlatform -= quantity;
        } else if (_artist == msg.sender) {
            require(
                quantity <= blueprint.mintAmountArtist,
                "quantity >"
            );
            blueprint.mintAmountArtist -= quantity;
        }
        _mintQuantity(quantity, msg.sender);
    }

    /**
     * @dev Mint a quantity of NFTs of blueprint to a recipient 
     * @param _quantity Quantity to mint
     * @param _nftRecipient Recipient of minted NFTs
     */
    function _mintQuantity(uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprint.erc721TokenIndex;
        uint64 newCap = blueprint.capacity;
        for (uint16 i; i < _quantity; i++) {
            require(newCap > 0, "quantity > cap");
            
            _mint(_nftRecipient, newTokenId + i);

            bytes32 prefixHash = keccak256(
                abi.encodePacked(
                    block.number,
                    block.timestamp,
                    block.coinbase,
                    newCap
                )
            );
            emit BlueprintMinted(
                artist,
                _nftRecipient,
                newTokenId + i,
                newCap,
                prefixHash
            );
            --newCap;
        }

        blueprint.erc721TokenIndex += _quantity;
        blueprint.capacity = newCap;
    }

    /**
     * @dev Pay for minting NFTs 
     * @param _quantity Quantity of NFTs to purchase
     * @param _tokenAmount Payment amount provided
     * @param _artist Artist of blueprint
     */
    function _confirmPaymentAmountAndSettleSale(
        uint32 _quantity,
        uint256 _tokenAmount,
        address _artist
    ) internal {
        address _erc20Token = blueprint.ERC20Token;
        uint128 _price = blueprint.price;
        if (_erc20Token == address(0)) {
            require(_tokenAmount == 0, "tokenAmount != 0");
            require(
                msg.value == _quantity * _price,
                "$ != expected"
            );
            _payFeesAndArtist(_erc20Token, msg.value, _artist);
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
            _payFeesAndArtist(_erc20Token, _tokenAmount, _artist);
        }
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * Create a merkle tree with address: quantity pairs as the leaves.
     * The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     */

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
     * @param newBaseTokenUri New base token uri to update to
     */ 
    function updateBlueprintTokenUri(
        string memory newBaseTokenUri
    ) external onlyRole(MINTER_ROLE) isBlueprintPrepared() {
        require(
            !blueprint.tokenUriLocked,
            "URI locked"
        );

        blueprint.baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(newBaseTokenUri);
    }

    /**
     * @dev Lock blueprint's token uri (from changing)
     */  
    function lockBlueprintTokenUri()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isBlueprintPrepared()
    {
        require(
            !blueprint.tokenUriLocked,
            "URI locked"
        );

        blueprint.tokenUriLocked = true;
    }

    /**
     * @dev Return token's uri
     * @param tokenId ID of token to return uri for
     * @return Token uri, constructed by taking base uri of blueprint, and concatenating token id
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
            "URI query for nonexistent token"
        );

        string memory baseURI = blueprint.baseTokenUri;
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
     * @param randomSeed Revealed seed 
     */
    function revealBlueprintSeed(string memory randomSeed)
        external
        onlyRole(MINTER_ROLE)
        isBlueprintPrepared()
    {
        emit BlueprintSeed(randomSeed);
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
     * @dev Update royalty config
     * @param _royaltyParameters New royalty parameters
     */  
    function updateRoyaltyParameters(RoyaltyParameters calldata _royaltyParameters) 
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        validRoyaltyParameters(_royaltyParameters)
    {
        royaltyParameters = _royaltyParameters; 
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
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount 
     * @param _artist Artist being paid
     */
    function _payFeesAndArtist(
        address _erc20Token,
        uint256 _amount,
        address _artist
    ) internal {
        address[] memory _primaryFeeRecipients = getPrimaryFeeRecipients();
        uint32[] memory _primaryFeeBPS = getPrimaryFeeBps();
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

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        (bool successfulWithdraw, ) = recipient.call{value: amount, gas: 20000}(
            ""
        );
        require(successfulWithdraw, "withdraw failed");
    }

    /**
     * @dev Get primary fee recipients of blueprint 
     */ 
    function getPrimaryFeeRecipients()
        public
        view
        returns (address[] memory)
    {
        if (blueprint.feeRecipientInfo.primaryFeeRecipients.length == 0) {
            address[] memory primaryFeeRecipients = new address[](1);
            primaryFeeRecipients[0] = (asyncSaleFeesRecipient);
            return primaryFeeRecipients;
        } else {
            return blueprint.feeRecipientInfo.primaryFeeRecipients;
        }
    }

    /**
     * @dev Get primary fee bps (allocations) of blueprint 
     */
    function getPrimaryFeeBps()
        public
        view
        returns (uint32[] memory)
    {
        if (blueprint.feeRecipientInfo.primaryFeeBPS.length == 0) {
            uint32[] memory primaryFeeBPS = new uint32[](1);
            primaryFeeBPS[0] = defaultPlatformPrimaryFeePercentage;

            return primaryFeeBPS;
        } else {
            return blueprint.feeRecipientInfo.primaryFeeBPS;
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
        feeRecipients[0] = royaltyParameters.split;
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
        uint32[] memory feeBps = new uint32[](1);
        feeBps[0] = royaltyParameters.royaltyCutBPS;
        return feeBps;
    }

    /**
     * @dev Support ERC-2981
     * @param _tokenId ID of token to return royalty for
     * @param _salePrice Price that NFT was sold at
     * @return receiver Royalty split
     * @return royaltyAmount Amount to send to royalty split
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        receiver = royaltyParameters.split;
        royaltyAmount = _salePrice * royaltyParameters.royaltyCutBPS / 10000;
    }

    /**
     * @dev Used for interoperability purposes
     * @return Returns platform address as owner of contract 
     */
    function owner() public view virtual returns (address) {
        return platform;
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

    /////////////////////////////////////////////////
    /// Required for OpenSea Operator Registry //////
    /////////////////////////////////////////////////

    // Custom Error Type For Operator Registry Methods
    error OperatorNotAllowed(address operator);

    /**
     * @dev Restrict operators who are allowed to transfer these tokens
     */
    modifier onlyAllowedOperator(address from) {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev Restrict operators who are allowed to approve transfer delegates
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Register this contract with the OpenSea operator registry. Subscribe to OpenSea's operator blacklist.
     */
    function registerWithOpenSeaOperatorRegistry() public {
        require(
            owner() == msg.sender || artist == msg.sender,
            "unauthorized"
        );
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        require(address(registry) != address(0), "attempt register to zero addr");
        registry.registerAndSubscribe(address(this), 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public {
        require(
            owner() == msg.sender || artist == msg.sender,
            "unauthorized"
        );
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. Also register this contract with that registry.
     */
    function updateOperatorFilterAndRegister(address newRegistry) public {
        updateOperatorFilterRegistryAddress(newRegistry);
        registerWithOpenSeaOperatorRegistry();
    }

    /**
     * @dev Check if operator can perform an action
     */
    function _checkFilterOperator(address operator) internal view {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    // Override 721 Methods to restrict non-royalty enforcing operators
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}