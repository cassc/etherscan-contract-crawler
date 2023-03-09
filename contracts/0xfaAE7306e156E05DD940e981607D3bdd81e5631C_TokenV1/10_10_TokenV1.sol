//SPDX-License-Identifier: Unlicensed
 
pragma solidity ^0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { AbstractTokenV1 } from "./AbstractTokenV1.sol";
import { Ownable } from "./Ownable.sol";
import { Pausable } from "./Pausable.sol";
import { Blacklistable } from "./Blacklistable.sol";
// import { Rescuable } from "./Rescuable.sol";

/**
 * @title Token
 * @dev ERC20 Token backed by fiat reserves
 */

contract TokenV1 is AbstractTokenV1, Ownable, Pausable, Blacklistable {
    
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    string public currency;
    address public masterMinter;
    //bool internal initializedToken;

    uint256 internal _totalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => address[]) internal approvedAddresses;
    mapping(address => bool) public isMinter;
    mapping(address => uint256) public minterAllowance; //Allowance set by approval



    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);

    modifier onlyMinter(){
        require(isMinter[msg.sender], "not a minter");
        _;
    }

     /**
     * @dev Throws if called by any account other than the masterMinter
     */
    modifier onlyMasterMinter() {
        require(
            msg.sender == masterMinter,
            "caller not masterMinter"
        );
        _;
    }

    function initializeToken(        
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenCurrency,
        uint8 tokenDecimals,
        address newMasterMinter,
        address newPauser, 
        address newBlacklister)
        public initializer {
        Ownable.initialize(msg.sender);
        Pausable.initPaused();
                require(
            newMasterMinter != address(0),
            "No zero addr"
        );
        require(
            newPauser != address(0),
            "No zero addr"
        );
        require(
            newBlacklister != address(0),
            "No zero addr"
        );
    
        _name = tokenName;
        _symbol = tokenSymbol;
        currency = tokenCurrency;
        _decimals = tokenDecimals;
        masterMinter = newMasterMinter;
        _pauser = newPauser;
        _blacklister = newBlacklister;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }


    function getApprovedAddresses() external view returns (address[] memory){
        return(approvedAddresses[msg.sender]);
    }

    function getMinterAllowance(address minter) external view returns (uint256) {
        return minterAllowance[minter];
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(address owner, address spender)
        external
        override
        view
        returns (uint256)
    {
        return allowed[owner][spender];
    }

    /**
     * @dev Get totalSupply of token
     */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Get token balance of an account
     * @param account address The account
     */
    function balanceOf(address account)
        external
        override
        view
        returns (uint256)
    {
        return balances[account];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value.
     * @param spender   Spender's address
     * @param value     Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 value)
        external
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {        
        require(msg.sender!=spender, "msg.sender not spender");
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Internal function to set allowance
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param value     Allowance amount
     */
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal override {

        require(owner != address(0), "No zero addr");
        require(spender != address(0), "No zero addr");
        approvedAddresses[owner].push(spender);
        allowed[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        require(
            value <= allowed[from][msg.sender],
            "amount > allowance"
        );
        require(
            allowed[from][msg.sender] > 0,
            "allowance = 0"
        );
        _transfer(from, to, value);
        allowed[from][msg.sender] -= value;
        return true;
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transfer(address to, uint256 value)
        external
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to)
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @notice Internal function to process transfers
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override {
        require(from != address(0), "No zero addr");
        require(to != address(0), "No zero addr");
        require(
            value <= balances[from],
            "amount > balance"
        );

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
    }

    /*
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @param _minterCap The minting allowance for the minter
     * @return True if the operation was successful.
     */
     
    function configureMinter(address minter, uint256 _minterAllowedAmount)
        external
        whenNotPaused
        onlyMasterMinter
        returns (bool)
    {
        isMinter[minter] = true;
        minterAllowance[minter] = _minterAllowedAmount;

        emit MinterConfigured(minter, _minterAllowedAmount);
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     * @return True if the operation was successful.
     */
    function removeMinter(address minter)
        external
        onlyMasterMinter
        returns (bool)
    {
        isMinter[minter] = false;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param _amount uint256 the amount of tokens to be burned
     */
    function burn(uint256 _amount)
        external
        whenNotPaused
        onlyMinter
        notBlacklisted(msg.sender)
    {
        uint256 balance = balances[msg.sender];
        require(_amount > 0, "burn amount not greater than 0");
        require(balance >= _amount, "burn amount exceeds balance");

        _totalSupply -= (_amount);
        balances[msg.sender] -= (_amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
    }

    function mint(address _to, uint256 _amount)
    public
    whenNotPaused
    notBlacklisted(msg.sender)
    notBlacklisted(_to)
    returns (bool)
    {
     
        require(_to != address(0), "No zero addr");
        require(_amount > 0, "must mint > 0");
        require(isMinter[_to], "unconfigured minter");
        require(minterAllowance[_to] >= _amount, "allowance exceeded");
        _totalSupply += _amount;
        balances[_to] += _amount;
        minterAllowance[_to] -= _amount;
        emit Mint(msg.sender, _to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function updateMasterMinter(address _newMasterMinter) external onlyOwner {
        require(
            _newMasterMinter != address(0),
            "No zero addr"
        );
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }

        /**
     * @notice Increase the allowance by a given increment
     * @param spender   Spender's address
     * @param increment Amount of increase in allowance
     * @return True if successful
     */
    function increaseAllowance(address spender, uint256 increment)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {       
        _increaseAllowance(msg.sender, spender, increment);
        return true;
    }

    /**
     * @notice Decrease the allowance by a given decrement
     * @param spender   Spender's address
     * @param decrement Amount of decrease in allowance
     * @return True if successful
     */
    function decreaseAllowance(address spender, uint256 decrement)
        external
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(spender)
        returns (bool)
    {

        _decreaseAllowance(msg.sender, spender, decrement);
        return true;
    }

     function _increaseAllowance(
        address owner,
        address spender,
        uint256 increment
    ) internal override { 
        _approve(owner, spender, allowed[owner][spender] + increment);
    }

    /**
     * @notice Internal function to decrease the allowance by a given decrement
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param decrement Amount of decrease
     */
    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 decrement
    ) internal override {
        require(
            
            allowed[owner][spender] >= decrement,
            "allowance < zero"
        );

        _approve(
            owner,
            spender,
            allowed[owner][spender] - decrement
        );
    }
}