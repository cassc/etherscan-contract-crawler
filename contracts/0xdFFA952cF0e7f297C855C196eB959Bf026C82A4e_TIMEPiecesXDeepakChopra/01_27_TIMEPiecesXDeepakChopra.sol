// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./TIME721Phasable.sol";
import "./TIMEAdmin.sol";

error TIMEDigitalArt__ContractNotAllowed();
error TIMEDigitalArt__ProxyContractNotAllowed();

contract TIMEPiecesXDeepakChopra is TIMEAdmin, TIME721Phasable, ReentrancyGuard {
    // Variables
    string private _baseUri = "";
    bool private _isRevealed;

    // Constructor
    constructor(
        string memory name,
        string memory tokenSymbol,
        uint256 _maxSupply
    ) TIME721Phasable(name, tokenSymbol, _maxSupply) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FINANCE_ROLE, _msgSender());
        _pause();
    }

    // Modifier
    /**
     * @dev Modifier to make a function NOT callable by contracts.
     */
    modifier notContract() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        if (size != 0) {
            revert TIMEDigitalArt__ContractNotAllowed();
        }
        _;
    }

    // Mint Functions
    function mint(uint256 _phase, uint256 _quantity)
        public
        payable
        notContract
        whenDistributionNotPaused
        nonReentrant
    {
        _mint(_phase, _quantity);
    }

    function mintWithSignature(
        uint256 _phase,
        uint256 _quantity,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) public payable notContract whenDistributionNotPaused nonReentrant {
        _mintWithSignature(_phase, _quantity, _maxQuantity, _signature);
    }

    function mintWithPass(
        uint256 _phase,
        uint256 _passId,
        uint256 _maxQuantity,
        bytes calldata _signature
    ) public payable notContract whenDistributionNotPaused nonReentrant {
        _mintWithPass(_phase, _passId, _maxQuantity, _signature);
    }

    /**
     * @dev Airdrops the specified `_quantity` of tokens to a list of addresses.
     */
    function distributeTokens(address[] memory _addresses, uint256 _quantity)
        external
        whenDistributionNotPaused
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _distributeTokens(_addresses, _quantity);
    }

    // Admin Methods
    /**
     * @dev Sets price for specified distribution phase.
     *
     * Requirements:
     *
     *  - Only admin users can access this method
     *
     * Emits a {PhasePriceUpdated} event.
     */
    function setPriceForPhase(uint256 _phase, uint256 _price)
        public
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setPriceForPhase(_phase, _price);
    }

    /**
     * @dev Sets total number of tokens allowed per wallet for specified distribution phase.
     *
     * Requirements:
     *
     *  - Only admin users can access this method
     *
     * Emits a {PhaseAllowedQuantityUpdated} event.
     */
    function setAllowedQuantityForPhase(uint256 _phase, uint256 _quantity)
        public
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setAllowedQuantityForPhase(_phase, _quantity);
    }

    /**
     * @dev Sets the start and end time for the specified distribution phase.
     *
     * Requirements:
     *
     *  - Only admin users can access this method
     *
     * Emits a {PhaseMintTimeUpdated} event.
     */
    function setMintTimeForPhase(
        uint256 _phase,
        uint256 _startTime,
        uint256 _endTime
    ) public whenNotFrozen onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMintTimeForPhase(_phase, _startTime, _endTime);
    }

    /**
     * @dev Sets the Merkle Tree Root for specified distribution phase.
     *
     * Requirements:
     *
     *  - Only admin users can access this method
     *
     * Emits a {PhaseMerkleRootUpdated} event.
     */
    function setMerkleRootForPhase(uint256 _phase, bytes32 _merkleRoot)
        public
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMerkleRootForPhase(_phase, _merkleRoot);
    }

    /**
     * @dev Sets the signerAddress for specified distribution phase.
     *
     * Requirements:
     *
     *  - Only admin users can access this method
     *
     * Emits a {PhaseSignerAddressUpdated} event.
     */
    function setSignerAddressForPhase(uint256 _phase, address _signerAddress)
        public
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setSignerAddressForPhase(_phase, _signerAddress);
    }

    /**
     * @dev Build an entire phase in one call.
     *
     * Requirements:
     *
     *  - Only admin users can access this method
     */
    function buildPhase(
        uint256 _phase,
        uint256 _price,
        uint256 _quantity,
        uint256 _startTime,
        uint256 _endTime,
        address _signerAddress,
        bytes32 _merkleRoot
    ) external whenNotFrozen onlyRole(DEFAULT_ADMIN_ROLE) {
        setPriceForPhase(_phase, _price);
        setMintTimeForPhase(_phase, _startTime, _endTime);
        setAllowedQuantityForPhase(_phase, _quantity);
        if (_signerAddress != address(0)) {
            setSignerAddressForPhase(_phase, _signerAddress);
        }
        if (_merkleRoot != bytes32(0)) {
            setMerkleRootForPhase(_phase, _merkleRoot);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(TIMEAdmin, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Token URI
    /**
     * @dev Sets the baseURI for all tokens of a collection.
     * Used for mass update of token metadata during reveal.
     */
    function setBaseURI(string calldata _newBaseUri)
        external
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        setBaseURIWithRevealFlag(_newBaseUri, false);
    }

    /**
     * @dev Sets the baseURI for all tokens of a collection.
     * And set the `_isRevealed` state.
     */
    function setBaseURIWithRevealFlag(
        string calldata _newBaseUri,
        bool _isReveal
    ) public whenNotFrozen onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseUri = _newBaseUri;
        if (_isReveal && !isRevealed()) _isRevealed = true;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /**
     * @dev Returns the `_isRevealed` state, for internal TIME Sites admin view.
     */
    function isRevealed()
        public
        view
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        return _isRevealed;
    }

    // Getter / Setter
    /**
     * @dev Sets total allowed minting quantity for each wallet.
     */
    function setTotalAllowedQuantity(uint256 _allowedQty)
        external
        virtual
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _totalAllowedQuantity = _allowedQty;
    }

    /**
     * @dev Sets total allowed minting quantity for each wallet.
     */
    function setMintPassAddress(address _mintPassAddress)
        external
        virtual
        whenNotFrozen
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _passAddress = _mintPassAddress;
    }
}