/**
 *Submitted for verification at Etherscan.io on 2020-08-28
*/

pragma solidity ^0.5.9;
 
library SafeMath {
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        return (a / b);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return (a - b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
 
contract ERC20Interface {
 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function approve(address _spender, uint256 _value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
}
 
contract WadzPayToken is ERC20Interface {
   
    string public constant name = "WadzPay";
    string public constant symbol = "WTK";
    uint8 public constant decimals = 2;  // 18 is the most common number of decimal places
 
 
    using SafeMath for uint256;
 
    // Total amount of tokens issued
    uint256 constant internal salesPool = 15000000000; // sales pool size
    uint256 constant internal retainedPool = 10000000000; // retained pool size
   
    uint256 internal salesIssued = 0;
    uint256 internal retainedIssued = 0;
   
    bool public isIcoRunning = false;
    bool public isTransferAllowed = false;
   
    address public owner;
   
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminsAdded(address[] _addresses);
    event Whitelisted(address[] _addresses);
 
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;
    mapping(address => bool) admins;
    mapping(address => bool) whitelist;
   
   
    /**
    * @dev The ERC20 constructor sets the original `owner` of the contract to the sender
    * account and initializes the pools
    */
    constructor() public {
        owner = msg.sender;
        admins[msg.sender] = true;
    }
   
    function startICO() public onlyOwner {
        isIcoRunning = true;
    }
      
    function startTransfers() public onlyOwner {
        isTransferAllowed = true;
    }
   
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
    modifier onlyAdmin() {
        require(isAdmin(msg.sender));
        _;
    }
   
    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
       
        emit OwnershipTransferred(owner, newOwner);
    }
   
    /**
    * @dev Allows the current owner to insert administratiors
    * @param _addresses An array of addresses to insert.
    */
    function setAdministrators(address[] memory _addresses) public onlyOwner {
        for(uint i=0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
       
        emit AdminsAdded(_addresses);
    }
   
    /**
    * @dev Allows the current owner to remove administratiors
    * @param _address Address of the administrator that needs to be disabled.
    */
    function unsetAdministrator(address _address) public onlyOwner {
        admins[_address] = false;
    }
   
    /**
    * @dev Checks whether an address is administrator or not
    * @param addr Address that we are checking.
    */
    function isAdmin(address addr) public view returns (bool) {
 
        return admins[addr];
    }
   
    /**
    * @dev Allows the current owner to whitelist addresses
    * @param _addresses An array of addresses to whitelist.
    */
    function whitelistAddresses(address[] memory _addresses) public onlyAdmin {
        for(uint i=0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
       
        emit Whitelisted(_addresses);
    }
   
    /**
    * @dev Allows the admins to remove existing whitelist permissions
    * @param _address Address of the user that needs to be blacklisted.
    */
    function unsetWhitelist(address _address) public onlyAdmin {
        whitelist[_address] = false;
    }
   
    /**
    * @dev Checks whether an address is whitelisted or not
    * @param addr Address that we are checking.
    */
    function isWhitelisted(address addr) public view returns (bool) {
 
        return whitelist[addr];
    }
 
    function totalSupply() public view returns (uint256) {
        return salesPool + retainedPool;
    }
   
    function getsalesSupply() public pure returns (uint256) {
        return salesPool;
    }
   
    function getRetainedSupply() public pure returns (uint256) {
        return retainedPool;
    }
   
    function getIssuedsalesSupply() public view returns (uint256) {
        return salesIssued;
    }
   
    function getIssuedRetainedSupply() public view returns (uint256) {
        return retainedIssued;
    }
   
 
    /* Get the account balance for an address */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }
 
 
 
    /* Transfer the balance from owner's account to another account */
    function transfer(address _to, uint256 _amount) public returns (bool) {
 
        require(_to != address(0x0));
 
 
        // amount sent cannot exceed balance
        require(balances[msg.sender] >= _amount);
       
        require(isTransferAllowed);
        require(isIcoRunning);
 
       
        // update balances
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to]        = balances[_to].add(_amount);
 
        // log event
        emit Transfer(msg.sender, _to, _amount);
       
        return true;
    }
   
    /* Sales transfer of balance from admin to investor */
    /* Amount includes the 2 decimal places, so if you want to send 22,54 tokens the amount should be 2254 */
    /* If you want to send 20 tokens, the amount should be 2000 */
    function salesTransfer(address _to, uint256 _amount) public onlyAdmin returns (bool) {
        require(isWhitelisted(_to));
       
        require(_to != address(0x0));
       
        require(salesPool >= salesIssued + _amount);
       
 
        balances[_to] = balances[_to].add(_amount);
        salesIssued = salesIssued.add(_amount);
       
        emit Transfer(address(0x0), _to, _amount);
       
        return true;
       
    }
   
    function retainedTransfer(address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(isWhitelisted(_to));
       
        require(_to != address(0x0));
       
        require(retainedPool >= retainedIssued + _amount);
       
       
        balances[_to] = balances[_to].add(_amount);
        retainedIssued = retainedIssued.add(_amount);
       
        emit Transfer(address(0x0), _to, _amount);
       
        return true;
    }
   
    /* Allow _spender to withdraw from your account up to _amount */
    function approve(address _spender, uint256 _amount) public returns (bool) {
       
        require(_spender != address(0x0));
 
        // update allowed amount
        allowed[msg.sender][_spender] = _amount;
 
        // log event
        emit Approval(msg.sender, _spender, _amount);
       
        return true;
    }
 
    /* Spender of tokens transfers tokens from the owner's balance */
    /* Must be pre-approved by owner */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
       
        require(_to != address(0x0));
       
 
        // balance checks
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);
       
        require(isTransferAllowed);
        require(isIcoRunning);
 
        // update balances and allowed amount
        balances[_from]            = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]              = balances[_to].add(_amount);
 
        // log event
        emit Transfer(_from, _to, _amount);
       
        return true;
    }
 
    /* Returns the amount of tokens approved by the owner */
    /* that can be transferred by spender */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
   
    function withdrawTo(address payable _to) public onlyOwner {
        require(_to != address(0));
        _to.transfer(address(this).balance);
    }
 
    function withdrawToOwner() public onlyOwner {
        withdrawTo(msg.sender);
    }
}