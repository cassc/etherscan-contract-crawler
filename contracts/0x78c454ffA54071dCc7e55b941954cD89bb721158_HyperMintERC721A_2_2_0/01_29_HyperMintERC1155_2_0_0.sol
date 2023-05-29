// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './Ownable_1_0_0.sol';

contract HyperMintERC1155_2_0_0 is ERC1155Burnable, Ownable {
    using SafeERC20 for IERC20;

    /* ================= CUSTOM ERRORS ================= */
    error NewSupplyTooLow();
    error ArrayLengthMismatch();
    error MaxSupplyExceeded();
    error SignatureExpired();
    error NotAuthorised();
    error BuyDisabled();
    error InsufficientPaymentValue();
    error PublicSaleClosed();
    error SaleClosed();
    error MaxPerTransactionsExceeded();
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
        uint256[] prices;
        uint256[] supplies;
        uint256[] totalSupplies;
        uint256[] maxPerTransactions;
    }

    // ========= Immutable Storage =========
    uint256 internal constant BASIS_POINTS = 10000;

    // ========== Mutable Storage ==========
    string public constant version = '2.0.0';

    /// @dev token info
    string public name;
    string public symbol;
    uint256[] public prices;
    uint256[] public supplies;
    uint256[] public totalSupplies;
    uint256[] public maxPerTransactions;

    /// @dev metadata info
    string public contractURI;

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
    /// @param _name token name
    /// @param _symbol token symbol
    /// @param _contractMetadataURI contract metadata uri
    /// @param _allowBuy toggle to enable/disable buying
    /// @param _addresses a collection of addresses
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _contractMetadataURI,
        string memory _tokenMetadataURI,
        bool _allowBuy,
        Addresses memory _addresses
    ) ERC1155('') {
        _transferOwnership(_addresses.collectionOwnerAddress);

        name = _name;
        symbol = _symbol;
        allowBuy = _allowBuy;
        _setURI(_tokenMetadataURI);
        contractURI = _contractMetadataURI;
        addresses = _addresses;
    }

    /* ====================== Views ====================== */
    function getTokenInfo() external view returns (TokenInfo memory tokenInfo) {
        tokenInfo = TokenInfo(
            prices,
            supplies,
            totalSupplies,
            maxPerTransactions
        );
    }

    function totalSupply(uint256 _tokenId)
        public
        view
        returns (uint256 _totalSupply)
    {
        _totalSupply = totalSupplies[_tokenId];
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
        override(ERC1155)
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
        name = _newName;
        symbol = _newSymbol;
    }

    function setMetadataURIs(
        string calldata _contractURI,
        string calldata _tokenURI
    ) external onlyContractManager {
        contractURI = _contractURI;
        _setURI(_tokenURI);
    }

    function setDates(uint256 _publicSale, uint256 _saleClosed)
        external
        onlyContractManager
    {
        publicSaleDate = _publicSale;
        saleCloseDate = _saleClosed;
    }

    function setTokenData(
        uint256 _id,
        uint256 _price,
        uint256 _supply,
        uint256 _maxPerAddress
    ) external onlyContractManager {
        if (supplies[_id] > _supply) revert NewSupplyTooLow();

        prices[_id] = _price;
        totalSupplies[_id] = _supply;
        maxPerTransactions[_id] = _maxPerAddress;
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

    function addTokens(
        uint256[] calldata _newSupplies,
        uint256[] calldata _newPrices,
        uint256[] calldata _maxPerTransactions
    ) external onlyContractManager arrayLengthMatch(_newSupplies, _newPrices) {
        uint256 suppliesLength = _newSupplies.length;

        if (suppliesLength != _newPrices.length) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < suppliesLength; ) {
            totalSupplies.push(_newSupplies[i]);
            supplies.push(0);
            prices.push(_newPrices[i]);
            maxPerTransactions.push(_maxPerTransactions[i]);

            unchecked {
                ++i;
            }
        }
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
        address[] calldata _to,
        uint256[][] calldata _ids,
        uint256[][] calldata _amounts
    ) external onlyContractManager nonContract {
        uint256 toLength = _to.length;
        for (uint256 i = 0; i < toLength; ) {
            uint256 idsLength = _ids[i].length;
            for (uint256 j = 0; j < idsLength; ) {
                uint256 _supply = supplies[_ids[i][j]];
                if (_supply + _amounts[i][j] > totalSupplies[_ids[i][j]])
                    revert MaxSupplyExceeded();
                /// @dev remove overflow protection enabled by default
                ///      as supplies is already capped by totalSupplies
                unchecked {
                    _supply += _amounts[i][j];
                }
                /// @dev write back to storage
                supplies[_ids[i][j]] = _supply;
                unchecked {
                    ++j;
                }
            }

            _mintBatch(_to[i], _ids[i], _amounts[i], '0x');
            unchecked {
                ++i;
            }
        }
    }

    // ================ Buy ================
    function buyAuthorised(
        uint256 _id,
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
                _expires,
                _id
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        if (
            ECDSA.recover(message, _signature) != addresses.authorisationAddress
        ) revert NotAuthorised();

        _buy(_id, _amount, _totalPrice);
    }

    function buy(uint256 _id, uint256 _amount)
        external
        payable
        buyAllowed
        nonContract
    {
        if (publicSaleDate == 0 || block.timestamp < publicSaleDate) revert PublicSaleClosed();

        uint256 totalPrice = prices[_id] * _amount;
        _buy(_id, _amount, totalPrice);
    }

    function _buy(
        uint256 _id,
        uint256 _amount,
        uint256 _totalPrice
    ) internal {
        uint256 _supply = supplies[_id];

        if (saleCloseDate != 0) {
            if (block.timestamp >= saleCloseDate) revert SaleClosed();
        }
        if (_supply + _amount > totalSupplies[_id]) revert MaxSupplyExceeded();

        if (maxPerTransactions[_id] != 0) {
            if (_amount > maxPerTransactions[_id])
                revert MaxPerTransactionsExceeded();
        }

        uint256 royaltyAmount = (_totalPrice * primaryRoyaltyFee) /
            BASIS_POINTS;

        if (addresses.purchaseTokenAddress != address(0)) {
            IERC20 token = IERC20(addresses.purchaseTokenAddress);
            /// @dev primary royalty cut for Hypermint
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
            /// @dev primary royalty cut for Hypermint
            payable(addresses.managerPrimaryRoyaltyAddress).transfer(
                royaltyAmount
            );
            /// @dev primary sale (i.e. minting revenue) for customer (or its payees)
            payable(addresses.customerPrimaryRoyaltyAddress).transfer(
                _totalPrice - royaltyAmount
            );
        }

        /// @dev remove overflow protection enabled by default
        ///      as supply is already capped by totalSupply
        unchecked {
            _supply += _amount;
        }

        /// @dev write back to storage
        supplies[_id] = _supply;

        _mint(msg.sender, _id, _amount, '0x');
    }

    // ============= Ownership=============
    function recoverContract() external {
        if (msg.sender != addresses.recoveryAddress) revert NotAuthorised();
        _transferContractManager(addresses.recoveryAddress);
    }

    /* ==================== MODIFIERS ===================== */
    modifier buyAllowed() {
        if (!allowBuy) revert BuyDisabled();
        _;
    }

    modifier arrayLengthMatch(
        uint256[] calldata arr1,
        uint256[] calldata arr2
    ) {
        if (arr1.length != arr2.length) revert ArrayLengthMismatch();
        _;
    }

    /// @dev this eliminates the possibility of being called
    ///      from a contract
    modifier nonContract() {
        if (tx.origin != msg.sender) revert ContractCallBlocked();
        _;
    }
}