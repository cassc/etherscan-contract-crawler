/**
 *Submitted for verification at Etherscan.io on 2023-08-31
*/

// SPDX-License-Identifier: MIT

/*

__/\\\\____________/\\\\___/\\\\\\\\\\\\\\\___/\\\________/\\\___/\\\\\\\\\\\\_________/\\\\\\\\\___________/\\\\\______        
 _\/\\\\\\________/\\\\\\__\/\\\///////////___\/\\\_______\/\\\__\/\\\////////\\\_____/\\\\\\\\\\\\\_______/\\\///\\\____       
  _\/\\\//\\\____/\\\//\\\__\/\\\______________\//\\\______/\\\___\/\\\______\//\\\___/\\\/////////\\\____/\\\/__\///\\\__      
   _\/\\\\///\\\/\\\/_\/\\\__\/\\\\\\\\\\\_______\//\\\____/\\\____\/\\\_______\/\\\__\/\\\_______\/\\\___/\\\______\//\\\_     
    _\/\\\__\///\\\/___\/\\\__\/\\\///////_________\//\\\__/\\\_____\/\\\_______\/\\\__\/\\\\\\\\\\\\\\\__\/\\\_______\/\\\_    
     _\/\\\____\///_____\/\\\__\/\\\_________________\//\\\/\\\______\/\\\_______\/\\\__\/\\\/////////\\\__\//\\\______/\\\__   
      _\/\\\_____________\/\\\__\/\\\__________________\//\\\\\_______\/\\\_______/\\\___\/\\\_______\/\\\___\///\\\__/\\\____  
       _\/\\\_____________\/\\\__\/\\\\\\\\\\\\\\\_______\//\\\________\/\\\\\\\\\\\\/____\/\\\_______\/\\\_____\///\\\\\/_____ 
        _\///______________\///___\///////////////_________\///_________\////////////______\///________\///________\/////_______

    Join us on telegram: https://t.me/mevdao

    https://mevdao.org

*/
pragma solidity =0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract MEVDAO is IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    // Buyer addreess => Block number
    mapping (address => uint256) public buyers;
    // Address => is allowed to transfer anytime
    mapping (address => bool) public allowedAddresses;
    address public owner;
    uint256 private _totalSupply = 1e6 * 1e18; // 1M tokens with 18 decimals
    string public name = 'MEVDAO';
    string public symbol = 'MEVDAO';
    uint256 public decimals = 18;
    bool public blockProtectionEnabled = true;
    address public pairAddress;
    bool public tradingEnabled;

    modifier onlyOwner {
        require(msg.sender == owner, "owner");
        _;
    }

    constructor (address _uniswapRouter) {
        _balances[msg.sender] = _totalSupply;
        owner = msg.sender;

        pairAddress = IUniswapV2Factory(IUniswapV2Router(_uniswapRouter).factory())
            .createPair(address(this), IUniswapV2Router(_uniswapRouter).WETH());
        allowedAddresses[msg.sender] = true;
    }

    function setBot(address _bot, bool _enabled) public onlyOwner {
        allowedAddresses[_bot] = _enabled;
    }

    function changeBotProtection(bool _enabled) public onlyOwner {
        blockProtectionEnabled = _enabled;
    }

    // Enable trading
    function openTheGates() public onlyOwner {
        tradingEnabled = true;
        allowedAddresses[pairAddress] = true;
    }

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _user) public override view returns (uint256) {
        return _balances[_user];
    }

    function allowance(address _user, address spender) public override view returns (uint256) {
        return _allowed[_user][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
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
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
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
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender] - value);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender] + addedValue);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender] - subtractedValue);
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));
        require(tradingEnabled || allowedAddresses[from], "Trading hasn't started yet"); // Must execute openTheGates() to allow the pair contract
        if (blockProtectionEnabled) {
            if (from == pairAddress) {
                buyers[to] = block.number;
            } else {
                if (!allowedAddresses[from]) {
                    require(block.number != buyers[from], "Buyers can't be sellers in the same block");
                }
            }
        }

        _balances[from] = _balances[from] - value;
        _balances[to] = _balances[to] + value;
        emit Transfer(from, to, value);
    }

    function _approve(address _user, address spender, uint256 value) internal {
        require(spender != address(0));
        require(_user != address(0));

        _allowed[_user][spender] = value;
        emit Approval(_user, spender, value);
    }

    function recoverETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function recoverStuckTokens(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
}