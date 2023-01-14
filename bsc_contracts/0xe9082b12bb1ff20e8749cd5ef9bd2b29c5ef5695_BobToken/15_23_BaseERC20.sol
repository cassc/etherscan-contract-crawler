// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title BaseERC20
 */
abstract contract BaseERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    function name() public view virtual override returns (string memory);

    function symbol() public view virtual override returns (string memory);

    function decimals() public view override returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view virtual override returns (uint256 _balance) {
        _balance = _balances[account];
        assembly {
            _balance := and(_balance, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _decreaseBalance(from, amount);
        _increaseBalance(to, amount);

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        _increaseBalance(account, amount);

        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _decreaseBalance(account, amount);
        totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _increaseBalance(address _account, uint256 _amount) internal {
        uint256 balance = _balances[_account];
        require(balance < 1 << 255, "ERC20: account frozen");
        unchecked {
            _balances[_account] = balance + _amount;
        }
    }

    function _decreaseBalance(address _account, uint256 _amount) internal {
        uint256 balance = _balances[_account];
        require(balance < 1 << 255, "ERC20: account frozen");
        require(balance >= _amount, "ERC20: amount exceeds balance");
        unchecked {
            _balances[_account] = balance - _amount;
        }
    }

    function _decreaseBalanceUnchecked(address _account, uint256 _amount) internal {
        uint256 balance = _balances[_account];
        unchecked {
            _balances[_account] = balance - _amount;
        }
    }

    function _isFrozen(address _account) internal view returns (bool) {
        return _balances[_account] >= 1 << 255;
    }

    function _freezeBalance(address _account) internal {
        _balances[_account] |= 1 << 255;
    }

    function _unfreezeBalance(address _account) internal {
        _balances[_account] &= (1 << 255) - 1;
    }
}