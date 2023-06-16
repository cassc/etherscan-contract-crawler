// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "./interfaces/IPRTCLCollections721V1.sol";
import "./interfaces/IRandomizerV1.sol";
import "./governance/PRTCLCoreERC721Votes.sol";

/// @title Core ERC721 contract for multiple collections
/// @author Particle Collection - valdi.eth
/// @notice Manages all collections tokens and voting rights
/// @dev Exposes all public functions and events needed by the Particle Collection's smart contract suite version 1
/// @dev Adheres to the ERC721 standard, ERC721MultiCollection extension and Manifold for secondary royalties
/// @dev Integrates with the OpenSea's Operator Filter Registry to allow for filtering of token transfers: https://github.com/ProjectOpenSea/operator-filter-registry
/// @dev Based on Artblock's GenArt721CoreV3 contract design: https://github.com/ArtBlocks/artblocks-contracts/blob/main/contracts/GenArt721CoreV3.sol
/// Modifications to the original design:
/// - AccessControl extension from OZ
/// - Voting power extension modified from OZ's Votes contract
/// - MultiCollection support
/// - Collection state management modified to accomodate sales
/// - Added coordinate system by modyifing the Randomization design
/// - Added per collection, multi token burning
/// @dev The PRTCLCollections721V1 contract contains the following privileged access for the following functions:
/// - The MINTER_ROLE can mint a new token for any collection using mint().
/// - The GOVERNOR_ROLE can mark a collection as sold using markCollectionSold().
/// - The GOVERNOR_ROLE can burn all tokens of any owner for a specific collectionId using burn().
/// - The DEFAULT_ADMIN_ROLE can update the base URI using updateBaseURI().
/// - The DEFAULT_ADMIN_ROLE can disable new collections from being added using forbidNewCollections().
/// - The DEFAULT_ADMIN_ROLE can add a new collection using addCollection().
/// - The DEFAULT_ADMIN_ROLE can change whether a collection is active using toggleCollectionIsActive().
/// - The DEFAULT_ADMIN_ROLE can update the collection data using updateCollectionData().
/// - The DEFAULT_ADMIN_ROLE can update the collection financials using updateCollectionRoyalties(), updateCollectionPrimarySplit(), or updateRoyaltiesAddresses().
/// - The DEFAULT_ADMIN_ROLE can request collection seed after the time criteria have passed using requestCollectionSeeds().
/// - The DEFAULT_ADMIN_ROLE can update the randomizer contract using updateRandomizer().
/// - The DEFAULT_ADMIN_ROLE can mint a new token for any collection using mint() regardless of the collection status as long as the particle does not exceed the maximum.
/// - The DEFAULT_ADMIN_ROLE can update the operator filter registry admin using updateOperatorFilterRegistryAdmin().
/// @custom:security-contact [email protected]
contract PRTCLCollections721V1 is
    AccessControl,
    EIP712,
    PRTCLCoreERC721Votes,
    IPRTCLCollections721V1,
    RevokableDefaultOperatorFilterer,
    ReentrancyGuard
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    uint256 constant MAX_BPS = 10000; // 10_000 BPS = 100%

    uint256 constant DEFAULT_ARTIST_ROYALTY_BPS = 500; // 5%
    uint256 constant DEFAULT_FJM_ROYALTY_BPS = 250; // 2,5%
    uint256 constant DEFAULT_DAO_ROYALTY_BPS = 250; // 2,5%

    uint256 constant DEFAULT_ARTIST_PRIMARY_BPS = 0; // 0%
    uint256 constant DEFAULT_FJM_PRIMARY_BPS = 10000; // 10_000 BPS = 100%
    uint256 constant DEFAULT_DAO_PRIMARY_BPS = 0; // 0%

    /// 4JM wallet address
    address payable public FJMAddress;
    /// Particle Collection DAO wallet address
    address payable public DAOAddress;
    /// Current randomizer contract
    IRandomizerV1 public randomizerContract;

    string public baseURI;

    struct Collection {
        // Number of particles in the collection
        uint24 nParticles;
        // Max number of particles in the collection
        uint24 maxParticles;
        bool active;
        // The original artwork has been sold through an accepted bid by the collection owners
        // Only editable by the governor contract, thus by a governance vote
        bool sold;
        string name;
        // Seeds to randomize token coordinates. Seeds are set after minting,
        // potentially altering the coordinate assignment of all tokens.
        // Only Randomizer contract can assign seeds.
        // E.g. Token id 1 could map to coordinate 4321
        uint24[] seeds;
        // Timestamp after which setting seeds (and thus revealing metadata) is allowed.
        // Block number, set to 256 blocks after last particle mint, to prevent speculation when setting seeds (look-ahead period of 8 epochs)
        uint256 setSeedsAfterBlock;
    }

    mapping(uint256 => Collection) collections;

    /// struct containing collection financial information
    struct CollectionFinance {
        address payable artistAddress;
        uint256 artistRoyaltyBPS;
        uint256 FJMRoyaltyBPS;
        uint256 DAORoyaltyBPS;
        uint256 artistPrimaryBPS;
        uint256 FJMPrimaryBPS;
        uint256 DAOPrimaryBPS;
    }

    // Collection financials mapping
    mapping(uint256 => CollectionFinance) collectionIdToFinancials;

    // Address that can modify the operator filter registry
    address public operatorFilterRegistryAdmin;

    modifier onlyNonZeroAddress(address _address) {
        require(_address != address(0), "Must input non-zero address");
        _;
    }

    modifier onlyNonEmptyString(string memory _string) {
        require(bytes(_string).length != 0, "Must input non-empty string");
        _;
    }

    constructor(
        string memory _bURI,
        address _delegationSigner,
        address payable _FJMAddress,
        address payable _DAOAddress
    )   onlyNonEmptyString(_bURI)
        onlyNonZeroAddress(_delegationSigner)
        ERC721MultiCollection(1_000_000)
        ERC721("Particle", "PRTCL")
        EIP712("Particle", "1")
        PRTCLCoreERC721Votes(_delegationSigner)
        ReentrancyGuard()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        operatorFilterRegistryAdmin = msg.sender;
        baseURI = _bURI;

        updateRoyaltiesAddresses(_FJMAddress, _DAOAddress);
    }

    /**
     * @notice Updates base URI to `_newBaseURI`.
     * @param _newBaseURI New base URI.
     */
    function updateBaseURI(string memory _newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyNonEmptyString(_newBaseURI)
    {
        baseURI = _newBaseURI;

        emit BaseURIUpdated(_newBaseURI);
    }

    /**
     * @notice Returns the base URI for all tokens. Used in tokenURI().
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Updates delegation signer to `_newDelegationSigner`.
     * @param _newDelegationSigner New delegation signer.
     */
    function updateDelegationSigner(address _newDelegationSigner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
        // Checks for non zero address
        _setDelegationSigner(_newDelegationSigner);
    }

    /**
     * @dev Updates the operator filter registry admin
     */
    function updateOperatorFilterRegistryAdmin(address _newAdmin)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyNonZeroAddress(_newAdmin)
    {
        operatorFilterRegistryAdmin = _newAdmin;
    }

    /**
     * @dev Returns the address that can modify the operator filter registry.
     * Used by RevokableDefaultOperatorFilterer to allow modifications or revoking of filtering.
     */
    function owner() public view override returns (address) {
        return operatorFilterRegistryAdmin;
    }

    /**
     * @notice Forever forbids new collections from being added to this contract.
     * Only callable by DEFAULT_ADMIN_ROLE.
     * Should only be used after a new version of this contract has been deployed.
     * Emits NewCollectionsForbidden event.
     */
    function forbidNewCollections()
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _forbidNewCollections();
    }

    /**
     * @notice Check if adding new collections is allowed on this contract.
     */
    function newCollectionsAllowed() public view returns (bool) {
        return _newCollectionsAllowed();
    }

    /**
     * @notice The collection can be sold if it has not been sold and is fully minted.
     */
    function collectionCanBeSold(uint256 _collectionId) onlyValidCollectionId(_collectionId) external view returns (bool) {
        Collection memory collection = collections[_collectionId];
        return !collection.sold && collection.nParticles == collection.maxParticles;
    }

    /**
     * @notice Proceeds for _tokens for a sale of `_salePrice`.
     */
    function proceeds(uint256 _collectionId, uint256 _salePrice, uint256 _commission, uint256 _tokens) onlyValidCollectionId(_collectionId) external view returns (uint256) {
        // Multiply first to avoid rounding errors as much as possible
        return (_salePrice - _salePrice * _commission / 100) * _tokens / collections[_collectionId].maxParticles;
    }

    /**
     * @notice Mark collection as sold.
     * Only callable by GOVERNOR_ROLE, thus by a completed and accepted governance
     * proposal being executed.
     */
    function markCollectionSold(uint256 _collectionId, address _buyer)
        external
        onlyRole(GOVERNOR_ROLE)
        onlyValidCollectionId(_collectionId)
    {
        Collection storage collection = collections[_collectionId];

        require(!collection.sold, "Already sold");
        collection.sold = true;

        emit CollectionSold(_collectionId, _buyer);
    }

    /**
     * @notice Gets royalty Basis Points (BPS) for token ID `tokenId`.
     * This conforms to the IManifold interface designated in the Royalty
     * Registry's RoyaltyEngineV1.sol contract.
     * ref: https://github.com/manifoldxyz/royalty-registry-solidity
     * @param tokenId Token ID to be queried.
     * @return recipients Array of royalty payment recipients
     * @return bps Array of Basis Points (BPS) allocated to each recipient,
     * aligned by index.
     * @dev only returns recipients that have a non-zero BPS allocation
     */
    function getRoyalties(
        uint256 tokenId
    )
        external
        view
        returns (address payable[] memory recipients, uint256[] memory bps)
    {
        require(_exists(tokenId), "Token ID does not exist");
        recipients = new address payable[](3);
        bps = new uint256[](3);

        CollectionFinance memory financials = collectionIdToFinancials[
            tokenIdToCollectionId(tokenId)
        ];

        // calculate BPS = percentage * 100
        uint256 artistBPS = financials.artistRoyaltyBPS;
        uint256 daoBPS = financials.DAORoyaltyBPS;
        uint256 fjmBPS = financials.FJMRoyaltyBPS;
        // populate arrays
        uint256 payeeCount;
        if (artistBPS > 0) {
            recipients[payeeCount] = financials.artistAddress;
            bps[payeeCount++] = artistBPS;
        }
        if (daoBPS > 0) {
            recipients[payeeCount] = DAOAddress;
            bps[payeeCount++] = daoBPS;
        }
        if (fjmBPS > 0) {
            recipients[payeeCount] = FJMAddress;
            bps[payeeCount++] = fjmBPS;
        }
        // trim arrays if necessary
        if (3 > payeeCount) {
            assembly {
                let decrease := sub(3, payeeCount)
                mstore(recipients, sub(mload(recipients), decrease))
                mstore(bps, sub(mload(bps), decrease))
            }
        }
        return (recipients, bps);
    }

    /**
     * @notice Returns the address of the artist for a given collection ID.
     */
    function collectionIdToArtistAddress(
        uint256 _collectionId
    ) external view onlyValidCollectionId(_collectionId) returns (address payable) {
        return collectionIdToFinancials[_collectionId].artistAddress;
    }

    /**
     * @notice Returns revenue split for primary sale of `_price` for collection `_collectionId`.
     * @dev Used by minter contract to determine how much to pay to each party.
     */
    function getPrimaryRevenueSplits(
        uint256 _collectionId,
        uint256 _price
    )
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (
            uint256 FJMRevenue_,
            address payable FJMAddress_,
            uint256 DAORevenue_,
            address payable DAOAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        )
    {
        CollectionFinance memory financials = collectionIdToFinancials[
            _collectionId
        ];
        // BPS should first be divided by 100 to get the percentage, then by 100 to get the value in the corresponding currency
        FJMRevenue_ =
            (_price * financials.FJMPrimaryBPS) /
            MAX_BPS;
        artistRevenue_ =
            (_price * financials.artistPrimaryBPS) /
            MAX_BPS;
        DAORevenue_ =
            (_price * financials.DAOPrimaryBPS) /
            MAX_BPS;

        FJMAddress_ = FJMAddress;
        artistAddress_ = financials.artistAddress;
        DAOAddress_ = DAOAddress;
    }

    /**
     * @notice Returns collection data for collection `_collectionId`.
     */
    function collectionData(uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (
            uint256 nParticles,
            uint256 maxParticles,
            bool active,
            string memory collectionName,
            bool sold,
            uint24[] memory seeds,
            uint256 setSeedsAfterBlock
        )
    {
        Collection memory collection = collections[_collectionId];

        nParticles = collection.nParticles;
        maxParticles = collection.maxParticles;
        active = collection.active;
        collectionName = collection.name;
        sold = collection.sold;
        seeds = collection.seeds;
        setSeedsAfterBlock = collection.setSeedsAfterBlock;
    }

    /**
     * @notice Returns the coordinate within the collection artwork for a given token ID.
     * @dev The coordinate is calculated based on the collection's seeds (set by the randomizer contract), and the token ID.
     */
    function getCoordinate(uint256 _tokenId) external view returns (uint256) {
        // Get collection id, check if seeds have been set, calculate coordinate based on seeds
        Collection memory collection = collections[
            tokenIdToCollectionId(_tokenId)
        ];

        require(collection.seeds.length != 0, "Seeds not set yet");

        // p1 and p2 are primes above 1M, guaranteeing no collisions
        // Using another prime to shift, to avoid 0 or last token id always being the first element
        uint32 p1 = collection.seeds[0];
        uint32 p2 = collection.seeds[1];
        uint256 maxParticles = collection.maxParticles;

        return (_tokenId * p1 + p2) % maxParticles;
    }

    /**
     * @notice Adds new collection `_collectionName` by `_artistAddress`.
     * @param _collectionName Artwork (ERC-721 collection) name.
     * @param _numberOfParticles Artwork will be divided in these many particles.
     * @param _artistAddress Artist's address.
     * @dev token price stored on minter contract. Emits CollectionAdded event from ERC721MultiCollection.
     */
    function addCollection(
        string memory _collectionName,
        uint24 _numberOfParticles,
        address payable _artistAddress
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyNonZeroAddress(_artistAddress)
        onlyNonEmptyString(_collectionName)
        returns (uint256)
    {
        uint256 collectionId = _addCollection(_numberOfParticles);

        require(collectionId <= type(uint232).max, "Collection id > 232 bits");

        collectionIdToFinancials[collectionId].artistAddress = _artistAddress;
        collectionIdToFinancials[collectionId].artistRoyaltyBPS = DEFAULT_ARTIST_ROYALTY_BPS;
        collectionIdToFinancials[collectionId].FJMRoyaltyBPS = DEFAULT_FJM_ROYALTY_BPS;
        collectionIdToFinancials[collectionId].DAORoyaltyBPS = DEFAULT_DAO_ROYALTY_BPS;

        // Primary sales revenue split
        collectionIdToFinancials[collectionId].artistPrimaryBPS = DEFAULT_ARTIST_PRIMARY_BPS;
        collectionIdToFinancials[collectionId].FJMPrimaryBPS = DEFAULT_FJM_PRIMARY_BPS;
        collectionIdToFinancials[collectionId].DAOPrimaryBPS = DEFAULT_DAO_PRIMARY_BPS;

        collections[collectionId].name = _collectionName;
        collections[collectionId].maxParticles = _numberOfParticles;

        return collectionId;
    }

    /**
     * @notice Toggles collection `_collectionId` as active/inactive.
     * @param _collectionId Collection ID to be toggled.
     */
    function toggleCollectionIsActive(uint256 _collectionId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyValidCollectionId(_collectionId)
    {
        collections[_collectionId].active = !collections[_collectionId].active;
        
        if (collections[_collectionId].active) {
            emit CollectionActive(_collectionId);
        } else {
            emit CollectionInactive(_collectionId);
        }
    }

    /**
     * @notice Updates a collection's data.
     * @param _collectionId Collection ID.
     * @param _artistAddress New artist address.
     * @param _collectionName New collection name.
     */
    function updateCollectionData(
        uint256 _collectionId,
        address payable _artistAddress,
        string memory _collectionName
    )
        external
        onlyValidCollectionId(_collectionId)
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyNonZeroAddress(_artistAddress)
        onlyNonEmptyString(_collectionName)
    {
        collections[_collectionId].name = _collectionName;
        collectionIdToFinancials[_collectionId].artistAddress = _artistAddress;
        emit CollectionDataUpdated(_collectionId);
    }

    /**
     * @notice Updates a collection's max particles.
     * @param _collectionId Collection ID.
     * @param _maxParticles New number of particles for collection.
     */
    function updateCollectionMaxParticles(
        uint256 _collectionId,
        uint24 _maxParticles
    )
        external
        onlyValidCollectionId(_collectionId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_validCollectionSize(_maxParticles), "maxParticles has to be > 0 and <= 1M");
        require(collections[_collectionId].nParticles == 0, "maxParticles can only be updated if no particles have been minted");
        collections[_collectionId].maxParticles = _maxParticles;
        emit CollectionSizeUpdated(_collectionId, _maxParticles);
    }

    /**
     * @notice Updates collection's financials.
     * @param _collectionId Collection ID.
     * @param _artistRoyaltyBPS New artist fee percentage.
     * @param _FJMRoyaltyBPS New 4JM fee percentage.
     * @param _DAORoyaltyBPS New DAO fee percentage.
     */
    function updateCollectionRoyalties(
        uint256 _collectionId,
        uint256 _artistRoyaltyBPS,
        uint256 _FJMRoyaltyBPS,
        uint256 _DAORoyaltyBPS
    )
        external
        onlyValidCollectionId(_collectionId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // 10_000 BPS = 100%
        // require the sum of all royalties to be less than or equal to MAX_BPS
        require(_artistRoyaltyBPS + _FJMRoyaltyBPS + _DAORoyaltyBPS <= MAX_BPS, "Royalties > 100%");
        collectionIdToFinancials[_collectionId].artistRoyaltyBPS = _artistRoyaltyBPS;
        collectionIdToFinancials[_collectionId].FJMRoyaltyBPS = _FJMRoyaltyBPS;
        collectionIdToFinancials[_collectionId].DAORoyaltyBPS = _DAORoyaltyBPS;
        emit CollectionRoyaltiesUpdated(_collectionId);
    }

    /**
     * @notice Updates collection's financials.
     * @param _collectionId Collection ID.
     * @param _artistPrimaryBPS New artist fee percentage.
     * @param _FJMPrimaryBPS New 4JM fee percentage.
     * @param _DAOPrimaryBPS New DAO fee percentage.
     */
    function updateCollectionPrimarySplit(
        uint256 _collectionId,
        uint256 _artistPrimaryBPS,
        uint256 _FJMPrimaryBPS,
        uint256 _DAOPrimaryBPS
    )
        external
        onlyValidCollectionId(_collectionId)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // 10_000 BPS = 100%
        // require the sum of all primary splits to be exactly MAX_BPS
        require(_artistPrimaryBPS + _FJMPrimaryBPS + _DAOPrimaryBPS == MAX_BPS, "Primary split != 100%");
        collectionIdToFinancials[_collectionId].artistPrimaryBPS = _artistPrimaryBPS;
        collectionIdToFinancials[_collectionId].FJMPrimaryBPS = _FJMPrimaryBPS;
        collectionIdToFinancials[_collectionId].DAOPrimaryBPS = _DAOPrimaryBPS;
        emit CollectionPrimarySplitUpdated(_collectionId);
    }

    /**
     * @notice Updates collection's seeds.
     * @param _collectionId Collection ID.
     * @param _seeds Seeds to be set for collection `_collectionId`.
     * @dev Only callable by Randomizer contract.
     */
    function setCollectionSeeds(
        uint256 _collectionId,
        uint24[2] calldata _seeds
    ) external onlyValidCollectionId(_collectionId) {
        require(
            msg.sender == address(randomizerContract),
            "Only randomizer may set"
        );

        Collection storage collection = collections[_collectionId];

        require(collection.seeds.length == 0, "Seeds already set");
        require(_seeds.length == 2, "Seeds must be length 2");

        collection.seeds = _seeds;

        emit CollectionSeedsSet(_collectionId, _seeds[0], _seeds[1]);
    }

    /**
     * @notice Requests an update to the collection's seeds from the Randomizer contract.
     * @param _collectionId Collection ID.
     * @dev Only callable by Admin after the setSeedsAfterBlock block number.
     */
    function requestCollectionSeeds(
        uint256 _collectionId
    ) external onlyValidCollectionId(_collectionId) onlyRole(DEFAULT_ADMIN_ROLE) {
        uint allowedBlock = collections[_collectionId].setSeedsAfterBlock;
        require(allowedBlock > 0 && block.number > allowedBlock, "Too early to set seeds");

        randomizerContract.setCollectionSeeds(_collectionId);
    }

    /**
     * @notice Updates 4JM and DAO addresses.
     * @param _FJMAddress 4JM address.
     * @param _DAOAddress DAO address.
     * Registry.
     */
    function updateRoyaltiesAddresses(
        address payable _FJMAddress,
        address payable _DAOAddress
    )
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyNonZeroAddress(_FJMAddress)
        onlyNonZeroAddress(_DAOAddress)
    {
        FJMAddress = _FJMAddress;
        DAOAddress = _DAOAddress;

        emit RoyaltiesAddressesUpdated(_FJMAddress, _DAOAddress);
    }

    /**
     * @notice Updates randomizer to `_randomizerAddress`.
     * @param _randomizerAddress Address of new randomizer.
     */
    function updateRandomizer(
        address _randomizerAddress
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        onlyNonZeroAddress(_randomizerAddress)
    {
        randomizerContract = IRandomizerV1(_randomizerAddress);

        emit RandomizerUpdated(_randomizerAddress);
    }

    /**
     * @notice Mints a new token for collection `_collectionId`.
     * @param _to Receiver of the new token.
     * @param _collectionId Collection ID.
     * @param _amount Number of tokens to mint.
     * @dev Mints ids in incremental order, coordinates are determined at random on last mint 
     * (requires minting all collection ids to generate seeds). Only callable by minter role 
     * (minter contract and admin account handling fiat sales).
     */
    function mint(
        address _to,
        uint256 _collectionId,
        uint24 _amount
    ) external onlyValidCollectionId(_collectionId) onlyRole(MINTER_ROLE) nonReentrant returns (uint256 tokenId) {
        require(_amount > 0, "Must mint at least one token");

        Collection storage collection = collections[_collectionId];
        uint24 oldNParticles = collection.nParticles;
        uint24 maxParticles = collection.maxParticles;

        uint24 newNParticles = oldNParticles + _amount;

        require(
            newNParticles <= maxParticles,
            "Cannot exceed max number of Particles"
        );

        require(
            collection.active || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Collection must be active"
        );

        collection.nParticles = newNParticles;

        uint256 newTokenId;

        unchecked {
            // oldNParticles is uint24 << max uint256. In production use,
            // _collectionId * ONE_MILLION must be << max uint256, otherwise
            // tokenIdToCollectionId function becomes invalid.
            // Therefore, no risk of overflow
            newTokenId = (_collectionId * MAX_COLLECTION_SIZE) + oldNParticles;
        }

        if (newNParticles == maxParticles) {
            // Allow setCollectionSeeds to be called 256 blocks (8 epochs) after the last mint, 
            // by a contract Admin (essentially revealing the final coordinates and metadata for each token)
            collection.setSeedsAfterBlock = block.number + 256;
            collection.active = false;

            emit CollectionFullyMinted(_collectionId);
        }

        for (uint256 i; i < _amount;) {
            _safeMint(_to, newTokenId + i);
            unchecked { i++; }
        }

        return newTokenId;
    }

    /**
     * @notice Burns tokensToRedeem tokens in a collection for user `tokensOwner`.
     * Used when redeeming proceeds from a sale.
     *
     * @dev The caller must be the governor contract.
     * Approval to burn is checked on the governor contract.
     */
    function burn(address tokensOwner, uint256 collectionId, uint256 tokensToRedeem)
        external
        onlyRole(GOVERNOR_ROLE)
        onlyValidCollectionId(collectionId)
        returns (uint256 tokensBurnt)
    {
        return _burn(tokensOwner, collectionId, tokensToRedeem);
    }

    /// @dev Override transfer and approval functions to use the operator filter registry

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721, ERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      The added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(IERC721, ERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721MultiCollection) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(PRTCLCoreERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}