//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IOwnable {
    function owner() external view returns (address);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address _owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract BaseErc20Light is IERC20, IOwnable {
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;
    uint256 internal _totalSupply;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    
    address public override owner;
    bool public launched;
    
    mapping (address => bool) internal exchanges;

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }
    
    modifier isLaunched() {
        require(launched, "can only be called once token is launched");
        _;
    }

    // @dev Trading is allowed before launch if the sender is the owner, we are transferring from the owner, or in canAlwaysTrade list
    modifier tradingEnabled(address from) {
        require(launched || from == owner, "trading not enabled");
        _;
    }
    
    function configure(address _owner) internal virtual {
        owner = _owner;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _owner) external override view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender) external override view returns (uint256) {
        return _allowed[_owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) external override tradingEnabled(msg.sender) returns (bool) {
        require(spender != address(0), "cannot approve the 0 address");

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) external override tradingEnabled(from) returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    // Virtual methods
    function launch() virtual external onlyOwner {
        require(launched == false, "contract already launched");
        launched = true;
    }
    
    function preTransfer(address from, address to, uint256 value) virtual internal { }

    // Admin methods
    function changeOwner(address who) external onlyOwner {
        owner = who;
    }

    function setExchange(address who, bool on) external onlyOwner {
        require(exchanges[who] != on, "already set");
        exchanges[who] = on;
    }

    // Private methods

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "cannot be zero address");

        preTransfer(from, to, value);

        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;

        emit Transfer(from, to, value);
    }
}