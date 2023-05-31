/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: contracts/TenPresaleETHPoly.sol


pragma solidity ^0.8.0;


interface USDT {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function symbol() external view returns (string memory);
}

interface IERC20{
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function symbol() external view returns (string memory);
}


contract LendPreSale {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) public deposits;
    mapping(address => bool) public whitelistedTokens;
    mapping(address => uint256) public totalDeposits;
    address public owner;
    uint256 internal _allocationLeft;
    uint256 constant public conversionRate = 33333333; // 6 decimal places
    uint256 internal maxSupply = 75000000e6;
    address public rewardAddress = 0x9039f3dE706f64044CA0a3fef6a7036AC8850B78;
    bool private _locked;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdrawal(address indexed user, address indexed token, uint256 amount);

    constructor() {
        owner = msg.sender;
        _allocationLeft = maxSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier reentrancyGuard() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false; 
    }

    function whitelistToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        whitelistedTokens[token] = true;
    }

    function deposit(address token, uint256 amount) external  reentrancyGuard {
        require(whitelistedTokens[token], "Token is not whitelisted");
        require(amount > 0, "Amount must be greater than 0");
        require(amount >= 100e6 || totalDeposits[msg.sender] >= 100e6, "Minimum deposit is 100 tokens"); // minimum deposit of 100 tokens (6 decimal places)
        if( token == address(0xdAC17F958D2ee523a2206206994597C13D831ec7)){
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        USDT(token).transferFrom(address(msg.sender), address(this), amount);
        uint256 balAfter = USDT(token).balanceOf(address(this));
        uint256 totalTransfer = balAfter.sub(balBefore);
        deposits[msg.sender][token] = deposits[msg.sender][token].add(totalTransfer);
        totalDeposits[msg.sender] = totalDeposits[msg.sender].add(totalTransfer);
        uint256 tokensConverted = totalTransfer.mul(conversionRate).div(1e6); // convert to 6 decimal places
        _allocationLeft = _allocationLeft.sub(tokensConverted);
        USDT(token).transfer(rewardAddress, amount);
        emit Deposit(msg.sender, token, amount);
        }
        else{
        require(IERC20(token).balanceOf(msg.sender) >= amount, "Insufficient balance");
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        uint256 balAfter = IERC20(token).balanceOf(address(this));
        uint256 totalTransfer = balAfter.sub(balBefore);
        deposits[msg.sender][token] = deposits[msg.sender][token].add(totalTransfer);
        totalDeposits[msg.sender] = totalDeposits[msg.sender].add(totalTransfer);
        uint256 tokensConverted = totalTransfer.mul(conversionRate).div(1e6); // convert to 6 decimal places
        _allocationLeft = _allocationLeft.sub(tokensConverted);
        require(IERC20(token).transfer(rewardAddress, amount), "Transfer Failed");
        emit Deposit(msg.sender, token, amount);
        }

    }

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        IERC20(token).transfer(msg.sender, amount);
        emit Withdrawal(msg.sender, token, amount);
    }

    function allocationLeft() external view returns (uint256) {
        return _allocationLeft.div(1e6);
    }
}