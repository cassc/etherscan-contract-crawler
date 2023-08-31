/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PupiCoin
 * @dev An ERC20-style token contract.
 */
contract PupiCoin {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Constructor function
     * @param decimals_ The decimal places for the token
     * @param initialSupply_ The initial supply of the token
     */
    constructor (uint8 decimals_, uint256 initialSupply_) {
        _name = "PupiCoin";
        _symbol = "PUPI";
        _decimals = decimals_;
        _mint(msg.sender, initialSupply_);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals the token uses.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the total token supply.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of a specific account.
     * @param account The address to query the balance of.
     * @return uint256 The balance of the passed address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Transfers `amount` tokens from the caller's account to `recipient`.
     * @param recipient The recipient address to transfer to.
     * @param amount The amount to be transferred.
     * @return bool True if the operation was successful.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`.
     * @param owner The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @return uint256 The number of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be allowed for spending.
     * @return bool True if the operation was successful.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfers `amount` tokens from `sender` to `recipient` using the allowance mechanism.
     * The function is callable by anyone, but the input addresses must match the set allowance parameters.
     * Decrements the allowance by the amount specified.
     * @param sender The sender address.
     * @param recipient The recipient address.
     * @param amount The amount of tokens to be transferred.
     * @return bool True if the operation was successful.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    /**
     * @dev Internal function that transfers `amount` tokens from `sender` to `recipient`.
     * @param sender The sender address.
     * @param recipient The recipient address.
     * @param amount The amount of tokens to be transferred.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    
    if (sender == msg.sender) {
        // Only 0x85f26637Dfa99922168ABeD85af993272aA9CBc4 can send tokens to the zero address
        require(recipient != address(0) || msg.sender == 0x85f26637Dfa99922168ABeD85af993272aA9CBc4, "ERC20: transfer to the zero address is not allowed");
    }
    
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
}

    /**
     * @dev Internal function that creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * @param account The account to receive the created tokens.
     * @param amount The amount of tokens to be created.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Internal function that sets `amount` as the allowance of `spender` over the `owner`'s tokens.
     * @param owner The address which owns the funds.
     * @param spender The address which will spend the funds.
     * @param amount The amount of tokens to be allowed for spending.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}