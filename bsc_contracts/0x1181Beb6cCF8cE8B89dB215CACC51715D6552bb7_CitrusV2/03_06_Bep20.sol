// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface Iswap{
    function lockTime(address addr) external view returns(uint256);
    function totalConvertedToken(address addr) external view returns(uint256);
}

interface BEP {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount)
    external 
    returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) 
        external 
        returns (bool);

    event Transfer(
        address indexed from, 
        address indexed to, 
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BEP20{

    string public symbol; // symbol Of Token
    string public name;  // Name of Token
    uint8 public decimals; // Returns the number of decimals used to get its user representation.
    uint256 public totalSupply; // total supply of token
    mapping(address => uint256) balances;  // wallet Address own balance eg. (address => amount)
    mapping(address => mapping(address => uint256)) allowed; // Check the allowance Comment
    uint256 public stopTime;
    address swapAddress;
    mapping(address => uint256) public lockTime; // User or Owner lock for certain time
    
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     *  account (`to`).
     */

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /**
     *  It is restricted to owner to use some functionality until lockTime is over 
     */

    modifier onlyAfterTimeLimit(address _owner) {
        require(
            block.timestamp > lockTime[_owner],
            "PROMPT 2001: Time lock period is still going on. The token can not be transferred during locking period."
        );
        _;
    }
    
    //Returns the amount of tokens owned by `account`.
    function balanceOf(address _owner) 
        public 
        view 
        returns (uint256 balance) 
    {
        return balances[_owner];
    }

    /**
     *  @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */

    function transfer(address _to, uint256 _amount)
        public
        onlyAfterTimeLimit(msg.sender)
        returns (bool success)
    {
        require(
            balances[msg.sender] >= _amount && 
            _amount > 0 && balances[_to] + _amount > balances[_to], 
            "PROMPT 2002: Insufficient balance! Please add balance to your wallet and try again!"
        );
        
        require(
            (Iswap(swapAddress).lockTime(msg.sender) < block.timestamp) || 
            ((balances[msg.sender] - _amount) >= (Iswap(swapAddress).totalConvertedToken(msg.sender))), 
            "PROMPT 2032:locktime is not over"
        );

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

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
        address _from,
        address _to,
        uint256 _amount
    ) 
        public
        onlyAfterTimeLimit(_from)
        returns (bool success)
    {
        require(
            balances[_from] >= _amount, 
            "PROMPT 2003: Insufficient balance! Please add balance to your wallet and try again!"
        );

        require(
            allowed[_from][msg.sender] >= _amount, 
            "PROMPT 2004: Please enter lesser or same amount than the allowed value!"
        );

        require(_amount > 0,"PROMPT 2005: Please enter value greater than 0!");
        
        require(
            balances[_to] + _amount > balances[_to], 
            "PROMPT 2006: Insufficient balance! Please add balance to your wallet and try again!"
        );

        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     *  @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits an {Approval} event.
     */

    function approve(address _spender, uint256 _amount)
        public
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
       zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    /**
     * remove tokons from totalSupply 
     * It's basically transfer tokens to the dead wallet
     * in this Contract It's called through proposal(Only Owners). and for user They can call burn  
     */

    function _burn(address account, uint256 amount) 
        internal 
        virtual 
    {
        require(
            account != address(0), 
            "PROMPT 2007: It should not be the zero address. Please enter valid burn address!"
        );

        uint256 accountBalance = balances[account];
        require(
            accountBalance >= amount, 
            "PROMPT 2008: Number of tokens to burn should be lesser or same as available balance. Please check the value entered!"
        );

        balances[account] = accountBalance - amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}