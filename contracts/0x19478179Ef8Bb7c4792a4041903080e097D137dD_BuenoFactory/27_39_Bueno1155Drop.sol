// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "operator-filter-registry/src/upgradeable/OperatorFiltererUpgradeable.sol";
import "./ICommon.sol";

struct TokenSettings {
    /// @dev total number of tokens that can be minted
    uint32 maxSupply;
    /// @dev total number of tokens that can be minted per wallet
    uint32 maxPerWallet;
    /// @dev tracks the total amount that have been minted
    uint32 amountMinted;
    /// @dev merkle root associated with claiming the token, otherwise bytes32(0)
    bytes32 merkleRoot;
    /// @dev timestamp of when the token can be minted
    uint32 mintStart;
    /// @dev timestamp of when the token can no longer be minted
    uint32 mintEnd;
    /// @dev price for the phase
    uint256 price;
    /// @dev uuid of the token within the Bueno ecosystem
    string uuid;
    /// @dev optional revenue splitting settings
    PaymentSplitterSettings paymentSplitterSettings;
}

struct TokenData {
    TokenSettings settings;
    uint256 index;
}

error TokenSettingsLocked();
error TokenAlreadyExists();
error InvalidPaymentSplitterSettings();
error TooManyTokens();
error InvalidToken();
error MintNotActive();
error InvalidMintDates();

/// @author Bueno.art
/// @title ERC-1155 "Drops" contract
contract Bueno1155Drop is
    ERC1155SupplyUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable,
    OperatorFiltererUpgradeable
{
    string public name;
    string public symbol;
    uint256 private _currentTokenId;
    bool private allowBurning;

    /// @dev maps the token ID (eg 1, 2 ...n) to the token's minting settings
    mapping(uint256 => TokenSettings) private _tokens;
    /// @dev track how many mints a particular wallet has made for a given token
    mapping(uint256 => mapping(address => uint64))
        private _mintBalanceByTokenId;
    /// @dev track how much revenue each payee has earned
    mapping(address => uint256) private _revenueByAddress;
    /// @dev track how much revenue has been released to each address
    mapping(address => uint256) private _released;
    /// @dev track how much revenue has been released in total
    uint256 private _totalReleased;
    /// @dev "fallback" payment splitter settings in case token-level settings aren't specified
    PaymentSplitterSettings private _fallbackPaymentSplitterSettings;

    event RoyaltyUpdated(address royaltyAddress, uint96 royaltyAmount);
    event TokenRoyaltyUpdated(
        uint256 tokenId,
        address royaltyAddress,
        uint96 royaltyAmount
    );
    event TokenCreated(string indexed uuid, uint256 indexed tokenId);
    event BurnStatusChanged(bool burnActive);
    event TokensAirdropped(uint256 numRecipients, uint256 numTokens);
    event TokenBurned(address indexed owner, uint256 tokenId, uint256 amount);
    event PaymentReleased(address to, uint256 amount);
    event TokenSettingsUpdated(uint256 tokenId);
    event RevenueSettingsUpdated(uint256 tokenId);
    event FallbackRevenueSettingsUpdated();
    event TokensMinted(address indexed to, uint256 tokenId, uint256 quantity);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        TokenSettings[] calldata _tokenSettings,
        RoyaltySettings calldata _royaltySettings,
        PaymentSplitterSettings calldata _paymentSplitterSettings,
        bool _allowBurning,
        address _deployer,
        address _operatorFilter
    ) public initializer {
        __ERC1155_init(_baseUri);
        __Ownable_init();

        uint256 numTokens = _tokenSettings.length;

        // set a reasonable maximum here so we don't run out of gas
        if (numTokens > 100) {
            revert TooManyTokens();
        }

        // verify fallback (contract-level) payment splitter settings
        _verifyPaymentSplitterSettings(_paymentSplitterSettings);

        for (uint256 i = 0; i < numTokens; ) {
            // verify token-level payment splitter settings, if present
            if (_tokenSettings[i].paymentSplitterSettings.payees.length > 0) {
                _verifyPaymentSplitterSettings(
                    _tokenSettings[i].paymentSplitterSettings
                );
            }

            _verifyMintingTime(
                _tokenSettings[i].mintStart,
                _tokenSettings[i].mintEnd
            );

            _tokens[i] = _tokenSettings[i];

            // this value should always be 0 for new tokens
            _tokens[i].amountMinted = 0;

            emit TokenCreated(_tokenSettings[i].uuid, i);

            // numTokens has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }

        _currentTokenId = numTokens;
        _fallbackPaymentSplitterSettings = _paymentSplitterSettings;
        name = _name;
        symbol = _symbol;
        allowBurning = _allowBurning;

        _setDefaultRoyalty(
            _royaltySettings.royaltyAddress,
            _royaltySettings.royaltyAmount
        );
        _transferOwnership(_deployer);
        OperatorFiltererUpgradeable.__OperatorFilterer_init(
            _operatorFilter,
            _operatorFilter == address(0) ? false : true // only subscribe if a filter is provided
        );
    }

    /*//////////////////////////////////////////////////////////////
                           CREATOR FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create a new token to be minted with the provided settings.
     */
    function createDropToken(
        TokenSettings calldata settings
    ) external onlyOwner {
        if (settings.paymentSplitterSettings.payees.length > 0) {
            _verifyPaymentSplitterSettings(settings.paymentSplitterSettings);
        }

        _verifyMintingTime(settings.mintStart, settings.mintEnd);

        uint256 id = _currentTokenId;

        _tokens[id] = settings;
        // this value should always be 0 for new tokens
        _tokens[id].amountMinted = 0;

        ++_currentTokenId;

        emit TokenCreated(settings.uuid, id);
    }

    /**
     * @notice Create multiple tokens to be minted with the provided settings.
     */
    function createDropTokens(
        TokenSettings[] calldata tokenSettings
    ) external onlyOwner {
        uint256 numTokens = tokenSettings.length;
        uint256 currentTokenId = _currentTokenId;

        for (uint256 i = 0; i < numTokens; ) {
            if (tokenSettings[i].paymentSplitterSettings.payees.length > 0) {
                _verifyPaymentSplitterSettings(
                    tokenSettings[i].paymentSplitterSettings
                );
            }

            TokenSettings memory settings = tokenSettings[i];

            _verifyMintingTime(settings.mintStart, settings.mintEnd);

            uint256 id = currentTokenId;

            // this value should always be 0 for new tokens
            settings.amountMinted = 0;
            _tokens[id] = settings;

            ++currentTokenId;

            // numTokens has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }

            emit TokenCreated(settings.uuid, id);
        }

        _currentTokenId = currentTokenId;
    }

    /**
     * @notice Update the settings for a token. Certain settings cannot be changed once a token has been minted.
     */
    function updateTokenSettingsByIndex(
        uint256 id,
        TokenSettings calldata settings
    ) external onlyOwner {
        // cannot edit a token larger than the current token ID
        if (id >= _currentTokenId) {
            revert InvalidToken();
        }

        TokenSettings memory token = _tokens[id];
        uint32 existingAmountMinted = token.amountMinted;
        PaymentSplitterSettings memory existingPaymentSplitterSettings = token
            .paymentSplitterSettings;

        // Once a token has been minted, it's not possible to change the supply & start/end times
        if (
            existingAmountMinted > 0 &&
            (settings.maxSupply != token.maxSupply ||
                settings.mintStart != token.mintStart ||
                settings.mintEnd != token.mintEnd)
        ) {
            revert TokenSettingsLocked();
        }

        _verifyMintingTime(settings.mintStart, settings.mintEnd);

        _tokens[id] = settings;

        // it's not possible to update how many have been claimed, but it's part of the TokenSettings struct
        // ignore any value that is passed in and use the existing value
        _tokens[id].amountMinted = existingAmountMinted;

        // payment splitter settings can only be updated via `updatePaymentSplitterSettingsByIndex`
        _tokens[id].paymentSplitterSettings = existingPaymentSplitterSettings;

        emit TokenSettingsUpdated(id);
    }

    function updatePaymentSplitterSettingsByIndex(
        uint256 id,
        PaymentSplitterSettings calldata settings
    ) external onlyOwner {
        // cannot edit a token larger than the current token ID
        if (id >= _currentTokenId) {
            revert InvalidToken();
        }

        // revenue split cannot be changed once a token is minted
        if (_tokens[id].amountMinted > 0) {
            revert TokenSettingsLocked();
        }

        _verifyPaymentSplitterSettings(settings);

        _tokens[id].paymentSplitterSettings = settings;

        emit RevenueSettingsUpdated(id);
    }

    function updateFallbackPaymentSplitterSettings(
        PaymentSplitterSettings calldata settings
    ) external onlyOwner {
        _verifyPaymentSplitterSettings(settings);

        _fallbackPaymentSplitterSettings = settings;

        emit FallbackRevenueSettingsUpdated();
    }

    function _verifyMintingTime(uint32 mintStart, uint32 mintEnd) private view {
        if (mintEnd > 0) {
            // mint end must be after mint start
            if (mintEnd < mintStart) {
                revert InvalidMintDates();
            }

            // mint end must be in the future
            if (mintEnd < block.timestamp) {
                revert InvalidMintDates();
            }
        }
    }

    function _verifyPaymentSplitterSettings(
        PaymentSplitterSettings calldata settings
    ) private pure {
        uint256 shareTotal;
        uint256 numPayees = settings.payees.length;

        // we discourage using the payment splitter for more than 4 payees, as it's not gas efficient for minting
        // more advanced use-cases should consider a multi-sig payee
        if (numPayees != settings.shares.length || numPayees > 4) {
            revert InvalidPaymentSplitterSettings();
        }

        for (uint256 i = 0; i < numPayees; ) {
            uint256 shares = settings.shares[i];

            if (shares == 0) {
                revert InvalidPaymentSplitterSettings();
            }

            shareTotal += shares;

            // this can't overflow as numPayees is capped at 4
            unchecked {
                ++i;
            }
        }

        if (shareTotal != 100) {
            revert InvalidPaymentSplitterSettings();
        }
    }

    /**
     * @notice Perform a batch airdrop of tokens to a list of recipients
     */
    function airdropToken(
        uint256 id,
        uint32[] calldata quantities,
        address[] calldata recipients
    ) external onlyOwner {
        if (id >= _currentTokenId) {
            revert InvalidToken();
        }

        uint256 numRecipients = recipients.length;
        uint256 totalAirdropped;
        if (numRecipients != quantities.length) revert InvalidAirdrop();

        TokenSettings storage token = _tokens[id];

        for (uint256 i = 0; i < numRecipients; ) {
            uint32 updatedAmountMinted = token.amountMinted + quantities[i];
            if (token.maxSupply > 0 && updatedAmountMinted > token.maxSupply) {
                revert SoldOut();
            }

            // airdrops are not subject to the per-wallet mint limits,
            // but we track how much is minted
            token.amountMinted = updatedAmountMinted;
            totalAirdropped += quantities[i];

            _mint(recipients[i], id, quantities[i], "");

            // numRecipients has a maximum value of 2^256 - 1
            unchecked {
                ++i;
            }
        }

        emit TokensAirdropped(numRecipients, totalAirdropped);
    }

    /**
     * @notice Release funds for a particular payee
     */
    function release(address payee) public {
        uint256 amount = releasable(payee);

        if (amount > 0) {
            _totalReleased += amount;

            // If "_totalReleased += amount" does not overflow, then "_released[payee] += amount" cannot overflow.
            unchecked {
                _released[payee] += amount;
            }

            AddressUpgradeable.sendValue(payable(payee), amount);

            emit PaymentReleased(payee, amount);
        }
    }

    /**
     * @notice Release funds for specified payees
     * @dev This is a convenience method to calling release() for each payee
     */
    function releaseBatch(address[] calldata payees) external {
        uint256 numPayees = payees.length;

        for (uint256 i = 0; i < numPayees; ) {
            release(payees[i]);

            // this can't overflow as numPayees is capped at 4
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Update the default royalty settings (EIP-2981) for the contract.
     */
    function setRoyaltyInfo(
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);

        emit RoyaltyUpdated(receiver, feeBasisPoints);
    }

    /**
     * @notice Update the royalty settings (EIP-2981) for the token.
     */
    function setTokenRoyaltyInfo(
        uint256 tokenId,
        address receiver,
        uint96 feeBasisPoints
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeBasisPoints);

        emit TokenRoyaltyUpdated(tokenId, receiver, feeBasisPoints);
    }

    /**
     * @notice If enabled, the token can be burned, for approved operators.
     * @dev The burn method will revert unless this is enabled
     */
    function toggleBurning() external onlyOwner {
        allowBurning = !allowBurning;

        emit BurnStatusChanged(allowBurning);
    }

    /**
     * @dev See {ERC1155Upgradeable-_setURI}
     */
    function setUri(string calldata uri) external onlyOwner {
        _setURI(uri);
    }

    /*//////////////////////////////////////////////////////////////
                           MINTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a token to the sender
     */
    function mintToken(uint256 id, uint32 quantity) external payable {
        TokenSettings memory token = _tokens[id];

        if (token.merkleRoot != bytes32(0)) {
            revert InvalidMintFunction();
        }

        _mintAfterChecks(
            msg.sender,
            msg.value,
            id,
            quantity,
            token.maxPerWallet
        );
    }

    /**
     * @notice Mint a token to a specific address
     * @dev Useful in case the recipient of the tokens is not the sender (gifting, fiat checkout, etc)
     */
    function mintTokenTo(
        address account,
        uint256 id,
        uint32 quantity
    ) external payable {
        TokenSettings memory token = _tokens[id];

        if (token.merkleRoot != bytes32(0)) {
            revert InvalidMintFunction();
        }

        _mintAfterChecks(account, msg.value, id, quantity, token.maxPerWallet);
    }

    /**
     * @notice Mint a token that has an allowlist associated with it.
     * @dev maxQuantity is encoded as part of the proof, and is a way to associate variable quantities with each allowlisted wallet
     */
    function mintTokenAllowlist(
        uint256 id,
        uint32 quantity,
        uint32 maxQuantity,
        bytes32[] calldata proof
    ) external payable {
        bytes32 merkleRoot = _tokens[id].merkleRoot;

        if (merkleRoot == bytes32(0)) {
            revert InvalidMintFunction();
        }

        if (
            !MerkleProof.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, maxQuantity))
            )
        ) {
            revert InvalidProof();
        }

        _mintAfterChecks(msg.sender, msg.value, id, quantity, maxQuantity);
    }

    function _mintAfterChecks(
        address account,
        uint256 balance,
        uint256 id,
        uint32 quantity,
        uint32 maxQuantity
    ) private {
        if (id >= _currentTokenId) {
            revert InvalidToken();
        }

        TokenSettings storage token = _tokens[id];

        if (balance != token.price * quantity) {
            revert InvalidPrice();
        }

        if (
            token.maxSupply > 0 &&
            token.amountMinted + quantity > token.maxSupply
        ) {
            revert SoldOut();
        }

        if (
            token.maxPerWallet > 0 &&
            // maxQuantity is either the token-level maxPerWallet, or the maxQuantity passed in from the allowlist mint function
            // if the latter, the value is provided by the user, but is first checked against the merkle tree
            _mintBalanceByTokenId[id][account] + quantity > maxQuantity
        ) {
            revert ExceedMaxPerWallet();
        }

        if (token.mintStart > 0 && block.timestamp < token.mintStart) {
            revert MintNotActive();
        }

        if (token.mintEnd > 0 && block.timestamp > token.mintEnd) {
            revert MintNotActive();
        }

        // we only need to proceed if this is a revenue generating mint
        if (balance > 0) {
            uint256 numPayees = token.paymentSplitterSettings.payees.length;

            if (numPayees > 0) {
                // if we have token-level payment splitter settings, use those
                calculateRevenueSplit(balance, token.paymentSplitterSettings);
            } else {
                // otherwise, fallback to the contract-level payment splitter settings
                calculateRevenueSplit(
                    balance,
                    _fallbackPaymentSplitterSettings
                );
            }
        }

        token.amountMinted += quantity;
        _mintBalanceByTokenId[id][account] += quantity;

        _mint(account, id, quantity, "");

        emit TokensMinted(account, id, quantity);
    }

    function calculateRevenueSplit(
        uint256 value,
        PaymentSplitterSettings storage paymentSplitterSettings
    ) private {
        uint256 numPayees = paymentSplitterSettings.payees.length;

        // each token can have different payment splitter settings, and price can change while mint is occurring
        // therefore we need to do some revenue accounting at the time of mint based on the price paid
        for (uint256 i = 0; i < numPayees; ) {
            address payee = paymentSplitterSettings.payees[i];
            uint256 amount = ((value * paymentSplitterSettings.shares[i]) /
                100);

            _revenueByAddress[payee] += amount;

            // this can't overflow as numPayees is capped at 4
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Burn a token, if the contract allows for it
     */
    function burn(uint256 id, uint256 amount) external {
        if (!allowBurning) {
            revert BurningNotAllowed();
        }

        _burn(msg.sender, id, amount);

        emit TokenBurned(msg.sender, id, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the token data based on it's ID (1, 2, etc)
     */
    function getTokenSettingsByTokenId(
        uint256 id
    ) external view returns (TokenSettings memory) {
        return _tokens[id];
    }

    /**
     * @notice Retrieve the fallback payment splitter config (used if a token doesn't have it's own payment splitter settings)
     */
    function getFallbackPaymentSplitterSettings()
        external
        view
        returns (PaymentSplitterSettings memory)
    {
        return _fallbackPaymentSplitterSettings;
    }

    /**
     * @notice Get the token data for all tokens associated with the contract
     */
    function getAllTokenData() external view returns (TokenData[] memory) {
        uint256 numTokens = _currentTokenId;
        TokenData[] memory tokens = new TokenData[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            tokens[i].settings = _tokens[i];
            tokens[i].index = i;
        }

        return tokens;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() external view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        return _revenueByAddress[account] - released(account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                      OPERATOR REGISTRY OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}