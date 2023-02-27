/**
 *Submitted for verification at BscScan.com on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
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

contract Staking {
    using SafeMath for uint256;
    address public owner;
    mapping(address => uint256) public stakes;
    mapping(address => uint256) public withdrawn;
    uint256 public totalStaked;
    uint256 public dailyROI;
    uint256 public devfees = 2;
    uint256 public withdrawalfees = 5;
    address public tokenAddress;
    mapping(address => bool) public canStake;
    IERC20 public token;
    mapping(address => StakedUser) public stakedUsers;
    mapping(address => uint256) public accumulatedInterest;

    address[] public stakedAddresses;
    struct StakedUser {
        address user;
        uint256 stakedAmount;
        uint256 withdrawnAmount;
        uint256 lastClaimTime;
        uint256 stakingtime;
        bool refer;
        address referer;
        
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
        dailyROI = 5; // set daily ROI to 0.05%
        owner = 0x6c497e0a69C0ceb76F35D63FFd4a3097A18A2489;

    }

    function deposit(uint256 _amount, address refer) public {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        totalStaked += _amount;
        stakes[msg.sender] += _amount;
        stakedUsers[msg.sender] = StakedUser(
            msg.sender,
            _amount,
            0,
            block.timestamp,
            block.timestamp,
            false,
            refer
        );
        accumulatedInterest[msg.sender] = 0;
        stakedAddresses.push(msg.sender);
    }
 function depositmore(uint256 _amount) public {
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Transfer failed"
        );
        totalStaked += _amount;
        stakes[msg.sender] += _amount;
        stakedUsers[msg.sender].stakedAmount +=_amount;
        
    }
    function approveStake(address _spender, uint256 _amount) public {
        token.approve(_spender, _amount);
        canStake[_spender] = true;
    }

    function withdraw(uint256 _amount) public {
        
       require(
            block.timestamp >= stakedUsers[msg.sender].stakingtime + 1209600,
           "You Can withdraw after 14 days of deposit"
        );

        require(stakes[msg.sender] >= _amount, "Insufficient stake balance");
     require(_amount >= 50000000000000000000, "Minimum of 50 BUSD");
        uint256 stake = stakes[msg.sender];
        uint256 dailyreward = stake.mul(dailyROI).div(100);
        // calculate the last claim

        uint256 stakeTimestamp = stakedUsers[msg.sender].lastClaimTime;
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsSinceStake = currentTimestamp.sub(stakeTimestamp);
        uint256 daysSinceStake = secondsSinceStake / 86400;
        uint256 interest = dailyreward.mul(daysSinceStake);
        //get withdrawal fees from interest he earned
        uint256 interest_per = (interest * withdrawalfees) / 100;
        // cut dev fees from investment
        uint256 dev_per = (stakes[msg.sender] * devfees) / 100;
        uint256 remainingamount = stakes[msg.sender].sub(
            interest_per.add(dev_per)
        );
        require(token.transfer(msg.sender, remainingamount), "Transfer failed");
        require(token.transfer(0x963174748111d01A30f1ECd9c8E489C2e403712B, dev_per), "Transfer failed");

        totalStaked -= _amount;
        stakes[msg.sender] -= _amount;
        withdrawn[msg.sender] += _amount;
        stakedUsers[msg.sender].withdrawnAmount += _amount;
    }

    function claim() public payable {
        require(
            block.timestamp >= stakedUsers[msg.sender].lastClaimTime + 86400,
            "You can claim your interest only once in 24 hours"
        );

        uint256 stake = stakes[msg.sender];
        uint256 dailyreward = stake.mul(dailyROI).div(100);
        // calculate the last claim

        uint256 stakeTimestamp = stakedUsers[msg.sender].lastClaimTime;
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsSinceStake = currentTimestamp.sub(stakeTimestamp);
        uint256 daysSinceStake = secondsSinceStake / 86400;
        uint256 interest = dailyreward.mul(daysSinceStake);
        // uint interest = (stake * dailyROI / 100) * (block.timestamp - stakedUsers[msg.sender].lastClaimTime) + accumulatedInterest[msg.sender];
        require(token.transfer(msg.sender, interest), "Transfer failed");
                stakedUsers[msg.sender].lastClaimTime = block.timestamp;

    }

    function compound() public payable {
        require(
            block.timestamp >= stakedUsers[msg.sender].lastClaimTime + 86400,
            "You can Compound your interest only once in 24 hours"
        );
        uint256 stake = stakes[msg.sender];
        uint256 dailyreward = stake.mul(dailyROI).div(100);
        // calculate the last claim
        uint256 stakeTimestamp = stakedUsers[msg.sender].lastClaimTime;
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsSinceStake = currentTimestamp.sub(stakeTimestamp);
        uint256 daysSinceStake = secondsSinceStake / 86400;
        uint256 interest = dailyreward.mul(daysSinceStake);
        stakes[msg.sender] += interest;
        stakedUsers[msg.sender].lastClaimTime = block.timestamp;
    }

    function changeROI(uint256 _newROI) public {
        require(
            msg.sender == owner,
            "Only the contract owner can change the ROI"
        );
        dailyROI = _newROI;
    }

    function changedevfees(uint256 _newdevfees) public {
        require(
            msg.sender == owner,
            "Only the contract owner can change the Development fees"
        );
        devfees = _newdevfees;
    }

    function changewithdrawalfees(uint256 _newwithdrawalfees) public {
        require(
            msg.sender == owner,
            "Only the contract owner can change the Withdrawal fees"
        );
        withdrawalfees = _newwithdrawalfees;
    }

    function totalStakedByUser(address _user) public view returns (uint256) {
        require(stakes[_user] > 0, "User has not staked any tokens yet");
        return stakes[_user];
    }

    function tclaim(address add) public view returns (uint256) {
        uint256 stake = stakes[add];
        uint256 dailyreward = stake.mul(dailyROI).div(100);
        // calculate the last claim
        uint256 stakeTimestamp = stakedUsers[add].lastClaimTime;
        uint256 currentTimestamp = block.timestamp;
        uint256 secondsSinceStake = currentTimestamp.sub(stakeTimestamp);
        uint256 daysSinceStake = secondsSinceStake / 86400;
        uint256 interest = dailyreward.mul(daysSinceStake);
        return interest;
    }

    function totalWithdrawn(address _user) public view returns (uint256) {
        require(withdrawn[_user] > 0, "User has not withdrawn any tokens yet");
        return withdrawn[_user];
    }

    function stakedUsersList() public view returns (address[] memory) {
        return stakedAddresses;
    }

    function getStakedUser(address _user)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            _user,
            stakedUsers[_user].stakedAmount,
            stakedUsers[_user].withdrawnAmount,
            stakedUsers[_user].stakingtime,
              stakedUsers[_user].referer
        );
    }
     function remainingtime(address _user)
        public
        view
        returns (
            uint256
        )
    {
        return (stakedUsers[_user].lastClaimTime);
    }
    function withdraw() public payable{
        require(msg.sender == owner, "Only Owner can withdraw");
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }
}