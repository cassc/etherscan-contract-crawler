// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// The wassieverse NFT
///
/// Contains 4 different stages to a sale:
///   - stage 1: whitelisted sale, based on a merkle tree. also fixed price, but a different one
///   - stage 2: public sale, permissionless, at a fixed price, predetermined supply, and with a per-account cap
///   - stage 3: after a grace period, public sale still works, but the contract owner has the right to freely mint any remaining supply
abstract contract NFTSale is AccessControl {
    //
    // Constants
    //

    bytes32 public constant SALE_ROLE = keccak256("SALE_ROLE");

    //
    // Errors
    //

    error InvalidArguments();
    error WhitelistSaleClosed();
    error PublicSaleClosed();
    error SalesNotOverYet();
    error UnexpectedETHAmount(uint256 given, uint256 expected);
    error AccountMaxExceeded();
    error NotEnoughSupplyLeft();
    error NotWhitelisted();
    error SettingsNowImmutable();

    //
    // Events
    //

    /// Emitted on a withdrawal by the owner
    event Withdrawn(address indexed to, uint256 amount);

    //
    // Structs
    //

    //
    // State
    //

    // prices
    uint256 public immutable pricePub;
    uint256 public immutable priceWhitelist;

    // max individual mints
    uint16 public immutable whitelistMax;
    uint16 public immutable publicMax;

    // timestamps for all stages
    uint64 public startPublic;
    uint64 public startWhitelist;

    // remaining supply
    uint16 public remainingSupply;

    /// address => # of public mints made
    mapping(address => uint16) public publicMints;
    mapping(address => uint16) public whitelistMints;

    /// merkle root
    bytes32 immutable whitelistMerkleRoot;

    //
    // Constructor
    //

    /// @param _startWhitelist start of whitelisted sale
    /// @param _startPublic start of public sale
    /// @param _priceWhitelist item price for whitelist sale
    /// @param _pricePub item price for public sale
    /// @param _supply Max total supply
    /// @param _publicMax max whitelist minting allowance per account
    /// @param _whitelistMax max public minting allowance per account
    /// @param _whitelistMerkleRoot merkle root used to authenticate whitelisted mints
    ///
    /// @dev The supplies are given as a 3-elem array purely to get around the
    /// 16 variable limit of solidity
    constructor(
        uint64 _startWhitelist,
        uint64 _startPublic,
        uint256 _priceWhitelist,
        uint256 _pricePub,
        uint16 _supply,
        uint16 _whitelistMax,
        uint16 _publicMax,
        bytes32 _whitelistMerkleRoot
    ) {
        if (
            _startWhitelist == 0 ||
            _startPublic <= _startWhitelist ||
            _priceWhitelist == 0 ||
            _pricePub == 0 ||
            _supply == 0 ||
            _whitelistMax == 0 ||
            _publicMax == 0 ||
            _whitelistMerkleRoot == 0
        ) {
            revert InvalidArguments();
        }

        _setNewDates(_startWhitelist, _startPublic);
        startWhitelist = _startWhitelist;
        startPublic = _startPublic;
        whitelistMax = _whitelistMax;
        publicMax = _publicMax;
        remainingSupply = _supply;
        whitelistMerkleRoot = _whitelistMerkleRoot;

        priceWhitelist = _priceWhitelist;
        pricePub = _pricePub;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SALE_ROLE, msg.sender);
    }

    //
    // Modifiers
    //

    modifier onlyUntilImmutable() {
        if (block.timestamp >= startWhitelist) {
            revert SettingsNowImmutable();
        }
        _;
    }

    modifier onlyDuringWhitelistSale() {
        if (
            remainingSupply == 0 ||
            _outsideBounds(startWhitelist, startPublic - 1)
        ) {
            revert WhitelistSaleClosed();
        }
        _;
    }

    modifier onlyDuringPublicSale() {
        if ((remainingSupply == 0) || startPublic > block.timestamp) {
            revert PublicSaleClosed();
        }
        _;
    }

    /// Ensures that the given ETH amount matches the expected value
    modifier ensureETHAmount(uint256 _price, uint16 _quantity) {
        uint256 expected = _price * _quantity;
        if (msg.value != expected) {
            revert UnexpectedETHAmount(msg.value, expected);
        }
        _;
    }

    /// check per-account minting limit
    modifier ensureAccountLimit(uint16 _quantity, uint16 _max) {
        uint16 newQuantity = publicMints[msg.sender] + _quantity;
        if (newQuantity > _max) {
            revert AccountMaxExceeded();
        }
        publicMints[msg.sender] = newQuantity;
        _;
    }

    modifier useWhitelist(bytes32[] calldata _proof, uint16 _quantity) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint16 prevQuantity = whitelistMints[msg.sender];
        uint16 newQuantity = prevQuantity + _quantity;

        if (newQuantity > whitelistMax) {
            revert AccountMaxExceeded();
        }

        if (!MerkleProof.verify(_proof, whitelistMerkleRoot, leaf)) {
            revert NotWhitelisted();
        }

        whitelistMints[msg.sender] = newQuantity;
        _;
    }

    //
    // Admin API
    //

    /// Sets new dates
    /// Can only be called until sales actually start
    /// @dev In case we need to postpone a couple of hours
    /// @dev enforces that both times are in the future, and that whitelist is
    ///   before public
    /// @param _whitelistStart new start date for whitelist sale
    /// @param _publicStart new start date for public sale
    function setNewDates(uint64 _whitelistStart, uint64 _publicStart)
        external
        onlyRole(SALE_ROLE)
        onlyUntilImmutable
    {
        _setNewDates(_whitelistStart, _publicStart);
    }

    //
    // Public API
    //

    /// Mints a single item to a whitelisted account
    /// Only callable during the whitelist sale period [startWhitelist, startLeftover]
    /// @dev The exact amount of ETH must be sent in the transaction
    /// @param _proof The merkle proof to be used alongside {msg.sender} to prove whitelist registration
    function mintWhitelist(bytes32[] calldata _proof, uint16 _quantity)
        external
        payable
        onlyDuringWhitelistSale
        ensureETHAmount(priceWhitelist, _quantity)
        useWhitelist(_proof, _quantity)
    {
        remainingSupply -= _quantity;
        _mintFromSale(msg.sender, _quantity);
    }

    /// Mints a given quantity
    /// Only callable during the public sale period [startPublic, startWhitelist]
    /// @dev The exact amount of ETH must be sent in the transaction
    /// @param _quantity How many items to mint (capped by {publicAccountMax})
    function mintPublic(uint16 _quantity)
        external
        payable
        onlyDuringPublicSale
        ensureETHAmount(pricePub, _quantity)
        ensureAccountLimit(_quantity, publicMax)
    {
        remainingSupply -= _quantity;
        _mintFromSale(msg.sender, _quantity);
    }

    /// Withdraws all ETH in the contract to the owner wallet
    /// @dev only callable by an authorized role
    function withdraw() external onlyRole(SALE_ROLE) {
        uint256 balance = address(this).balance;
        address _owner = msg.sender;

        emit Withdrawn(_owner, balance);

        // slither-disable-next-line low-level-calls
        (bool success, ) = _owner.call{value: balance}("");
        require(success);
    }

    /// @dev See {IERC165-supportsInterface}
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl)
        returns (bool)
    {
        return AccessControl.supportsInterface(interfaceId);
    }

    //
    // Internal API
    //

    /// Checks whether the current block timestamp falls outside of an (inclusive) range
    /// @param from range start
    /// @param to range end
    /// @return true if block.timestamp is outside the given range
    function _outsideBounds(uint64 from, uint64 to)
        internal
        view
        returns (bool)
    {
        uint64 _now = uint64(block.timestamp);
        return _now < from || _now > to;
    }

    function _setNewDates(uint64 _whitelist, uint64 _public) internal {
        if (_whitelist >= _public) {
            revert InvalidArguments();
        }

        startWhitelist = _whitelist;
        startPublic = _public;
    }

    /// Needs to be implemented by a subclass, and delegate to a specific implementation of minting
    /// @dev Allows this contract to be inherited from an ERC721-type contract, instead of having to inherit from one itself,
    ///   for better separation-of-concerns
    /// @dev Implementation should only need to delegate to {_mint(address,uint256)} from the chosen ERC721 impl
    // slither-disable-next-line dead-code
    function _mintFromSale(address _to, uint256 _quantity) internal virtual;
}