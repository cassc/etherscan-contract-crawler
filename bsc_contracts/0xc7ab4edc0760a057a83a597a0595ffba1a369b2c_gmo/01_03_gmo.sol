// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
interface IERC20 {
  // @dev Returns the amount of tokens in existence.
  function totalSupply() external view returns (uint256);

  // @dev Returns the token decimals.
  function decimals() external view returns (uint8);

  // @dev Returns the token symbol.
  function symbol() external view returns (string memory);

  //@dev Returns the token name.
  function name() external view returns (string memory);

  //@dev Returns the bep token owner.
  function getOwner() external view returns (address);

  //@dev Returns the amount of tokens owned by `account`.
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
  function allowance(address _owner, address spender) external view returns (uint256);

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

  //@dev Emitted when `value` tokens are moved from one account (`from`) to  another (`to`). Note that `value` may be zero.
  event Transfer(address indexed from, address indexed to, uint256 value);

  //@dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}. `value` is the new allowance.
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

import "@openzeppelin/contracts/access/Ownable.sol";


contract gmo is IERC20, Ownable {

    address private IDO; // 39.585%
    address private LP_DEX; // 10.192%
    address private FUTURE_REWARDS; // 11%
    address private TEAM; // 5%
    address private OPERATIONS; // 4.498%
    address private ADVISORS; // 3%
    address private MARKETING; // 3%
    address private SEED; // 23.725%
    
    uint256 private _taxFee = 11;

    // token liquidity metadata
    // 100,000,000,000 100 billion 100000000000
    uint public override totalSupply = 100000000000;
    uint8 public override decimals = 18;
    
    mapping(address => uint) public balances;
    
    mapping(address => mapping(address => uint)) public allowances;
    
    // token title metadata
    string public override name = "GMO TEST";
    string public override symbol = "GMO";
    
    // EVENTS
    // (now in interface) event Transfer(address indexed from, address indexed to, uint value);
    // (now in interface) event Approval(address indexed owner, address indexed spender, uint value);
    
    // On init of contract we're going to set the admin and give them all tokens.

    constructor(address IDO_address, address LP_DEX_address, address TEAM_address, address OPERATIONS_address, address ADVISORS_address, address MARKETING_address, address SEED_address) {

        IDO = IDO_address;
        LP_DEX = LP_DEX_address;
        TEAM = TEAM_address;
        OPERATIONS = OPERATIONS_address;
        ADVISORS = ADVISORS_address;
        MARKETING = MARKETING_address;
        SEED = SEED_address;
        
        // split the tokens according to agreed upon percentages
        balances[IDO] =  totalSupply * 39585 / 100000;
        balances[LP_DEX] = totalSupply * 10192 / 100000;
        balances[FUTURE_REWARDS] =  totalSupply * 11 / 100;
        balances[TEAM] = totalSupply * 5 / 100;
        balances[OPERATIONS] = totalSupply * 4498 / 100000;
        balances[ADVISORS] = totalSupply * 3 / 100;
        balances[MARKETING] = totalSupply * 3 / 100;
        balances[SEED] = totalSupply * 23725 / 100000;
        
        balances[owner()] = totalSupply;
    }
    
    // Get the address of the token's owner
    function getOwner() public view override returns(address) {
        return owner();
    }

    
    // Get the balance of an account
    function balanceOf(address account) public view override returns(uint) {
        return balances[account];
    }
    
    // Transfer balance from one user to another
    function transfer(address to, uint value) public override returns(bool) {
        require(value > 0, "Transfer value has to be higher than 0.");
        require(balanceOf(msg.sender) >= value, "Balance is too low to make transfer.");
        
        //withdraw the taxed from the total value
        uint rebaseTBD = value * _taxFee / 100;
        uint valueAfterTax= value - rebaseTBD;
        
        // perform the transfer operation
        balances[to] += valueAfterTax;
        balances[msg.sender] -= value;
        
        emit Transfer(msg.sender, to, value);
        
        //tax goes to owner currently
        balances[owner()] += rebaseTBD;
        
        return true;
    }
    
    // approve a specific address as a spender for your account, with a specific spending limit
    function approve(address spender, uint value) public override returns(bool) {
        allowances[msg.sender][spender] = value; 
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    // allowance
    function allowance(address _owner, address spender) public view override returns(uint) {
        return allowances[_owner][spender];
    }
    
    // an approved spender can transfer currency from one account to another up to their spending limit
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        require(allowances[from][msg.sender] > 0, "No Allowance for this address.");
        require(allowances[from][msg.sender] >= value, "Allowance too low for transfer.");
        require(balances[from] >= value, "Balance is too low to make transfer.");
        
        balances[to] += value;
        balances[from] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
    
    function _setTaxFee(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function _getTaxFee() public view returns(uint256) {
        return _taxFee;
    }

    // function to allow users to burn currency from their account
    function burn(uint256 amount) public returns(bool) {
        _burn(msg.sender, amount);
        
        return true;
    }
    
    // intenal functions
    
    // burn amount of currency from specific account
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "You can't burn from zero address.");
        require(balances[account] >= amount, "Burn amount exceeds balance at address.");
    
        balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
    
}