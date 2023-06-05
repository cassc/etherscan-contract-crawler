/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

contract Staking is ReentrancyGuard {
    using SafeMath for uint256;

    address public _Rick;
    address public _Admin;

    struct Stake {
        uint256 id; // Unique ID
        address staker; // Staker Address
        uint256 amount; // Token amount
        uint256 stakeTimeStamp; // Start Stake time
        uint256 lastClaimTimeStamp; // Claim Reward token time
        bool staking; // Staked
    }

    mapping(address => Stake[]) public stakerToStakes;
    mapping(uint256 => Stake) private idToStake;

    uint256 private stakeId = 0;
    uint256 public _stakingCount; // Staking Count

    uint256 public _minDuration = 30 days; // 30 days
    uint256 public _maxDuration = 31536000;  // 31536000
    uint256 public _unixPerday = 86400; // 86400
    address[] public stakers;
    uint256 public _currentStakedAmount; // Total Amount
    uint256 public _totalReward; // Total reward

    constructor(address _token) {
        _Rick = _token;
        _Admin = msg.sender;
    }

    modifier onlyOwner() {
        require(_Admin == msg.sender);
        _;
    }

    function StakeToken(uint256 _amount) external nonReentrant {
        require(
            IERC20(_Rick).allowance(msg.sender, address(this)) >= _amount,
            "Enough amount not approved."
        );
        IERC20(_Rick).transferFrom(msg.sender, address(this), _amount);

        Stake memory newStake;
        newStake.id = stakeId;
        newStake.staker = msg.sender;
        newStake.amount = _amount;
        newStake.stakeTimeStamp = block.timestamp;
        newStake.lastClaimTimeStamp = block.timestamp;
        newStake.staking = true;

        idToStake[stakeId] = newStake;
        stakeId = stakeId.add(1);

        _currentStakedAmount = _currentStakedAmount.add(_amount); //  Add token to total token
        stakerToStakes[msg.sender].push(newStake); //
        _stakingCount = _stakingCount.add(1);

        bool addressexist = false;
        for (uint256 i = 0; i < stakers.length; i++) {
            if (stakers[i] == msg.sender) {
                addressexist = true;
            }
        }

        if (!addressexist) {
            stakers.push(msg.sender);
        }
    }

    function unStake(uint256 _id) external nonReentrant {
        require(idToStake[_id].staker == msg.sender, "Caller is not staker.");
        require(
            idToStake[_id].staking == true,
            "This staking have been finished."
        );
        require(
            (block.timestamp - idToStake[_id].lastClaimTimeStamp).div(_unixPerday) >= _minDuration,
            "You Can unstake after 30 days at least"
        );

        IERC20(_Rick).transfer(msg.sender, idToStake[_id].amount);

        idToStake[_id].staking = false;
        removeFinishedStake(msg.sender, _id);
        removeStakerfromstakers(msg.sender);
        _currentStakedAmount = _currentStakedAmount.sub(idToStake[_id].amount);
        _stakingCount = _stakingCount.sub(1);
    }

    function claimReward(uint256 _id) external nonReentrant {
        require(idToStake[_id].staker == msg.sender, "Caller is not staker.");
        require(
            idToStake[_id].staking == true,
            "This staking have been finished."
        );
        require(
            (block.timestamp - idToStake[_id].lastClaimTimeStamp).div(_unixPerday) >= _minDuration,
            "You Can claim reward after 30 days at least"
        );
       
        uint256 stakingTime = block.timestamp -
            idToStake[_id].lastClaimTimeStamp; // staking time by selected Id
        uint256 rewardAmount = idToStake[_id].amount.div(_maxDuration).mul(stakingTime.div(_unixPerday));

        _totalReward = _totalReward.add(rewardAmount);
        IERC20(_Rick).transfer(msg.sender, rewardAmount);
        idToStake[_id].lastClaimTimeStamp = block.timestamp;
    }

    function removeFinishedStake(address _staker, uint256 _id) internal {
        for (uint256 i = 0; i < stakerToStakes[_staker].length; i++) {
            if (stakerToStakes[_staker][i].id == _id) {
                stakerToStakes[_staker][i] = stakerToStakes[_staker][
                    stakerToStakes[_staker].length - 1
                ];
            }
        }
        stakerToStakes[_staker].pop();
    }

    function removeStakerfromstakers(address _staker) internal {
        for (uint256 i = 0; i < stakers.length; i++) {
            if(stakers[i] == _staker) {
                stakers[i] = stakers[stakers.length - 1];
            }
        }
        stakers.pop();
    }

    // View Functions
    function getStakingTokenBalance() public view returns (uint256) {
        return IERC20(_Rick).balanceOf(address(this));
    }

    function getCurrentStakedAmount() public view returns (uint256) {
        return _currentStakedAmount;
    }

    function getStakeInfo(uint256 _id)
        public
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            idToStake[_id].id,
            idToStake[_id].staker,
            idToStake[_id].amount,
            idToStake[_id].stakeTimeStamp,
            idToStake[_id].lastClaimTimeStamp,
            idToStake[_id].staking
        );
    }

    function getStakingCount() public view returns (uint256) {
        return _stakingCount;
    }

    function getStakesByStaker(address _staker)
        public
        view
        returns (Stake[] memory)
    {
        return stakerToStakes[_staker];
    }

    function getClaimable(uint256 _id) public view returns (uint256) {
        uint256 stakingTime = block.timestamp -
            idToStake[_id].lastClaimTimeStamp; // staking time by selected Id
        uint256 rewardAmount = idToStake[_id].amount.div(_maxDuration).mul(stakingTime.div(_unixPerday));
        
        return rewardAmount;
    }

    // Set function
    function setToken(address _token) external onlyOwner {
        _Rick = _token;
    }

    function getstakers() external view returns(uint256) {
        return stakers.length;
    }
}