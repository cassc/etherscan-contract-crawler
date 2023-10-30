// SPDX-License-Identifier: MIT
//
//  ____    ____   ________   ______     _____   ________       _        ___  ____    _________  
// |_   \  /   _| |_   __  | |_   _ `.  |_   _| |_   __  |     / \      |_  ||_  _|  |  _   _  | 
//   |   \/   |     | |_ \_|   | | `. \   | |     | |_ \_|    / _ \       | |_/ /    |_/ | | \_| 
//   | |\  /| |     |  _| _    | |  | |   | |     |  _|      / ___ \      |  __'.        | |     
//  _| |_\/_| |_   _| |__/ |  _| |_.' /  _| |_   _| |_     _/ /   \ \_   _| |  \ \_     _| |_    
// |_____||_____| |________| |______.'  |_____| |_____|   |____| |____| |____||____|   |_____|   
//              
//                                                                               

pragma solidity ^0.8.0;

import './Security.sol';

contract MEDIFAKT is Security {

    string private _name;
    string private _symbol;
    uint256 private _decimals;

    uint256 private _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _name = "MEDIFAKT";
        _symbol = "FAKT";
        _decimals = 18;

        _mint(_msgSender(), 999999999 * 10 ** 18);
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
    * @dev Returns the decimals of the token.
    */
    function decimals() public view returns (uint256) {
        return _decimals;
    }

    /**
    * @dev Returns the total supply of the token.
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Returns the amount of tokens owned by `account`.
    */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev Returns the allowances.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Mints the amount of tokens by owner.
     */
    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    /**
     * @dev Burns the amount of tokens owned by caller.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    */
    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        require(!isBlackListed[owner], "FAKT: locked account");
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev Increases the allowance of `spender` by `amount`.
     */
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        require(!isBlackListed[owner], "FAKT: locked account");
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Decreases the allowance of `spender` by `amount`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);

        require(!isBlackListed[owner], "FAKT: locked account");
        require(currentAllowance >= subtractedValue, "FAKT: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
    * @dev Moves `amount` tokens from the caller's account to `to`.
    */
    function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
        address owner = _msgSender();
        require(!isBlackListed[owner], "FAKT: locked account");
        _transfer(owner, to, amount);
        return true;
    }

    /**
    * @dev Moves `amount` tokens from `from` to `to` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    */
    function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
        address spender = _msgSender();
        require(!isBlackListed[from], "FAKT: locked account");
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /*////////////////////////////////////////////////
                    INTERNAL FUNCTIONS
      ////////////////////////////////////////////////*/

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "FAKT: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "FAKT: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "FAKT: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "FAKT: approve from the zero address");
        require(spender != address(0), "FAKT: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "FAKT: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "FAKT: transfer from the zero address");
        require(to != address(0), "FAKT: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "FAKT: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal {}

    /*////////////////////////////////////////////////
                    EVENTS
      ////////////////////////////////////////////////*/

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}