// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "./utils/Authorizable.sol";
import "../interfaces/IERC20.sol";
import "../libraries/SafeMath.sol";

// QredoToken => QT
contract QredoToken is Authorizable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _circulatingSupply;

    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 initialSupply_) public {
        require(bytes(name_).length > 0, "QT:constructor::name_ is undefined");
        require(bytes(symbol_).length > 0, "QT:constructor::symbol_ is undefined");
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;
        
        if(initialSupply_ > 0){
            _mint(_msgSender(), initialSupply_);
        }
    }

    //*************************************************** PUBLIC ***************************************************//
    
    /**
        * @dev Moves `amount` tokens from the caller's account to `recipient`.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} event.
        *
        * Requirements:
        * - `recipient` cannot be the zero address.
        * - the caller must have a balance of at least `amount`.
    */
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
        * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
        *
        * This internal function is equivalent to `approve`, and can be used to
        * e.g. set automatic allowances for certain subsystems, etc.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits an {Approval} event.
        *
        * Requirements:
        * - `owner` cannot be the zero address.
        * - `spender` cannot be the zero address.
        *
        * Emits an {Approval} event.
    */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
        * @dev Atomically increases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
        *
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        * - `spender` cannot be the zero address.
    */
    function increaseAllowance(address spender, uint256 addedValue) external override returns (bool) {
        require(spender != address(0),"QT::increaseAllowance:spender must be different than 0");
        
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
        * @dev Atomically decreases the allowance granted to `spender` by the caller.
        *
        * This is an alternative to {approve} that can be used as a mitigation for
        * problems described in https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729.
        *
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits an {Approval} event indicating the updated allowance.
        *
        * Requirements:
        * - `spender` cannot be the zero address.
        * - `spender` must have allowance for the caller of at least
        * `subtractedValue`.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        require(spender != address(0),"QT::decreaseAllowance:spender must be different than 0");

        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "QT::decreaseAllowance: decreased allowance below zero");
        
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    /**
        * @dev Moves `amount` tokens from `sender` to `recipient` using the
        * allowance mechanism. `amount` is then deducted from the caller's
        * allowance.
        *
        * Returns a boolean value indicating whether the operation succeeded.
        *
        * Emits a {Transfer} and {Approve} events
        *
        * Requirements:
        * - `sender` and `recipient` cannot be the zero address.
        * - `sender` must have a balance of at least `amount`.
        * - the caller must have allowance for ``sender``'s tokens of at least
        * `amount`..
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "QT::transferFrom: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance.sub(amount));

        return true;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens
     * @param value The amount of tokens to mint
     */
    function mint(address to, uint256 value) external override onlyAuthorized() returns (bool) {
        _mint(to, value);
        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    //*************************************************** VIEWS ***************************************************//
    
    /**
        * @dev Returns the name of the token.
    */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
        * @dev Returns the symbol of the token, usually a shorter version of the
        * name.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
        * @dev Returns the number of decimals used to get its user representation.
        * For example, if `decimals` equals `2`, a balance of `505` tokens should
        * be displayed to a user as `5,05` (`505 / 10 ** 2`).
        *
        * Tokens usually opt for a value of 18, imitating the relationship between
        * Ether and Wei. This is the value {ERC20} uses, unless this function is
        * overridden;
        *
        * NOTE: This information is only used for _display_ purposes: it in
        * no way affects any of the arithmetic of the contract, including
        * {ERC20Proxy-balanceOf}, {ERC20Storage-balanceOf}  and {ERC20Logic-transfer}.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
        * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
        * @dev Returns the amount of tokens in existence.
    */
    function circulatingSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }
    
    /**
        * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
        * @dev Returns the remaining number of tokens that `spender` will be
        * allowed to spend on behalf of `owner` through {transferFrom}. This is
        * zero by default.
        *
        * This value changes when {approve}, {increaseAllowance}, {decreaseAllowance} or {transferFrom} are called.
    */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    //*************************************************** INTERNAL ***************************************************//
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "QT::_transfer: transfer from the zero address");
        require(recipient != address(0), "QT::_transfer: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "QT::_transfer: transfer amount exceeds balance");

        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "QT::_approve: approve from the zero address");
        require(spender != address(0), "QT::_approve: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "QT::_mint:mint to the zero address");
        require(_circulatingSupply.add(amount) <= _totalSupply, "QT::_mint:mint exceeds totalSupply");
        require(amount > 0, "QT::_mint:amount must be greater than zero");

        _circulatingSupply = _circulatingSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "QT::_burn:burn from the zero address");
        require(amount > 0, "QT::_burn:amount must be greater than zero");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "QT::_burn:burn amount exceeds balance");

        _balances[account] = accountBalance.sub(amount);
        _circulatingSupply = _circulatingSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

}