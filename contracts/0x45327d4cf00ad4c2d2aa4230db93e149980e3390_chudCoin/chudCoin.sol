/**
 *Submitted for verification at Etherscan.io on 2023-07-09
*/

pragma solidity ^0.8.18;


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)
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

// SPDX-License-Identifier: MIT
//         .75PP5?: :557  ^557 !55^  755: J5555Y7:  ^J55557.      :?5PP57.   :555~   !557  ~55^     7555^ :555?   :555~   !55^ ~Y5Y~ J555555?     ^557.5555555P?
//        ^#@#?7P#5.^@@G::[email protected]@5 [email protected]@!  [email protected]@~ #@@[email protected]&^.#@#?YGP~     [email protected]@G7?G#J   [email protected]#@&:  [email protected]@@[email protected]@!     [email protected]@@G [email protected]@@G  [email protected]#@#:  [email protected]@[email protected]@5~  #@@J?JJ!     [email protected]@5 [email protected]@#JJ!
//        [email protected]@7   :  ^@@&###@@Y [email protected]@~  [email protected]@~ [email protected]&  [email protected]@Y !5G###G!     [email protected]@:   .   [email protected]#^[email protected] [email protected]@[email protected]#[email protected]@!     [email protected]@[email protected]@P  [email protected]#^[email protected]  [email protected]@@@@@7   #@@PPPP~     [email protected]@5   :@@P
//        ^#@[email protected]:^@@P  [email protected]@5 [email protected]@P!!#@&: #@@[email protected]@~^GBY^[email protected]@G     [email protected]@5!!G&5 [email protected]@#[email protected]@P [email protected]@^~#@@@!     [email protected]^@@@[email protected] [email protected]@#[email protected]@5 [email protected]@5:[email protected]@5. #@@?777!     [email protected]@5   ^@@G
//         :?PGGGY^ :PP?  ^PP7  ~YGGGPJ:  YPPPP5J^  !5GPPP?.      ^JPGGPJ::PPJ...?PP^!PP: .YPP^     7GJ ?PJ ?G?:PPJ...?PP^!PP^  ?PP?.YPPPPPPY     ^PP7   :PPJ
//
//
//
//                                                                      ^~~~~~~~^  .^!!~:     :~!!^.
//                                                                      5#[email protected]@@##P.5&&BG&&P^ ^[email protected]&[email protected]&Y.
//                                                                        [email protected]&:  [email protected]@7  ^@@G #@#:  [email protected]@?
//                                                                         [email protected]&.  [email protected]@?  [email protected]@P [email protected]&^  [email protected]@7
//                                                                         [email protected]#.   J#&BB&#5: :P&&B#&B?
//                                                                         :::      :^^:.     .:^^:
//
//
//
//
//                                                                                  ....
//                                                             .:7Y5GGPPPPPPGGGGGBBB####BP5YJ?!^:.
//                                                          :!5#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BPBBPPY?!^.
//                                                      :^?P&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GY!
//                                                  :!YB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@GY?^.
//                                              .~YB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PJ??^
//                                           :!5#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G
//                                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5.
//                                       7#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####&@@@@&#@@@@@@@@@@@@&&@@@@@B~
//                                       [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#P?^....:^~!~:.~!~YGGGGGBBP^^[email protected]@@@@&:
//                                     ^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BGGPPPP5555555Y7^.                             7#@@@Y
//                                    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@&BY7^:.                                                [email protected]
//                                    :&@@@@@@@@@@@@@@@@@@@@@@@P!.                                                         ^BY
//                                    [email protected]@@@@@@@@@@@@@@@@@@@@@?                                                             ~&~
//                                     [email protected]@@@@@@@@@@@@@@@@@@@#!                                                               YB:
//                                     [email protected]@@@@@@@@@@@@@@@@@@J.                          ~                                      Y#^
//                                     [email protected]@@@@@@@@@@@@@@@@@@Y                           ?7                   .                  5B.
//                                    ^&@@@@@@@@@@@@@@@@@@B^                            7J.                .Y.                 :@?
//                                    [email protected]@@@@@@@@@@@@@@@@@&:                              ~J~               ~J                   [email protected]^
//                                    [email protected]@@@@@@@@@@@@@@@@@J                                ^P               J7                   .&J
//                                    [email protected]@@@@@@@@@@@@@@@@G                                  Y!              P^                    PG
//                                    [email protected]@@@@@@@@@@@@@@@@!                                  ~5             .~                     ?&.
//                                    [email protected]@@@@@@@@@@@@@5                                    5:            Y!                     J#.
//                                    J&: [email protected]@@@@@@@@@@@~         J55J?!^..                                5&^                    Y#.
//                                    GP  [email protected]@@@@@@@@@Y          [email protected]@@@@@&#GY!^.              .            :&5             .^75GBJB5
//                                   .#Y   ~&@@@@@@@&?            ?5G#&@@@@@@@#GPJ!:       .J7             BP       .~7J5G&@@@@[email protected]
//                                   .#J    !#@@@@@G:                .^7YPGBGB&@@@@&BGPP5J77~              G#Y   ~!P#@@@@@@&B5! [email protected]^
//                                   ^@?     !G&@BY^ .           !GGPGB#&BGGB#&&@@@@@@@@@@#^               [email protected]@@@&#PJ!:.    [email protected]^
//                                   [email protected]~  .JB&BGBGGBBBBG5??????JJ#@G~^^::....:^~7JY555PB##@@B?.           ^@[email protected]@@@@[email protected]@5~
//                                   [email protected]^  ^@@!.    .:^[email protected]@~                    [email protected]@P.:~!7??!.  :&[email protected]@@B.
//                                   5&:  [email protected]#                   ^&@~ .^^!~~^^^^^.           [email protected]@#&#GPPG#BGY7&&&@~                [email protected]@G
//                                   5&:  [email protected]@Y^                  [email protected]^ [email protected]@@@#P7^.       ^&@#~.    .:!5#@@@G      .:::^:     [email protected]@P
//                                   J&.   ~JP?                 .B#. ^&Y   [email protected]@@@@@@@B5?~.   .&@!          [email protected]@P?JJYPB&&&&P?     [email protected]@J
//                                   7&:                        [email protected]  .YG5^ [email protected]@@@@@@@?^5&7   :&@^           [email protected]@5!~^[email protected]@@@@@P      [email protected]@J
//                                   [email protected]!                        [email protected]#.   .?G55B###B14885GY    [email protected]&.           [email protected]@J^^^[email protected]@&&#&5      [email protected]@J
//                                   [email protected]!                        ^&@BPY7^..:...!~~~~~!.      [email protected]            ^@&JYYJ69420Y&J      [email protected]@J
//                                   .BY                         .~?Y5#&#BBPP5PPPP55YJ7?YPGG&@7            [email protected]@5?5Y?7!^[email protected]@!
//                                    7#.                              :^^!777?JJJJJJYYJB&?!~:             [email protected]@BGB#&&BBB&@@&@@@@@&5.
//                                    :&7                                               GY                   B#.  :^!??!~~^:^^^^BP
//                                     PP                                              ~&^                   [email protected]^               .&?
//                                     ?B                                              ?#                    [email protected]!               :&7
//                                     ~&^                                             BY                    :#G.              :&7
//                                     :#~                                            ~&:                     [email protected]              [email protected]^
//                                     :&~                                            5B~~7?:                 :&P              Y#.
//                                      B?                                           :&@YJ?!.     ..          [email protected]             ^@?
//                                      P5                                           5##J.    .!5B##?.   :^[email protected]             :BP
//                                      GP                                          [email protected]~:P#GY~ ?#B#&&5.  7&@@@@@~            ?B?
//                                      GP                                         [email protected]   :?5J.   .::    JY?!~~&?          .GG:
//                                      GP                                         B&:                       :@Y         :GG.
//                                      B5            ^^                          7&~       .....            .B5        !#J
//                                      B5            ^G.                        [email protected]  .^7JJ5P5555P5J^^~7??!:  5B       [email protected]
//                                      B5             Y!                       ^&J.^J##57!^     .:YGYJ?!!?GY ?&:      GG
//                                     .#Y             Y!                      :#[email protected]?Y555Y777777!~^^^^~^[email protected]^&J    ~GP:
//                                     [email protected]!             P~                      GB..~P5?^   :[email protected]#.  J#!
//                                    ~#5             .G:                      7^    ^75P5!.            ~J55?!:^@! PB:
//                                   .#5             .Y?                                .!Y55P5?^   :~JP57:     ^!B5.
//                                   ?&^             :~                                      .^?PYJ55J7:        !&?
//                                   Y#                                                     .~~~!7JJ!:         Y#!
//                                  ~&J                                                    :~^...   :Y       .GG:
//                                 [email protected]                                                               .    .^JBG:
//                               .5&7               :~7!                                             .^?PBBPJ!
//                               P&^             ^5P5Y?~                                        .7JYG##GY!:
//                             !GB^             Y#?.                                          .?##[email protected]~.
//                          ^!PG!             .P#^                                          .?&G^ ^&?
//                     ...~GB57            ..?B5:                                    :~~~7YYBB?.   !&Y~~~:.
//               .^~7J5P5YPG5YJ.          !55P~                                      ^JJ?J5!:       ^?JJY5P5YYYYYYYYYYYYJJ??!^.
//             7PGPYJ7^.                                                                                  .::::::::^^^^^~!!7YPGPYY!~^
contract chudCoin is ERC20 {
    address payable public owner;
    uint256 private _totalSupply = 148869420 * (10 ** 18);
    uint256 private _tokenPrice = 200000 * (10 ** 18);

    constructor() ERC20("chudCoin", "CHUD")  {
        owner = payable(msg.sender);
        _mint(owner, _totalSupply);
    }
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function setTokenPrice(uint256 newTokenPrice) external onlyOwner {
        require(newTokenPrice > 0, "Token price should be greater than 0");
        _tokenPrice = newTokenPrice;
    }

    function getTokenPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    function burn(uint256 amount) external {
        require(amount > 0, "Amount to burn should be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Not enough tokens to burn");
        _burn(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender, _msgSender()) - amount);
        return true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address.");
        owner = payable(newOwner);
    }

    function renounceOwnership() external onlyOwner {
        owner = payable(address(0));
    }
}