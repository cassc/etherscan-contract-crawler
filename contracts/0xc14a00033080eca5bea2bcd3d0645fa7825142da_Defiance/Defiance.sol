/**
 *Submitted for verification at Etherscan.io on 2020-12-01
*/

pragma solidity ^0.6.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

interface ICallable {
	function tokenCallback(address _from, uint256 _tokens, bytes calldata _data) external returns (bool);
}

// 
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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Defiance is Ownable {

	using SafeMath for uint;

	uint256 constant private FLOAT_SCALAR = 2**64;
	uint256 constant private INITIAL_SUPPLY = 36e23; // 3.6m
	uint256 constant private BURN_RATE = 2; // 2% per tx
	uint256 constant private SUPPLY_FLOOR = 10; // 1% of 3.6m = 360k
	uint256 constant private MIN_STAKE_AMOUNT = 1e21; // 1,000

	string constant public name = "Defiance Phoenix";
	string constant public symbol = "DEPH";
	uint8 constant public decimals = 18;

	struct User {
		bool whitelisted;
		bool pauseWhitelisted;
		uint256 balance;
		uint256 staked;
		mapping(address => uint256) allowance;
		int256 scaledPayout;
	}

	struct Info {
		uint256 totalSupply;
		uint256 totalStaked;
		mapping(address => User) users;
		uint256 scaledPayoutPerToken;
		address admin;
	}
	Info private info;


	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Whitelist(address indexed user, bool status);
	event PauseWhitelist(address indexed user, bool status);
	event Stake(address indexed owner, uint256 tokens);
	event Unstake(address indexed owner, uint256 tokens);
	event Collect(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);
	event Pause();
	event Unpause();
	event NotPausable();

	bool public paused = false;
	bool public canPause = true;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused || msg.sender == owner || info.users[msg.sender].pauseWhitelisted, "paused.!");
    _;
  }
   /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused, "not paused.!");
    _;
  }
  modifier onlyAdmin() {
    require(msg.sender == info.admin,"only admin.!");
    _;
  }
  /**
     * @dev called by the owner to pause, triggers stopped state
     **/
    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }

  /**
     * @dev Prevent the token from ever being paused again
     **/
    function notPausable() onlyOwner public{
        paused = false;
        canPause = false;
        emit NotPausable();
    }

	constructor() public {
		info.admin = msg.sender;
		info.totalSupply = INITIAL_SUPPLY;
		info.users[msg.sender].balance = INITIAL_SUPPLY;
		emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
		whitelist(msg.sender, true);
		paused = true;
	}

	function stake(uint256 _tokens)  external whenNotPaused {
		_stake(_tokens);
	}

	function unstake(uint256 _tokens) external whenNotPaused {
		_unstake(_tokens);
	}

	function collect() external whenNotPaused returns (uint256) {
		uint256 _dividends = dividendsOf(msg.sender);
		require(_dividends >= 0);
		info.users[msg.sender].scaledPayout += int256(_dividends.mul(FLOAT_SCALAR));
		uint _balance = info.users[msg.sender].balance;
		info.users[msg.sender].balance = _balance.add(_dividends);
		emit Transfer(address(this), msg.sender, _dividends);
		emit Collect(msg.sender, _dividends);
		return _dividends;
	}

	function burn(uint256 _tokens) external {
		require(msg.sender != info.admin);
		require(balanceOf(msg.sender) >= _tokens);

		uint _balance = info.users[msg.sender].balance;
		info.users[msg.sender].balance = _balance.sub(_tokens);
		uint256 _burnedAmount = _tokens;
		if (info.totalStaked > 0) {
			_burnedAmount = _burnedAmount.div(2);
			uint _scaledPayout = _burnedAmount.mul(FLOAT_SCALAR).div(info.totalStaked);
			info.scaledPayoutPerToken = info.scaledPayoutPerToken.add(_scaledPayout);
			emit Transfer(msg.sender, address(this), _burnedAmount);
		}
		info.totalSupply = info.totalSupply.sub(_burnedAmount);
		emit Transfer(msg.sender, address(0x0), _burnedAmount);
		emit Burn(_burnedAmount);
	}

	function distribute(uint256 _tokens) external {
		require(info.totalStaked > 0);
		require(balanceOf(msg.sender) >= _tokens);
		uint _balance = info.users[msg.sender].balance;
		info.users[msg.sender].balance = _balance.sub(_tokens);
		
		uint _scaledPayout = _tokens.mul(FLOAT_SCALAR).div(info.totalStaked);
		info.scaledPayoutPerToken = info.scaledPayoutPerToken.add(_scaledPayout);
		emit Transfer(msg.sender, address(this), _tokens);
	}

	function transfer(address _to, uint256 _tokens) external whenNotPaused returns (bool) {
		_transfer(msg.sender, _to, _tokens);
		return true;
	}

	function approve(address _spender, uint256 _tokens) external whenNotPaused returns (bool) {
		info.users[msg.sender].allowance[_spender] = _tokens;
		emit Approval(msg.sender, _spender, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external whenNotPaused returns (bool) {
		require(info.users[_from].allowance[msg.sender] >= _tokens);

		uint _balance = info.users[_from].allowance[msg.sender];
		info.users[_from].allowance[msg.sender] = _balance.sub(_tokens);
		_transfer(_from, _to, _tokens);
		return true;
	}

	function transferAndCall(address _to, uint256 _tokens, bytes calldata _data) external whenNotPaused returns (bool) {
		uint256 _transferred = _transfer(msg.sender, _to, _tokens);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(ICallable(_to).tokenCallback(msg.sender, _transferred, _data));
		}
		return true;
	}

	function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external whenNotPaused {
		require(_receivers.length == _amounts.length);
		for (uint256 i = 0; i < _receivers.length; i++) {
			_transfer(msg.sender, _receivers[i], _amounts[i]);
		}
	}

	function whitelist(address _user, bool _status) public onlyAdmin {
		//require(msg.sender == info.admin);
		info.users[_user].whitelisted = _status;
		emit Whitelist(_user, _status);
	}
	function pauseWhitelist(address _user, bool _status) public onlyAdmin {
		//require(msg.sender == info.admin);
		info.users[_user].pauseWhitelisted = _status;
		emit PauseWhitelist(_user, _status);
	}

	function totalSupply() public view returns (uint256) {
		return info.totalSupply;
	}

	function totalStaked() public view returns (uint256) {
		return info.totalStaked;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return info.users[_user].balance.sub(stakedOf(_user));
	}

	function stakedOf(address _user) public view returns (uint256) {
		return info.users[_user].staked;
	}

	function dividendsOf(address _user) public view returns (uint256) {
		return uint256(int256(info.scaledPayoutPerToken.mul(info.users[_user].staked)) - info.users[_user].scaledPayout).div(FLOAT_SCALAR);
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function isWhitelisted(address _user) public view returns (bool) {
		return info.users[_user].whitelisted;
	}

	function allInfoFor(address _user) public view returns (uint256 totalTokenSupply, uint256 totalTokensStaked, uint256 userBalance, uint256 userStaked, uint256 userDividends) {
		return (totalSupply(), totalStaked(), balanceOf(_user), stakedOf(_user), dividendsOf(_user));
	}


	function _transfer(address _from, address _to, uint256 _tokens) internal returns (uint256) {
		require(balanceOf(_from) >= _tokens);
		uint _fromBalance = info.users[_from].balance;
		info.users[_from].balance = _fromBalance.sub(_tokens);
		
		uint256 _burnedAmount = _tokens.mul(BURN_RATE).div(100);
		if (totalSupply().sub(_burnedAmount) < INITIAL_SUPPLY.mul(SUPPLY_FLOOR).div(100) || isWhitelisted(_from)) {
			_burnedAmount = 0;
		}
		uint256 _transferred = _tokens.sub(_burnedAmount);
		
		uint _toBalance = info.users[_to].balance;

		info.users[_to].balance = _toBalance.add(_transferred);
		emit Transfer(_from, _to, _transferred);
		if (_burnedAmount > 0) {
			if (info.totalStaked > 0) {
				_burnedAmount = _burnedAmount.div(2);
				
				uint _scaledPayout = _burnedAmount.mul(FLOAT_SCALAR).div(info.totalStaked);

				info.scaledPayoutPerToken = info.scaledPayoutPerToken.add(_scaledPayout);
				emit Transfer(_from, address(this), _burnedAmount);
			}
			info.totalSupply = info.totalSupply.sub(_burnedAmount);
			emit Transfer(_from, address(0x0), _burnedAmount);
			emit Burn(_burnedAmount);
		}
		return _transferred;
	}

	function _stake(uint256 _amount) internal {
		require(balanceOf(msg.sender) >= _amount);
		require(stakedOf(msg.sender).add(_amount) >= MIN_STAKE_AMOUNT);
		info.totalStaked = info.totalStaked.add(_amount);

		uint _userStaked = info.users[msg.sender].staked;
		info.users[msg.sender].staked = _userStaked.add(_amount);
		info.users[msg.sender].scaledPayout += int256(_amount.mul(info.scaledPayoutPerToken));
		emit Transfer(msg.sender, address(this), _amount);
		emit Stake(msg.sender, _amount);
	}
	function _unstake(uint256 _amount) internal {
		require(stakedOf(msg.sender) >= _amount);
		uint256 _burnedAmount = _amount.mul(BURN_RATE).div(100);
		info.scaledPayoutPerToken = info.scaledPayoutPerToken.add(_burnedAmount.mul(FLOAT_SCALAR).div(info.totalStaked));
		info.totalStaked = info.totalStaked.sub(_amount);

		uint _userBalance = info.users[msg.sender].balance;
		info.users[msg.sender].balance = _userBalance.sub(_burnedAmount);

		uint _userStaked = info.users[msg.sender].staked;
		info.users[msg.sender].staked = _userStaked.sub(_amount);

		info.users[msg.sender].scaledPayout -= int256(_amount.mul(info.scaledPayoutPerToken));
		emit Transfer(address(this), msg.sender, _amount.sub(_burnedAmount));
		emit Unstake(msg.sender, _amount);
	}
}