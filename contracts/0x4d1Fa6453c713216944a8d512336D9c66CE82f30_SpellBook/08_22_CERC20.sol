// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./uniswap/IUniswapV2Pair.sol";

import "./ICurse.sol";
import "./ICaster.sol";

/**
 * @dev Implementation of the {IERC20} interface for CURSE {CERC20}.
 *
 * This implementation supports basic features of the CURSE ecosystem.
 * Inheriting this contract means that it will be compatible with the CURSE ecosystem
 * and the supply/demand mechanism of the standard ERC-20 contract can be altered
 * by Spells which could be casted by the users. 
 *
 * TIP: For a detailed writeup see our guide
 * https://medium.com/TheCurseDao/the-ecosystem-icerc-20-5f318a4c8777
 * how to implement the required featues.
 *
 */
contract CERC20 is Context, IERC20, IERC20Metadata, AccessControl, ICurse {
    bytes32 public constant SPELLBOOK_ROLE = keccak256("SPELLBOOK_ROLE");
    
    // Spell settings
    uint256 public constant SPELL_DENOMINATOR = 10000; // Allow settings set in the range of 0.01%

    // Spell contants
    uint8 public constant EFFECT_FREEZE = 1;
    uint8 public constant EFFECT_PROTECT = 2;
    uint8 public constant EFFECT_STOLEN = 3;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    ICaster internal CASTER;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address data, string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        CASTER = ICaster(data);
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
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
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Get the frozen effect from the caster data
     *
     * This internal function to query the frozen effect from the caster data. Can be used
     * in the token logic to prevent sells/etc
     *
     */
    function isFrozen(address target) internal view returns (bool) {
        return CASTER.hasEffect(target, EFFECT_FREEZE);
    }

    /**
     * @dev Get the stolen effect from the caster data
     *
     * This internal function to query the stolen effect from the caster data. Can be used
     * in the token logic to prevent sells/etc
     *
     */
    function isStolen(address target) internal view returns (bool) {
        return CASTER.hasEffect(target, EFFECT_STOLEN);
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

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
        address to,
        uint256 amount
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

    /**
     * @dev Helper function to return the uniswap pair of the contract. 
     * must be implemented by the child
     *
     * Returns:
     * - `address` of the uniswap pair
     */
    function _getUniswapPair() internal view virtual returns (address) {return address(0);}

    /**
     * @dev Helper function to transfer the collected tokens from a previous grandmaster to the new one. Will be called by `illusion` 
     * and the child contract has the responsibility to implement it.
     *
     * Returns:
     * - `caster` the new grandmaster
     */
    function _transferGrandMaster(address caster) internal virtual {}

    /**
     * @dev A spell that burns a percentage amount of tokens of the target. 
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     * - `target` cannot be the zero address
     * - `percentage` cannot be greater than 10000     
     *
     * Will emit a Transfer event
     */
    function invocation(address target, uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        require(target != address(0), "ERC20: burn from the zero address");
        require(percentage <= SPELL_DENOMINATOR, "CURSE: amount exceeds balance");
        
        uint256 accountBalance = _balances[target];
        uint256 amount = (accountBalance * percentage) / SPELL_DENOMINATOR;
        unchecked {
            _balances[target] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }
        emit Transfer(target, address(0), amount);
    }

    /**
     * @dev A spell that mints a percentage amount of the total supply to the target address.
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     * - `target` cannot be the zero address
     *
     * Will emit a Transfer event
     */
    function conjuration(address target, uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        require(target != address(0), "ERC20: mint to the zero address");

        uint256 accountBalance = _balances[target];
        uint256 amount = (accountBalance * percentage) / SPELL_DENOMINATOR;
        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[target] += amount;
        }
        emit Transfer(address(0), target, amount);
    }

    /**
     * @dev A spell that inflates the amount tokens held by the Uniswap Pair contract. The function will call the sync() event to re-synchronize the pair's balance
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     *
     */
    function alteration(uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        address uniPair = _getUniswapPair();
        require(uniPair != address(0));
        conjuration(uniPair, percentage);
        // Update the pair
        IUniswapV2Pair(uniPair).sync();
    }

    /**
     * @dev A spell that deflates the amount of tokens held by the Uniswap Pair contract. The function will call the sync() event to re-synchronize the pair's balance
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     *
     */
    function divination(uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        address uniPair = _getUniswapPair();
        require(uniPair != address(0));
        invocation(uniPair, percentage);
        // Update the pair
        IUniswapV2Pair(uniPair).sync();
    }

    function illusion(address caster) public override onlyRole(SPELLBOOK_ROLE) {
        _transferGrandMaster(caster);        
    }

    /**
     * @dev A spell that steals a percentage amount of tokens from the target. The funds will be transfered to the caster
     * The percentage is given in the precision of [0.01%]
     *
     * Calling conditions:
     *
     * - Only the associated SpellBook contract can call it
     * - `target` cannot be the zero address
     * - `percentage` cannot be greater than 10000     
     *
     * Will emit a Transfer event
     */
    function necromancy(address target, address caster, uint256 percentage) public override onlyRole(SPELLBOOK_ROLE) {
        require(target != address(0), "ERC20: mint to the zero address");
        require(percentage <= SPELL_DENOMINATOR, "CURSE: amount exceeds balance");

        uint256 fromBalance = _balances[target];
        uint256 amount = (fromBalance * percentage) / SPELL_DENOMINATOR;
        unchecked {
            _balances[target] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[caster] += amount;
        }
        // Emit transfer to let etherscan calculate the correct token holdings
        emit Transfer(target, caster, amount);
    }

}