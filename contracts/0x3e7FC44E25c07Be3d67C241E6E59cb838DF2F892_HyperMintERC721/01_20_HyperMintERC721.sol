// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './Ownable.sol';

contract HyperMintERC721 is
    ERC721,
    Ownable,
    Pausable,
    ERC721Burnable,
    ReentrancyGuard
{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    /* ================= STATE VARIABLES ================= */

    // ============== Structs ==============
    struct Addresses {
        address customerAddress;
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
        uint256 totalSupply;
        uint256 maxPerAddress;
    }

    // ========= Immutable Storage =========
    uint16 internal constant BASIS_POINTS = 10000;

    // ========== Mutable Storage ==========
    string public version = '2.0.0';

    /// @dev token info
    string _name;
    string _symbol;
    uint256 public price;
    uint256 public supply;
    uint256 public totalSupply;
    uint256 public maxPerAddress;
    mapping(address => uint256) public totalMinted;

    /// @dev metadata info
    string public contractURI;
    string public tokenMetadataURI;

    bool public allowBuy;

    /// @dev sale dates
    uint256 public publicSaleDate;
    uint256 public saleCloseDate;

    /// @dev royalty fees
    uint96 public primaryRoyaltyFee;
    uint96 public secondaryRoyaltyFee;

    Addresses public addresses;

    /* =================== CONSTRUCTOR =================== */
    /// @notice Creates a new NFT contract
    /// @param __name token name
    /// @param __symbol token symbol
    /// @param _price token price
    /// @param _totalSupply token total supply
    /// @param _allowBuy toggle to enable/disable buying
    /// @param _maxPerAddress max amount an address can buy
    /// @param _addresses a collection of addresses
    constructor(
        string memory __name,
        string memory __symbol,
        uint256 _price,
        uint256 _totalSupply,
        string memory _contractMetadataURI,
        string memory _tokenMetadataURI,
        bool _allowBuy,
        uint256 _maxPerAddress,
        Addresses memory _addresses
    ) ERC721('', '') {
        /**
         * @dev Initializes the contract setting the hypermint
         * support staff as the initial Collection Owner
         */
        _transferCollectionOwnership(_addresses.collectionOwnerAddress);

        _name = __name;
        _symbol = __symbol;
        price = _price;
        totalSupply = _totalSupply;
        allowBuy = _allowBuy;
        tokenMetadataURI = _tokenMetadataURI;
        contractURI = _contractMetadataURI;
        maxPerAddress = _maxPerAddress;
        addresses = _addresses;
    }

    /* ====================== Views ====================== */
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(tokenMetadataURI, _tokenId.toString()));
    }

    function getTokenInfo() public view returns (TokenInfo memory) {
        return TokenInfo(price, supply, totalSupply, maxPerAddress);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * secondaryRoyaltyFee) /
            BASIS_POINTS;
        /// @dev secondary royalty to be paid out by the marketplace
        ///      to the splitter contract
        return (addresses.secondaryRoyaltyAddress, royaltyAmount);
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721)
        returns (bool)
    {
        return (_interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId));
    }

    /* ================ MUTATIVE FUNCTIONS ================ */

    // ============ Restricted =============
    function setNameAndSymbol(string memory _newName, string memory _newSymbol)
        public
        onlyContractManager
    {
        _name = _newName;
        _symbol = _newSymbol;
    }

    function setMetadataURIs(
        string memory _contractURI,
        string memory _tokenURI
    ) public onlyContractManager {
        contractURI = _contractURI;
        tokenMetadataURI = _tokenURI;
    }

    function setDates(uint256 _publicSale, uint256 _saleClosed)
        public
        onlyContractManager
    {
        publicSaleDate = _publicSale;
        saleCloseDate = _saleClosed;
    }

    function setTokenData(
        uint256 _price,
        uint256 _supply,
        uint256 _maxPerAddress
    ) public onlyContractManager {
        require(supply < _supply + 1, 'Supply too low');

        price = _price;
        totalSupply = _supply;
        maxPerAddress = _maxPerAddress;
    }

    function setAddresses(Addresses memory _addresses)
        public
        onlyContractManager
    {
        if (
            addresses.collectionOwnerAddress !=
            _addresses.collectionOwnerAddress
        ) {
            _transferCollectionOwnership(_addresses.collectionOwnerAddress);
        }

        addresses = _addresses;
    }

    function setAllowBuy(bool _allowBuy) public onlyContractManager {
        allowBuy = _allowBuy;
    }

    function setRoyalty(uint96 _primaryFee, uint96 _secondaryFee)
        public
        onlyContractManager
    {
        primaryRoyaltyFee = _primaryFee;
        secondaryRoyaltyFee = _secondaryFee;
    }

    // ============== Minting ==============
    function mintBatch(address[] memory _accounts, uint256[] memory _amounts)
        public
        whenNotPaused
        onlyContractManager
        nonContract
        nonReentrant
    {
        uint256 _supply = supply;
        /// @dev operate on _supply instead of supply to save on reads (5,000 gas per read)
        for (uint256 i = 0; i < _accounts.length; i++) {
            require(
                _supply + _amounts[i] < totalSupply + 1,
                'Not enough supply'
            );

            for (uint256 j = 1; j < _amounts[i] + 1; j++) {
                _safeMint(_accounts[i], _supply + j);
            }

            totalMinted[_accounts[i]] = totalMinted[_accounts[i]] + _amounts[i];

            /// @dev remove overflow protection enabled by default
            ///      as supply is already capped by totalSupply
            unchecked {
                _supply += _amounts[i];
            }
        }

        /// @dev write back to storage
        supply = _supply;
    }

    // ================ Buy ================
    function buyAuthorised(
        uint256 _amount,
        uint256 _totalPrice,
        uint256 _maxPerAddress,
        uint256 _expires,
        bytes memory _signature
    ) external payable buyAllowed nonContract nonReentrant {
        require(block.timestamp < _expires, 'Signature expired');

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

        require(
            ECDSA.recover(message, _signature) ==
                addresses.authorisationAddress,
            'Not authorised'
        );

        _buy(_amount, _totalPrice, _maxPerAddress);
    }

    function buy(uint256 _amount)
        external
        payable
        buyAllowed
        nonContract
        nonReentrant
    {
        require(allowBuy, 'Buy disabled');
        require(block.timestamp + 1 > publicSaleDate, 'Public sale closed');

        uint256 totalPrice = price * _amount;
        _buy(_amount, totalPrice, maxPerAddress);
    }

    function _buy(
        uint256 _amount,
        uint256 _totalPrice,
        uint256 _maxPerAddress
    ) internal {
        uint256 _supply = supply;

        /// @dev sanity checks
        if (saleCloseDate != 0) {
            require(block.timestamp < saleCloseDate, 'Sale closed');
        }
        require(_supply + _amount < totalSupply + 1, 'Not enough supply');

        uint256 mintedCount = totalMinted[msg.sender];

        if (_maxPerAddress != 0) {
            require(
                mintedCount + _amount <= _maxPerAddress,
                'Max per address limit'
            );
        }

        totalMinted[msg.sender] = mintedCount + _amount;

        /// @dev mint tokens
        for (uint256 i = 1; i < _amount + 1; i++) {
            _safeMint(msg.sender, _supply + i);
        }

        /// @dev remove overflow protection enabled by default
        ///      as supply is already capped by totalSupply
        unchecked {
            _supply += _amount;
        }

        /// @dev write back to storage
        supply = _supply;

        uint256 royaltyAmount = (_totalPrice * primaryRoyaltyFee) /
            BASIS_POINTS;

        if (addresses.purchaseTokenAddress == address(0)) {
            require(msg.value >= _totalPrice, 'Insufficient value');
            /// @dev primary royalty cut for Hypermint
            payable(addresses.managerPrimaryRoyaltyAddress).transfer(
                royaltyAmount
            );
            /// @dev primary sale (i.e. minting revenue) for customer (or its payees)
            payable(addresses.customerPrimaryRoyaltyAddress).transfer(
                _totalPrice - royaltyAmount
            );
        } else {
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
        }
    }

    // ============= Onwership =============
    function transferContractOwnership() public {
        require(msg.sender == addresses.customerAddress, 'Not authorised');
        _transferContractOwnership(addresses.customerAddress);
    }

    // =============== Pause ===============
    function pause() public onlyContractManager {
        _pause();
    }

    function unpause() public onlyContractManager {
        _unpause();
    }

    /* ==================== MODIFIERS ===================== */
    modifier buyAllowed() {
        require(allowBuy, 'Buy disabled');
        _;
    }

    /// @dev this eliminates the possibility of being called
    ///      from a contract
    modifier nonContract() {
        require(tx.origin == msg.sender, 'Cannot be called by a contract');
        _;
    }
}