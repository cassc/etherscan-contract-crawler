// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// implementations
import "./impl/ERC721OmmgSnapshot.sol";
import "./impl/OmmgAccessControl.sol";
import "./impl/ERC721Ommg.sol";

// interfaces
import "./interfaces/IERC721OmmgEnumerable.sol";
import "./interfaces/IERC721OmmgMetadata.sol";
import "./interfaces/IERC721OmmgMetadataFreezable.sol";

import "./interfaces/IOmmgAcquirable.sol";
import "./interfaces/IOmmgAcquirableWithToken.sol";
import "./interfaces/IOmmgEmergencyTokenRecoverable.sol";
import "./interfaces/IOmmgWithdrawable.sol";

import "./interfaces/IOmmgProvenanceHash.sol";
import "./interfaces/IOmmgMutablePrice.sol";
import "./interfaces/IOmmgSalePausable.sol";
import "./interfaces/IOmmgSupplyCap.sol";
import "./interfaces/IOmmgFrontEnd.sol";

import "./def/ArtistContractConfig.sol";
import "./def/CustomErrors.sol";

// utility
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

contract OmmgArtistContract is
    IOmmgFrontEnd,
    OmmgAccessControl,
    ERC721Ommg,
    ERC721OmmgSnapshot,
    IERC721OmmgEnumerable,
    IERC721OmmgMetadata,
    IERC721OmmgMetadataFreezable,
    IOmmgSalePausable,
    IOmmgSupplyCap,
    IOmmgMutablePrice,
    IOmmgProvenanceHash,
    IOmmgAcquirable,
    IOmmgAcquirableWithToken,
    IOmmgEmergencyTokenRecoverable,
    IOmmgWithdrawable
{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    /// @notice The identifying hash of the state administrator role. The state
    /// administrator role empowers the accounts that hold it to change state variables.
    /// @dev is just keccak256("CONTRACT_STATE_ADMIN")
    bytes32 public constant CONTRACT_STATE_ADMIN_ROLE =
        0x7e69b879a040173b938f56bb64bfa62bcd758c08ae6ed7cfdf7da6d7dba92708;

    /// @notice The identifying hash of the withdrawal administrator role. The
    /// role empowers the accounts that hold it to withdraw eth.
    /// @dev is just keccak256("CONTRACT_WITHDRAW_ADMIN")
    bytes32 public constant CONTRACT_WITHDRAW_ADMIN_ROLE =
        0x7c13537556c77ef3fb98601c3356887ddbe5991e86dc065741ce77e1dd2554a3;

    /// @notice The identifying hash of the free acquire role. The role empowers
    /// the accounts that hold it to mint tokens for free, for example for marketing purposes.
    /// @dev is just keccak256("CONTRACT_FREE_ACQUIRE")
    bytes32 public constant CONTRACT_FREE_ACQUIRE_ROLE =
        0xfdd7b2ba629c0a0b84029cda831836222e5708c95d3e782c0762066b472dad0e;

    /// @dev the immutable max supply cap of this token
    uint256 private immutable _supplyCap;
    /// @dev the mutable public mint price of this token
    uint256 private _price;
    /// @dev the total number of shares held by all shareholders
    uint256 private _totalShares;

    /// @dev indicates whether the token metadata is revealed
    bool private _revealed;
    /// @dev indicates whether the public sale is active
    bool private _saleIsActive;
    /// @dev indicates whether the token metadata is frozen
    bool private _metadataFrozen;
    /// @dev indicates whether the provenance hash is frozen
    bool private _provenanceFrozen;

    /// @dev the name of the token contract
    string private _name;
    /// @dev the symbol of the token contract
    string private _symbol;
    /// @dev the base URI of the token metadata which is prepended to the tokenID,
    /// unless overridden for a token. Only shows when the token is revealed
    string private _baseURI;
    /// @dev the URI of the token metadata for the unrevealed state
    string private _unrevealedTokenURI;
    /// @dev the provenance hash
    string private _provenanceHash;

    /// @dev optional mapping for token URIs to override the default behavior
    mapping(uint256 => string) private _tokenURIs;
    /// @dev whether the token URI for this item is a full override or simply gets appended to the `_baseURI`
    mapping(uint256 => bool) private _overrideFullURI;
    /// @dev Optional mapping for token reveal override, to indicate if an individual token has been revealed
    mapping(uint256 => bool) private _tokenRevealed;

    /// @dev the list of all shareholders who will receive eth when `withdraw` is called
    Shareholder[] private _shareholders;

    /// @dev the list of all configured tokens for the token discount mechanic
    IERC721[] private _configuredTokens;
    /// @dev a shorthand way to check if a token is configured
    mapping(IERC721 => bool) _tokenConfigured;
    /// @dev a mapping per configured token to indicate whether a specific token of that token contract has been used as
    /// a discount token already or not. It goes as follows: `_tokenIdsUsed[address][version][tokenId]`
    mapping(IERC721 => mapping(uint256 => mapping(uint256 => bool))) _tokenIdsUsed;
    /// @dev a mapping per configured token to its tokenIdsUsed version, needed for resets.
    mapping(IERC721 => uint256) _tokensUsedVersion;
    /// @dev a mapping per configured token to its used number.
    mapping(IERC721 => uint256) _tokensUsedNumber;
    /// @dev the configurations (price, active state) of a token discount
    mapping(IERC721 => TokenDiscountConfig) _tokenConfigurations;

    /// @notice Initializes the contract with the given configuration.
    /// @dev The config is the 'magic' behind this contract and the core of it's flexibility
    /// @param config the config of this contract as an {ArtistContractConfig} struct
    /// `config.name` will be the name of the contract.
    /// `config.symbol` will be the symbol.
    /// `config.withdrawAdmins` can be a list of users who will be assigned the `CONTRACT_WITHDRAW_ADMIN_ROLE` on construction.
    /// `config.stateAdmins` can be a list of users who will be assigned the `CONTRACT_STATE_ADMIN_ROLE` on construction.
    /// `config.mintForFree` can be a list of users who will be assigned the `CONTRACT_FREE_ACQUIRE_ROLE` on construction.
    /// `config.initialPrice` is the initial value assigned to the mutable price property.
    /// `config.supplyCap` is the immutable supply cap.
    /// `config.maxBatchSize` is the maximum number of tokens mintable in one transaction.
    /// `config.shareholders` is a list of the shareholders (see {Shareholder} struct).
    /// `config.tokenDiscounts` is a list of token discounts (see {TokenDiscount} struct) which will be usable to mint tokens.
    constructor(ArtistContractConfig memory config)
        ERC721Ommg(config.maxBatchSize)
    {
        _name = config.name;
        _symbol = config.symbol;
        _price = config.initialPrice;
        _supplyCap = config.supplyCap;

        _addRoleToAll(config.withdrawAdmins, CONTRACT_WITHDRAW_ADMIN_ROLE);
        _addRoleToAll(config.stateAdmins, CONTRACT_STATE_ADMIN_ROLE);
        _addRoleToAll(config.mintForFree, CONTRACT_FREE_ACQUIRE_ROLE);

        uint256 amount = config.shareholders.length;
        for (uint256 i = 0; i < config.shareholders.length; i++) {
            _addShareholder(config.shareholders[i]);
        }

        amount = config.tokenDiscounts.length;
        for (uint256 i = 0; i < amount; i++) {
            _addTokenDiscount(
                config.tokenDiscounts[i].tokenAddress,
                config.tokenDiscounts[i].config
            );
        }
    }

    /// @inheritdoc ERC721Ommg
    function maxBatchSize()
        public
        view
        override(ERC721Ommg, IOmmgFrontEnd)
        returns (uint256)
    {
        return super.maxBatchSize();
    }

    function tokensAvailable()
        external
        view
        override
        returns (uint256 amount)
    {
        return supplyCap() - _currentIndex();
    }

    /// @dev little helper function to add `role` to all accounts supplied
    function _addRoleToAll(address[] memory accounts, bytes32 role) private {
        uint256 len = accounts.length;
        if (len > 0) {
            for (uint256 i = 0; i < len; i++) {
                grantRole(role, accounts[i]);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgWithdrawable //////////////////////////////////////////////

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`.
    /// @inheritdoc IOmmgWithdrawable
    function addShareholder(address walletAddress, uint256 shares)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _addShareholder(Shareholder(walletAddress, shares));
    }

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`.
    /// @inheritdoc IOmmgWithdrawable
    function removeShareholder(address walletAddress)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (walletAddress == address(0)) revert NullAddress();
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == walletAddress) {
                _removeShareholderAt(i);
                return;
            }
        }
        revert ShareholderDoesNotExist(walletAddress);
    }

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`.
    /// @inheritdoc IOmmgWithdrawable
    function updateShareholder(address walletAddress, uint256 updatedShares)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (walletAddress == address(0)) revert NullAddress();
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == walletAddress) {
                _shareholders[i].shares = updatedShares;
                emit ShareholderUpdated(walletAddress, updatedShares);
                return;
            }
        }
        revert ShareholderDoesNotExist(walletAddress);
    }

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`. Reverts if the address is the null address,
    /// or if a shareholder with this address does not exist.
    /// @inheritdoc IOmmgWithdrawable
    function shares(address walletAddress)
        external
        view
        override
        returns (uint256)
    {
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == walletAddress) {
                return _shareholders[i].shares;
            }
        }
        revert ShareholderDoesNotExist(walletAddress);
    }

    /// @inheritdoc IOmmgWithdrawable
    function shareholders()
        external
        view
        override
        returns (Shareholder[] memory)
    {
        return _shareholders;
    }

    /// @inheritdoc IOmmgWithdrawable
    function totalShares() external view override returns (uint256) {
        return _totalShares;
    }

    function emergencyWithdraw()
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit EmergencyWithdrawn(msg.sender, balance);
    }

    /// @inheritdoc IOmmgWithdrawable
    function withdraw()
        external
        override
        onlyOwnerOrRole(CONTRACT_WITHDRAW_ADMIN_ROLE)
    {
        uint256 balance = address(this).balance;
        uint256 totalShares_ = _totalShares;
        uint256 length = _shareholders.length;
        if (totalShares_ == 0 || length == 0) revert ZeroShares();
        uint256 amountPerShare = balance / totalShares_;
        for (uint256 i = 0; i < length; i++) {
            Shareholder memory sh = _shareholders[i];
            uint256 shareholderAmount = sh.shares * amountPerShare;
            payable(sh.addr).transfer(shareholderAmount);
            emit PaidOut(_msgSender(), sh.addr, shareholderAmount);
        }
        emit Withdrawn(_msgSender(), amountPerShare * _totalShares);
    }

    function _removeShareholderAt(uint256 index) private {
        uint256 length = _shareholders.length;
        Shareholder memory sh = _shareholders[index];
        for (uint256 i = index; i < length - 1; i++) {
            _shareholders[i] = _shareholders[i + 1];
        }
        _shareholders.pop();
        _totalShares -= sh.shares;
        emit ShareholderRemoved(sh.addr, sh.shares);
    }

    function _addShareholder(Shareholder memory shareholder) internal {
        if (shareholder.shares == 0) revert ZeroShares();
        if (shareholder.addr == address(0)) revert NullAddress();
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == shareholder.addr)
                revert ShareholderAlreadyExists(shareholder.addr);
        }
        _shareholders.push(shareholder);
        _totalShares += shareholder.shares;
        emit ShareholderAdded(shareholder.addr, shareholder.shares);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgEmergencyTokenRecoverable /////////////////////////////////

    /// @inheritdoc IOmmgEmergencyTokenRecoverable
    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) public virtual override onlyOwnerOrRole(CONTRACT_WITHDRAW_ADMIN_ROLE) {
        if (receiver == address(0)) revert NullAddress();
        token.safeTransfer(receiver, amount);
        emit TokensRecovered(token, receiver, amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgAcquirableWithToken //////////////////////////////////////

    /// @inheritdoc IOmmgAcquirableWithToken
    function acquireWithToken(IERC721 token, uint256[] memory tokenIds)
        external
        payable
        override(IOmmgAcquirableWithToken, IOmmgFrontEnd)
    {
        uint256 amount = tokenIds.length;
        if (amount == 0) revert InvalidAmount(0, 1, maxBatchSize());
        _checkSupplyCapAndMaxBatch(amount);
        _revertIfTokenNotActive(token);
        uint256 price_ = _getTokenDiscountInfo(token).price;
        if (msg.value != price_ * amount) {
            revert InvalidMessageValue(msg.value, price_ * amount);
        }
        _checkTokenElegibility(msg.sender, token, tokenIds);
        _setTokensUsedForDiscount(token, tokenIds);
        _safeMint(msg.sender, amount);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokenDiscounts()
        external
        view
        override(IOmmgAcquirableWithToken, IOmmgFrontEnd)
        returns (TokenDiscountOutput[] memory)
    {
        uint256 len = _configuredTokens.length;
        IERC721[] memory localCopy = _configuredTokens;
        TokenDiscountOutput[] memory td = new TokenDiscountOutput[](len);
        for (uint256 i = 0; i < len; i++) {
            address addr = address(localCopy[i]);
            td[i] = TokenDiscountOutput(
                IERC721(addr),
                _getRemoteNameOrEmpty(address(addr)),
                _getRemoteSymbolOrEmpty(address(addr)),
                _tokensUsedNumber[localCopy[i]],
                _tokenConfigurations[localCopy[i]]
            );
        }
        return td;
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) public onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE) {
        _addTokenDiscount(tokenAddress, config);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function setTokenDiscountActive(IERC721 tokenAddress, bool active)
        external
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        if (_tokenConfigurations[tokenAddress].active != active) {
            _tokenConfigurations[tokenAddress].active = active;
            emit TokenDiscountUpdated(
                tokenAddress,
                _tokenConfigurations[tokenAddress]
            );
        }
    }

    function _getRemoteNameOrEmpty(address remote)
        internal
        view
        returns (string memory)
    {
        try IERC721Metadata(remote).name() returns (string memory name_) {
            return name_;
        } catch {
            return "";
        }
    }

    function _getRemoteSymbolOrEmpty(address remote)
        internal
        view
        returns (string memory)
    {
        try IERC721Metadata(remote).symbol() returns (string memory symbol_) {
            return symbol_;
        } catch {
            return "";
        }
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokensUsedForDiscount(
        IERC721 tokenAddress,
        uint256[] memory tokenIds
    )
        external
        view
        virtual
        override(IOmmgAcquirableWithToken, IOmmgFrontEnd)
        returns (bool[] memory used)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        uint256 length = tokenIds.length;
        bool[] memory arr = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            arr[i] = _tokenIdsUsed[tokenAddress][
                _tokensUsedVersion[tokenAddress]
            ][tokenIds[i]];
        }
        return arr;
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function removeTokenDiscount(IERC721 tokenAddress)
        external
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        uint256 length = _configuredTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (_configuredTokens[i] == tokenAddress) {
                _tokenConfigured[tokenAddress] = false;
                _popTokenConfigAt(i);
                emit TokenDiscountRemoved(tokenAddress);
                return;
            }
        }
        revert TokenNotConfigured(tokenAddress);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokenDiscountInfo(IERC721 tokenAddress)
        external
        view
        returns (TokenDiscountOutput memory)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        return
            TokenDiscountOutput(
                tokenAddress,
                _getRemoteNameOrEmpty(address(tokenAddress)),
                _getRemoteSymbolOrEmpty(address(tokenAddress)),
                _tokensUsedNumber[tokenAddress],
                _getTokenDiscountInfo(tokenAddress)
            );
    }

    function _getTokenDiscountInfo(IERC721 tokenAddress)
        internal
        view
        returns (TokenDiscountConfig memory)
    {
        return _tokenConfigurations[tokenAddress];
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function updateTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) external override onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE) {
        _revertIfTokenNotConfigured(tokenAddress);
        _tokenConfigurations[tokenAddress] = config;
        emit TokenDiscountUpdated(tokenAddress, config);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function resetTokenDiscountUsed(IERC721 tokenAddress)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        _tokensUsedVersion[tokenAddress]++;
        _tokensUsedNumber[tokenAddress] = 0;
        emit TokenDiscountReset(tokenAddress);
    }

    function _checkTokenElegibility(
        address account,
        IERC721 tokenAddress,
        uint256[] memory tokenIds
    ) internal view {
        uint256 length = tokenIds.length;
        if (
            _tokensUsedNumber[tokenAddress] + length >
            _tokenConfigurations[tokenAddress].supply
        )
            revert TokenSupplyExceeded(
                tokenAddress,
                _tokenConfigurations[tokenAddress].supply
            );
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            // try catch for reverts in ownerOf
            try tokenAddress.ownerOf(tokenId) returns (address owner) {
                if (owner != account)
                    revert TokenNotOwned(tokenAddress, tokenId);
            } catch {
                revert TokenNotOwned(tokenAddress, tokenId);
            }
            if (
                _tokenIdsUsed[tokenAddress][_tokensUsedVersion[tokenAddress]][
                    tokenId
                ]
            ) revert TokenAlreadyUsed(tokenAddress, tokenId);
        }
    }

    function _popTokenConfigAt(uint256 index) private {
        uint256 length = _configuredTokens.length;
        if (index >= length) return;
        for (uint256 i = index; i < length - 1; i++) {
            _configuredTokens[i] = _configuredTokens[i + 1];
        }
        _configuredTokens.pop();
    }

    // no checks
    function _setTokensUsedForDiscount(
        IERC721 token,
        uint256[] memory tokenIds
    ) internal {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _tokenIdsUsed[token][_tokensUsedVersion[token]][
                tokenIds[i]
            ] = true;
            emit TokenUsedForDiscount(msg.sender, token, tokenIds[i]);
        }
        _tokensUsedNumber[token] += length;
    }

    function _addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountConfig memory config
    ) internal {
        if (address(tokenAddress) == address(0)) revert NullAddress();
        if (_tokenConfigured[tokenAddress])
            revert TokenAlreadyConfigured(tokenAddress);
        _tokenConfigured[tokenAddress] = true;
        _tokensUsedVersion[tokenAddress]++;
        _tokenConfigurations[tokenAddress] = config;
        _configuredTokens.push(tokenAddress);
        emit TokenDiscountAdded(tokenAddress, config);
    }

    function _revertIfTokenNotConfigured(IERC721 tokenAddress) internal view {
        if (address(tokenAddress) == address(0)) revert NullAddress();
        if (!_tokenConfigured[tokenAddress])
            revert TokenNotConfigured(tokenAddress);
    }

    function _revertIfTokenNotActive(IERC721 tokenAddress) internal view {
        if (!_tokenConfigured[tokenAddress])
            revert TokenNotConfigured(tokenAddress);
        if (!_tokenConfigurations[tokenAddress].active)
            revert TokenNotActive(tokenAddress);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgProvenanceHash ///////////////////////////////////////////

    function whenProvenanceIsNotFrozen() private view {
        if (_provenanceFrozen) revert ProvenanceHashIsFrozen();
    }

    /// @inheritdoc IOmmgProvenanceHash
    function provenanceHash() public view override returns (string memory) {
        return _provenanceHash;
    }

    /// @inheritdoc IOmmgProvenanceHash
    function provenanceFrozen() public view override returns (bool) {
        return _provenanceFrozen;
    }

    /// @inheritdoc IOmmgProvenanceHash
    function setProvenanceHash(string memory provenanceHash_)
        public
        virtual
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        whenProvenanceIsNotFrozen();
        _provenanceHash = provenanceHash_;
        emit ProvenanceHashSet(_provenanceHash);
    }

    /// @inheritdoc IOmmgProvenanceHash
    function freezeProvenance()
        public
        virtual
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        whenProvenanceIsNotFrozen();
        _provenanceFrozen = true;
        emit ProvenanceHashFrozen();
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgMutablePrice //////////////////////////////////////////////

    /// @inheritdoc IOmmgMutablePrice
    function price()
        public
        view
        override(IOmmgMutablePrice, IOmmgFrontEnd)
        returns (uint256)
    {
        return _price;
    }

    /// @inheritdoc IOmmgMutablePrice
    function setPrice(uint256 price)
        public
        virtual
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _price = price;
        emit PriceChanged(_price);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgSupplyCap /////////////////////////////////////////////////

    /// @inheritdoc IOmmgSupplyCap
    function supplyCap()
        public
        view
        virtual
        override(IOmmgSupplyCap, IOmmgFrontEnd)
        returns (uint256)
    {
        return _supplyCap;
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgSalePausable //////////////////////////////////////////////

    /// @inheritdoc IOmmgSalePausable
    function saleIsActive()
        public
        view
        override(IOmmgSalePausable, IOmmgFrontEnd)
        returns (bool)
    {
        return _saleIsActive;
    }

    /// @inheritdoc IOmmgSalePausable
    function setSaleIsActive(bool newValue)
        public
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _saleIsActive = newValue;
        emit SaleIsActiveSet(_saleIsActive);
    }

    modifier whenSaleIsActive() {
        if (!_saleIsActive) {
            revert SaleNotActive();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgAcquirable ////////////////////////////////////////////////

    /// @inheritdoc IOmmgAcquirable
    function acquireForCommunity(address receiver, uint256 amount)
        external
        override
        onlyOwnerOrRole(CONTRACT_FREE_ACQUIRE_ROLE)
    {
        _checkSupplyCapAndMaxBatch(amount);
        _safeMint(receiver, amount);
    }

    /// @inheritdoc IOmmgAcquirable
    function acquire(uint256 amount)
        external
        payable
        override(IOmmgAcquirable, IOmmgFrontEnd)
        whenSaleIsActive
    {
        _checkSupplyCapAndMaxBatch(amount);
        if (msg.value != price() * amount) {
            revert InvalidMessageValue(msg.value, price() * amount);
        }

        _safeMint(msg.sender, amount);
    }

    function _checkSupplyCapAndMaxBatch(uint256 amount) private view {
        if (amount > maxBatchSize() || amount == 0) {
            revert InvalidAmount(amount, 1, maxBatchSize());
        }
        if (_currentIndex() + amount > supplyCap()) {
            // +1 because 0 based index
            revert AmountExceedsCap(
                amount,
                supplyCap() - _currentIndex(),
                supplyCap()
            );
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC721OmmgEnumerable //////////////////////////////////////////

    /// @inheritdoc IERC721Enumerable
    function totalSupply() public view override returns (uint256) {
        return _currentIndex() - _burned();
    }

    /// @inheritdoc IERC721Enumerable
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index >= totalSupply())
            revert IndexOutOfBounds(index, totalSupply());
        if (_burned() == 0) return index + 1;
        uint256 j = 0;
        uint256 maxIndex = _currentIndex();
        for (uint256 i = 0; i < maxIndex; i++) {
            if (j == index) return i;
            if (_exists(i)) j++;
        }
        revert OperationFailed();
    }

    /// @inheritdoc IERC721Enumerable
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index > balanceOf(owner))
            revert IndexOutOfBounds(index, balanceOf(owner));

        uint256 limit = _currentIndex();
        uint256 tokenIdsIdx = 0;
        for (uint256 i = 0; i < limit; i++) {
            if (_exists(i)) {
                if (_ownershipOf(i).addr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert OperationFailed();
    }

    /// @inheritdoc IERC721OmmgEnumerable
    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC721OmmgMetadata ////////////////////////////////////////////

    /// @inheritdoc IERC721Metadata
    function name()
        public
        view
        virtual
        override(IERC721Metadata, IOmmgFrontEnd)
        returns (string memory)
    {
        return _name;
    }

    /// @inheritdoc IERC721Metadata
    function symbol()
        public
        view
        virtual
        override(IERC721Metadata, IOmmgFrontEnd)
        returns (string memory)
    {
        return _symbol;
    }

    /// @inheritdoc IERC721OmmgMetadata
    function revealed() public view returns (bool) {
        return _revealed;
    }

    /// @inheritdoc IERC721OmmgMetadata
    function tokenRevealed(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenRevealed[tokenId] || _revealed;
    }

    /// @inheritdoc IERC721OmmgMetadata
    function overridesFullURI(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _overrideFullURI[tokenId];
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory _base = _baseURI;

        if (!_revealed && !_tokenRevealed[tokenId]) {
            return _unrevealedTokenURI;
        } else {
            if (bytes(_tokenURI).length > 0) {
                if (_overrideFullURI[tokenId]) return _tokenURI;
                else return string(abi.encodePacked(_base, _tokenURI));
            } else {
                if (bytes(_baseURI).length > 0)
                    return string(abi.encodePacked(_base, tokenId.toString()));
                else return _tokenURI;
            }
        }
    }

    /// @inheritdoc IERC721OmmgMetadata
    function reveal()
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revealed = true;
        emit Revealed();
    }

    /// @inheritdoc IERC721OmmgMetadata
    function revealToken(uint256 tokenId)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        _tokenRevealed[tokenId] = true;
        emit TokenRevealed(tokenId);
    }

    /// @inheritdoc IERC721OmmgMetadata
    function setTokenURI(
        uint256 tokenId,
        bool overrideBaseURI,
        bool overrideReveal,
        string memory _tokenURI
    )
        external
        override
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
        _overrideFullURI[tokenId] = overrideBaseURI;
        if (overrideReveal && !_tokenRevealed[tokenId]) {
            _tokenRevealed[tokenId] = true;
            emit TokenRevealed(tokenId);
        }
        emit SetTokenUri(tokenId, false, false, _tokenURI);
    }

    /// @inheritdoc IERC721OmmgMetadata
    function setUnrevealedTokenURI(string memory unrevealedTokenURI)
        external
        override
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _unrevealedTokenURI = unrevealedTokenURI;
        emit UnrevealedTokenUriSet(_unrevealedTokenURI);
    }

    /// @inheritdoc IERC721OmmgMetadata
    function setBaseURI(string memory baseURI)
        external
        override
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _baseURI = baseURI;
        emit SetBaseUri(baseURI);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC721OmmgMetadataFreezable ///////////////////////////////////

    modifier whenMetadataIsNotFrozen() {
        if (_metadataFrozen) revert MetadataIsFrozen();
        _;
    }

    /// @inheritdoc IERC721OmmgMetadataFreezable
    function metadataFrozen() public view returns (bool) {
        return _metadataFrozen;
    }

    /// @inheritdoc IERC721OmmgMetadataFreezable
    function freezeMetadata()
        public
        virtual
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _metadataFrozen = true;
        emit MetadataFrozen();
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC165 ////////////////////////////////////////////////////////

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721Ommg, ERC721OmmgSnapshot, OmmgAccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IOmmgEmergencyTokenRecoverable).interfaceId ||
            interfaceId == type(IERC721OmmgMetadataFreezable).interfaceId ||
            interfaceId == type(IOmmgAcquirableWithToken).interfaceId ||
            interfaceId == type(IERC721OmmgEnumerable).interfaceId ||
            interfaceId == type(IERC721OmmgMetadata).interfaceId ||
            interfaceId == type(IOmmgProvenanceHash).interfaceId ||
            interfaceId == type(IOmmgMutablePrice).interfaceId ||
            interfaceId == type(IOmmgWithdrawable).interfaceId ||
            interfaceId == type(IOmmgSalePausable).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IOmmgAcquirable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IOmmgSupplyCap).interfaceId ||
            interfaceId == type(IOmmgFrontEnd).interfaceId ||
            interfaceId == type(IOmmgOwnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}