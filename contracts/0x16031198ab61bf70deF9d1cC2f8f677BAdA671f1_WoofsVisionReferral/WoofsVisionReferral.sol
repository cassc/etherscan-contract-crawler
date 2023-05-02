/**
 *Submitted for verification at Etherscan.io on 2023-05-01
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: launchpad.sol




pragma solidity ^0.8.0;



contract WoofsVisionLaunchpad {
    using SafeMath for uint256;

    IERC20 public woofsVisionToken;
    address public admin;
    uint256 public rate;

    event TokenPurchased(address indexed buyer, uint256 tokens);

    constructor(address _tokenAddress, uint256 _rate) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_rate > 0, "Invalid rate");

        woofsVisionToken = IERC20(_tokenAddress);
        admin = msg.sender;
        rate = _rate;
    }

    function buyTokens() external payable {
        require(msg.value > 0, "Invalid amount");
        
        uint256 tokens = msg.value.mul(rate);
        require(woofsVisionToken.balanceOf(address(this)) >= tokens, "Insufficient tokens in the contract");

        woofsVisionToken.transfer(msg.sender, tokens);
        payable(admin).transfer(msg.value);

        emit TokenPurchased(msg.sender, tokens);
    }

    function updateRate(uint256 _newRate) external {
        require(msg.sender == admin, "Unauthorized");
        require(_newRate > 0, "Invalid rate");

        rate = _newRate;
    }

    function withdrawTokens(uint256 _amount) external {
        require(msg.sender == admin, "Unauthorized");

        woofsVisionToken.transfer(admin, _amount);
    }
}

// File: launchpadreferral.sol


pragma solidity ^0.8.0;




contract WoofsVisionReferral {
    using SafeMath for uint256;

    IERC20 public woofsVisionToken;
    WoofsVisionLaunchpad public woofsVisionLaunchpad;
    address public admin;

    uint256 public referralRewardPercentage;

    mapping(address => bool) public existingUsers;
    mapping(address => address) public referredBy;

    event ReferralRewardPaid(address indexed referrer, address indexed newInvestor, uint256 bonusAmount);

    constructor(address _woofsVisionTokenAddress, address _woofsVisionLaunchpadAddress, uint256 _referralRewardPercentage) {
        require(_woofsVisionTokenAddress != address(0), "Invalid token address");
        require(_woofsVisionLaunchpadAddress != address(0), "Invalid launchpad address");
        require(_referralRewardPercentage > 0 && _referralRewardPercentage <= 100, "Invalid reward percentage");

        woofsVisionToken = IERC20(_woofsVisionTokenAddress);
        woofsVisionLaunchpad = WoofsVisionLaunchpad(_woofsVisionLaunchpadAddress);
        admin = msg.sender;
        
        referralRewardPercentage = _referralRewardPercentage;
    }

    function buyTokensWithReferral(address referral) external payable {
        require(msg.value > 0, "Invalid amount");

        if (referral != address(0) && !existingUsers[msg.sender]) {
            existingUsers[msg.sender] = true;
            referredBy[msg.sender] = referral;

            woofsVisionLaunchpad.buyTokens{value: msg.value}();
            
            uint256 tokens = msg.value.mul(woofsVisionLaunchpad.rate());
            uint256 referralReward = tokens.mul(referralRewardPercentage).div(100);

            require(woofsVisionToken.balanceOf(address(this)) >= referralReward, "Insufficient tokens in the contract");

            woofsVisionToken.transfer(referral, referralReward);

            emit ReferralRewardPaid(referral, msg.sender, referralReward);
        } else {
            woofsVisionLaunchpad.buyTokens{value: msg.value}();
        }
    }

    function updateReferralRewardPercentage(uint256 _newPercentage) external {
        require(msg.sender == admin, "Unauthorized");
        require(_newPercentage > 0 && _newPercentage <= 100, "Invalid reward percentage");

        referralRewardPercentage = _newPercentage;
    }

    function depositTokens(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");

        woofsVisionToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawTokens(uint256 _amount) external {
        require(msg.sender == admin, "Unauthorized");

        woofsVisionToken.transfer(admin, _amount);
    }
}