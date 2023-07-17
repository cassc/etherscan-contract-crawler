// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './Ownable_1_0_0.sol';
import 'erc721a/contracts/extensions/ERC721ABurnable.sol';

contract HyperMintERC721A_2_0_0 is ERC721ABurnable, Ownable {
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

    /* ================= STATE VARIABLES ================= */

    // ============== Structs ==============
    struct Addresses {
        address recoveryAddress;
        address collectionOwnerAddress;
        address authorisationAddress;
        address purchaseTokenAddress;
        address managerPrimaryRoyaltyAddress;
        address customerPrimaryRoyaltyAddress;
        address secondaryRoyaltyAddress;
    }

    struct TokenInfo {
        uint256 price;
        uint256 supply;
        uint256 maxSupply;
        uint256 maxPerTransaction;
    }

    // ========= Immutable Storage =========
    uint256 internal constant BASIS_POINTS = 10000;

    // ========== Mutable Storage ==========
    string public constant version = '2.0.0';

    /// @dev token info
    string _name;
    string _symbol;
    uint256 public price;
    uint256 public maxSupply;
    /// @dev only apply to public sale
    uint256 public maxPerTransaction;

    /// @dev metadata info
    string public contractURI;
    string public tokenMetadataURI;

    /// @dev toggle for api mints
    bool public allowBuy;

    /// @dev sale dates
    uint256 public publicSaleDate;
    uint256 public saleCloseDate;

    /// @dev royalty fees
    uint256 public primaryRoyaltyFee;
    uint256 public secondaryRoyaltyFee;

    Addresses public addresses;

    /* =================== CONSTRUCTOR =================== */
    /// @notice Creates a new NFT contract
    /// @param __name token name
    /// @param __symbol token symbol
    /// @param _price token price
    /// @param _maxSupply token max supply
    /// @param _allowBuy toggle to enable/disable buying
    /// @param _maxPerTransaction max amount an address can buy
    /// @param _addresses a collection of addresses
    constructor(
        string memory __name,
        string memory __symbol,
        uint256 _price,
        uint256 _maxSupply,
        string memory _contractMetadataURI,
        string memory _tokenMetadataURI,
        bool _allowBuy,
        uint256 _maxPerTransaction,
        Addresses memory _addresses
    ) ERC721A('', '') {
        _transferOwnership(_addresses.collectionOwnerAddress);

        _name = __name;
        _symbol = __symbol;
        price = _price;
        maxSupply = _maxSupply;
        allowBuy = _allowBuy;
        tokenMetadataURI = _tokenMetadataURI;
        contractURI = _contractMetadataURI;
        maxPerTransaction = _maxPerTransaction;
        addresses = _addresses;
    }

    /* ====================== Views ====================== */
    function name() public view override returns (string memory tokenName) {
        tokenName = _name;
    }

    function totalMinted(address addr) public view returns (uint256 numMinted) {
        numMinted = _numberMinted(addr);
    }

    function symbol() public view override returns (string memory tokenSymbol) {
        tokenSymbol = _symbol;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        if (!_exists(_tokenId)) revert NonExistentToken();
        uri = string(abi.encodePacked(tokenMetadataURI, _toString(_tokenId)));
    }

    function getTokenInfo() external view returns (TokenInfo memory tokenInfo) {
        tokenInfo = TokenInfo(
            price,
            totalSupply(),
            maxSupply,
            maxPerTransaction
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
        royaltyAmount = (_salePrice * secondaryRoyaltyFee) / BASIS_POINTS;
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
        _name = _newName;
        _symbol = _newSymbol;
    }

    function setMetadataURIs(
        string calldata _contractURI,
        string calldata _tokenURI
    ) external onlyContractManager {
        contractURI = _contractURI;
        tokenMetadataURI = _tokenURI;
    }

    function setDates(uint256 _publicSale, uint256 _saleClosed)
        external
        onlyContractManager
    {
        publicSaleDate = _publicSale;
        saleCloseDate = _saleClosed;
    }

    function setTokenData(
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxPerTransaction
    ) external onlyContractManager {
        if (totalSupply() > _maxSupply) revert NewSupplyTooLow();

        price = _price;
        maxSupply = _maxSupply;
        maxPerTransaction = _maxPerTransaction;
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
        allowBuy = _allowBuy;
    }

    function setRoyalty(uint256 _primaryFee, uint256 _secondaryFee)
        external
        onlyContractManager
    {
        primaryRoyaltyFee = _primaryFee;
        secondaryRoyaltyFee = _secondaryFee;
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

            if (_totalMinted() + amount > maxSupply) revert MaxSupplyExceeded();

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
        if (publicSaleDate == 0 || block.timestamp < publicSaleDate) revert PublicSaleClosed();

        uint256 totalPrice = price * _amount;
        _buy(_amount, totalPrice);
    }

    function _buy(uint256 _amount, uint256 _totalPrice) internal {
        if (saleCloseDate != 0) {
            if (block.timestamp >= saleCloseDate) revert SaleClosed();
        }
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyExceeded();
        if (maxPerTransaction != 0) {
            if (_amount > maxPerTransaction) revert MaxPerTransactionExceeded();
        }

        uint256 royaltyAmount = (_totalPrice * primaryRoyaltyFee) /
            BASIS_POINTS;

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
        if (!allowBuy) revert BuyDisabled();
        _;
    }

    /// @dev this eliminates the possibility of being called
    ///      from a contract
    modifier nonContract() {
        if (tx.origin != msg.sender) revert ContractCallBlocked();
        _;
    }
}