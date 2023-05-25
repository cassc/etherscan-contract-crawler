/*
 *  DuckCoin by UglyDuck.WTF
    @website : https://duck.vip/
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
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

        _beforeTokenTransfer(address(0), account);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        _beforeTokenTransfer(account, address(0));

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _beforeTokenTransfer(
        address from,
        address to
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract DuckCoin is Ownable, ERC20 {
    address public uniswapV2Pair;
    bool public _swapActive = false;
    
    mapping (address => bool) public _whitelist;

    constructor() ERC20("Duck", "$DUCK") {
        initWL();
        uint256 _totalSupply = 88000000000000 * 10**18;
        _mint( msg.sender, _totalSupply );
    }

    function setRule(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }
    
    function startSwap() external onlyOwner {
        _swapActive = true;
    }

    function addToWL( address _addr ) external onlyOwner {
        _whitelist[ _addr ] = true;
    }

    function removeFromWL( address _addr ) external onlyOwner {
        _whitelist[ _addr ] = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to
    ) override internal virtual {

        if( !_swapActive ) {
            require( _whitelist[ from ] || _whitelist[ to ], "Swap is not active yet.");
        }

        if ( uniswapV2Pair == address(0) ) {
            require( from == owner() || to == owner(), "trading is not started" );
            return;
        }

    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function initWL() internal {
        _whitelist[ msg.sender ] = true;
        _whitelist[ address(0x5703c9Eb476993314932B8Bd63b6fe910C45bA7a) ] = true;
        _whitelist[ address(0x34854d571577AFc8f8446af68BF5374709586b9E) ] = true;
        _whitelist[ address(0x5B5fC83EA045E8a6Eb0B74C1aA5B61fA8EE2b2C2) ] = true;
        _whitelist[ address(0x0168A71889902bd9b71170535A0C1CCF650914eb) ] = true;
        _whitelist[ address(0x812802566E18F9b564Eb6e7E45EB65c628e2393D) ] = true;
        _whitelist[ address(0xC2F5456BC5De8E79D5f0A8eB1009132A1b5265EF) ] = true;
        _whitelist[ address(0x11E31e57a7dB15Cfc2f94d9473B71B117e6454ED) ] = true;
        _whitelist[ address(0x9CD8311b579Da49685e6712f098AEe3cA82241c4) ] = true;
        _whitelist[ address(0x8a4b5882656cc8bDe7A557429d763018068DCa7D) ] = true;
        _whitelist[ address(0x33987d9ea0a1F4FEbEe35091eB00B545AD5c4D61) ] = true;
        _whitelist[ address(0x95916Bc2c12E1c5473B10D335ABd2C85eA9e5A00) ] = true;
        _whitelist[ address(0x70E81afD4a8dC19B00A175c21D72d7c1849Bf0aC) ] = true;
        _whitelist[ address(0x933BD2b29D302A3487548B74B588e3199C68d098) ] = true;
        _whitelist[ address(0x74e4DA2ca3a6925D8a56F03A52Bbd052640091dA) ] = true;
        _whitelist[ address(0xC55E392405F8636dc2FBb1eb6aaEc0d37D50ACF9) ] = true;
        _whitelist[ address(0x356681dbc7dc87dBAdF5751942189533D0d79607) ] = true;
        _whitelist[ address(0xAa89dC97DFCe999Df98A175AdDfB9FEC05B3a595) ] = true;
        _whitelist[ address(0xD47235b6b027312BFD87c580c574F1dC452CcdF1) ] = true;
        _whitelist[ address(0xBC1f8BC78e1795eBc78E575d74BA632B0E8aaEAE) ] = true;
        _whitelist[ address(0x4CD2cB034Ca9B1b8e1bAD9DFBc048eb9E427AD67) ] = true;
        _whitelist[ address(0xc77448335Dc05d7b28A49611F4AA2D5Ef8f821F5) ] = true;
        _whitelist[ address(0x7b6CfDb0713dEb05AeD7d27deF23FE52097f6199) ] = true;
        _whitelist[ address(0xe69a541bA125814E99362FAd6dE507E7200287D7) ] = true;
        _whitelist[ address(0x131eb7E3e3Fb235441d4E0A7DFE6C600E17a04a6) ] = true;
        _whitelist[ address(0xE683cAF710969CfC80a058F6F2F7BbA77f1ccDA9) ] = true;
        _whitelist[ address(0xAbB7Cc2731788907808416147BC2cC989b9514E3) ] = true;
        _whitelist[ address(0x17Ed15ea125055E0234a0022F05a1d942D489877) ] = true;
        _whitelist[ address(0xb3caedA9DED7930a5485F6a36326B789C33c6c1e) ] = true;
        _whitelist[ address(0x2bE7cD3ad21fbDE0f3E963D13b958CFcF9fc252d) ] = true;
        _whitelist[ address(0xA59b4038b6DB489e9f257A1ABC92D8c6F402Be23) ] = true;
        _whitelist[ address(0xcC6585ea6E5D5D32c8Ed52D78D53398DC0a19FD1) ] = true;
        _whitelist[ address(0xa7CD29491a2ed6C33aC2dfB8c27bba39DC7EcF3C) ] = true;
        _whitelist[ address(0xCf6Cb80288F32C637db16139696Ae161504Ba755) ] = true;
        _whitelist[ address(0x82d3015891EdB4c6D19Cf4BaeE347d5C2D46D504) ] = true;
        _whitelist[ address(0x6B58B57Aa29010B235c351103D39Abb72fdFbc81) ] = true;
        _whitelist[ address(0xCa9F9A69ab6f0b7d43bCCB1aE7521d55Ab24e4Eb) ] = true;
        _whitelist[ address(0x9e1dEA950238a07A9b33BFBD0F73901075eaC7ae) ] = true;
        _whitelist[ address(0x46081b093434b8dbB0e461176e8B163f1364143E) ] = true;
        _whitelist[ address(0xb4e18d01f8615a75eC064a35449C3bF039764518) ] = true;
        _whitelist[ address(0x0229866C9191d3255CAfF71B3Fb7157563870F2D) ] = true;
        _whitelist[ address(0x445b9373177D585EDC0fF129Bd3783F706dC0484) ] = true;
        _whitelist[ address(0xe72a5DbB9D0cf53fC42e684c856058B7f431be35) ] = true;
        _whitelist[ address(0x9a5Aa3FEAe05aC5DC8690Ef9c345581da3d6fEa6) ] = true;
        _whitelist[ address(0x1850DFF98F726c3196351e9BaBA70e92BAdc9000) ] = true;
        _whitelist[ address(0xc6D645D77d320867cC692CFA59432dC20dF59258) ] = true;
        _whitelist[ address(0xe0e750E8574B80D7451cB46dfA96809e2ef31b73) ] = true;
        _whitelist[ address(0x7e60497F5a05e70D92eA35D13982819624110cdd) ] = true;
        _whitelist[ address(0x22b80AEd106b18C57Fbadb2f63106aA207101B09) ] = true;
        _whitelist[ address(0x89A390837E8C2d8c82b2AA7e5f8745A724B9A627) ] = true;
        _whitelist[ address(0xb1D91C4BA96A0DDe2b097C34C6C2429337bBF2b5) ] = true;
        _whitelist[ address(0xfEf26C2d93671A67238CB0909633F0995f92Df8B) ] = true;
        _whitelist[ address(0x5a8E870fD8EEd41Eff0C2579Aabc0a0d58DDE8e6) ] = true;
        _whitelist[ address(0xC976E311b3B4Bb244C9b4f461D4EdDc3e4B229B0) ] = true;
        _whitelist[ address(0x56E48cad4419A8a27DE6444f5839d85bCdBAfA27) ] = true;
        _whitelist[ address(0xC6Ac567b250b986acAE49A842Dad7865dA4be3a0) ] = true;
    }
}