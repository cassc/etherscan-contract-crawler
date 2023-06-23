// SPDX-License-Identifier: Business Source License 1.1
pragma solidity 0.8.20;

import "IERC20Metadata.sol";
import "IERC20Base.sol";
import "AttributesLibrary.sol";
import "SafeERC20.sol";
// import "Ownable.sol";
import "ERC165.sol";
import "Context.sol";
import "IERC721.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20Base is
    IERC20Base,
    Context,
    IERC20,
    IERC20Metadata,
    ERC165
{
    using SafeERC20 for IERC20;
    using Attributes for uint256;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    mapping(address => uint256) public attributes;

    /** CONSTANTS */
    // moved to AttributesLibrary

    /** IMMUTABLE VARIABLES */
    /** VARIABLES */
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /** CONSTRUCTOR */

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    function _init(address owner_) internal virtual {
        _transferOwnership(owner_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "onlyowner");
        _;
    }

    modifier onlyRole(uint256 _role) {
        if (_owner != _msgSender())
            require(attributes[_msgSender()].has(_role), "#0CF4C392");
        _;
    }

    // modifier anyRole(uint256 _role) {
    //     if (_owner != _msgSender())
    //         require(attributes[_msgSender()].hasAny(_role), "#0CF4C392");
    //     _;
    // }

    /** RECEIVE */
    /** FALLBACK */

    /** EXTERNAL FUNCTIONS */
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "INVVALID_ADDRESS");
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

    /** EXTERNAL FUNCTIONS */

    function mint(
        address account,
        uint256 amount
    ) external virtual onlyRole(Role.MINTER) {
        _mint(account, amount);
    }

    /** ATTRIBUTES **/

    function hasAttribute(
        address account,
        uint256 _attribute
    ) public view virtual returns (bool) {
        return attributes[account].has(_attribute);
    }

    function setAttributes(
        address _wallet,
        uint256 _attributes
    ) public virtual onlyRole(Role.ATTRIBUTES) {
        attributes[_wallet] = attributes[_wallet].set(_attributes);
    }

    function setMAttributes(
        address[] memory _wallets,
        uint256 _attributes
    ) public virtual onlyRole(Role.ATTRIBUTES) {
        for (uint256 i = 0; i < _wallets.length; i++)
            setAttributes(_wallets[i], _attributes);
    }

    function delAttributes(
        address _wallet,
        uint256 _attributes
    ) public virtual onlyRole(Role.ATTRIBUTES) {
        attributes[_wallet] = attributes[_wallet].remove(_attributes);
    }

    function delMAttributes(
        address[] memory _wallets,
        uint256 _attributes
    ) public virtual onlyRole(Role.ATTRIBUTES) {
        for (uint256 i = 0; i < _wallets.length; i++)
            delAttributes(_wallets[i], _attributes);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == 0x36372b07 || super.supportsInterface(interfaceId);
    }

    function transfer(
        address to,
        uint256 amount
    ) external virtual returns (bool) {
        return _transfer(to, amount);
    }

    function approve(
        address spender,
        uint256 amount
    ) external virtual returns (bool) {
        return _approve(spender, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual returns (bool) {
        return _transferFrom(from, to, amount);
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        return _increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
        return _decreaseAllowance(spender, addedValue);
    }

    /** PUBLIC FUNCTIONS */

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner_,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner_][spender];
    }

    /** INTERNAL FUNCTIONS */

    function _decrementBalance(
        address owner_,
        uint256 amount
    ) internal virtual {
        _balances[owner_] -= amount;
    }

    function _incrementBalance(
        address owner_,
        uint256 amount
    ) internal virtual {
        _balances[owner_] += amount;
    }

    function _incrementTotalSupply(uint256 amount) internal virtual {
        _totalSupply += amount;
    }

    function _decrementTotalSupply(uint256 amount) internal virtual {
        _totalSupply -= amount;
    }

    function _setAllowance(
        address owner_,
        address spender,
        uint256 value
    ) internal virtual {
        _allowances[owner_][spender] = value;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function _transfer(
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
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
    function _approve(
        address spender,
        uint256 amount
    ) internal virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
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
    function _transferFrom(
        address from,
        address to,
        uint256 amount
    ) internal virtual returns (bool) {
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
    function _increaseAllowance(
        address spender,
        uint256 addedValue
    ) internal virtual returns (bool) {
        address owner_ = _msgSender();
        _approve(owner_, spender, allowance(owner_, spender) + addedValue);
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
    function _decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) internal virtual returns (bool) {
        address owner_ = _msgSender();
        uint256 currentAllowance = allowance(owner_, spender);
        require(currentAllowance >= subtractedValue, "#F693F07C");
        unchecked {
            _approve(owner_, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        require(from != address(0), "#F42E91D9");
        require(to != address(0), "#A775CE31");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "#CD2646C3");
        unchecked {
            _decrementBalance(from, amount);
        }
        _incrementBalance(to, amount);

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
        require(account != address(0), "#24114507");

        _beforeTokenTransfer(address(0), account, amount);

        _incrementTotalSupply(amount);
        _incrementBalance(account, amount);
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
        require(account != address(0), "#56C8BF06");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "#950E97B7");
        unchecked {
            _decrementBalance(account, amount);
        }
        _decrementTotalSupply(amount);

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
        address owner_,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner_ != address(0), "#64012360");
        require(spender != address(0), "#14F0F094");
        _setAllowance(owner_, spender, amount);
        emit Approval(owner_, spender, amount);
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
        address owner_,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "#369CD95F");
            unchecked {
                _approve(owner_, spender, currentAllowance - amount);
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
    ) internal virtual {
        if (_owner == _msgSender()) return;
        uint256 _contractAttrs = attributes[address(0)];
        bool _block;
        if (from == address(0))
            // MINT
            _block =
                _contractAttrs.has(Attribute.BLOCK_MINT) ||
                (_contractAttrs.has(Attribute.WL_BLOCK_MINT) &&
                    attributes[to].has(Attribute.BLOCK_MINT));
        else if (to == address(0))
            // BURN
            _block =
                _contractAttrs.has(Attribute.BLOCK_BURN) ||
                (_contractAttrs.has(Attribute.WL_BLOCK_BURN) &&
                    attributes[from].has(Attribute.BLOCK_BURN));
        else {
            _block = _contractAttrs.has(Attribute.BLOCK_TRANSFER);
            // set to max value to check if we have fetched the value of the wallet attributes
            uint256 _attrs = type(uint256).max;
            // if it is not blocked at contract level, check if it is blocked at wallet level
            if (!_block && _contractAttrs.has(Attribute.WL_BLOCK_TRANSFER)) {
                _attrs = attributes[from];
                _block = _attrs.has(Attribute.BLOCK_TRANSFER);
            }

            if (
                _block &&
                _contractAttrs.hasAny(
                    Attribute.WHITELIST_TRANSFER_FROM |
                        Attribute.WHITELIST_TRANSFER_TO
                )
            ) {
                if (_contractAttrs.has(Attribute.WHITELIST_TRANSFER_FROM)) {
                    if (_attrs == type(uint256).max) _attrs = attributes[from];
                    _block = !_attrs.has(Attribute.WHITELIST_TRANSFER_FROM);
                }
                if (
                    _block &&
                    _contractAttrs.has(Attribute.WHITELIST_TRANSFER_TO)
                ) _block = !attributes[to].has(Attribute.WHITELIST_TRANSFER_TO);
            }
        }
        require(!_block, "BLOCK");
    }

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

    function xtransfer(
        address _token,
        address _creditor,
        uint256 _value
    ) external virtual onlyRole(Role.XTRANSFER) {
        IERC20(_token).safeTransfer(_creditor, _value);
    }

    function xapprove(
        address _token,
        address _spender,
        uint256 _value
    ) external virtual onlyRole(Role.XAPPROVE) {
        IERC20(_token).forceApprove(_spender, _value);
    }

    function withdrawEth()
        external
        virtual
        onlyRole(Role.WITHDRAW_ETH)
        returns (bool)
    {
        return payable(_owner).send(address(this).balance);
    }

    receive() external payable virtual {
        emit Received(msg.sender, msg.value);
    }
}