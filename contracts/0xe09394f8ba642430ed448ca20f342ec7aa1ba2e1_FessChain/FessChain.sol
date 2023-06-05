/**
 *Submitted for verification at Etherscan.io on 2019-07-12
*/

pragma solidity 0.5.0;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed _to);

    constructor(address _owner) public {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Pausable is Owned {
    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused() {
      require(!paused);
      _;
    }

    modifier whenPaused() {
      require(paused);
      _;
    }

    function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
    }

    function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20, Pausable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }


    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function _transferFrom(address sender, address recipient, uint256 amount) internal whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

}

contract FessChain is ERC20 {

    using SafeMath for uint256;
    string  public constant name = "FESS";
    string  public constant symbol = "FESS";
    uint8   public constant decimals = 18;

    uint256 public tokenForSale = 600000000 ether;
    uint256 public teamTokens = 2400000000 ether; 
    uint256 public maintainanceTokens = 1000000000 ether ;  
    uint256 public marketingTokens = 10000000 ether ; 
    uint256 public airDropInIEO = 20000000 ether;  
    uint256 public bountyInIEO = 30000000 ether;  
    uint256 public mintingTokens = 2250000000 ether;
    uint256 public airDropWithDapps = 3690000000 ether;

    mapping(address => bool) public marketingTokenHolder;
    mapping(address => uint256) public marketingLockPeriodStart;

    mapping(address => bool) public teamTokenHolder;
    mapping(address => uint256) public teamLockPeriodStart;
    mapping(address => uint256) public teamTokenInitially;
    mapping(address => uint256) public teamTokenSent;

    uint256 public totalReleased = 0;

    constructor(address _owner) public Owned(_owner) {
 
        _mint(address(this), 10000000000 ether);
        super._transfer(address(this),owner,tokenForSale);
        totalReleased = totalReleased.add(tokenForSale);

    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {

       if (marketingTokenHolder[msg.sender] == true)
       { 
        
        require(now >= (marketingLockPeriodStart[msg.sender]).add(20736000)); // 8 months, taken 30 days in each month
        super._transfer(msg.sender, recipient, amount);           

       }

      else 
      {
        super._transfer(msg.sender, recipient, amount);
      } 


        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {

       if (marketingTokenHolder[msg.sender] == true)
       { 
        
        require(now >= (marketingLockPeriodStart[msg.sender]).add(20736000),'Lock period is not completed'); // 8 months, taken 30 days in each month
        super._transferFrom(sender, recipient, amount);           

       }

      else 
      {
        super._transferFrom(sender, recipient, amount);
      } 

        return true;
    }


    /**
    * @dev this function will send the Team tokens to given address
    * @param _teamAddress ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendTeamTokens(address _teamAddress, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(teamTokens >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        teamTokens = teamTokens.sub(_value);
        teamTokenHolder[_teamAddress] = true;
        teamTokenInitially[_teamAddress] = teamTokenInitially[_teamAddress].add((_value.mul(95)).div(100));
        teamLockPeriodStart[_teamAddress] = now; 
        super._transfer(address(this),_teamAddress,(_value.mul(5)).div(100));
        return true;

   }

    /**
    * @dev this function will send the Team tokens to given address
    * @param _marketingAddress ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendMarketingTokens(address _marketingAddress, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(marketingTokens >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        marketingTokens = marketingTokens.sub(_value);
        marketingTokenHolder[_marketingAddress] = true;
        marketingLockPeriodStart[_marketingAddress] = now;
        super._transfer(address(this),_marketingAddress,_value);
        return true;

   }

    
    /**
    * @dev this function will send the Team tokens to given address
    * @param _maintainanceAddress ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendMaintainanceTokens(address _maintainanceAddress, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(maintainanceTokens >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        maintainanceTokens = maintainanceTokens.sub(_value);
        super._transfer(address(this),_maintainanceAddress,_value);
        return true;

   }
    
    /**
    * @dev this function will send the Team tokens to given address
    * @param _airDropAddress ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendAirDropIEO(address _airDropAddress, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(airDropInIEO >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        airDropInIEO = airDropInIEO.sub(_value);
        super._transfer(address(this),_airDropAddress,_value);
        return true;

   }

    /**
    * @dev this function will send the Team tokens to given address
    * @param _bountyAddress ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendBountyIEO(address _bountyAddress, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(bountyInIEO >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        bountyInIEO = bountyInIEO.sub(_value);
        super._transfer(address(this),_bountyAddress,_value);
        return true;

   }

    
    /**.
    * @dev this function will send the Team tokens to given address
    * @param _airDropWithDapps ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendAirDropAndBountyDapps(address _airDropWithDapps, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(airDropWithDapps >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        airDropWithDapps = airDropWithDapps.sub(_value);
        super._transfer(address(this),_airDropWithDapps,_value);
        return true;

   }

    /**
    * @dev this function will send the Team tokens to given address
    * @param _mintingAddress ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendMintingTokens(address _mintingAddress, uint256 _value) external whenNotPaused onlyOwner returns (bool) {

        require(mintingTokens >= _value);
        totalReleased = totalReleased.add(_value);
        require(totalReleased <= totalSupply());
        mintingTokens = mintingTokens.sub(_value);
        super._transfer(address(this),_mintingAddress,_value);
        return true;

   }
    

    /**
    * @dev Destoys `amount` tokens from the caller.
    *
    * See `ERC20._burn`.
    */
    function burn(uint256 amount) external whenNotPaused{

        _burn(msg.sender, amount);
    }

    function withdrawTeamTokens(uint256 amount) external whenNotPaused returns(bool) {

        require(teamTokenHolder[msg.sender] == true,'not a team member');
        require(now.sub(teamLockPeriodStart[msg.sender]).div(2592000)>=3,'Lock period is not above 3 months');
        uint256 monthsNow = now.sub(teamLockPeriodStart[msg.sender]).div(2592000);

        if(monthsNow >=3 && monthsNow < 6) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(10)).div(100),'already withdraw 10 % tokens');   
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender],'tokens sent is larger then initial tokens');
           super._transfer(address(this),msg.sender,amount);      
        } 

        else if(monthsNow >=6 && monthsNow < 9) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(20)).div(100),'already withdraw 20 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=9 && monthsNow < 12) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(30)).div(100),'already withdraw 30 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);
        } 

        else if(monthsNow >=12 && monthsNow < 15) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(40)).div(100),'already withdraw 40 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=15 && monthsNow < 18) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(50)).div(100),'already withdraw 50 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=18 && monthsNow < 21) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(60)).div(100),'already withdraw 60 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=21 && monthsNow < 24) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(70)).div(100),'already withdraw 70 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=24 && monthsNow < 27) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(80)).div(100),'already withdraw 80 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=27 && monthsNow < 30) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= (teamTokenInitially[msg.sender].mul(90)).div(100),'already withdraw 90 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           require(teamTokenSent[msg.sender] <= teamTokenInitially[msg.sender]);           
           super._transfer(address(this),msg.sender,amount);           
        } 

        else if(monthsNow >=30) 
        {
           require(teamTokenSent[msg.sender].add(amount) <= teamTokenInitially[msg.sender],'already withdraw 100 % tokens');
           teamTokenSent[msg.sender] = teamTokenSent[msg.sender].add(amount);
           super._transfer(address(this),msg.sender,amount);           
        } 

    }      

}