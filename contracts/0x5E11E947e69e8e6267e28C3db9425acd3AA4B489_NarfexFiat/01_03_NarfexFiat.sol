//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface INarfexFiatFactory {
  /**
   * @dev Returns the factory owner address
   */
  function owner() external view returns (address);
  
  /**
   * @dev Returns the router address
   */
  function getRouter() external view returns (address);
}

contract NarfexFiat is IERC20 {
    using Address for address;

    INarfexFiatFactory private _factory;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 constant MAX_INT = type(uint).max;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address factoryAddress
        ) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _factory = INarfexFiatFactory(factoryAddress);

        uint8 currentDecimals = 6;
        if (block.chainid == 56 || block.chainid == 97) {
            currentDecimals = 18;
        }
        _decimals = currentDecimals;
    }

    modifier onlyOwner {
        require(isHaveFullAccess(msg.sender), "You have no access");
        _;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() public view returns (address) {
        return _factory.owner();
    }

    /**
     * @dev Returns current router.
     */
    function getRouter() public view returns (address) {
        return _factory.getRouter();
    }

    /// @notice Returns true if the specified address have full access to user funds management
    /// @param account Account address
    /// @return Boolean
    function isHaveFullAccess(address account) internal view returns (bool) {
        return account == getOwner() || account == getRouter();
    }

    /**
     * @dev Returns the token name.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token decimals.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the token symbol.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Returns available allowance for specified spender address
    /// @notice The owners have maximum allowance
    /// @param owner The balance owner
    /// @param spender Spender account address
    /// @return Allowed amount of tokens
    function allowance(address owner, address spender) public override view returns (uint256) {
        if (isHaveFullAccess(spender)) {
            return MAX_INT;
        } else {
            return _allowances[owner][spender];
        }
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (!isHaveFullAccess(msg.sender)) { // Do not decrease allowance for the owners
            _approve(
                sender,
                msg.sender,
                _allowances[sender][msg.sender] - amount
            );
        }
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - subtractedValue
        );
        return true;
    }

    /// @notice Mint amount of tokens to specified reciever address
    /// @notice Only owners can mint a new tokens
    /// @param receiver Account address which will receive the tokens
    /// @param amount Number of minted tokens
    /// @return Always true
    function mintTo(address receiver, uint256 amount) public onlyOwner returns (bool) {
        _mint(receiver, amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Burn amount of tokens from specified account address
    /// @notice Only owners can burn
    /// @param account The address where the tokens will be burned
    /// @param amount Number of burned tokens
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }

    /// @notice Returns data for user in one request
    /// @param account Account address
    /// @return Token Name
    /// @return Token Symbol
    /// @return Account balance
    function getInfo(address account) public view returns (string memory, string memory, uint) {
        return (
            _name,
            _symbol,
            balanceOf(account)
        );
    }
}