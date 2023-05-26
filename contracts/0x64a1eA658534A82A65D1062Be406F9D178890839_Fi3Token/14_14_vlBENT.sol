/**
 *Submitted for verification at BscScan.com on 2023-03-29
 */

/**
 *Submitted for verification at BscScan.com on 2023-03-23
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IERC20.sol";
import "./utils/Initializable.sol";
import "./BentCDP.sol";

contract vlBENT is Initializable, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public totalSupply;

    string public name;
    string public symbol;
    address public admin;
    address public minter;

    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        name = _name;
        symbol = _symbol;
        admin = address(msg.sender);
        minter = address(msg.sender);
    }

    function updateMinter(address _minter) public {
        require(msg.sender == admin, "only owner");
        minter = _minter;
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param from The address of the source account
     * @param to The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        BentCDP CDP = BentCDP(minter);
        CDP.onTransfer(from, to);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
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
        }

        emit Transfer(from, to, amount);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param to The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = msg.sender;
        BentCDP CDP = BentCDP(minter);
        CDP.onTransfer(msg.sender, to);
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @notice Mint New Token
     * @param to The address of the Account For which token are minted
     * @param amount The number of tokens to mint
     */
    function mintRequest(address to, uint256 amount) public {
        require(msg.sender == admin || msg.sender == minter, "only owner");
        mint(to, amount);
    }

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param to The address of the Account For which token are burned
     * @param amount The number of tokens to burned
     */
    function burnRequest(address to, uint256 amount) public {
        require(msg.sender == admin || msg.sender == minter, "only owner");
        burn(to, amount);
    }

    function burn(address account, uint256 amount) public {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

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
}