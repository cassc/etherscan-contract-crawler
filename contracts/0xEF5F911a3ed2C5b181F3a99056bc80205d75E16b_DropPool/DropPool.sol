/**
 *Submitted for verification at Etherscan.io on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
  * @title TokenDrop pool
  *
  * @notice The Drop pool of ERC-20 tokens-Leaf
  * @dev for Allimeta metaverse ecosystem
  */
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see ERC20_infos.
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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

contract Governance {

    address public governance;

    constructor() {
        governance = tx.origin;
    }

    event GovernanceTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyGovernance {
        require(msg.sender == governance, "Sender not governance");
        _;
    }

    function setGovernance(address _governance)  public  onlyGovernance
    {
        require(_governance != address(0), "new governance the zero address");
        emit GovernanceTransferred(governance, _governance);
        governance = _governance;
    }

}

contract DropPool is Governance {

    using SafeMath for uint256;
    string constant version  = "1";   
    string public TokenSymbol  = "LEAF";
    uint256 chainId = 1;
    address public ErcToken =  address(0xD80158874FAf522b35F30484AE70052A0A0bafab);
    IERC20 _ercx =  IERC20(ErcToken);

    address public RewardPool =  address(0x0);
    address public DevPool =  address(0x0);

    uint256 public rewardRate = 1500;
    uint256 public rewardavl = 0;
    uint256 public devavl = 0;

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // PERMIT_TYPEHASH is keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline,uint256 startline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x7f5a1ca9a215ae5b26b01072441ad3d07ae7a76b9c06f94bc041bc1e748952c6;
    
    mapping (address => mapping (uint256 => bool)) public nonces;
    mapping (string => uint256 ) public eventbalance;
    mapping (string => address ) public eventowner;
    mapping (string => uint256 ) public eventexpiry;

    event Permit(address indexed from, address indexed to, uint256 value, uint256 nonce);
    event depositToQuota(address _from, string eventname, address ErcToken, uint256 amount, uint256 finalamount);
    event withdrawQuota(string eventname,address _to, address ErcToken, uint256 amount);
    event ExecPermit(string eventname,address _to, address ErcToken, uint256 amount);

    constructor (uint256 chainId_) {

        chainId = chainId_;

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(TokenSymbol)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));

    }

   function _permit(address owner, address spender, uint256 value,uint256 nonce, uint256 deadline,uint256 startline, 
                    uint8 v, bytes32 r, bytes32 s) internal 
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     owner,
                                     spender,
                                     value,
                                     nonce,
                                     deadline,
                                     startline ))
        ));

        require(owner != address(0), "invalid-address-0");
        require(governance == ecrecover(digest, v, r, s), "invalid-permit");
        require(deadline == 0 || block.timestamp <= deadline, "permit-expired");
        require(startline == 0 || block.timestamp >= startline, "permit too early");

        require(!nonces[owner][nonce], "invalid-nonce");
        nonces[owner][nonce] = true;
        emit Permit(owner, spender, value, nonce);
    }

    function getPermit(string memory eventname, address spender, uint256 value,uint256 nonce, uint256 deadline,uint256 startline,
                    uint8 v, bytes32 r, bytes32 s) external
    {
        _permit(eventowner[eventname], spender, value, nonce, deadline, startline, v, r, s);
        
        require( eventbalance[eventname] >= value, "insufficient-available");

        _ercx.transfer( spender, value );
        eventbalance[eventname] = eventbalance[eventname] - value;
        emit ExecPermit(eventname, spender, ErcToken, value);
    }

    function deposit( uint256 amount, string memory eventname, uint256 new_timestamp ) public
    {       
            require( !compare(eventname, "") , "eventname invalid");
            require( new_timestamp > block.timestamp , "timestamp invalid");
            require( _ercx.balanceOf(msg.sender) >= amount, "sender balance error");
            require( amount > 0 , "amount inavlid" );

            uint256 balance0 =  _ercx.balanceOf(address(this));
            _ercx.transferFrom(msg.sender, address(this), amount);
            uint256 balance1 =  _ercx.balanceOf(address(this));
            uint final_amount = balance1.sub(balance0);
            require( final_amount <= amount, "amount error");

            uint256 rewd = (final_amount*rewardRate)/10000;
            uint256 fordev = (final_amount*500)/10000;
            uint256 store = final_amount - rewd - fordev;
            
            eventbalance[eventname] = eventbalance[eventname] + store;
            devavl = devavl + fordev;
            rewardavl = rewardavl + rewd;
            if( new_timestamp > eventexpiry[eventname] )
                eventexpiry[eventname] = new_timestamp;

            require( eventowner[eventname] == msg.sender || eventowner[eventname]==address(0x0), "eventowner error");
            eventowner[eventname] = msg.sender;

            emit depositToQuota(msg.sender, eventname, ErcToken, amount, final_amount);
    }

    function withdraw(string memory eventname) public 
    {
        if( compare(eventname, "") )
        {
            _ercx.transfer( RewardPool, rewardavl);
            _ercx.transfer( DevPool, devavl);
            rewardavl = 0;
            devavl = 0;
            emit withdrawQuota(eventname, RewardPool, ErcToken, rewardavl);
            emit withdrawQuota(eventname, DevPool, ErcToken, devavl);
        }
        else{ 
               require( eventexpiry[eventname] < block.timestamp , "To Waiting for Event expired");
               require( eventowner[eventname] == msg.sender, "EventOwner error");
                _ercx.transfer( msg.sender, eventbalance[eventname]);
                eventbalance[eventname] = 0;
                emit withdrawQuota(eventname, msg.sender, ErcToken, eventbalance[eventname]);
        }
    }

    function compare(string memory str1, string memory str2) internal pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function setERCToken( string memory symb, address _erctoken ) external onlyGovernance {
        require(ErcToken==address(0x0) , "ErcToken is exist");
        TokenSymbol = symb;
        ErcToken = _erctoken;
        _ercx =  IERC20(ErcToken);

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(TokenSymbol)),
            keccak256(bytes(version)),
            chainId,
            address(this)
        ));
    }

    function setRewardRate( uint256 rate ) external onlyGovernance {
        rewardRate = rate;
    }
    
    function setPool( address reward_pool, address dev_pool ) external onlyGovernance {
        RewardPool = reward_pool;
        DevPool = dev_pool;
    }

}