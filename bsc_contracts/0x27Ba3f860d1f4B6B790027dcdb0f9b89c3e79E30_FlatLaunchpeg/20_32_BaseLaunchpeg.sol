// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./ERC721AUpgradeable.sol";
import "operator-filter-registry/src/IOperatorFilterRegistry.sol";

import "./LaunchpegErrors.sol";
import "./interfaces/IBaseLaunchpeg.sol";
import "./interfaces/IBatchReveal.sol";
import "./utils/SafePausableUpgradeable.sol";

/// @title BaseLaunchpeg
/// @author Trader Joe
/// @notice Implements the functionalities shared between Launchpeg and FlatLaunchpeg contracts.
abstract contract BaseLaunchpeg is
    IBaseLaunchpeg,
    ERC721AUpgradeable,
    SafePausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC2981Upgradeable
{
    using StringsUpgradeable for uint256;

    /// @dev Structure for pre-mint data
    struct PreMintData {
        // address to mint NFTs to
        address sender;
        // No. of NFTs to mint
        uint96 quantity;
    }

    /// @dev Structure for a set of pre-mint data.
    struct PreMintDataSet {
        // pre-mint data array
        PreMintData[] preMintDataArr;
        // maps a user address to the index of the user's pre-mint data in the
        // `preMintDataArr` array. Plus 1 because index 0 means data does not
        // exist for that user.
        mapping(address => uint256) indexes;
    }

    /// @notice Role granted to project owners
    bytes32 public constant override PROJECT_OWNER_ROLE =
        keccak256("PROJECT_OWNER_ROLE");

    /// @notice Percentage base point
    uint256 public constant BASIS_POINT_PRECISION = 10_000;

    /// @notice The collection size (e.g 10000)
    uint256 public override collectionSize;

    /// @notice Amount of NFTs reserved for the project owner (e.g 200)
    /// @dev It can be minted any time via `devMint`
    uint256 public override amountForDevs;

    /// @notice Amount of NFTs available for the allowlist mint (e.g 1000)
    uint256 public override amountForAllowlist;

    /// @notice Max amount of NFTs an address can mint in public phases
    uint256 public override maxPerAddressDuringMint;

    /// @notice The fees collected by Joepegs on the sale benefits
    /// @dev In basis points e.g 100 for 1%
    uint256 public override joeFeePercent;

    /// @notice The address to which the fees on the sale will be sent
    address public override joeFeeCollector;

    /// @notice Batch reveal contract
    IBatchReveal public batchReveal;

    /// @notice Token URI after collection reveal
    string public override baseURI;

    /// @notice Token URI before the collection reveal
    string public override unrevealedURI;

    /// @notice The amount of NFTs each allowed address can mint during
    /// the pre-mint or allowlist mint
    mapping(address => uint256) public override allowlist;

    /// @notice Tracks the amount of NFTs minted by `projectOwner`
    uint256 public override amountMintedByDevs;

    /// @notice Tracks the amount of NFTs minted in the Pre-Mint phase
    uint256 public override amountMintedDuringPreMint;

    /// @notice Tracks the amount of pre-minted NFTs that have been claimed
    uint256 public override amountClaimedDuringPreMint;

    /// @notice Tracks the amount of NFTs minted on Allowlist phase
    uint256 public override amountMintedDuringAllowlist;

    /// @notice Tracks the amount of NFTs minted on Public Sale phase
    uint256 public override amountMintedDuringPublicSale;

    /// @notice Start time of the pre-mint in seconds
    uint256 public override preMintStartTime;

    /// @notice Start time of the allowlist mint in seconds
    uint256 public override allowlistStartTime;

    /// @notice Start time of the public sale in seconds
    /// @dev A timestamp greater than the allowlist mint start
    uint256 public override publicSaleStartTime;

    /// @notice End time of the public sale in seconds
    /// @dev A timestamp greater than the public sale start
    uint256 public override publicSaleEndTime;

    /// @notice Start time when funds can be withdrawn
    uint256 public override withdrawAVAXStartTime;

    /// @notice Contract filtering allowed operators, preventing unauthorized contract to transfer NFTs
    /// By default, Launchpeg contracts are subscribed to OpenSea's Curated Subscription Address at 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
    IOperatorFilterRegistry public operatorFilterRegistry;

    /// @dev Set of pending pre-mint data (user address and quantity)
    PreMintDataSet private _pendingPreMints;

    /// @dev Emitted on initializeJoeFee()
    /// @param feePercent The fees collected by Joepegs on the sale benefits
    /// @param feeCollector The address to which the fees on the sale will be sent
    event JoeFeeInitialized(uint256 feePercent, address feeCollector);

    /// @dev Emitted on devMint()
    /// @param sender The address that minted
    /// @param quantity Amount of NFTs minted
    event DevMint(address indexed sender, uint256 quantity);

    /// @dev Emitted on preMint()
    /// @param sender The address that minted
    /// @param quantity Amount of NFTs minted
    /// @param price Price of 1 NFT
    event PreMint(address indexed sender, uint256 quantity, uint256 price);

    /// @dev Emitted on auctionMint(), claimPreMint(), batchClaimPreMint(),
    /// allowlistMint(), publicSaleMint()
    /// @param sender The address that minted
    /// @param quantity Amount of NFTs minted
    /// @param price Price in AVAX for the NFTs
    /// @param startTokenId The token ID of the first minted NFT:
    /// if `startTokenId` = 100 and `quantity` = 2, `sender` minted 100 and 101
    /// @param phase The phase in which the mint occurs
    event Mint(
        address indexed sender,
        uint256 quantity,
        uint256 price,
        uint256 startTokenId,
        Phase phase
    );

    /// @dev Emitted on withdrawAVAX()
    /// @param sender The address that withdrew the tokens
    /// @param amount Amount of AVAX transfered to `sender`
    /// @param fee Amount of AVAX paid to the fee collector
    event AvaxWithdraw(address indexed sender, uint256 amount, uint256 fee);

    /// @dev Emitted on setBaseURI()
    /// @param baseURI The new base URI
    event BaseURISet(string baseURI);

    /// @dev Emitted on setUnrevealedURI()
    /// @param unrevealedURI The new base URI
    event UnrevealedURISet(string unrevealedURI);

    /// @dev Emitted on seedAllowlist()
    event AllowlistSeeded();

    /// @dev Emitted on _setDefaultRoyalty()
    /// @param receiver Royalty fee collector
    /// @param feePercent Royalty fee percent in basis point
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);

    /// @dev Emitted on setPreMintStartTime()
    /// @param preMintStartTime New pre-mint start time
    event PreMintStartTimeSet(uint256 preMintStartTime);

    /// @dev Emitted on setAllowlistStartTime()
    /// @param allowlistStartTime New allowlist start time
    event AllowlistStartTimeSet(uint256 allowlistStartTime);

    /// @dev Emitted on setPublicSaleStartTime()
    /// @param publicSaleStartTime New public sale start time
    event PublicSaleStartTimeSet(uint256 publicSaleStartTime);

    /// @dev Emitted on setPublicSaleEndTime()
    /// @param publicSaleEndTime New public sale end time
    event PublicSaleEndTimeSet(uint256 publicSaleEndTime);

    /// @dev Emitted on setWithdrawAVAXStartTime()
    /// @param withdrawAVAXStartTime New withdraw AVAX start time
    event WithdrawAVAXStartTimeSet(uint256 withdrawAVAXStartTime);

    /// @dev Emitted on updateOperatorFilterRegistryAddress()
    /// @param operatorFilterRegistry New operator filter registry
    event OperatorFilterRegistryUpdated(
        IOperatorFilterRegistry indexed operatorFilterRegistry
    );

    modifier isEOA() {
        if (tx.origin != msg.sender) {
            revert Launchpeg__Unauthorized();
        }
        _;
    }

    /// @notice Checks if the current phase matches the required phase
    modifier atPhase(Phase _phase) {
        if (currentPhase() != _phase) {
            revert Launchpeg__WrongPhase();
        }
        _;
    }

    /// @notice Pre-mints can be claimed from the allowlist phase
    /// (including after sale ends)
    modifier isClaimPreMintAvailable() {
        if (block.timestamp < allowlistStartTime) {
            revert Launchpeg__WrongPhase();
        }
        _;
    }

    /// @notice Phase time can be updated if it has been initialized and
    // the time has not passed
    modifier isTimeUpdateAllowed(uint256 _phaseTime) {
        if (_phaseTime == 0) {
            revert Launchpeg__NotInitialized();
        }
        if (_phaseTime <= block.timestamp) {
            revert Launchpeg__WrongPhase();
        }
        _;
    }

    /// @notice Checks if new time is equal to or after block timestamp
    modifier isNotBeforeBlockTimestamp(uint256 _newTime) {
        if (_newTime < block.timestamp) {
            revert Launchpeg__InvalidPhases();
        }
        _;
    }

    /// @notice Allow spending tokens from addresses with balance
    /// Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
    /// from an EOA.
    modifier onlyAllowedOperator(address from) virtual {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /// @notice Allow approving tokens transfers
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /// @dev BaseLaunchpeg initialization
    /// @param _collectionData Launchpeg collection data
    /// @param _ownerData Launchpeg owner data
    function initializeBaseLaunchpeg(
        CollectionData calldata _collectionData,
        CollectionOwnerData calldata _ownerData
    ) internal onlyInitializing {
        __SafePausable_init();
        __ReentrancyGuard_init();
        __ERC2981_init();
        __ERC721A_init(_collectionData.name, _collectionData.symbol);

        if (_ownerData.owner == address(0)) {
            revert Launchpeg__InvalidOwner();
        }
        if (_ownerData.projectOwner == address(0)) {
            revert Launchpeg__InvalidProjectOwner();
        }
        if (
            _collectionData.collectionSize == 0 ||
            _collectionData.amountForDevs + _collectionData.amountForAllowlist >
            _collectionData.collectionSize
        ) {
            revert Launchpeg__LargerCollectionSizeNeeded();
        }
        if (
            _collectionData.maxPerAddressDuringMint >
            _collectionData.collectionSize
        ) {
            revert Launchpeg__InvalidMaxPerAddressDuringMint();
        }

        // Initialize the operator filter registry and subcribe to OpenSea's list
        IOperatorFilterRegistry _operatorFilterRegistry = IOperatorFilterRegistry(
                0x000000000000AAeB6D7670E522A718067333cd4E
            );
        if (address(_operatorFilterRegistry).code.length > 0) {
            _operatorFilterRegistry.registerAndSubscribe(
                address(this),
                0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
            );
        }
        _updateOperatorFilterRegistryAddress(_operatorFilterRegistry);

        // Default royalty is 5%
        _setDefaultRoyalty(_ownerData.royaltyReceiver, 500);
        _initializeJoeFee(_ownerData.joeFeePercent, _ownerData.joeFeeCollector);

        batchReveal = IBatchReveal(_collectionData.batchReveal);
        collectionSize = _collectionData.collectionSize;
        maxPerAddressDuringMint = _collectionData.maxPerAddressDuringMint;
        amountForDevs = _collectionData.amountForDevs;
        amountForAllowlist = _collectionData.amountForAllowlist;

        grantRole(PAUSER_ROLE, msg.sender);
        grantRole(PROJECT_OWNER_ROLE, _ownerData.projectOwner);
        _transferOwnership(_ownerData.owner);
    }

    /// @notice Initialize the sales fee percent taken by Joepegs and address that collects the fees
    /// @param _joeFeePercent The fees collected by Joepegs on the sale benefits
    /// @param _joeFeeCollector The address to which the fees on the sale will be sent
    function _initializeJoeFee(uint256 _joeFeePercent, address _joeFeeCollector)
        internal
    {
        if (_joeFeePercent > BASIS_POINT_PRECISION) {
            revert Launchpeg__InvalidPercent();
        }
        if (_joeFeeCollector == address(0)) {
            revert Launchpeg__InvalidJoeFeeCollector();
        }
        joeFeePercent = _joeFeePercent;
        joeFeeCollector = _joeFeeCollector;
        emit JoeFeeInitialized(_joeFeePercent, _joeFeeCollector);
    }

    /// @notice Initialize batch reveal. Leave undefined to disable
    /// batch reveal for the collection.
    /// @dev Can only be set once. Cannot be initialized once sale has ended.
    /// @param _batchReveal Batch reveal contract address
    function initializeBatchReveal(address _batchReveal)
        external
        override
        onlyOwner
    {
        if (address(batchReveal) != address(0)) {
            revert Launchpeg__BatchRevealAlreadyInitialized();
        }
        // Disable once sale has ended
        if (publicSaleEndTime > 0 && block.timestamp >= publicSaleEndTime) {
            revert Launchpeg__WrongPhase();
        }
        batchReveal = IBatchReveal(_batchReveal);
    }

    /// @notice Set the royalty fee
    /// @param _receiver Royalty fee collector
    /// @param _feePercent Royalty fee percent in basis point
    function setRoyaltyInfo(address _receiver, uint96 _feePercent)
        external
        override
        onlyOwner
    {
        // Royalty fees are limited to 25%
        if (_feePercent > 2_500) {
            revert Launchpeg__InvalidRoyaltyInfo();
        }
        _setDefaultRoyalty(_receiver, _feePercent);
        emit DefaultRoyaltySet(_receiver, _feePercent);
    }

    /// @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
    /// address, checks will be bypassed. OnlyOwner
    /// @param _newRegistry The address of the new OperatorFilterRegistry
    function updateOperatorFilterRegistryAddress(
        IOperatorFilterRegistry _newRegistry
    ) external onlyOwner {
        _updateOperatorFilterRegistryAddress(_newRegistry);
    }

    /// @notice Set amount of NFTs mintable per address during the allowlist phase
    /// @param _addresses List of addresses allowed to mint during the allowlist phase
    /// @param _numNfts List of NFT quantities mintable per address
    function seedAllowlist(
        address[] calldata _addresses,
        uint256[] calldata _numNfts
    ) external override onlyOwner {
        uint256 addressesLength = _addresses.length;
        if (addressesLength != _numNfts.length) {
            revert Launchpeg__WrongAddressesAndNumSlotsLength();
        }
        for (uint256 i; i < addressesLength; i++) {
            allowlist[_addresses[i]] = _numNfts[i];
        }

        emit AllowlistSeeded();
    }

    /// @notice Set the base URI
    /// @dev This sets the URI for revealed tokens
    /// Only callable by project owner
    /// @param _baseURI Base URI to be set
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(baseURI);
    }

    /// @notice Set the unrevealed URI
    /// @dev Only callable by project owner
    /// @param _unrevealedURI Unrevealed URI to be set
    function setUnrevealedURI(string calldata _unrevealedURI)
        external
        override
        onlyOwner
    {
        unrevealedURI = _unrevealedURI;
        emit UnrevealedURISet(unrevealedURI);
    }

    /// @notice Set the allowlist start time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _allowlistStartTime New allowlist start time
    function setAllowlistStartTime(uint256 _allowlistStartTime)
        external
        override
        onlyOwner
        isTimeUpdateAllowed(allowlistStartTime)
        isNotBeforeBlockTimestamp(_allowlistStartTime)
    {
        if (
            _allowlistStartTime < preMintStartTime ||
            publicSaleStartTime < _allowlistStartTime
        ) {
            revert Launchpeg__InvalidPhases();
        }
        allowlistStartTime = _allowlistStartTime;
        emit AllowlistStartTimeSet(_allowlistStartTime);
    }

    /// @notice Set the public sale start time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _publicSaleStartTime New public sale start time
    function setPublicSaleStartTime(uint256 _publicSaleStartTime)
        external
        override
        onlyOwner
        isTimeUpdateAllowed(publicSaleStartTime)
        isNotBeforeBlockTimestamp(_publicSaleStartTime)
    {
        if (
            _publicSaleStartTime < allowlistStartTime ||
            publicSaleEndTime < _publicSaleStartTime
        ) {
            revert Launchpeg__InvalidPhases();
        }

        publicSaleStartTime = _publicSaleStartTime;
        emit PublicSaleStartTimeSet(_publicSaleStartTime);
    }

    /// @notice Set the public sale end time. Can only be set after phases
    /// have been initialized.
    /// @dev Only callable by owner
    /// @param _publicSaleEndTime New public sale end time
    function setPublicSaleEndTime(uint256 _publicSaleEndTime)
        external
        override
        onlyOwner
        isTimeUpdateAllowed(publicSaleEndTime)
        isNotBeforeBlockTimestamp(_publicSaleEndTime)
    {
        if (_publicSaleEndTime < publicSaleStartTime) {
            revert Launchpeg__InvalidPhases();
        }
        publicSaleEndTime = _publicSaleEndTime;
        emit PublicSaleEndTimeSet(_publicSaleEndTime);
    }

    /// @notice Set the withdraw AVAX start time.
    /// @param _withdrawAVAXStartTime New public sale end time
    function setWithdrawAVAXStartTime(uint256 _withdrawAVAXStartTime)
        external
        override
        onlyOwner
        isNotBeforeBlockTimestamp(_withdrawAVAXStartTime)
    {
        withdrawAVAXStartTime = _withdrawAVAXStartTime;
        emit WithdrawAVAXStartTimeSet(_withdrawAVAXStartTime);
    }

    /// @notice The remaining no. of pre-minted NFTs for the user address
    /// @param _user user address
    function userPendingPreMints(address _user)
        public
        view
        override
        returns (uint256)
    {
        uint256 idx = _pendingPreMints.indexes[_user];
        if (idx == 0) {
            return 0;
        }
        return _pendingPreMints.preMintDataArr[idx - 1].quantity;
    }

    /// @notice Mint NFTs to the project owner
    /// @dev Can only mint up to `amountForDevs`
    /// @param _quantity Quantity of NFTs to mint
    function devMint(uint256 _quantity)
        external
        override
        onlyOwnerOrRole(PROJECT_OWNER_ROLE)
        whenNotPaused
    {
        if (_totalSupplyWithPreMint() + _quantity > collectionSize) {
            revert Launchpeg__MaxSupplyReached();
        }
        if (amountMintedByDevs + _quantity > amountForDevs) {
            revert Launchpeg__MaxSupplyForDevReached();
        }
        amountMintedByDevs = amountMintedByDevs + _quantity;
        _batchMint(msg.sender, _quantity, maxPerAddressDuringMint);
        emit DevMint(msg.sender, _quantity);
    }

    /// @notice Mint NFTs during the pre-mint
    /// @param _quantity Quantity of NFTs to mint
    function preMint(uint96 _quantity)
        external
        payable
        override
        whenNotPaused
        atPhase(Phase.PreMint)
    {
        if (_quantity == 0) {
            revert Launchpeg__InvalidQuantity();
        }
        if (_quantity > allowlist[msg.sender]) {
            revert Launchpeg__NotEligibleForAllowlistMint();
        }
        if (amountMintedDuringPreMint + _quantity > amountForAllowlist) {
            revert Launchpeg__MaxSupplyReached();
        }
        allowlist[msg.sender] -= _quantity;
        amountMintedDuringPreMint += _quantity;
        _addPreMint(msg.sender, _quantity);
        uint256 price = _getPreMintPrice();
        uint256 totalCost = price * _quantity;
        emit PreMint(msg.sender, _quantity, price);
        _refundIfOver(totalCost);
    }

    /// @notice Claim pre-minted NFTs
    function claimPreMint()
        external
        override
        whenNotPaused
        isClaimPreMintAvailable
    {
        uint256 quantity = userPendingPreMints(msg.sender);
        if (quantity == 0) {
            revert Launchpeg__InvalidClaim();
        }
        _removePreMint(msg.sender, uint96(quantity));
        amountClaimedDuringPreMint += quantity;
        uint256 price = _getPreMintPrice();
        _batchMint(msg.sender, quantity, maxPerAddressDuringMint);
        emit Mint(
            msg.sender,
            quantity,
            price,
            _totalMinted() - quantity,
            Phase.PreMint
        );
    }

    /// @notice Claim pre-minted NFTs for users
    /// @param _maxQuantity Max quantity of NFTs to mint
    function batchClaimPreMint(uint96 _maxQuantity)
        external
        override
        whenNotPaused
        isClaimPreMintAvailable
    {
        if (_maxQuantity == 0) {
            revert Launchpeg__InvalidQuantity();
        }
        if (amountMintedDuringPreMint == amountClaimedDuringPreMint) {
            revert Launchpeg__InvalidClaim();
        }
        uint256 maxBatchSize = maxPerAddressDuringMint;
        uint256 price = _getPreMintPrice();
        uint96 remQuantity = _maxQuantity;
        uint96 mintQuantity;
        for (
            uint256 len = _pendingPreMints.preMintDataArr.length;
            len > 0 && remQuantity > 0;

        ) {
            PreMintData memory preMintData = _pendingPreMints.preMintDataArr[
                len - 1
            ];
            if (preMintData.quantity > remQuantity) {
                mintQuantity = remQuantity;
            } else {
                mintQuantity = preMintData.quantity;
                --len;
            }
            _removePreMint(preMintData.sender, mintQuantity);
            remQuantity -= mintQuantity;
            _batchMint(preMintData.sender, mintQuantity, maxBatchSize);
            emit Mint(
                preMintData.sender,
                mintQuantity,
                price,
                _totalMinted() - mintQuantity,
                Phase.PreMint
            );
        }
        amountClaimedDuringPreMint += (_maxQuantity - remQuantity);
    }

    /// @notice Mint NFTs during the allowlist mint
    /// @param _quantity Quantity of NFTs to mint
    function allowlistMint(uint256 _quantity)
        external
        payable
        override
        whenNotPaused
        atPhase(Phase.Allowlist)
    {
        if (_quantity > allowlist[msg.sender]) {
            revert Launchpeg__NotEligibleForAllowlistMint();
        }
        if (
            amountMintedDuringPreMint +
                amountMintedDuringAllowlist +
                _quantity >
            amountForAllowlist
        ) {
            revert Launchpeg__MaxSupplyReached();
        }
        allowlist[msg.sender] -= _quantity;
        uint256 price = _getAllowlistPrice();
        uint256 totalCost = price * _quantity;

        _batchMint(msg.sender, _quantity, maxPerAddressDuringMint);
        amountMintedDuringAllowlist += _quantity;
        emit Mint(
            msg.sender,
            _quantity,
            price,
            _totalMinted() - _quantity,
            Phase.Allowlist
        );
        _refundIfOver(totalCost);
    }

    /// @notice Mint NFTs during the public sale
    /// @param _quantity Quantity of NFTs to mint
    function publicSaleMint(uint256 _quantity)
        external
        payable
        override
        isEOA
        whenNotPaused
        atPhase(Phase.PublicSale)
    {
        if (
            numberMintedWithPreMint(msg.sender) + _quantity >
            maxPerAddressDuringMint
        ) {
            revert Launchpeg__CanNotMintThisMany();
        }
        // ensure sufficient supply for devs. note we can skip this check
        // in prior phases as long as they do not exceed the phase allocation
        // and the total phase allocations do not exceed collection size
        uint256 remainingDevAmt = amountForDevs - amountMintedByDevs;
        if (
            _totalSupplyWithPreMint() + remainingDevAmt + _quantity >
            collectionSize
        ) {
            revert Launchpeg__MaxSupplyReached();
        }
        uint256 price = _getPublicSalePrice();
        uint256 total = price * _quantity;

        _mint(msg.sender, _quantity, "", false);
        amountMintedDuringPublicSale += _quantity;
        emit Mint(
            msg.sender,
            _quantity,
            price,
            _totalMinted() - _quantity,
            Phase.PublicSale
        );
        _refundIfOver(total);
    }

    /// @dev Returns pre-mint price. Used by mint methods.
    function _getPreMintPrice() internal view virtual returns (uint256);

    /// @dev Returns allowlist price. Used by mint methods.
    function _getAllowlistPrice() internal view virtual returns (uint256);

    /// @dev Returns public sale price. Used by mint methods.
    function _getPublicSalePrice() internal view virtual returns (uint256);

    /// @notice Withdraw AVAX to the given recipient
    /// @param _to Recipient of the earned AVAX
    function withdrawAVAX(address _to)
        external
        override
        onlyOwnerOrRole(PROJECT_OWNER_ROLE)
        nonReentrant
        whenNotPaused
    {
        if (
            withdrawAVAXStartTime > block.timestamp ||
            withdrawAVAXStartTime == 0
        ) {
            revert Launchpeg__WithdrawAVAXNotAvailable();
        }

        uint256 amount = address(this).balance;
        uint256 fee;
        bool sent;

        if (joeFeePercent > 0) {
            fee = (amount * joeFeePercent) / BASIS_POINT_PRECISION;
            amount = amount - fee;

            (sent, ) = joeFeeCollector.call{value: fee}("");
            if (!sent) {
                revert Launchpeg__TransferFailed();
            }
        }

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert Launchpeg__TransferFailed();
        }

        emit AvaxWithdraw(_to, amount, fee);
    }

    /// @notice Returns the ownership data of a specific token ID
    /// @param _tokenId Token ID
    /// @return TokenOwnership Ownership struct for a specific token ID
    function getOwnershipData(uint256 _tokenId)
        external
        view
        override
        returns (TokenOwnership memory)
    {
        return _ownershipOf(_tokenId);
    }

    /// @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    /// @param _id Token id
    /// @return URI Token URI
    function tokenURI(uint256 _id)
        public
        view
        override(ERC721AUpgradeable, IERC721MetadataUpgradeable)
        returns (string memory)
    {
        if (address(batchReveal) == address(0)) {
            return string(abi.encodePacked(baseURI, _id.toString()));
        } else if (
            _id >= batchReveal.launchpegToLastTokenReveal(address(this))
        ) {
            return unrevealedURI;
        } else {
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        batchReveal
                            .getShuffledTokenId(address(this), _id)
                            .toString()
                    )
                );
        }
    }

    /// @notice Returns the number of NFTs minted by a specific address
    /// @param _owner The owner of the NFTs
    /// @return numberMinted Number of NFTs minted
    function numberMinted(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return _numberMinted(_owner);
    }

    /// @dev Returns true if this contract implements the interface defined by
    /// `interfaceId`. See the corresponding
    /// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// to learn more about how these IDs are created.
    /// This function call must use less than 30 000 gas.
    /// @param _interfaceId InterfaceId to consider. Comes from type(InterfaceContract).interfaceId
    /// @return isInterfaceSupported True if the considered interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(
            ERC721AUpgradeable,
            ERC2981Upgradeable,
            IERC165Upgradeable,
            SafePausableUpgradeable
        )
        returns (bool)
    {
        return
            _interfaceId == type(IBaseLaunchpeg).interfaceId ||
            ERC721AUpgradeable.supportsInterface(_interfaceId) ||
            ERC2981Upgradeable.supportsInterface(_interfaceId) ||
            ERC165Upgradeable.supportsInterface(_interfaceId) ||
            SafePausableUpgradeable.supportsInterface(_interfaceId) ||
            super.supportsInterface(_interfaceId);
    }

    /// @dev Verifies that enough AVAX has been sent by the sender and refunds the extra tokens if any
    /// @param _price The price paid by the sender for minting NFTs
    function _refundIfOver(uint256 _price) internal {
        if (msg.value < _price) {
            revert Launchpeg__NotEnoughAVAX(msg.value);
        }
        if (msg.value > _price) {
            (bool success, ) = msg.sender.call{value: msg.value - _price}("");
            if (!success) {
                revert Launchpeg__TransferFailed();
            }
        }
    }

    /// @notice Returns the current phase
    /// @return phase Current phase
    function currentPhase() public view virtual override returns (Phase);

    /// @notice Reveals the next batch if the reveal conditions are met
    function revealNextBatch() external override isEOA whenNotPaused {
        if (address(batchReveal) == address(0)) {
            revert Launchpeg__BatchRevealDisabled();
        }
        if (!batchReveal.revealNextBatch(address(this), totalSupply())) {
            revert Launchpeg__RevealNextBatchNotAvailable();
        }
    }

    /// @notice Tells you if a batch can be revealed
    /// @return bool Whether reveal can be triggered or not
    /// @return uint256 The number of the next batch that will be revealed
    function hasBatchToReveal() external view override returns (bool, uint256) {
        if (address(batchReveal) == address(0)) {
            return (false, 0);
        }
        return batchReveal.hasBatchToReveal(address(this), totalSupply());
    }

    /// @dev Total supply including pre-mints
    function _totalSupplyWithPreMint() internal view returns (uint256) {
        return
            totalSupply() +
            amountMintedDuringPreMint -
            amountClaimedDuringPreMint;
    }

    /// @notice Number minted by user including pre-mints
    function numberMintedWithPreMint(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return _numberMinted(_owner) + userPendingPreMints(_owner);
    }

    /// @dev Adds pre-mint data to the pre-mint data set
    /// @param _sender address to mint NFTs to
    /// @param _quantity No. of NFTs to add to mint quantity
    function _addPreMint(address _sender, uint96 _quantity) private {
        PreMintDataSet storage set = _pendingPreMints;
        uint256 idx = set.indexes[_sender];
        // user exists in set
        if (idx != 0) {
            set.preMintDataArr[idx - 1].quantity += _quantity;
        } else {
            PreMintData memory preMintData = PreMintData({
                sender: _sender,
                quantity: _quantity
            });
            set.preMintDataArr.push(preMintData);
            set.indexes[_sender] = set.preMintDataArr.length;
        }
    }

    /// @dev Removes pre-mint data from the pre-mint data set
    /// @param _sender address to mint NFTs to
    /// @param _quantity No. of NFTs to remove from mint quantity
    function _removePreMint(address _sender, uint96 _quantity) private {
        PreMintDataSet storage set = _pendingPreMints;
        uint256 idx = set.indexes[_sender];
        // user exists in set
        if (idx != 0) {
            uint96 currQuantity = set.preMintDataArr[idx - 1].quantity;
            uint96 newQuantity = (currQuantity > _quantity)
                ? currQuantity - _quantity
                : 0;
            // remove from set
            if (newQuantity == 0) {
                uint256 toDeleteIdx = idx - 1;
                uint256 lastIdx = set.preMintDataArr.length - 1;
                if (toDeleteIdx != lastIdx) {
                    PreMintData memory lastPreMintData = set.preMintDataArr[
                        lastIdx
                    ];
                    set.preMintDataArr[toDeleteIdx] = lastPreMintData;
                    set.indexes[lastPreMintData.sender] = idx;
                }
                set.preMintDataArr.pop();
                delete set.indexes[_sender];
            } else {
                set.preMintDataArr[idx - 1].quantity = newQuantity;
            }
        }
    }

    /// @dev Mint in batches of up to `_maxBatchSize`. Used to control
    /// gas costs for subsequent transfers in ERC721A contracts.
    /// @param _sender address to mint NFTs to
    /// @param _quantity No. of NFTs to mint
    /// @param _maxBatchSize Max no. of NFTs to mint in a batch
    function _batchMint(
        address _sender,
        uint256 _quantity,
        uint256 _maxBatchSize
    ) private {
        uint256 numChunks = _quantity / _maxBatchSize;
        for (uint256 i; i < numChunks; ++i) {
            _mint(_sender, _maxBatchSize, "", false);
        }
        uint256 remainingQty = _quantity % _maxBatchSize;
        if (remainingQty != 0) {
            _mint(_sender, remainingQty, "", false);
        }
    }

    /// @dev Update the address that the contract will make OperatorFilter checks against. When set to the zero
    /// address, checks will be bypassed.
    /// @param _newRegistry The address of the new OperatorFilterRegistry
    function _updateOperatorFilterRegistryAddress(
        IOperatorFilterRegistry _newRegistry
    ) private {
        operatorFilterRegistry = _newRegistry;
        emit OperatorFilterRegistryUpdated(_newRegistry);
    }

    /// @dev Checks if the address (the operator) trying to transfer the NFT is allowed
    /// @param operator Address of the operator
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }

    /// @dev `setApprovalForAll` wrapper to prevent the sender to approve a non-allowed operator
    /// @param operator Address being approved
    /// @param approved Whether the operator is approved or not
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev `aprove` wrapper to prevent the sender to approve a non-allowed operator
    /// @param operator Address being approved
    /// @param tokenId TokenID approved
    function approve(address operator, uint256 tokenId)
        public
        override(ERC721AUpgradeable, IERC721Upgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev `transferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721AUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721AUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev `safeTransferFrom` wrapper to prevent a non-allowed operator to transfer the NFT
    /// @param from Address to transfer from
    /// @param to Address to transfer to
    /// @param tokenId TokenID to transfer
    /// @param data Data to send along with a safe transfer check
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        override(ERC721AUpgradeable, IERC721Upgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}