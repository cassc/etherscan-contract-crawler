/**
 *Submitted for verification at BscScan.com on 2023-01-01
*/

pragma solidity ^0.8.11;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function payoutDivs() external;
}

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

contract DividendVault {
    using SafeMath for uint256;

    //-- Core Variable Values
    uint public Total; 
    uint public SValue; 
    uint public PendingRewards;
    mapping(address => uint) public UserS;
    mapping(address => uint) public Stake;

    IBEP20 public LockupContract;
    IBEP20 public kinectToken;
    address public owner;

    bool public lockupSet;

    //Events
    event UserDeposit(address user, uint256 amount);
    event UserWithdrawl(address user, uint256 amount);
    event UserCompound(address user, uint256 amount);
    event UserRedeem(address user, uint256 amount);
    event DistributedRewards(uint256 amount);

    //Initializing Core Values
    constructor(IBEP20 _kinectToken) {
        Total = 0;
        SValue = 0;
        PendingRewards = 0;
        kinectToken = _kinectToken;
        owner = msg.sender;
    }

    function updateLockup(IBEP20 _lockupContract) public {
        if(msg.sender == owner && lockupSet == false) {
            LockupContract = _lockupContract;
        } else {
            revert();
        }
    }

    function callPayoutDivs() external {
        LockupContract.payoutDivs();
    }

    //Deposit assets into the vault
    function Deposit(uint _amount) external {
        require(kinectToken.transferFrom(msg.sender, address(this), _amount));
        emit UserDeposit(msg.sender, _amount);
        this.Compound();
        uint deposited = Stake[msg.sender];
        uint reward = (deposited.mul(((SValue.sub(UserS[msg.sender]))))/ 10**18);
        if(reward > 0) {
            Stake[msg.sender] = Stake[msg.sender].add(_amount).add(reward);
            UserS[msg.sender] = SValue;
            Total = Total.add(_amount).add(reward);
        } else {
            Stake[msg.sender] = Stake[msg.sender].add(_amount);
            UserS[msg.sender] = SValue;
            Total = Total.add(_amount);
        }
    }

    //Withdrawl your assets
    function Withdrawl(uint _amount) external {
        this.callPayoutDivs();
        if(_amount <= Stake[msg.sender]) {
            emit UserWithdrawl(msg.sender, _amount);
            Total = Total.sub(_amount);
            uint fee = (_amount * 3 / 100);
            uint withdrawlAmount = _amount.sub(fee);
            this.Redeem();
            require(kinectToken.transfer(msg.sender, withdrawlAmount));
            Stake[msg.sender] = Stake[msg.sender].sub(_amount);
            require(kinectToken.transfer(address(LockupContract), fee));
        } else {
            revert();
        }
    }

    function Compound() external returns(bool) {
        this.callPayoutDivs();
        uint deposited = Stake[tx.origin];
        uint reward = (deposited.mul(((SValue.sub(UserS[tx.origin]))))/ 10**18);
        UserS[tx.origin] = SValue;
        Stake[tx.origin] = Stake[tx.origin].add(reward);
        emit UserCompound(tx.origin, reward);
        Total = Total.add(reward);
        return true;
    }

    function Redeem() external {
        this.callPayoutDivs();
        uint deposited = Stake[tx.origin];
        uint rewards = (deposited.mul(((SValue.sub(UserS[tx.origin]))))/ 10**18);
        if(rewards > 0){
            UserS[tx.origin] = SValue;
            uint fee = (rewards * 3 / 100);
            emit UserRedeem(tx.origin, rewards.sub(fee));
            require(kinectToken.transfer(tx.origin, rewards.sub(fee)));
            require(kinectToken.transfer(address(LockupContract), fee));
        }

    }

    //Add & distribute rewards
    function AddRewards(uint _amount) external {
        require(kinectToken.transferFrom(msg.sender, address(this), _amount));
        PendingRewards = PendingRewards.add(_amount);
        if(Total != 0) {
            emit DistributedRewards(PendingRewards);
            SValue = SValue.add(((PendingRewards * 10**18).div(Total)));
            PendingRewards = 0;
        }
    }

    function _AddRewards(uint _amount) internal {
        PendingRewards = PendingRewards.add(_amount);
        if(Total != 0) {
            emit DistributedRewards(PendingRewards);
            SValue = SValue.add(((PendingRewards * 10**18).div(Total)));
            PendingRewards = 0;
        }
    }

    //Get your current balance
    function balanceOf(address _user) public view returns(uint) {
        uint deposited = Stake[_user];
        return deposited;
    }

    //Check what your pending rewards are
    function rewardsOf(address _user) public view returns(uint) {
        uint deposited = Stake[_user];
        uint reward = (deposited.mul(((SValue.sub(UserS[_user])))).div(10**18));
        return reward;
    }

}