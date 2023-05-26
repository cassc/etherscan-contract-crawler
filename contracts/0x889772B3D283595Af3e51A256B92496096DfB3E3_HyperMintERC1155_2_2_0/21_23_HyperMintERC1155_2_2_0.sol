// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './opensea-operator-filter/OperatorFilterer.sol';
import './Ownable_1_0_0.sol';
import './Interfaces/IHyperMintERC1155_2_2_0.sol';

contract HyperMintERC1155_2_2_0 is
    IHyperMintERC1155_2_2_0,
    ERC1155Burnable,
    Ownable,
    OperatorFilterer
{
    using SafeERC20 for IERC20;

    /* ================= STATE VARIABLES ================= */
    // ========= Immutable Storage =========
    uint256 internal constant BASIS_POINTS = 10000;

    // ========== Mutable Storage ==========
    string public constant version = '2.2.0';

    GeneralConfig public generalConfig;
    TokenConfig[] public tokenConfigs;
    Addresses public addresses;

    uint256[] public supplies;

    /* =================== CONSTRUCTOR =================== */
    /// @param _generalConfig settings for the contract
    /// @param _addresses a collection of addresses
    constructor(
        GeneralConfig memory _generalConfig,
        Addresses memory _addresses
    )
        ERC1155('')
        OperatorFilterer(
            address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), // default filter by OS
            true // subscribe to the filter list
        )
    {
        _transferOwnership(_addresses.collectionOwnerAddress);
        generalConfig = _generalConfig;
        addresses = _addresses;

        _setURI(generalConfig.tokenMetadataUrl);
    }

    /* ====================== Views ====================== */
    function getTokenConfigs()
        external
        view
        returns (TokenConfig[] memory configs)
    {
        configs = tokenConfigs;
    }

    function getSupplies()
        external
        view
        returns (uint256[] memory tokenSupplies)
    {
        tokenSupplies = supplies;
    }

    function name() public view returns (string memory collectionName) {
        collectionName = generalConfig.name;
    }

    function symbol() public view returns (string memory collectionSymbol) {
        collectionSymbol = generalConfig.symbol;
    }

    function contractURI() public view virtual returns (string memory uri) {
        uri = generalConfig.contractMetadataUrl;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address royaltyAddress, uint256 royaltyAmount) {
        /// @dev secondary royalty to be paid out by the marketplace
        ///      to the splitter contract
        royaltyAddress = addresses.secondaryRoyaltyAddress;
        royaltyAmount =
            (_salePrice * generalConfig.secondaryRoyaltyFee) /
            BASIS_POINTS;
    }

    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        virtual
        override(ERC1155, IHyperMintERC1155_2_2_0)
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
        _setURI(_tokenURI);
    }

    function setDates(
        uint256 _publicSale,
        uint256 _saleClosed
    ) external onlyContractManager {
        generalConfig.publicSaleDate = _publicSale;
        generalConfig.saleCloseDate = _saleClosed;
    }

    function setTokenConfig(
        uint256 _id,
        uint256 _price,
        uint256 _maxSupply,
        uint256 _maxPerTransaction
    ) external onlyContractManager {
        if (supplies[_id] > _maxSupply) revert NewSupplyTooLow();

        tokenConfigs[_id].price = _price;
        tokenConfigs[_id].maxSupply = _maxSupply;
        tokenConfigs[_id].maxPerTransaction = _maxPerTransaction;
    }

    function setAddresses(
        Addresses calldata _addresses
    ) external onlyContractManager {
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

    function setAllowPublicTransfer(
        bool _allowPublicTransfer
    ) external onlyContractManager {
        generalConfig.allowPublicTransfer = _allowPublicTransfer;
    }

    function setEnableOpenSeaOperatorFilterRegistry(
        bool _enable
    ) external onlyContractManager {
        generalConfig.enableOpenSeaOperatorFilterRegistry = _enable;
    }

    function setRoyalty(
        uint256 _primaryFee,
        uint256 _secondaryFee
    ) external onlyContractManager {
        generalConfig.primaryRoyaltyFee = _primaryFee;
        generalConfig.secondaryRoyaltyFee = _secondaryFee;
    }

    function addTokens(
        TokenConfig[] calldata _tokens
    ) external onlyContractManager {
        for (uint256 i = 0; i < _tokens.length; ) {
            supplies.push(0);
            tokenConfigs.push(_tokens[i]);

            unchecked {
                ++i;
            }
        }
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

                if (
                    _supply + _amounts[i][j] >
                    tokenConfigs[_ids[i][j]].maxSupply
                ) revert MaxSupplyExceeded();

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

    function buy(
        uint256 _id,
        uint256 _amount
    ) external payable buyAllowed nonContract {
        if (
            generalConfig.publicSaleDate == 0 ||
            block.timestamp < generalConfig.publicSaleDate
        ) revert PublicSaleClosed();

        uint256 totalPrice = tokenConfigs[_id].price * _amount;
        _buy(_id, _amount, totalPrice);
    }

    function _buy(uint256 _id, uint256 _amount, uint256 _totalPrice) internal {
        if (generalConfig.saleCloseDate != 0) {
            if (block.timestamp >= generalConfig.saleCloseDate)
                revert SaleClosed();
        }

        uint256 _supply = supplies[_id];
        uint256 _maxSupply = tokenConfigs[_id].maxSupply;

        if (_supply + _amount > _maxSupply) revert MaxSupplyExceeded();

        uint256 _maxPerTransaction = tokenConfigs[_id].maxPerTransaction;
        if (_maxPerTransaction != 0) {
            if (_amount > _maxPerTransaction)
                revert MaxPerTransactionsExceeded();
        }

        uint256 royaltyAmount = (_totalPrice *
            generalConfig.primaryRoyaltyFee) / BASIS_POINTS;

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

    // ================ Transfers ================
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155)
        transferAllowed(from, to)
        onlyAllowedOperator(
            from,
            generalConfig.enableOpenSeaOperatorFilterRegistry
        )
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function transferAuthorised(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount,
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
                _amount,
                _expires
            )
        );

        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        if (
            ECDSA.recover(message, _signature) != addresses.authorisationAddress
        ) revert NotAuthorised();

        super.safeTransferFrom(_from, _to, _tokenId, _amount, '0x');
    }

    // ============= Ownership=============
    function recoverContract() external {
        if (msg.sender != addresses.recoveryAddress) revert NotAuthorised();
        _transferContractManager(addresses.recoveryAddress);
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