/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: GPL-3.0
// Gartier TIER standard token

pragma solidity ^0.8.7;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }
    
     /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}


contract Authorizable is owned {

    struct Authoriz{
        uint index;
        address account;
    }
    
    mapping(address => bool) public authorized;
    mapping(address => Authoriz) public authorizs;
    address[] public authorizedAccts;

    modifier onlyAuthorized() {
        if(authorizedAccts.length >0)
        {
            require(authorized[msg.sender] == true || owner == msg.sender);
            _;
        }else{
            require(owner == msg.sender);
            _;
        }
     
    }

    function addAuthorized(address _toAdd) 
        isOwner 
        public 
    {
        require(_toAdd != address(0));
        require(!isAuthorizedAccount(_toAdd));
        authorized[_toAdd] = true;
        Authoriz storage authoriz = authorizs[_toAdd];
        authoriz.account = _toAdd;
        //authoriz.index = authorizedAccts.push(_toAdd) -1;
        authorizedAccts.push(_toAdd);
        authoriz.index = authorizedAccts.length -1;


    }

    function removeAuthorized(address _toRemove) 
        isOwner 
        public 
    {
        require(_toRemove != address(0));
        require(_toRemove != msg.sender);
        authorized[_toRemove] = false;
    }
    
    function isAuthorizedAccount(address account) 
        public 
        view 
        returns(bool isIndeed) 
    {
        if(account == owner) return true;
        if(authorizedAccts.length == 0) return false;
        return (authorizedAccts[authorizs[account].index] == account);
    }

}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol,
        uint8 initialDecimals
    ) {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = initialDecimals > 0? initialDecimals: decimals; //Set the Decimals
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender's allowance
        totalSupply -= _value;                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}


/***********************************************************/
/* Gartier (TIER) STARTS HERE   */
/***********************************************************/

contract Gartier is Authorizable, TokenERC20 {

    using SafeMath for uint256;
    
    /// Maximum tokens to be allocated on the sale
    uint256 public tokenSaleHardCap;
    /// Base exchange rate is set to 1 ETH = GodTr.
    uint256 public baseRate;

   /// no tokens can be ever issued when this is set to "true"
    bool public tokenSaleClosed = false;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    modifier inProgress {
        require(totalSupply < tokenSaleHardCap
            && !tokenSaleClosed);
        _;
    }

    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }
    
    event LogPurchase(address buyer, uint256 price, uint256 amountToken,  string memo);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() TokenERC20(0, "Gartier", "TIER", 18) {
        tokenSaleHardCap = 4000000 * 10**uint256(decimals); // Default Crowsale Hard Cap amount with decimals
        baseRate = 1767 * 10**uint256(decimals); // Default base rate Token) :1 eth amount with decimals
    }

    receive() external payable {
        //emit log("Receive payable call purchaseTokens");
        //purchaseTokens(msg.sender);
        emit LogPurchase(msg.sender, msg.value, 0, "Direct purchase token active receive");
        purchaseTokens();

    }
  
    fallback() external payable {
        //  //emit log("fallback payable call purchaseTokens")
        emit LogPurchase(msg.sender, msg.value, 0, "Direct purchase token active fallback");
        purchaseTokens();
    }
    
    /// @dev Issue token based on Ether received.
    function purchaseTokens() public payable inProgress{
        // only accept a minimum amount of ETH?
        require(msg.value >= 0.01 ether);

        uint _tokens = computeTokenAmount(msg.value); 
        doIssueTokens(msg.sender, _tokens);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyAuthorized public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(address(0), address(this), mintedAmount);
        emit Transfer(address(this), target, mintedAmount);
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param target Address to be frozen
    /// @param freeze either to freeze it or not
    function freezeAccount(address target, bool freeze) onlyAuthorized public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice Allow users to buy tokens for `newRatePrice` eth 
    /// @param newRate Price the users can sell to the contract
    function setRatePrices(uint256 newRate) onlyAuthorized public {
        baseRate = newRate;
    }

    /// @notice Allow users to buy tokens for `newTokenSaleHardCap`
    /// @param newTokenSaleHardCap Amount of  token sale hard cap
    function setTokenSaleHardCap(uint256 newTokenSaleHardCap) onlyAuthorized public {
        tokenSaleHardCap = newTokenSaleHardCap;
    }

    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));
        balanceOf[_beneficiary] += _tokens;
        totalSupply += _tokens;
        emit Transfer(address(0), address(this), _tokens);
        emit Transfer(address(this), _beneficiary, _tokens);
    }

    /// @dev Compute the amount of  token that can be purchased.
    /// @param ethAmount Amount of Ether in WEI to purchase  .
    /// @return Amount of token to purchase
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256) {
        uint256 tokens = ethAmount.mul(baseRate) / 10**uint256(decimals);
        return tokens;
    }

    /// @notice getBalance ether
    function getBalance() public view onlyAuthorized returns (uint) {
        return address(this).balance;
    }

    /// @dev withdraw eth to onlyAuthorized address
    function withdrawMoney() public onlyAuthorized {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    /// @dev withdraw eth with amount to target address
    function withdrawMoneyTo(address payable _to, uint256 _amount) public onlyAuthorized {
        require(_amount <= getBalance());
        _to.transfer(_amount);
    }

    /// @dev Closes the sale, issues the team tokens and burns the unsold
    function close() public onlyAuthorized beforeEnd {
        tokenSaleClosed = true;
    }

    /// @dev Open the sale status
    function openSale() public onlyAuthorized{
        tokenSaleClosed = false;
    }

}