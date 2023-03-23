/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

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

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Launchpad is Ownable {
    using SafeMath for uint256;

    uint256 _decimals = 18;
    uint256 _maximumLimitPer;
    IERC20 _rewardToken;
    IERC20 _usdtToken;

    address private _market;

    bool public _icoable = true;
    bool public _withdrawable_usdt = true;
    bool public _withdrawable_token = false;

    mapping(address => bool) public _isJoined;
    mapping(address => uint256) public _withdrawableUsdt;
    mapping(address => uint256) public _withdrawableToken;

    event JoinLaunchpad(address indexed add, uint indexed time);
    event UserClaimUsdt(address indexed add,uint indexed amount,uint indexed time);
    event UserClaimToken(address indexed add,uint indexed amount,uint indexed time);

    constructor (address _usdtAddress,address _marketAddress,uint256 _maximumLimit) {
        _usdtToken = IERC20(_usdtAddress);
        _market = _marketAddress;
        _maximumLimitPer = _maximumLimit * 10 ** _decimals;
    }

    function setUsdtToken(address _usdtAddress) public onlyOwner(){
        _usdtToken = IERC20(_usdtAddress);
    }

    function setRewardToken(address _rewardAddress) public onlyOwner(){
        _rewardToken = IERC20(_rewardAddress);
    }

    function setIcoable(bool _able) public onlyOwner(){
        _icoable = _able;
    }

    function setUsdtWithdrawl(bool _able) public onlyOwner(){
        _withdrawable_usdt = _able;
    }

    function setTokenWithdrawl(bool _able) public onlyOwner(){
        _withdrawable_token = _able;
    }

    function setMaxLimit(uint256 _limit) public onlyOwner(){
        _maximumLimitPer = _limit * 10 ** _decimals;
    }

    function setMarketAddress(address _marketAddress) public onlyOwner(){
        _market = _marketAddress;
    }

    function setUserUsdt(address[] memory _users,uint256[] memory _amount) public onlyOwner(){
        require(_users.length > 0,"null list!");
        require(_amount.length > 0,"null list!");
        for(uint256 i = 0; i<_users.length;i++){
            _withdrawableUsdt[_users[i]] =_withdrawableUsdt[_users[i]].add(_amount[i]);
        }
    }

    function setUserToken(address[] memory _users,uint256[] memory _amount) public onlyOwner(){
        require(_users.length > 0,"null list!");
        require(_amount.length > 0,"null list!");
        for(uint256 i = 0; i<_users.length;i++){
            _withdrawableToken[_users[i]] =_withdrawableToken[_users[i]].add(_amount[i]);
        }
    }

    function withdrawToken(address _to,uint _amount) public onlyOwner(){
        _rewardToken.transfer(_to,_amount);
    }

    function withdrawUsdtToken(address _to,uint _amount) public onlyOwner(){
        _usdtToken.transfer(_to,_amount);
    }

    function ico() public{
        uint256 approved = _usdtToken.allowance(msg.sender,address(this));
        require(_icoable,"ico close!");
        require(!_isJoined[msg.sender],"joined!");
        require(approved >= _maximumLimitPer,"insufficient authorization limit!");

        _usdtToken.transferFrom(msg.sender,address(this),_maximumLimitPer.div(100).mul(15));
        _usdtToken.transferFrom(msg.sender,_market,_maximumLimitPer.div(100).mul(85));
        _isJoined[msg.sender] = true;

        emit JoinLaunchpad(msg.sender,block.timestamp);
        
    }

    function withdraw_usdt() public {
        require(_withdrawable_usdt,"withdraw usdt close!");
        require(_withdrawableUsdt[msg.sender]>0,"no usdt withdrawable!");
        _usdtToken.transfer(msg.sender,_withdrawableUsdt[msg.sender]);
        emit UserClaimUsdt(msg.sender,_withdrawableUsdt[msg.sender],block.timestamp);
        _withdrawableUsdt[msg.sender] = 0;
    }

    function withdraw_token() public {
        require(_withdrawable_token,"withdraw token close!");
        require(_withdrawableToken[msg.sender]>0,"no token withdrawable!");
        _rewardToken.transfer(msg.sender,_withdrawableToken[msg.sender]);
        emit UserClaimToken(msg.sender,_withdrawableToken[msg.sender],block.timestamp);
        _withdrawableToken[msg.sender] = 0;
    }

    receive() external payable{
        payable(msg.sender).transfer(msg.value);
    }
}