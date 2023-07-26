/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Introducing Inedible Pepe. The first community owned meme token that is inedible.
 * Protected by Inediblex.com, the first DEX with native mev and rug protection. Inedible Pepe likes to show Jared the finger.
 *
 * Inedible Pepe drops a staggering 40% to Inedible holders (30 day cliff). That's some vested incentive right there. 
 * Inedible Pepe is a deflationary meme token with a 2% burn tax on sell.
 * 
 * Links:
 * - https://twitter.com/InediblePepe
 * - https://t.me/+xPk0DaJfSCxjMWM0
 * - https://inedible-pepe.xyz/
 * - https://inediblex.com
 * - https://inediblecoin.com
 * 
 * 
 * ..   ......  .... ..  ........ .            ..   .....   ....  .   ....... ..   .....  ....... .....
.......   ..     ......     .    .......         .     ...  .. ... ..        ....   ..  ............
....    .  . .....    .. .   .^7J555555YYJJ?!^.    ....                        .... ..  ...   ......
....  ...   ....       .  .^?5PP5YYYYYYYY555PP5Y?~:        ..:^~!!77?????7!^.   ......   ... .......
....  ...  ......  ...  .7PGP5Y5Y5555Y5555Y55Y55PGPY!..:~?5PPPGPPPPPPPPP5PGGP?^. .....   .  ........
.. ..  ........... .  .7P?75!7P!J?!!?J!!!7P7!5!!!!P5!?G?!7JJ!!!J?~!?J~!!?Y~!7GG5~  .... ... .... ...
......   ........    7PGG. 5. ~ !! ~57 ~: Y: Y .~ Y? 7&~ !5! ~ :~ ^5? ^:.7 :J5Y5GJ. ....  . ......  
    ..       ....  :5G5YG: 5..  7! ~5? !^ Y: Y .~ ?? 7#~ !5! ^7Y! ^5? :7J? :J5YYYBJ. .     .......  
      ... .  .    !GPYYYG:.5.~7 7! ~J7 ^:.5^.5..~ 7? ^J~ ~J! ?GG! ^?7 !BB? :7555YY#~    ....  .   . 
      .. ..  .. .YG5YYYY5YY5PGGY55YYY5YYYY5YY5YYYY55YYYPGGGP5PPP5YYY5YY555YYY5PPPPBP?~:.   .      ..
       .   ... :PGYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PP5YYYYYYYYYYYYYYYYYYYYYYYY5PP5J!.         
   ..  .   .. .PGYYYYYYYYYYYYYYYYYYYYYYYYY55555555555555555PG55YYYYYYYY5555555555555YY55PGG?:       
   . ....     JBYYYYYYYYYYYYYYYYYYYYY555555YYY5555555555555YYY5P5Y55555555555555555555555Y5PY?~. .  
.. ....  :~?Y5#5YYYYYYYYYYYYYYYYYY5555YYYY55555YYYYYYYYYY555555GB555555555YYYYYYYYY55555555555PJ. ..
       ^YPP5YPBYYYYYYYYYYYYYYY5555YYYYY5555YYYYYYYY555YJJJJJJJJJPG5YYYYYYYYYYYYY55YJ?????JYYY55PJ~..
 ... .JG5YYYYB5YYYYYYYYYYYYY5555Y5555555YYYYYY5PB##BB&J.........:7P555PGB#####?~7#?.     ..:^~!!J5. 
 .. ^PGYYYYY5GYYYYYYYYYYYY5P555555YYYJJJPGGB##&&&@#!^GY           ??&&&&&&&&&&[email protected] .  .        ~~ 
.. ^GPYYYYYYYYYYYYYYYYYYYYYYY5YY55!:... [email protected]@@&&&&&&&&&&!  ..     :!: [email protected]@&&&&&&&@@@B~           .:~!:.
. ^GPYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ?!^:.7G&&@@@@&&#P~      .:~75J: .?PB&&&&&#BP7.   ..:^~!7??J5?...
 ^BPYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55555YJ7!?JYYYJ7~:..::^~!?JY5YYP5J7!!7JJJJJ?7!!77??JJYYYY55YYJ~ ..
 !PYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5555555YYYYYYYJJYYY555555555YYYYYYYYYYYYYYYYYYYYYYYYY55~:.. ...
 ^YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5555555555555555YYYYYYYYYYYYYYYYYYYYYYYYYYY55YJ7: .......
 ^YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5555YYYYYYYYYY5YYYYYYYYYYYYYY5PY!^:.  ........
.^YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY55555YYYYYYYYYYYYYYY5555PP55555555YPP7. ...........
.^YYYYYYYYYYYYYYYYYYYYYYYYYYYY5PPPP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY555YYYYYYYYYYPP~ ..........
.~YYYYYYYYYYYYYYYYYYYYYYYYYYYGGP555GG5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5G7 .........
.~YYYYYYYYYYYPPPPPPYYYYYYYYYPBYYYYPY5BPYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYGJ.........
.~YYYYYYYYY5BGPPPPPB5YYYYYYY5B5YYYGGY5BPYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYGJ .......
.~YYYYYYYYYBPP5YYP55BYYYYYYYY5BPYYYGGYYGGP5YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYB?^......
.~YYYYYYYYY#55555P55BYYYYYYYYY5GG5YYPGPYY5GGPPP555YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY5PPGGPP^....
.~YYYYYYYYYB5YYYYYYPBYYYYYP5YYYY5GG5YYPGGP55555PPPPGPPPPPPPPPPP55555YYYYYYYYYYY555PPPPGPP55YYY#?....
.~YYYYYYYYYB5YYYYYYGPJYYYYY555YYYY5PGGP555PGGPP5YYYYYY5555555555PPPPPPPPPPPPPPPPP555YYYYYY5PPP?.....
.~YYYY55555#5YYYYYYGP555YYYYY5555YYYYY5PGPP555PPPGPPPP555555YYYYYYYYYYYYYYYYY5555555PPGGBGJ7^.......
.~YYPGGGPPG#5YYYYYYBBPPGBP5PP5YYYYYYYYYYYY5PPPPPP555555PPPPPPPGGGPPPPPPPGPPPPPPPPPP55555PGJ.........
:~YPBYYYYYYB5YYYYYYG5YYYP&PPPGBYYYYYYYYYYYYYYYY55PPGGPP5555YYYYYY5YY555YYYYYYYYYYYYYYYY55G5:........
:~YBPYYYYYYB5YYYYYYGP5YY5G55YJ5GYYYYY5JJJ5YY5YJJ55YYYPP5PGPGGG5YY5PP5JJYPYYYYYYYYP5PPPP5?~..........
:^G&5YYYYYYPYYYYYYYGBY ^^.5! ~ ~Y^ :J^ ~:?PP~ ! :G:  Y5 :? ?PP. 7YG5.:^ 5^ !J: !YY77!~:. ...........
.!B&5YYYYYYYYYYYYYY5GY ::.5: ? .#? ~B?^:!55P: 5JJY ^ !P  . ?PP. !5PJ !! ?^ ~Y: ~J^    ..............
.!G#PYYYYYYYYYYYYYYY5Y ^^ ?^ ! :B? ~B7~7 ^PP: ?:^! ^ :Y ^. ?PP  555Y ~~ J^ JG: ?~...................
.!B#PYYYYYYYYYYYYYYY55!7775Y!!!5GJ!?PJ!!!J55Y!!!J?!Y?7Y!YJ!Y5577P55P7~~~J!~77!~7....................
.~PBB5YYYYYYYYYYYYYYYY5555YY555#GPGP5PPPP5555PPPPPPPPPPPPPGPPPG#B#BJ~::..::..::.....................
.~YY5GGYYYYYYYYYYYYYYYYYYYYYYY5#5555PPPPPPPPP555555PPP555555PGBBGGGBGY~. ...........................
.~YYYYYYYYYYYYYYYYYYYYYYYYYYYYP#BBBBBBBBBGGGGGGGBBBBBBBBBBBBBGGGGGGGGBB5!. .........................
.!G5YYYYYYYYYYYYYYYYYYYYYYYYYYP#GGBGBGGGBBBBBBBBBBBBGGBGGGGBBBBBBBBBBBBBBP!.........................
.~PPPYJJJJJJJJJJJJJJJJJJJJJJJ?5G55555555555555555555555555555555555555555PP?........................
.::::::.::::........................................................................................
:::^^^^:::::........................................................................................

*/

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


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


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract InediblePepe is ERC20, Ownable {
    mapping(address => bool) private isInPool;
    address private DEPLOYER_ADDRESS;
    uint private constant SELL_TAX_BURN = 2;

    constructor() ERC20("Inedible Pepe", "INEDIBLEPEPE") {
        _mint(msg.sender, 100000000000000000000000000000000); // 100 trillion
        DEPLOYER_ADDRESS = msg.sender;
    }

    // Pools are user in the transfer function to check if sell-tax should be applied.
    function addPool(address pool) external {
        require(
            msg.sender == DEPLOYER_ADDRESS,
            "Only the deployer can add a pool"
        );
        isInPool[pool] = true;
    }

    function isAddressInPool(address to) public view returns (bool) {
        return isInPool[to];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (isAddressInPool(to)) {
            uint256 sellTax = (amount * SELL_TAX_BURN) / 100;
            uint256 amountAfterTax = amount - sellTax;
            super._transfer(from, to, amountAfterTax); // transfer remainder after tax to pool
            super._burn(from, sellTax); // Burn tax
        } else {
            super._transfer(from, to, amount);
        }
    }
}