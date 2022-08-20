// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./EAS/TellerAS.sol";
import "./EAS/TellerASResolver.sol";

//must continue to use this so storage slots are not broken
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

// Interfaces
import "./interfaces/IMarketRegistry.sol";

// Libraries
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract MarketRegistry is
    IMarketRegistry,
    Initializable,
    Context,
    TellerASResolver
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /** Constant Variables **/

    uint256 public constant CURRENT_CODE_VERSION = 5;

    /* Storage Variables */

    struct Marketplace {
        address owner;
        string metadataURI;
        uint16 marketplaceFeePercent; // 10000 is 100%
        bool lenderAttestationRequired;
        EnumerableSet.AddressSet verifiedLendersForMarket;
        mapping(address => bytes32) lenderAttestationIds;
        uint32 paymentCycleDuration; //unix time
        uint32 paymentDefaultDuration; //unix time
        uint32 bidExpirationTime; //unix time
        bool borrowerAttestationRequired;
        EnumerableSet.AddressSet verifiedBorrowersForMarket;
        mapping(address => bytes32) borrowerAttestationIds;
        address feeRecipient;
    }

    bytes32 public lenderAttestationSchemaId;

    mapping(uint256 => Marketplace) internal markets;
    mapping(bytes32 => uint256) internal _uriToId;
    uint256 public marketCount;
    bytes32 private _attestingSchemaId;
    bytes32 public borrowerAttestationSchemaId;

    uint256 public version;

    mapping(uint256 => bool) private marketIsClosed;

    TellerAS public tellerAS;

    /* Modifiers */

    modifier ownsMarket(uint256 _marketId) {
        require(markets[_marketId].owner == _msgSender(), "Not the owner");
        _;
    }

    modifier withAttestingSchema(bytes32 schemaId) {
        _attestingSchemaId = schemaId;
        _;
        _attestingSchemaId = bytes32(0);
    }

    /* Events */

    event MarketCreated(address indexed owner, uint256 marketId);
    event SetMarketURI(uint256 marketId, string uri);
    event SetPaymentCycleDuration(uint256 marketId, uint32 duration);
    event SetPaymentDefaultDuration(uint256 marketId, uint32 duration);
    event SetBidExpirationTime(uint256 marketId, uint32 duration);
    event SetMarketFee(uint256 marketId, uint16 feePct);
    event LenderAttestation(uint256 marketId, address lender);
    event BorrowerAttestation(uint256 marketId, address borrower);
    event LenderRevocation(uint256 marketId, address lender);
    event BorrowerRevocation(uint256 marketId, address borrower);
    event MarketClosed(uint256 marketId);
    event LenderExitMarket(uint256 marketId, address lender);
    event BorrowerExitMarket(uint256 marketId, address borrower);
    event SetMarketOwner(uint256 marketId, address newOwner);
    event SetMarketFeeRecipient(uint256 marketId, address newRecipient);

    /* External Functions */

    function initialize(TellerAS _tellerAS) external initializer {
        tellerAS = _tellerAS;

        lenderAttestationSchemaId = tellerAS.getASRegistry().register(
            "(uint256 marketId, address lenderAddress)",
            this
        );
        borrowerAttestationSchemaId = tellerAS.getASRegistry().register(
            "(uint256 marketId, address borrowerAddress)",
            this
        );
    }

    /**
     * @notice Sets the new tellerAS on upgrade
     */
    function onUpgrade() external {
        require(
            version != CURRENT_CODE_VERSION,
            "Contract already upgraded to latest version!"
        );
        version = CURRENT_CODE_VERSION;
    }

    /**
     * @notice Creates a new market.
     * @param _initialOwner Address who will initially own the market.
     * @param _paymentCycleDuration Length of time in seconds before a bid's next payment is required to be made.
     * @param _paymentDefaultDuration Length of time in seconds before a loan is considered in default for non-payment.
     * @param _bidExpirationTime Length of time in seconds before pending bids expire.
     * @param _requireLenderAttestation Boolean that indicates if lenders require attestation to join market.
     * @param _requireBorrowerAttestation Boolean that indicates if borrowers require attestation to join market.
     * @param _uri URI string to get metadata details about the market.
     */
    function createMarket(
        address _initialOwner,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,
        uint16 _feePercent,
        bool _requireLenderAttestation,
        bool _requireBorrowerAttestation,
        string calldata _uri
    ) external {
        require(_initialOwner != address(0), "Invalid owner address");
        // Increment market ID counter
        uint256 marketId = ++marketCount;

        // Set the market owner
        markets[marketId].owner = _initialOwner;

        setMarketURI(marketId, _uri);
        setPaymentCycleDuration(marketId, _paymentCycleDuration);
        setPaymentDefaultDuration(marketId, _paymentDefaultDuration);
        setMarketFeePercent(marketId, _feePercent);
        setBidExpirationTime(marketId, _bidExpirationTime);

        // Check if market requires lender attestation to join
        if (_requireLenderAttestation) {
            markets[marketId].lenderAttestationRequired = true;
        }
        // Check if market requires borrower attestation to join
        if (_requireBorrowerAttestation) {
            markets[marketId].borrowerAttestationRequired = true;
        }

        emit MarketCreated(_initialOwner, marketId);
    }

    /**
     * @notice Closes a market so new bids cannot be added.
     * @param _marketId The market ID for the market to close.
     */

    function closeMarket(uint256 _marketId) public ownsMarket(_marketId) {
        if (!marketIsClosed[_marketId]) {
            marketIsClosed[_marketId] = true;

            emit MarketClosed(_marketId);
        }
    }

    /**
     * @notice Returns the status of a market being open or closed for new bids.
     * @param _marketId The market ID for the market to check.
     */
    function isMarketClosed(uint256 _marketId)
        public
        view
        override
        returns (bool)
    {
        return marketIsClosed[_marketId];
    }

    /**
     * @notice Adds a lender to a market.
     * @dev See {_attestStakeholder}.
     */
    function attestLender(
        uint256 _marketId,
        address _lenderAddress,
        uint256 _expirationTime
    ) external {
        _attestStakeholder(_marketId, _lenderAddress, _expirationTime, true);
    }

    /**
     * @notice Adds a lender to a market via delegated attestation.
     * @dev See {_attestStakeholderViaDelegation}.
     */
    function attestLender(
        uint256 _marketId,
        address _lenderAddress,
        uint256 _expirationTime,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _attestStakeholderViaDelegation(
            _marketId,
            _lenderAddress,
            _expirationTime,
            true,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Removes a lender from an market.
     * @dev See {_revokeStakeholder}.
     */
    function revokeLender(uint256 _marketId, address _lenderAddress) external {
        _revokeStakeholder(_marketId, _lenderAddress, true);
    }

    /**
     * @notice Removes a borrower from a market via delegated revocation.
     * @dev See {_revokeStakeholderViaDelegation}.
     */
    function revokeLender(
        uint256 _marketId,
        address _lenderAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _revokeStakeholderViaDelegation(
            _marketId,
            _lenderAddress,
            true,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Allows a lender to voluntarily leave a market.
     * @param _marketId The market ID to leave.
     */
    function lenderExitMarket(uint256 _marketId) external {
        // Remove lender address from market set
        bool response = markets[_marketId].verifiedLendersForMarket.remove(
            _msgSender()
        );
        if (response) {
            emit LenderExitMarket(_marketId, _msgSender());
        }
    }

    /**
     * @notice Adds a borrower to a market.
     * @dev See {_attestStakeholder}.
     */
    function attestBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint256 _expirationTime
    ) external {
        _attestStakeholder(_marketId, _borrowerAddress, _expirationTime, false);
    }

    /**
     * @notice Adds a borrower to a market via delegated attestation.
     * @dev See {_attestStakeholderViaDelegation}.
     */
    function attestBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint256 _expirationTime,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _attestStakeholderViaDelegation(
            _marketId,
            _borrowerAddress,
            _expirationTime,
            false,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Removes a borrower from an market.
     * @dev See {_revokeStakeholder}.
     */
    function revokeBorrower(uint256 _marketId, address _borrowerAddress)
        external
    {
        _revokeStakeholder(_marketId, _borrowerAddress, false);
    }

    /**
     * @notice Removes a borrower from a market via delegated revocation.
     * @dev See {_revokeStakeholderViaDelegation}.
     */
    function revokeBorrower(
        uint256 _marketId,
        address _borrowerAddress,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        _revokeStakeholderViaDelegation(
            _marketId,
            _borrowerAddress,
            false,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Allows a borrower to voluntarily leave a market.
     * @param _marketId The market ID to leave.
     */
    function borrowerExitMarket(uint256 _marketId) external {
        // Remove borrower address from market set
        bool response = markets[_marketId].verifiedBorrowersForMarket.remove(
            _msgSender()
        );
        if (response) {
            emit BorrowerExitMarket(_marketId, _msgSender());
        }
    }

    /**
     * @notice Verifies an attestation is valid.
     * @dev This function must only be called by the `attestLender` function above.
     * @param recipient Lender's address who is being attested.
     * @param schema The schema used for the attestation.
     * @param data Data the must include the market ID and lender's address
     * @param
     * @param attestor Market owner's address who signed the attestation.
     * @return Boolean indicating the attestation was successful.
     */
    function resolve(
        address recipient,
        bytes calldata schema,
        bytes calldata data,
        uint256, /* expirationTime */
        address attestor
    ) external payable override returns (bool) {
        bytes32 attestationSchemaId = keccak256(
            abi.encodePacked(schema, address(this))
        );
        (uint256 marketId, address lenderAddress) = abi.decode(
            data,
            (uint256, address)
        );
        return
            (_attestingSchemaId == attestationSchemaId &&
                recipient == lenderAddress &&
                attestor == markets[marketId].owner) ||
            attestor == address(this);
    }

    /**
     * @notice Transfers ownership of a marketplace.
     * @param _marketId The ID of a market.
     * @param _newOwner Address of the new market owner.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function transferMarketOwnership(uint256 _marketId, address _newOwner)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].owner = _newOwner;
        emit SetMarketOwner(_marketId, _newOwner);
    }

    /**
     * @notice Updates multiple market settings for a given market.
     * @param _marketId The ID of a market.
     * @param _paymentCycleDuration Delinquency duration for new loans
     * @param _paymentDefaultDuration Default duration for new loans
     * @param _bidExpirationTime Duration of time before a bid is considered out of date
     * @param _metadataURI A URI that points to a market's metadata.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function updateMarketSettings(
        uint256 _marketId,
        uint32 _paymentCycleDuration,
        uint32 _paymentDefaultDuration,
        uint32 _bidExpirationTime,       
        uint16 _feePercent,
        bool _borrowerAttestationRequired,
        bool _lenderAttestationRequired,
        string calldata _metadataURI     
    ) public ownsMarket(_marketId) {
        setMarketURI(_marketId, _metadataURI);
        setPaymentCycleDuration(_marketId, _paymentCycleDuration);
        setPaymentDefaultDuration(_marketId, _paymentDefaultDuration);
        setBidExpirationTime(_marketId, _bidExpirationTime);
        setMarketFeePercent(_marketId, _feePercent);

        markets[_marketId].borrowerAttestationRequired = _borrowerAttestationRequired;
        markets[_marketId].lenderAttestationRequired = _lenderAttestationRequired;
    }

    /**
     * @notice Sets the fee recipient address for a market.
     * @param _marketId The ID of a market.
     * @param _recipient Address of the new fee recipient.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketFeeRecipient(uint256 _marketId, address _recipient)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].feeRecipient = _recipient;
        emit SetMarketFeeRecipient(_marketId, _recipient);
    }

    /**
     * @notice Sets the metadata URI for a market.
     * @param _marketId The ID of a market.
     * @param _uri A URI that points to a market's metadata.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketURI(uint256 _marketId, string calldata _uri)
        public
        ownsMarket(_marketId)
    {
        // Check if URI is already used
        bytes32 uriId = keccak256(abi.encode(_uri));
        require(_uriToId[uriId] == 0, "non-unique market URI");

        // Update market counter & store reverse lookup
        _uriToId[uriId] = _marketId;
        markets[_marketId].metadataURI = _uri;

        emit SetMarketURI(_marketId, _uri);
    }

    /**
     * @notice Sets the duration of new loans for this market before they turn delinquent.
     * @notice Changing this value does not change the terms of existing loans for this market.
     * @param _marketId The ID of a market.
     * @param _duration Delinquency duration for new loans
     */
    function setPaymentCycleDuration(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].paymentCycleDuration = _duration;

        emit SetPaymentCycleDuration(_marketId, _duration);
    }

    /**
     * @notice Sets the duration of new loans for this market before they turn defaulted.
     * @notice Changing this value does not change the terms of existing loans for this market.
     * @param _marketId The ID of a market.
     * @param _duration Default duration for new loans
     */
    function setPaymentDefaultDuration(uint256 _marketId, uint32 _duration)
        public
        ownsMarket(_marketId)
    {
        markets[_marketId].paymentDefaultDuration = _duration;

        emit SetPaymentDefaultDuration(_marketId, _duration);
    }

    function setBidExpirationTime(uint256 marketId, uint32 duration)
        public
        ownsMarket(marketId)
    {
        markets[marketId].bidExpirationTime = duration;

        emit SetBidExpirationTime(marketId, duration);
    }

    /**
     * @notice Sets the fee for the market.
     * @param _marketId The ID of a market.
     * @param _newPercent The percentage fee in basis points.
     *
     * Requirements:
     * - The caller must be the current owner.
     */
    function setMarketFeePercent(uint256 _marketId, uint16 _newPercent)
        public
        ownsMarket(_marketId)
    {
        require(_newPercent >= 0 && _newPercent <= 10000, "invalid percent");
        markets[_marketId].marketplaceFeePercent = _newPercent;
        emit SetMarketFee(_marketId, _newPercent);
    }

    /**
     * @notice Gets the data associated with a market.
     * @param _marketId The ID of a market.
     */
    function getMarketData(uint256 _marketId)
        public
        view
        returns (
            address owner,
            uint32 paymentCycleDuration,
            uint32 paymentDefaultDuration,
            uint32 loanExpirationTime,
            string memory metadataURI,
            uint16 marketplaceFeePercent,
            bool lenderAttestationRequired
        )
    {
        return (
            markets[_marketId].owner,
            markets[_marketId].paymentCycleDuration,
            markets[_marketId].paymentDefaultDuration,
            markets[_marketId].bidExpirationTime,
            markets[_marketId].metadataURI,
            markets[_marketId].marketplaceFeePercent,
            markets[_marketId].lenderAttestationRequired
        );
    }

    /**
     * @notice Gets the attestation requirements for a given market.
     * @param _marketId The ID of the market.
     */
    function getMarketAttestationRequirements(uint256 _marketId)
        public
        view
        returns (
            bool lenderAttestationRequired,
            bool borrowerAttestationRequired
        )
    {
        return (
            markets[_marketId].lenderAttestationRequired,
            markets[_marketId].borrowerAttestationRequired
        );
    }

    /**
     * @notice Gets the address of a market's owner.
     * @param _marketId The ID of a market.
     * @return The address of a market's owner.
     */
    function getMarketOwner(uint256 _marketId)
        public
        view
        override
        returns (address)
    {
        return markets[_marketId].owner;
    }

    /**
     * @notice Gets the fee recipient of a market.
     * @param _marketId The ID of a market.
     * @return The address of a market's fee recipient.
     */
    function getMarketFeeRecipient(uint256 _marketId)
        public
        view
        override
        returns (address)
    {
        address recipient = markets[_marketId].feeRecipient;

        if (recipient == address(0)) {
            return markets[_marketId].owner;
        }

        return recipient;
    }

    /**
     * @notice Gets the metadata URI of a market.
     * @param _marketId The ID of a market.
     * @return URI of a market's metadata.
     */
    function getMarketURI(uint256 _marketId)
        public
        view
        override
        returns (string memory)
    {
        return markets[_marketId].metadataURI;
    }

    /**
     * @notice Gets the loan delinquent duration of a market.
     * @param _marketId The ID of a market.
     * @return Duration of a loan until it is delinquent.
     */
    function getPaymentCycleDuration(uint256 _marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[_marketId].paymentCycleDuration;
    }

    /**
     * @notice Gets the loan default duration of a market.
     * @param _marketId The ID of a market.
     * @return Duration of a loan repayment interval until it is default.
     */
    function getPaymentDefaultDuration(uint256 _marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[_marketId].paymentDefaultDuration;
    }

    function getBidExpirationTime(uint256 marketId)
        public
        view
        override
        returns (uint32)
    {
        return markets[marketId].bidExpirationTime;
    }

    /**
     * @notice Gets the marketplace fee in basis points
     * @param _marketId The ID of a market.
     * @return fee in basis points
     */
    function getMarketplaceFee(uint256 _marketId)
        public
        view
        override
        returns (uint16 fee)
    {
        return markets[_marketId].marketplaceFeePercent;
    }

    /**
     * @notice Checks if a lender has been attested and added to a market.
     * @param _marketId The ID of a market.
     * @param _lenderAddress Address to check.
     * @return isVerified_ Boolean indicating if a lender has been added to a market.
     * @return uuid_ Bytes32 representing the UUID of the lender.
     */
    function isVerifiedLender(uint256 _marketId, address _lenderAddress)
        public
        view
        override
        returns (bool isVerified_, bytes32 uuid_)
    {
        return
            _isVerified(
                _lenderAddress,
                markets[_marketId].lenderAttestationRequired,
                markets[_marketId].lenderAttestationIds,
                markets[_marketId].verifiedLendersForMarket
            );
    }

    /**
     * @notice Checks if a borrower has been attested and added to a market.
     * @param _marketId The ID of a market.
     * @param _borrowerAddress Address of the borrower to check.
     * @return isVerified_ Boolean indicating if a borrower has been added to a market.
     * @return uuid_ Bytes32 representing the UUID of the borrower.
     */
    function isVerifiedBorrower(uint256 _marketId, address _borrowerAddress)
        public
        view
        override
        returns (bool isVerified_, bytes32 uuid_)
    {
        return
            _isVerified(
                _borrowerAddress,
                markets[_marketId].borrowerAttestationRequired,
                markets[_marketId].borrowerAttestationIds,
                markets[_marketId].verifiedBorrowersForMarket
            );
    }

    /**
     * @notice Gets addresses of all attested lenders.
     * @param _marketId The ID of a market.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return Array of addresses that have been added to a market.
     */
    function getAllVerifiedLendersForMarket(
        uint256 _marketId,
        uint256 _page,
        uint256 _perPage
    ) public view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = markets[_marketId]
            .verifiedLendersForMarket;

        return _getStakeholdersForMarket(set, _page, _perPage);
    }

    /**
     * @notice Gets addresses of all attested borrowers.
     * @param _marketId The ID of the market.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return Array of addresses that have been added to a market.
     */
    function getAllVerifiedBorrowersForMarket(
        uint256 _marketId,
        uint256 _page,
        uint256 _perPage
    ) public view returns (address[] memory) {
        EnumerableSet.AddressSet storage set = markets[_marketId]
            .verifiedBorrowersForMarket;
        return _getStakeholdersForMarket(set, _page, _perPage);
    }

    /**
     * @notice Gets addresses of all attested relevant stakeholders.
     * @param _set The stored set of stakeholders to index from.
     * @param _page Page index to start from.
     * @param _perPage Number of items in a page to return.
     * @return stakeholders_ Array of addresses that have been added to a market.
     */
    function _getStakeholdersForMarket(
        EnumerableSet.AddressSet storage _set,
        uint256 _page,
        uint256 _perPage
    ) internal view returns (address[] memory stakeholders_) {
        uint256 len = _set.length();

        uint256 start = _page * _perPage;
        if (start <= len) {
            uint256 end = start + _perPage;
            // Ensure we do not go out of bounds
            if (end > len) {
                end = len;
            }

            stakeholders_ = new address[](end - start);
            for (uint256 i = start; i < end; i++) {
                stakeholders_[i] = _set.at(i);
            }
        }
    }

    /* Internal Functions */

    /**
     * @notice Sets the metadata URI for a market.
     * @param _marketId The ID of a market.
     * @param _uri A URI that points to a market's metadata.
     */
    function _setMarketUri(uint256 _marketId, string calldata _uri) internal {
        require(_marketId > 0, "Market ID 0");

        // Check if URI is already used
        bytes32 uriId = keccak256(abi.encode(_uri));
        require(_uriToId[uriId] == 0, "non-unique market URI");

        // Update market counter & store reverse lookup
        _uriToId[uriId] = _marketId;
        markets[_marketId].metadataURI = _uri;

        emit SetMarketURI(_marketId, _uri);
    }

    /**
     * @notice Adds a stakeholder (lender or borrower) to a market.
     * @param _marketId The market ID to add a borrower to.
     * @param _stakeholderAddress The address of the stakeholder to add to the market.
     * @param _expirationTime The expiration time of the attestation.
     * @param _expirationTime The expiration time of the attestation.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _attestStakeholder(
        uint256 _marketId,
        address _stakeholderAddress,
        uint256 _expirationTime,
        bool _isLender
    )
        internal
        withAttestingSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        require(
            _msgSender() == markets[_marketId].owner,
            "Not the market owner"
        );

        // Submit attestation for borrower to join a market
        bytes32 uuid = tellerAS.attest(
            _stakeholderAddress,
            _attestingSchemaId, // set by the modifier
            _expirationTime,
            0,
            abi.encode(_marketId, _stakeholderAddress)
        );
        _attestStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            uuid,
            _isLender
        );
    }

    /**
     * @notice Adds a stakeholder (lender or borrower) to a market via delegated attestation.
     * @dev The signature must match that of the market owner.
     * @param _marketId The market ID to add a lender to.
     * @param _stakeholderAddress The address of the lender to add to the market.
     * @param _expirationTime The expiration time of the attestation.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @param _v Signature value
     * @param _r Signature value
     * @param _s Signature value
     */
    function _attestStakeholderViaDelegation(
        uint256 _marketId,
        address _stakeholderAddress,
        uint256 _expirationTime,
        bool _isLender,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        internal
        withAttestingSchema(
            _isLender ? lenderAttestationSchemaId : borrowerAttestationSchemaId
        )
    {
        // NOTE: block scope to prevent stack too deep!
        bytes32 uuid;
        {
            bytes memory data = abi.encode(_marketId, _stakeholderAddress);
            address attestor = markets[_marketId].owner;
            // Submit attestation for stakeholder to join a market (attestation must be signed by market owner)
            uuid = tellerAS.attestByDelegation(
                _stakeholderAddress,
                _attestingSchemaId, // set by the modifier
                _expirationTime,
                0,
                data,
                attestor,
                _v,
                _r,
                _s
            );
        }
        _attestStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            uuid,
            _isLender
        );
    }

    /**
     * @notice Adds a stakeholder (borrower/lender) to a market.
     * @param _marketId The market ID to add a stakeholder to.
     * @param _stakeholderAddress The address of the stakeholder to add to the market.
     * @param _uuid The UUID of the attestation created.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _attestStakeholderVerification(
        uint256 _marketId,
        address _stakeholderAddress,
        bytes32 _uuid,
        bool _isLender
    ) internal {
        if (_isLender) {
            // Store the lender attestation ID for the market ID
            markets[_marketId].lenderAttestationIds[
                _stakeholderAddress
            ] = _uuid;
            // Add lender address to market set
            markets[_marketId].verifiedLendersForMarket.add(
                _stakeholderAddress
            );

            emit LenderAttestation(_marketId, _stakeholderAddress);
        } else {
            // Store the lender attestation ID for the market ID
            markets[_marketId].borrowerAttestationIds[
                _stakeholderAddress
            ] = _uuid;
            // Add lender address to market set
            markets[_marketId].verifiedBorrowersForMarket.add(
                _stakeholderAddress
            );

            emit BorrowerAttestation(_marketId, _stakeholderAddress);
        }
    }

    /**
     * @notice Removes a stakeholder from an market.
     * @dev The caller must be the market owner.
     * @param _marketId The market ID to remove the borrower from.
     * @param _stakeholderAddress The address of the borrower to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     */
    function _revokeStakeholder(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender
    ) internal {
        require(
            _msgSender() == markets[_marketId].owner,
            "Not the market owner"
        );

        bytes32 uuid = _revokeStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            _isLender
        );
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        tellerAS.revoke(uuid);
    }

    /**
     * @notice Removes a stakeholder from an market via delegated revocation.
     * @param _marketId The market ID to remove the borrower from.
     * @param _stakeholderAddress The address of the borrower to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @param _v Signature value
     * @param _r Signature value
     * @param _s Signature value
     */
    function _revokeStakeholderViaDelegation(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        bytes32 uuid = _revokeStakeholderVerification(
            _marketId,
            _stakeholderAddress,
            _isLender
        );
        // NOTE: Disabling the call to revoke the attestation on EAS contracts
        //        address attestor = markets[_marketId].owner;
        //        tellerAS.revokeByDelegation(uuid, attestor, _v, _r, _s);
    }

    /**
     * @notice Removes a stakeholder (borrower/lender) from a market.
     * @param _marketId The market ID to remove the lender from.
     * @param _stakeholderAddress The address of the stakeholder to remove from the market.
     * @param _isLender Boolean indicating if the stakeholder is a lender. Otherwise it is a borrower.
     * @return uuid_ The ID of the previously verified attestation.
     */
    function _revokeStakeholderVerification(
        uint256 _marketId,
        address _stakeholderAddress,
        bool _isLender
    ) internal returns (bytes32 uuid_) {
        if (_isLender) {
            uuid_ = markets[_marketId].lenderAttestationIds[
                _stakeholderAddress
            ];
            // Remove lender address from market set
            markets[_marketId].verifiedLendersForMarket.remove(
                _stakeholderAddress
            );

            emit LenderRevocation(_marketId, _stakeholderAddress);
        } else {
            uuid_ = markets[_marketId].borrowerAttestationIds[
                _stakeholderAddress
            ];
            // Remove borrower address from market set
            markets[_marketId].verifiedBorrowersForMarket.remove(
                _stakeholderAddress
            );

            emit BorrowerRevocation(_marketId, _stakeholderAddress);
        }
    }

    /**
     * @notice Checks if a stakeholder has been attested and added to a market.
     * @param _stakeholderAddress Address of the stakeholder to check.
     * @param _attestationRequired Stored boolean indicating if attestation is required for the stakeholder class.
     * @param _stakeholderAttestationIds Mapping of attested Ids for the stakeholder class.
     */
    function _isVerified(
        address _stakeholderAddress,
        bool _attestationRequired,
        mapping(address => bytes32) storage _stakeholderAttestationIds,
        EnumerableSet.AddressSet storage _verifiedStakeholderForMarket
    ) internal view returns (bool isVerified_, bytes32 uuid_) {
        if (_attestationRequired) {
            isVerified_ =
                _verifiedStakeholderForMarket.contains(_stakeholderAddress) &&
                tellerAS.isAttestationActive(
                    _stakeholderAttestationIds[_stakeholderAddress]
                );
            uuid_ = _stakeholderAttestationIds[_stakeholderAddress];
        } else {
            isVerified_ = true;
        }
    }
}