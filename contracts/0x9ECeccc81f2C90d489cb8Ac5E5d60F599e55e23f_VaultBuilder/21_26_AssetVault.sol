// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./interfaces/IMetaWealthModerator.sol";
import "./interfaces/IAssetVault.sol";
import "./interfaces/IVaultBuilder.sol";

contract AssetVault is
    Initializable,
    ContextUpgradeable,
    ReentrancyGuardUpgradeable,
    IAssetVault
{
    uint256 private _totalShares;

    mapping(address => uint256) private _shares;

    /// @notice Maintain list of all share holders
    address[] private _payees;
    /// @notice Mapping to eliminate for-loops for above array where possible
    mapping(address => uint256) private _shareholderIndex;

    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice MetaWealth moderator contract for currency and whitelist checks
    IMetaWealthModerator public metawealthMod;

    address private _vaultBuilder;

    /// @notice Asset activity metadata
    bool active;

    /// @notice not used anymore, it still here to not break storage
    uint64 unlockTimestamp;
    /// @notice Asset-specific currency attached
    address tradingCurrency;
    address public collection;
    uint256 public tokenId;
    string private _name;
    string private _symbol;

    modifier onlyAdmin() {
        require(
            metawealthMod.isAdmin(_msgSender()),
            "MetaWealthAccessControl: Restricted to Admins"
        );
        _;
    }
    modifier onlyAssetManager() {
        require(
            metawealthMod.isAssetManager(_msgSender()),
            "MetaWealthAccessControl: Restricted to Asset managers"
        );
        _;
    }
    modifier onlySupportedCurrency(IERC20Upgradeable currency) {
        require(
            metawealthMod.isSupportedCurrency(address(currency)),
            "MetaWealthCurrencies: currency not supported"
        );
        _;
    }

    /// @param payees all shareholders
    /// @param shares_ shares of each payee in payees array
    /// @param metawealthMod_ is the moderator contract of MetaWealth platform
    function initialize(
        address[] memory payees,
        uint256[] memory shares_,
        IMetaWealthModerator metawealthMod_,
        address vaultBuilder_,
        address _collection,
        uint256 _tokenId,
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ReentrancyGuard_init();
        __Context_init();
        require(
            AddressUpgradeable.isContract(_collection),
            "AssetVault: collection is not contract"
        );
        require(
            AddressUpgradeable.isContract(address(metawealthMod_)),
            "AssetVault: metawealthMod is not contract"
        );
        require(
            AddressUpgradeable.isContract(address(vaultBuilder_)),
            "AssetVault: vaultBuilder is not contract"
        );
        require(
            payees.length == shares_.length,
            "PaymentSplitter: payees and shares length mismatch"
        );
        require(payees.length > 0, "PaymentSplitter: no payees");
        /// @dev Push a 0-address so that reverse-mapping of _shareholderIndex can start from 1
        _payees.push(address(0));
        _shareholderIndex[address(0)] = 0;
        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
            emit Transfer(address(0), payees[i], shares_[i]);
        }
        _name = name_;
        _symbol = symbol_;

        metawealthMod = metawealthMod_;
        _vaultBuilder = vaultBuilder_;
        tradingCurrency = metawealthMod.defaultCurrency();
        active = false;
        collection = _collection;
        tokenId = _tokenId;
        emit CurrencyChanged(address(0), tradingCurrency);
    }

    function version() public pure returns (string memory) {
        return "V1";
    }

    // >>>>>>>> View Methods <<<<<<<<<
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalShares;
    }

    function isActive() external view override returns (bool active_) {
        return active;
    }

    function getShareholders()
        external
        view
        override
        returns (address[] memory)
    {
        return _payees;
    }

    function getTradingCurrency()
        external
        view
        override
        returns (address currency)
    {
        return tradingCurrency;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _shares[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    // >>>>>>>> View Methods <<<<<<<<<

    // >>>>>>>> Mutations <<<<<<<<<
    function setTradingCurrency(
        IERC20Upgradeable newCurrency
    ) external override onlyAdmin onlySupportedCurrency(newCurrency) {
        address _old = tradingCurrency;
        tradingCurrency = address(newCurrency);
        emit CurrencyChanged(_old, tradingCurrency);
    }

    function toggleStatus()
        external
        override
        onlyAssetManager
        returns (bool newStatus)
    {
        active = !active;
        emit StatusChanged(active);
        return active;
    }

    function defractionalize()
        external
        override
        onlyAdmin
        nonReentrant
        returns (address shareholder)
    {
        require(_payees.length > 1, "AssetVault: account is not shareholder");
        address account = _payees[1];

        require(
            _shares[account] != 0,
            "AssetVault: account is not shareholder"
        );
        require(
            _shares[account] == _totalShares,
            "AssetVault: account has to be one shareholder"
        );

        require(
            IVaultBuilder(_vaultBuilder).onDefractionalize(
                collection,
                tokenId,
                account
            ),
            "AssetVauld: failed to defractinalize"
        );
        _removePayee(account);
        _totalShares = 0;
        IERC721Upgradeable(collection).transferFrom(
            address(this),
            account,
            tokenId
        );

        return account;
    }

    function deposit(
        IERC20Upgradeable token,
        uint256 _amount
    ) external onlyAssetManager onlySupportedCurrency(token) nonReentrant {
        uint256 fee = metawealthMod.calculateAssetDepositShareholdersFee(
            _amount
        );
        address treasurryWallet = metawealthMod.treasuryWallet();
        SafeERC20Upgradeable.safeTransferFrom(
            token,
            _msgSender(),
            treasurryWallet,
            fee
        );
        uint256 amount = _amount - fee;
        /// @dev start from 1 to skip zero address
        for (uint256 i = 1; i < _payees.length; i++) {
            address account = _payees[i];
            uint256 payment = _pendingPayment(account, amount);
            if (payment == 0) {
                continue;
            }

            SafeERC20Upgradeable.safeTransferFrom(
                token,
                _msgSender(),
                account,
                payment
            );
        }

        emit FundsDeposited(address(token), amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // >>>>>>>> Mutations <<<<<<<<<

    // >>>>>>>> Helpers <<<<<<<<<
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _shares[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _shares[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _shares[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _pendingPayment(
        address account,
        uint256 totalAmount
    ) private view returns (uint256) {
        return (_shares[account] * totalAmount) / _totalShares;
    }

    function _removePayee(address account) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );

        uint256 lastPayeeIndex = _payees.length - 1;
        address lastPayee = _payees[lastPayeeIndex];
        uint256 index = _shareholderIndex[account];
        address payeeToBeRemoved = _payees[index];

        _payees[index] = lastPayee;
        _shareholderIndex[lastPayee] = index;

        delete _shareholderIndex[payeeToBeRemoved];
        _payees.pop();

        uint256 shares_ = _shares[account];
        _shares[account] = 0;
        emit PayeeRemoved(account, shares_);
    }

    function _addPayee(address account, uint256 shares_) private {
        require(
            account != address(0),
            "PaymentSplitter: account is the zero address"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[account] == 0,
            "PaymentSplitter: account already has shares"
        );

        // _payees.push(account);
        _shareholderIndex[account] = _payees.length;
        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        /// @dev case where an existing shareholder exits the position
        if (
            from != address(0) &&
            _shares[from] == 0 &&
            _shareholderIndex[from] != 0
        ) {
            _removePayee(from);
        }

        /// @dev case where a new shareholder starts the position
        if (
            to != address(0) &&
            _shares[to] == amount &&
            _shareholderIndex[to] == 0
        ) {
            _shareholderIndex[to] = _payees.length;
            _payees.push(to);
        }
    }

    // >>>>>>>> Helpers <<<<<<<<<

    uint256[38] private __gap;
}