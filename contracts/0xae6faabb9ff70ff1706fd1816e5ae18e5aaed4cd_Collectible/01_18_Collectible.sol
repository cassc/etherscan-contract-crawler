// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "./interfaces/IManifold.sol";

contract Collectible is
    Initializable,
    ERC1155Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC1155SupplyUpgradeable,
    IERC1155ReceiverUpgradeable,
    IManifold
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private constant maxRoyaltyShares = 10000;

    struct TokenInfo {
        /// @dev Arweave hash of the "ERC-1155 Metadata URI JSON Schema".
        string hash;
        /// @dev Initial price in Wei.
        uint256 price;
        /// @dev Royalty shares.
        Royalty[] royalties;
    }

    struct Royalty {
        /// @dev Wallet address.
        address wallet;
        /// @dev Amount of shares. 100 = 1%, 10000 = 100%.
        uint shares;
    }

    /// @dev Current token ID counter.
    CountersUpgradeable.Counter private tokenIdCounter;

    /// @dev Collection name.
    string public name;
    /// @dev Collection symbol.
    string public symbol;

    /// @dev Base URI for all tokens.
    string public baseUri;

    /// @dev TokenID => TokenInfo
    mapping(uint256 => TokenInfo) public tokens;

    /// @dev Token sales and royalty balances in Wei. address(this) is used for token sales.
    /// Any user with the DEFAULT_ADMIN_ROLE can withdraw the funds from token sales.
    mapping(address => uint256) public balances;

    event Mint(
        uint256 indexed tokenId,
        uint256 amount,
        string uri,
        string hash,
        uint256 price,
        address[] royaltyAddresses,
        uint256[] royaltyShares
    );

    event Buy(
        uint256 indexed tokenId,
        address to,
        uint256 value,
        uint256 valueAfterRoyalties
    );

    event Withdraw(address indexed to, uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param _baseUri Base URI for all tokens. Should end with '/'.
     * @param _adminWallet Admin wallet address. This account will be assigned the DEFAULT_ADMIN_ROLE (and other roles).
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseUri,
        address _adminWallet
    ) public initializer {
        __ERC1155_init(""); // base URI for all tokens
        __Pausable_init();
        __AccessControl_init();
        __ERC1155Supply_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        _grantRole(PAUSER_ROLE, _adminWallet);
        _grantRole(MINTER_ROLE, _adminWallet);

        name = _name;
        symbol = _symbol;
        baseUri = _baseUri;
    }

    function setName(
        string calldata _name
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        name = _name;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @dev Returns the next token ID.
    function nextTokenId() public view returns (uint256) {
        return tokenIdCounter.current();
    }

    /**
     * @param _tokenHash Arweave hash of the "ERC-1155 Metadata URI JSON Schema".
     * @param _supply Amount of prints.
     * @param _price Initial token price.
     * @param _royaltyAddresses Royalty addresses. Should match _royaltyShares array.
     * @param _royaltyShares Royalty shares per address. 100 = 1%, 10000 = 100%.
     */
    function mint(
        string calldata _tokenHash,
        uint256 _supply,
        uint256 _price,
        address[] calldata _royaltyAddresses,
        uint256[] calldata _royaltyShares
    ) external onlyRole(MINTER_ROLE) {
        require(bytes(_tokenHash).length > 0, "Invalid token hash");
        require(
            _royaltyAddresses.length == _royaltyShares.length,
            "Royalty addresses and shares arrays have different lengths"
        );

        uint _tokenId = tokenIdCounter.current();

        tokenIdCounter.increment();

        _mint(address(this), _tokenId, _supply, "");
        _setTokenInfo(
            _tokenId,
            _tokenHash,
            _price,
            _royaltyAddresses,
            _royaltyShares
        );

        emit URI(uri(_tokenId), _tokenId);
        emit Mint(
            _tokenId,
            _supply,
            uri(_tokenId),
            _tokenHash,
            _price,
            _royaltyAddresses,
            _royaltyShares
        );
    }

    /// @dev See `mint` function docs.
    function _setTokenInfo(
        uint256 _tokenId,
        string calldata _tokenHash,
        uint256 _price,
        address[] calldata _royaltyAddresses,
        uint256[] calldata _royaltyShares
    ) internal {
        TokenInfo storage tokenInfo = tokens[_tokenId];

        tokenInfo.hash = _tokenHash;
        tokenInfo.price = _price;
        uint totalRoyaltyShares = 0;

        for (uint i = 0; i < _royaltyAddresses.length; i++) {
            require(
                _royaltyAddresses[i] != address(0),
                "Zero address is not allowed for royalties"
            );
            require(
                _royaltyShares[i] > 0 && _royaltyShares[i] <= maxRoyaltyShares,
                "Royalty shares must be between 1 and 10000 (inclusive)"
            );

            tokenInfo.royalties.push(
                Royalty(_royaltyAddresses[i], _royaltyShares[i])
            );
            totalRoyaltyShares += _royaltyShares[i];
        }

        require(
            totalRoyaltyShares <= 1000,
            "Total royalty shares cannot exceed 1000 (10% of the price)"
        );
    }

    /**
     * @param _tokenId ID of the token a user wants to buy.
     */
    function buy(uint256 _tokenId) external payable whenNotPaused {
        require(exists(_tokenId), "Token does not exist");
        require(
            balanceOf(address(this), _tokenId) > 0,
            "Token has been sold out"
        );
        require(
            msg.value == tokens[_tokenId].price,
            "Invalid ETH amount attached"
        );

        // calculate royalties
        uint256 remainingAmount = msg.value;

        for (uint i = 0; i < tokens[_tokenId].royalties.length; i++) {
            // collaborators get x10 royalties from the initial sale
            uint256 amount = ((msg.value *
                tokens[_tokenId].royalties[i].shares) / maxRoyaltyShares) * 10;

            balances[tokens[_tokenId].royalties[i].wallet] += amount;
            remainingAmount -= amount;
        }

        balances[address(this)] += remainingAmount;

        _safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");

        emit Buy(_tokenId, msg.sender, msg.value, remainingAmount);
    }

    /**
     * @param _tokenId ID of the token a user wants to buy.
     * @param _amount Amount of tokens.
     * @param _to Wallet address the token will be transferred to.
     */
    function buy(
        uint256 _tokenId,
        uint256 _amount,
        address _to
    ) external whenNotPaused onlyRole(MINTER_ROLE) {
        require(exists(_tokenId), "Token does not exist");
        require(
            balanceOf(address(this), _tokenId) > 0,
            "Token has been sold out"
        );

        _safeTransferFrom(address(this), _to, _tokenId, _amount, "");

        emit Buy(_tokenId, msg.sender, 0, 0);
    }

    /**
     * Withdraw funds from sales and royalties to a given address.
     *
     * @param _to Wallet address the funds will be transferred to.
     */
    function withdraw(address _to) external {
        address _balanceAddress = _resolveBalanceWalletAddress(msg.sender);
        uint256 _amount = balances[_balanceAddress];

        require(_amount > 0, "Balance is empty");

        balances[_balanceAddress] = 0;

        payable(_to).transfer(_amount);

        emit Withdraw(_to, _amount);
    }

    /// @dev Returns sender's accumulated ETH balance.
    /// If sender has the DEFAULT_ADMIN_ROLE, returns accumulated funds from token sales.
    function getEthBalance() external view returns (uint256) {
        return balances[_resolveBalanceWalletAddress(msg.sender)];
    }

    /// @dev If _wallet has the DEFAULT_ADMIN_ROLE, returns address(this). Otherwise, returns _wallet.
    function _resolveBalanceWalletAddress(
        address _wallet
    ) internal view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _wallet) ? address(this) : _wallet;
    }

    /// @dev Returns token details.
    function getTokenInfo(
        uint256 _tokenId
    ) external view returns (TokenInfo memory) {
        require(exists(_tokenId), "Token does not exist");

        return tokens[_tokenId];
    }

    /// @dev Returns token price for the `buy` function.
    function getTokenPrice(uint256 _tokenId) external view returns (uint256) {
        require(exists(_tokenId), "Token does not exist");

        return tokens[_tokenId].price;
    }

    /**
     * Manifold's interface for fetching token royalties information.
     *
     * @param _tokenId Token ID.
     */
    function getRoyalties(
        uint256 _tokenId
    )
        external
        view
        override
        returns (address payable[] memory, uint256[] memory)
    {
        uint size = tokens[_tokenId].royalties.length;
        address payable[] memory _addresses = new address payable[](size);
        uint256[] memory _shares = new uint256[](size);

        for (uint i = 0; i < tokens[_tokenId].royalties.length; i++) {
            _addresses[i] = payable(tokens[_tokenId].royalties[i].wallet);
            _shares[i] = tokens[_tokenId].royalties[i].shares;
        }

        return (_addresses, _shares);
    }

    /// @dev Returns a token URI that leads to its "ERC-1155 Metadata URI JSON Schema".
    function uri(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        if (!exists(_tokenId)) {
            return "";
        }

        return string.concat(baseUri, tokens[_tokenId].hash);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /////////////////////////////////
    // Service functions below
    /////////////////////////////////

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            ERC1155Upgradeable,
            AccessControlUpgradeable,
            IERC165Upgradeable
        )
        returns (bool)
    {
        return
            interfaceId == type(IManifold).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}