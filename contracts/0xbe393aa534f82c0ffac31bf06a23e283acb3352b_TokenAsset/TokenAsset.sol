/**
 *Submitted for verification at Etherscan.io on 2019-12-23
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Library/IERC20.sol

pragma solidity ^0.5.14;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: contracts/Library/SafeMath.sol

pragma solidity ^0.5.14;

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

// File: contracts/Library/Freezer.sol

pragma solidity ^0.5.14;


/**
 * @title Freezer
 * @author Yoonsung
 * @notice This Contracts is an extension of the ERC20. Transfer
 * of a specific address can be blocked from by the Owner of the
 * Token Contract.
 */
contract Freezer is Ownable {
    event Freezed(address dsc);
    event Unfreezed(address dsc);

    mapping (address => bool) public freezing;

    modifier isFreezed (address src) {
        require(freezing[src] == false, "Freeze/Fronzen-Account");
        _;
    }

    /**
    * @notice The Freeze function sets the transfer limit
    * for a specific address.
    * @param _dsc address The specify address want to limit the transfer.
    */
    function freeze(address _dsc) external onlyOwner {
        require(_dsc != address(0), "Freeze/Zero-Address");
        require(freezing[_dsc] == false, "Freeze/Already-Freezed");

        freezing[_dsc] = true;

        emit Freezed(_dsc);
    }

    /**
    * @notice The Freeze function removes the transfer limit
    * for a specific address.
    * @param _dsc address The specify address want to remove the transfer.
    */
    function unFreeze(address _dsc) external onlyOwner {
        require(freezing[_dsc] == true, "Freeze/Already-Unfreezed");

        delete freezing[_dsc];

        emit Unfreezed(_dsc);
    }
}

// File: contracts/Library/SendLimiter.sol

pragma solidity ^0.5.14;


/**
 * @title SendLimiter
 * @author Yoonsung
 * @notice This contract acts as an ERC20 extension. It must
 * be called from the creator of the ERC20, and a modifier is
 * provided that can be used together. This contract is short-lived.
 * You cannot re-enable it after SendUnlock, to be careful. Provides 
 * a set of functions to manage the addresses that can be sent.
 */
contract SendLimiter is Ownable {
    event SendWhitelisted(address dsc);
    event SendDelisted(address dsc);
    event SendUnlocked();

    bool public sendLimit;
    mapping (address => bool) public sendWhitelist;

    /**
    * @notice In constructor, Set Send Limit exceptionally msg.sender.
    * constructor is used, the restriction is activated.
    */
    constructor() public {
        sendLimit = true;
        sendWhitelist[msg.sender] = true;
    }

    modifier isAllowedSend (address dsc) {
        if (sendLimit) require(sendWhitelist[dsc], "SendLimiter/Not-Allow-Address");
        _;
    }

    /**
    * @notice Register the address that you want to allow to be sent.
    * @param _whiteAddress address The specify what to send target.
    */
    function addAllowSender(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "SendLimiter/Not-Allow-Zero-Address");
        sendWhitelist[_whiteAddress] = true;
        emit SendWhitelisted(_whiteAddress);
    }

    /**
    * @notice Register the addresses that you want to allow to be sent.
    * @param _whiteAddresses address[] The specify what to send target.
    */
    function addAllowSenders(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            addAllowSender(_whiteAddresses[i]);
        }
    }

    /**
    * @notice Remove the address that you want to allow to be sent.
    * @param _whiteAddress address The specify what to send target.
    */
    function removeAllowedSender(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "SendLimiter/Not-Allow-Zero-Address");
        delete sendWhitelist[_whiteAddress];
        emit SendDelisted(_whiteAddress);
    }

    /**
    * @notice Remove the addresses that you want to allow to be sent.
    * @param _whiteAddresses address[] The specify what to send target.
    */
    function removeAllowedSenders(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            removeAllowedSender(_whiteAddresses[i]);
        }
    }

    /**
    * @notice Revoke transfer restrictions.
    */
    function sendUnlock() external onlyOwner {
        sendLimit = false;
        emit SendUnlocked();
    }
}

// File: contracts/Library/ReceiveLimiter.sol

pragma solidity ^0.5.14;


/**
 * @title ReceiveLimiter
 * @author Yoonsung
 * @notice This contract acts as an ERC20 extension. It must
 * be called from the creator of the ERC20, and a modifier is
 * provided that can be used together. This contract is short-lived.
 * You cannot re-enable it after ReceiveUnlock, to be careful. Provides 
 * a set of functions to manage the addresses that can be sent.
 */
contract ReceiveLimiter is Ownable {
    event ReceiveWhitelisted(address dsc);
    event ReceiveDelisted(address dsc);
    event ReceiveUnlocked();

    bool public receiveLimit;
    mapping (address => bool) public receiveWhitelist;

    /**
    * @notice In constructor, Set Receive Limit exceptionally msg.sender.
    * constructor is used, the restriction is activated.
    */
    constructor() public {
        receiveLimit = true;
        receiveWhitelist[msg.sender] = true;
    }

    modifier isAllowedReceive (address dsc) {
        if (receiveLimit) require(receiveWhitelist[dsc], "Limiter/Not-Allow-Address");
        _;
    }

    /**
    * @notice Register the address that you want to allow to be receive.
    * @param _whiteAddress address The specify what to receive target.
    */
    function addAllowReceiver(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "Limiter/Not-Allow-Zero-Address");
        receiveWhitelist[_whiteAddress] = true;
        emit ReceiveWhitelisted(_whiteAddress);
    }

    /**
    * @notice Register the addresses that you want to allow to be receive.
    * @param _whiteAddresses address[] The specify what to receive target.
    */
    function addAllowReceivers(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            addAllowReceiver(_whiteAddresses[i]);
        }
    }

    /**
    * @notice Remove the address that you want to allow to be receive.
    * @param _whiteAddress address The specify what to receive target.
    */
    function removeAllowedReceiver(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "Limiter/Not-Allow-Zero-Address");
        delete receiveWhitelist[_whiteAddress];
        emit ReceiveDelisted(_whiteAddress);
    }

    /**
    * @notice Remove the addresses that you want to allow to be receive.
    * @param _whiteAddresses address[] The specify what to receive target.
    */
    function removeAllowedReceivers(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            removeAllowedReceiver(_whiteAddresses[i]);
        }
    }

    /**
    * @notice Revoke Receive restrictions.
    */
    function receiveUnlock() external onlyOwner {
        receiveLimit = false;
        emit ReceiveUnlocked();
    }
}

// File: contracts/TokenAsset.sol

pragma solidity ^0.5.14;







/**
 * @title TokenAsset
 * @author Yoonsung
 * @notice This Contract is an implementation of TokenAsset's ERC20
 * Basic ERC20 functions and "Burn" functions are implemented. For the 
 * Burn function, only the Owner of Contract can be called and used 
 * to incinerate unsold Token. Transfer and reception limits are imposed
 * after the contract is distributed and can be revoked through SendUnlock
 * and ReceiveUnlock. Don't do active again after cancellation. The Owner 
 * may also suspend the transfer of a particular account at any time.
 */
contract TokenAsset is Ownable, IERC20, SendLimiter, ReceiveLimiter, Freezer {
    using SafeMath for uint256;

    string public constant name = "tokenAsset";
    string public constant symbol = "NTB";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 200000000e18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    
   /**
    * @notice In constructor, Set Send Limit and Receive Limits.
    * Additionally, Contract's publisher is authorized to own all tokens.
    */
    constructor() SendLimiter() ReceiveLimiter() public {
        balanceOf[msg.sender] = totalSupply;
    }

    /**
    * @notice Transfer function sends Token to the target. However,
    * caller must have more tokens than or equal to the quantity for send.
    * @param _to address The specify what to send target.
    * @param _value uint256 The amount of token to tranfer.
    * @return True if the withdrawal succeeded, otherwise revert.
    */
    function transfer (
        address _to,
        uint256 _value
    ) external isAllowedSend(msg.sender) isAllowedReceive(_to) isFreezed(msg.sender) returns (bool) {
        require(_to != address(0), "TokenAsset/Not-Allow-Zero-Address");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
    * @notice Transfer function sends Token to the target.
    * In most cases, the allowed caller uses this function. Send
    * Token instead of owner. Allowance address must have more
    * tokens than or equal to the quantity for send.
    * @param _from address The acoount to sender.
    * @param _to address The specify what to send target.
    * @param _value uint256 The amount of token to tranfer.
    * @return True if the withdrawal succeeded, otherwise revert.
    */
    function transferFrom (
        address _from,
        address _to,
        uint256 _value
    ) external isAllowedSend(_from) isAllowedReceive(_to) isFreezed(_from) returns (bool) {
        require(_from != address(0), "TokenAsset/Not-Allow-Zero-Address");
        require(_to != address(0), "TokenAsset/Not-Allow-Zero-Address");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
    * @notice The Owner of the Contracts incinerate own
    * Token. burn unsold Token and reduce totalsupply. Caller
    * must have more tokens than or equal to the quantity for send.
    * @param _value uint256 The amount of incinerate token.
    * @return True if the withdrawal succeeded, otherwise revert.
    */
    function burn (
        uint256 _value
    ) external returns (bool) {
        require(_value <= balanceOf[msg.sender]);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Transfer(msg.sender, address(0), _value);
        
        return true;
    }

    /**
    * @notice Allow specific address to send token instead.
    * @param _spender address The address to send transaction on my behalf
    * @param _value uint256 The amount on my behalf, Usually 0 or uint256(-1).
    * @return True if the withdrawal succeeded, otherwise revert.
    */
    function approve (
        address _spender,
        uint256 _value
    ) external returns (bool) {
        require(_spender != address(0), "TokenAsset/Not-Allow-Zero-Address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}