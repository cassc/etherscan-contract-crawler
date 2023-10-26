// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./DVinMembership.sol";
import "./EIP712Whitelisting.sol";

error RoundDisabled(uint256 round);
error InvalidTier(uint256 tier);
error FailedToMint();
error LengthMismatch();
error PurchaseLimitExceeded();
error InsufficientValue();
error RoundLimitExceeded();
error FailedToSendETH();

/// @title DVin Membership Sale
/// @notice Sale contract with authorization to mint tokens on the DVin NFT contract
contract DVinMint is EIP712Whitelisting {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); /*Role used to permission admin minting*/
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE"); /*Role used to permission contract configuration changes*/

    address payable public ethSink; /*recipient for ETH*/

    mapping(uint256 => address) public tierContracts; /*Contracts for different tier options*/

    uint256 public limitPerPurchase; /*Max amount of tokens someone can buy in one transaction*/

    /* Track when presales and public sales are allowed */
    enum ContractState {
        Presale,
        Public
    }
    mapping(ContractState => bool) public contractState; /*Track which state is enabled*/

    /* Track prices and limits for sales*/
    struct SaleConfig {
        uint256 price;
        uint256 limit;
    }
    mapping(uint256 => SaleConfig) public presaleConfig; /*Configuration for presale*/
    mapping(uint256 => SaleConfig) public publicConfig; /*Configuration for public sale*/

    /// @notice Constructor configures sale parameters
    /// @dev Sets external contract addresses, sets up roles
    /// @param _tiers Token types
    /// @param _addresses Token addresses
    /// @param _sink Address to send sale ETH to
    constructor(
        uint256[] memory _tiers,
        address[] memory _addresses,
        address payable _sink
    ) EIP712Whitelisting("DVin") {
        _setupRole(MINTER_ROLE, msg.sender); /*Grant role to deployer for admin minting*/
        _setupRole(OWNER_ROLE, msg.sender); /*Grant role to deployer for config changes*/
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); /*Grant role to deployer for access control changes*/
        ethSink = _sink; /*Set address to send ETH to*/

        setTierContracts(_tiers, _addresses); /*Set contracts to use for types*/
    }

    /*****************
    EXTERNAL MINTING FUNCTIONS
    *****************/
    /// @notice Mint tokens by authorized address - useful for people buying with CC
    /// @param _tier Which token type to purchase
    /// @param _dst Where to send tokens
    /// @param _qty Quantity to send
    function mintTierAdmin(
        uint256 _tier,
        address _dst,
        uint256 _qty
    ) public onlyRole(MINTER_ROLE) {
        if (tierContracts[_tier] == address(0)) revert InvalidTier(_tier); /*Ensure tier contract is populated*/
        if (!DVin(tierContracts[_tier]).mint(_dst, _qty)) revert FailedToMint(); /*Mint token by admin to specified address*/
    }

    function mintTierAdminBatch(
        uint256[] calldata _tiers,
        address[] calldata _dsts,
        uint256[] calldata _qtys
    ) public onlyRole(MINTER_ROLE) {
        if (_tiers.length != _dsts.length || _dsts.length != _qtys.length)
            revert LengthMismatch();

        for (uint256 index = 0; index < _tiers.length; index++) {
            mintTierAdmin(_tiers[index], _dsts[index], _qtys[index]);
        }
    }

    /// @notice Mint presale by qualified address.
    /// @dev Presale state must be enabled
    /// @param _tier Which token type to purchase
    /// @param _qty How many tokens to buy
    /// @param _nonce Whitelist signature nonce
    /// @param _signature Whitelist signature
    function purchaseTokenPresale(
        uint256 _tier,
        uint256 _qty,
        uint256 _nonce,
        bytes calldata _signature
    ) external payable requiresWhitelist(_signature, _nonce) {
        if (!contractState[ContractState.Presale])
            revert RoundDisabled(uint256(ContractState.Presale)); /*Presale must be enabled*/
        if (presaleConfig[_tier].price == 0) revert InvalidTier(_tier); /*Do not allow 0 value purchase. If desired use separate function for free claim*/
        SaleConfig memory _config = presaleConfig[_tier]; /*Fetch sale config*/
        _purchase(_tier, _qty, _config.price, _config.limit); /*Purchase token if all values & limits are valid*/
    }

    /// @notice Mint presale by anyone
    /// @dev Public sale must be enabled
    /// @param _tier Which token type to purchase
    /// @param _qty How many tokens to buy
    function purchaseTokenOpensale(uint256 _tier, uint256 _qty)
        external
        payable
    {
        if (!contractState[ContractState.Public])
            revert RoundDisabled(uint256(ContractState.Public)); /*Public must be enabled*/
        if (publicConfig[_tier].price == 0) revert InvalidTier(_tier); /*Do not allow 0 value purchase. If desired use separate function for free claim*/
        _purchase(
            _tier,
            _qty,
            publicConfig[_tier].price,
            publicConfig[_tier].limit
        ); /*Purchase token if all values & limits are valid*/
    }

    /*****************
    INTERNAL MINTING FUNCTIONS AND HELPERS
    *****************/
    /// @notice Mint tokens and transfer eth to sink
    /// @dev Validations:
    ///      - Msg value is checked in comparison to price and quantity
    /// @param _tier Token type to mint
    /// @param _qty How many tokens to mint
    /// @param _price Price per token
    /// @param _limit Max token ID
    function _purchase(
        uint256 _tier,
        uint256 _qty,
        uint256 _price,
        uint256 _limit
    ) internal {
        if (_qty > limitPerPurchase) revert PurchaseLimitExceeded();
        if (msg.value < (_price * _qty)) revert InsufficientValue();

        if ((DVin(tierContracts[_tier]).totalSupply() + _qty) > _limit)
            revert RoundLimitExceeded();

        (bool _success, ) = ethSink.call{value: msg.value}(""); /*Send ETH to sink first*/
        if (!_success) revert FailedToSendETH();

        if (!DVin(tierContracts[_tier]).mint(msg.sender, _qty))
            revert FailedToMint(); /*Mint token by admin to specified address*/
    }

    /*****************
    CONFIG FUNCTIONS
    *****************/

    /// @notice Set states enabled or disabled as owner
    /// @param _state 0: presale, 1: public sale
    /// @param _enabled specified state on or off
    function setContractState(ContractState _state, bool _enabled)
        external
        onlyRole(OWNER_ROLE)
    {
        contractState[_state] = _enabled;
    }

    /// @notice Set sale proceeds address
    /// @param _sink new sink
    function setSink(address payable _sink) external onlyRole(OWNER_ROLE) {
        ethSink = _sink;
    }

    /// @notice Set new contracts for types
    /// @param _tiers Token types like 1,2
    /// @param _addresses Addresses of token contracts
    function setTierContracts(
        uint256[] memory _tiers,
        address[] memory _addresses
    ) public onlyRole(OWNER_ROLE) {
        if (_tiers.length != _addresses.length) revert LengthMismatch();
        for (uint256 index = 0; index < _tiers.length; index++) {
            tierContracts[_tiers[index]] = _addresses[index];
        }
    }

    /// @notice Set token limits for this sale
    /// @param _tier Token type to set
    /// @param _presaleLimit Max tokens of this type to sell during presale
    /// @param _publicLimit Max tokens of this type to sell during public
    function setLimit(
        uint256 _tier,
        uint256 _presaleLimit,
        uint256 _publicLimit
    ) external onlyRole(OWNER_ROLE) {
        presaleConfig[_tier].limit = _presaleLimit;
        publicConfig[_tier].limit = _publicLimit;
    }

    /// @notice Set token limits for this sale
    /// @param _tier Token type to set
    /// @param _presalePrice Price at which to sell this type during presale
    /// @param _opensalePrice Price at which to sell this type during public sale
    function setPrice(
        uint256 _tier,
        uint256 _presalePrice,
        uint256 _opensalePrice
    ) external onlyRole(OWNER_ROLE) {
        presaleConfig[_tier].price = _presalePrice;
        publicConfig[_tier].price = _opensalePrice;
    }

    /// @notice Set token limits per purchase
    /// @param _limit Max tokens someone can buy at once
    function setLimitPerPurchase(uint256 _limit) external onlyRole(OWNER_ROLE) {
        limitPerPurchase = _limit;
    }
}