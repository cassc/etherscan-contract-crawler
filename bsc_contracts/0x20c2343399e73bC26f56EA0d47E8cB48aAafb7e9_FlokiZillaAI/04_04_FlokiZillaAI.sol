// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlokiZillaAI is IERC20, Ownable {
    /// @dev Registry of user token balances.
    mapping(address => uint256) private _balances;

    /// @dev Registry of addresses users have given allowances to.
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @dev Name of the token.
    string private _name;

    /// @dev Symbol of the token.
    string private _symbol;

    /**
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token.
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;

        _balances[_msgSender()] = totalSupply();

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    /**
     * @notice Get token name.
     * @return Name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Get token symbol.
     * @return Symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Get number of decimals used by the token.
     * @return Number of decimals used by the token.
     */
    function decimals() external pure returns (uint8) {
        return 9;
    }

    /**
     * @notice Get the maximum number of tokens.
     * @return The maximum number of tokens that will ever be in existence.
     */
    function totalSupply() public pure override returns (uint256) {
        // Ten trillion, i.e., 10,000,000,000,000 tokens.
        return 1e13 * 1e9;
    }

    /**
     * @notice Get token balance of given given account.
     * @param account Address to retrieve balance for.
     * @return The number of tokens owned by `account`.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfer tokens from caller's address to another.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if transfer succeeds, else an error is raised.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice Get the allowance `owner` has given `spender`.
     * @param owner The address on behalf of whom tokens can be spent by `spender`.
     * @param spender The address authorized to spend tokens on behalf of `owner`.
     * @return The allowance `owner` has given `spender`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve address to spend caller's tokens.
     * @dev This method can be exploited by malicious spenders if their allowance is already non-zero. See the following
     * document for details: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit.
     * Ensure the spender can be trusted before calling this method if they've already been approved before. Otherwise
     * use either the `increaseAllowance`/`decreaseAllowance` functions, or first set their allowance to zero, before
     * setting a new allowance.
     * @param spender Address to authorize for token expenditure.
     * @param amount The number of tokens `spender` is allowed to spend.
     * @return True if the approval succeeds, else an error is raised.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @param sender Address to move tokens from.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if the transfer succeeds, else an error is raised.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "FlokiZillaAI:transferFrom:ALLOWANCE_EXCEEDED: Transfer amount exceeds allowance."
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @notice Increase spender's allowance.
     * @param spender Address of user authorized to spend caller's tokens.
     * @param addedValue The number of tokens to add to `spender`'s allowance.
     * @return True if the allowance is successfully increased, else an error is raised.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;
    }

    /**
     * @notice Decrease spender's allowance.
     * @param spender Address of user authorized to spend caller's tokens.
     * @param subtractedValue The number of tokens to remove from `spender`'s allowance.
     * @return True if the allowance is successfully decreased, else an error is raised.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "FlokiZillaAI:decreaseAllowance:ALLOWANCE_UNDERFLOW: Subtraction results in sub-zero allowance."
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Approve spender on behalf of owner.
     * @param owner Address on behalf of whom tokens can be spent by `spender`.
     * @param spender Address to authorize for token expenditure.
     * @param amount The number of tokens `spender` is allowed to spend.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "FlokiZillaAI:_approve:OWNER_ZERO: Cannot approve for the zero address.");
        require(spender != address(0), "FlokiZillaAI:_approve:SPENDER_ZERO: Cannot approve to the zero address.");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer `amount` tokens from account `from` to account `to`.
     * @param from Address the tokens are moved out of.
     * @param to Address the tokens are moved to.
     * @param amount The number of tokens to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "FlokiZillaAI:_transfer:FROM_ZERO: Cannot transfer from the zero address.");
        require(to != address(0), "FlokiZillaAI:_transfer:TO_ZERO: Cannot transfer to the zero address.");
        require(amount > 0, "FlokiZillaAI:_transfer:ZERO_AMOUNT: Transfer amount must be greater than zero.");
        require(amount <= _balances[from], "FlokiZillaAI:_transfer:INSUFFICIENT_BALANCE: Transfer amount exceeds balance.");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
}