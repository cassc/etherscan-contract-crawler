// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.1;

import "./Owned.sol";

contract gazeERC20 is Owned {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // Below are public events on the blockchain that will notify clients
	
	// This notifies clients about the tokens amount transfer between accounts 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    // This notifies clients about the tokens amount approved to _spender to use on account _owner
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the tokens amount burnt
    event Burn(address indexed _from, uint256 _value);
	
	// This notifies clients about the tokens amount minted
    event Mint(address indexed _to, uint256 _value);


    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
	 *
	 * @param _initialSupply Total initial amount of tokens
     * @param _name full name of the token
	 * @param _symbol short name of the token
     */
    constructor (
        uint256 _initialSupply,
        string memory _name,
        string memory _symbol
    ) public {
		require(_initialSupply>0);
        totalSupply = _initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                	 // Give the contract owner all initial tokens
        name = _name;  
        symbol = _symbol;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint256 _value) internal {
		require(_from != address(0), "transfer attempt from zero address"); // Prevent transfer from 0x0 address.
        require(_to != address(0), "transfer attempt to zero address"); // Prevent transfer to 0x0 address.
        require(balanceOf[_from] >= _value, "from address balance is not enough");
        require(balanceOf[_to] + _value >= balanceOf[_to], "destination address balance overflow"); // Check for overflows
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value The amount of token minimal units (10**(-18)) to send
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value The amount of token minimal units (10**(-18)) to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender], "transfer not allowed");     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value The max amount of token minimal units (10**(-18)) it can spend
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
		require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of token minimal units (10**(-18)) to burn
     */
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool) {
        require(balanceOf[_from] >= _value, "address balance is smaller, than amount to burn");
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
		assert(totalSupply >= 0);
        return true;
    }
	
   /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of token minimal units (10**(-18)) to burn
     */
    function burn(uint256 _value) public onlyOwner returns (bool) {
        return burnFrom(msg.sender, _value);
    }
	
    /**
     * Create new tokens to account
	 *
	 * Create _mintAmount of new tokens to account _target
	 *
	 * @param _mintAmount the amount of token minimal units (10**(-18)) to mint
	 * @param _target the address to own new mint tokens
     *
     * Internal function, can be called from the contract and it's children contracts only
     */
	function _mintToken(address _target, uint256 _mintAmount) internal {
		require(_target != address(0), "mint attempt to zero address"); // Prevent mint to 0x0 address.
		require(totalSupply + _mintAmount > totalSupply);
        balanceOf[_target] += _mintAmount;
        totalSupply += _mintAmount;
        emit Mint(_target, _mintAmount);
    }
	
	/**
     * Create tokens to account
     *
     * Create `_mintAmount` tokens  and set them to _target account.
     *
     * @param _target the address for new tokens
     * @param _mintAmount the amount of token minimal units (10**(-18)) to create
     */
	function mintToken(address _target, uint256 _mintAmount) public onlyOwner returns (bool) {
		_mintToken(_target, _mintAmount);
		return true;
	}
	
	/**
     * Destroy contract
     *
	 * @param _beneficiary Address to send all contract's Ether balance
     */
	function destroy(address payable _beneficiary) public onlyOwner {
		require(_beneficiary != address(0), "beneficiary is zero address");
		selfdestruct(_beneficiary);
	}
	
	receive() external payable { 
		revert();
	}
}