// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './Ownable_1_0_0.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';
import './opensea-operator-filter/OperatorFilterer.sol';

contract HyperMintERC721A_2_2_0 is ERC721ABurnable, Ownable, OperatorFilterer {
    using SafeERC20 for IERC20;

    /* ================= CUSTOM ERRORS ================= */
    error NewSupplyTooLow();
    error MaxSupplyExceeded();
    error SignatureExpired();
    error NotAuthorised();
    error BuyDisabled();
    error InsufficientPaymentValue();
    error PublicSaleClosed();
    error SaleClosed();
    error MaxPerAddressExceeded();
    error MaxPerTransactionExceeded();
    error NonExistentToken();
    error ContractCallBlocked();
    error ImmutableRecoveryAddress();
    error TransfersDisabled();

    /* ================= STATE VARIABLES ================= */

    // ============== Structs ==============
    struct GeneralConfig {
        string name;
        string symbol;
        string contractMetadataUrl;
        string tokenMetadataUrl;
        bool allowBuy;
        bool allowPublicTransfer;
        bool enableOpenSeaOperatorFilterRegistry;
        uint256 publicSaleDate;
        uint256 saleCloseDate;
        uint256 primaryRoyaltyFee;
        uint256 secondaryRoyaltyFee;
    }

    struct Addresses {
        address recoveryAddress;
        address collectionOwnerAddress;
        address authorisationAddress;
        address purchaseTokenAddress;
        address managerPrimaryRoyaltyAddress;
        address customerPrimaryRoyaltyAddress;
        address secondaryRoyaltyAddress;
    }

    struct TokenConfig {
        uint256 price;
        uint256 maxSupply;
        uint256 maxPerTransaction;
    }

    // ========= Immutable Storage =========
    uint256 internal constant BASIS_POINTS = 10000;

    // ========== Mutable Storage ==========
    string public constant version = '2.2.0';

    GeneralConfig public generalConfig;
    TokenConfig public tokenConfig;
    Addresses public addresses;

    /* =================== CONSTRUCTOR =================== */
    /// @param _generalConfig settings for the contract
    /// @param _tokenConfig settings for tokens minted by the contract
    /// @param _addresses a collection of addresses
    constructor(
        GeneralConfig memory _generalConfig,
        TokenConfig memory _tokenConfig,
        Addresses memory _addresses
    )
        ERC721A('', '')
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), // default filter by OS
            true // subscribe to the filter list
        )
    {
        _transferOwnership(_addresses.collectionOwnerAddress);
        generalConfig = _generalConfig;
        tokenConfig = _tokenConfig;
        addresses = _addresses;
    }

    /* ====================== Views ====================== */
    function name()
        public
        view
        override
        returns (string memory collectionName)
    {
        collectionName = generalConfig.name;
    }

    function symbol()
        public
        view
        override
        returns (string memory collectionSymbol)
    {
        collectionSymbol = generalConfig.symbol;
    }

    function supply() public view returns (uint256 _supply) {
        _supply = _totalMinted();
    }

    function totalMinted(address addr) public view returns (uint256 numMinted) {
        numMinted = _numberMinted(addr);
    }

    function contractURI() public view virtual returns (string memory uri) {
        uri = generalConfig.contractMetadataUrl;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        if (!_exists(_tokenId)) revert NonExistentToken();
        uri = string(
            abi.encodePacked(
                generalConfig.tokenMetadataUrl,
                _toString(_tokenId)
            )
        );
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address royaltyAddress, uint256 royaltyAmount)
    {
        /// @dev secondary royalty to be paid out by the marketplace
        ///      to the splitter contract
        royaltyAddress = addresses.secondaryRoyaltyAddress;
        royaltyAmount =
            (_salePrice * generalConfig.secondaryRoyaltyFee) /
            BASIS_POINTS;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool result)
    {
        result = (_interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId));
    }

    /* ================ MUTATIVE FUNCTIONS ================ */

    // ============ Restricted =============
    function setNameAndSymbol(
        string calldata _newName,
        string calldata _newSymbol
    ) external onlyContractManager {
        generalConfig.name = _newName;
        generalConfig.symbol = _newSymbol;
    }

    function setMetadataURIs(
        string calldata _contractURI,
        string calldata _tokenURI
    ) external onlyContractManager {
        generalConfig.contractMetadataUrl = _contractURI;
        generalConfig.tokenMetadataUrl = _tokenURI;
    }

    function setDates(uint256 _publicSale, uint256 _saleClosed)
        external
        onlyContractManager
    {
        generalConfig.publicSaleDate = _publicSale;
        generalConfig.saleCloseDate = _saleClosed;
    }

    function setTokenConfig(
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxPerTransaction
    ) external onlyContractManager {
        if (totalSupply() > _maxSupply) revert NewSupplyTooLow();

        tokenConfig.price = _price;
        tokenConfig.maxSupply = _maxSupply;
        tokenConfig.maxPerTransaction = _maxPerTransaction;
    }

    function setAddresses(Addresses calldata _addresses)
        external
        onlyContractManager
    {
        if (_addresses.recoveryAddress != addresses.recoveryAddress)
            revert ImmutableRecoveryAddress();

        if (
            addresses.collectionOwnerAddress !=
            _addresses.collectionOwnerAddress
        ) {
            _transferOwnership(_addresses.collectionOwnerAddress);
        }

        addresses = _addresses;
    }

    function setAllowBuy(bool _allowBuy) external onlyContractManager {
        generalConfig.allowBuy = _allowBuy;
    }

    function setAllowPublicTransfer(bool _allowPublicTransfer)
        external
        onlyContractManager
    {
        generalConfig.allowPublicTransfer = _allowPublicTransfer;
    }

    function setEnableOpenSeaOperatorFilterRegistry(bool _enable) external onlyContractManager {
        generalConfig.enableOpenSeaOperatorFilterRegistry = _enable;
    }

    function setRoyalty(uint256 _primaryFee, uint256 _secondaryFee)
        external
        onlyContractManager
    {
        generalConfig.primaryRoyaltyFee = _primaryFee;
        generalConfig.secondaryRoyaltyFee = _secondaryFee;
    }

    // ============== Minting ==============
    function mintBatch(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) external onlyContractManager nonContract {
        uint256 length = _accounts.length;

        for (uint256 i = 0; i < length; ) {
            address account = _accounts[i];
            uint256 amount = _amounts[i];

            if (supply() + amount > tokenConfig.maxSupply)
                revert MaxSupplyExceeded();

            _mint(account, amount);

            unchecked {
                i += 1;
            }
        }
    }

    // ================ Buy ================
    function buyAuthorised(
        uint256 _amount,
        uint256 _totalPrice,
        uint256 _maxPerAddress,
        uint256 _expires,
        bytes calldata _signature
    ) external payable buyAllowed nonContract {
        if (block.timestamp >= _expires) revert SignatureExpired();

        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                _amount,
                _totalPrice,
                _maxPerAddress,
                _expires
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        if (
            ECDSA.recover(message, _signature) != addresses.authorisationAddress
        ) revert NotAuthorised();

        if (_maxPerAddress != 0) {
            if (_numberMinted(msg.sender) + _amount > _maxPerAddress)
                revert MaxPerAddressExceeded();
        }

        _buy(_amount, _totalPrice);
    }

    function buy(uint256 _amount) external payable buyAllowed nonContract {
        if (
            generalConfig.publicSaleDate == 0 ||
            block.timestamp < generalConfig.publicSaleDate
        ) revert PublicSaleClosed();

        uint256 totalPrice = tokenConfig.price * _amount;
        _buy(_amount, totalPrice);
    }

    function _buy(uint256 _amount, uint256 _totalPrice) internal {
        if (generalConfig.saleCloseDate != 0) {
            if (block.timestamp >= generalConfig.saleCloseDate)
                revert SaleClosed();
        }

        if (_totalMinted() + _amount > tokenConfig.maxSupply)
            revert MaxSupplyExceeded();

        if (tokenConfig.maxPerTransaction != 0) {
            if (_amount > tokenConfig.maxPerTransaction)
                revert MaxPerTransactionExceeded();
        }

        uint256 royaltyAmount = (_totalPrice *
            generalConfig.primaryRoyaltyFee) / BASIS_POINTS;

        if (addresses.purchaseTokenAddress != address(0)) {
            IERC20 token = IERC20(addresses.purchaseTokenAddress);
            /// @dev primary royalty cut for HyperMint
            token.safeTransferFrom(
                msg.sender,
                addresses.managerPrimaryRoyaltyAddress,
                royaltyAmount
            );
            /// @dev primary sale (i.e. minting revenue) for customer (or its payees)
            token.safeTransferFrom(
                msg.sender,
                addresses.customerPrimaryRoyaltyAddress,
                _totalPrice - royaltyAmount
            );
        } else {
            if (msg.value < _totalPrice) revert InsufficientPaymentValue();
            /// @dev primary royalty cut for HyperMint
            payable(addresses.managerPrimaryRoyaltyAddress).transfer(
                royaltyAmount
            );
            /// @dev primary sale (i.e. minting revenue) for customer (or its payees)
            payable(addresses.customerPrimaryRoyaltyAddress).transfer(
                _totalPrice - royaltyAmount
            );
        }

        /// @dev mint tokens
        _mint(msg.sender, _amount);
    }

    // ================ Transfers ================
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    )
        internal
        override
        transferAllowed(from, to)
        onlyAllowedOperator(from, generalConfig.enableOpenSeaOperatorFilterRegistry)
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function transferAuthorised(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _expires,
        bytes calldata _signature
    ) external nonContract {
        if (block.timestamp >= _expires) revert SignatureExpired();

        bytes32 hash = keccak256(
            abi.encodePacked(
                address(this),
                msg.sender,
                _from,
                _to,
                _tokenId,
                _expires
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        if (
            ECDSA.recover(message, _signature) != addresses.authorisationAddress
        ) revert NotAuthorised();

        super.safeTransferFrom(_from, _to, _tokenId);
    }

    // ============= Ownership =============
    function recoverContract() external {
        if (msg.sender != addresses.recoveryAddress) revert NotAuthorised();
        _transferContractManager(addresses.recoveryAddress);
    }

    function _startTokenId() internal pure override returns (uint256 tokenId) {
        tokenId = 1;
    }

    /* ==================== MODIFIERS ===================== */
    modifier buyAllowed() {
        if (!generalConfig.allowBuy) revert BuyDisabled();
        _;
    }

    /// @dev this eliminates the possibility of being called
    ///      from a contract
    modifier nonContract() {
        if (tx.origin != msg.sender) revert ContractCallBlocked();
        _;
    }

    modifier transferAllowed(address from, address to) {
        bool isMinting = from == address(0);
        bool isBurning = to == address(0);
        bool isContractManager = from == this.contractManager();
        bool isTransferAuthorised = msg.sig == this.transferAuthorised.selector;

        if (
            !isMinting &&
            !isContractManager &&
            !isBurning &&
            !isTransferAuthorised
        ) {
            if (!generalConfig.allowPublicTransfer) revert TransfersDisabled();
        }
        _;
    }
}