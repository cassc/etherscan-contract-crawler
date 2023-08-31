/**
 *Submitted for verification at Etherscan.io on 2023-07-21
*/

// SPDX-License-Identifier: MIT
/*
  AntiMEV token detects and defends against MEV attack bots
  
  Website: https://antimev.io

  Twitter: https://twitter.com/Anti_MEV

  Telegram: https://t.me/antimev
*/
pragma solidity ^0.8.17;

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract AntiMEV is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _lastTxBlock; // block number for user's last tx
    mapping(address => bool) public isBOT; // MEV bots
    mapping(address => bool) public isVIP; // VIP addresses

    bool public _detectMEV = true; // enable MEV detection features
    uint256 public _mineBlocks = 3; // blocks to mine before 2nd tx
    uint256 public _gasDelta = 25; // increase in gas price to be considered bribe
    uint256 public _avgGasPrice = 1 * 10**9; // initial rolling average gas price
    uint256 private _maxSample = 10; // blocks used to calculate average gas price
    uint256 private _txCounter = 0; // counter used for average gas price

    string private constant _name = unicode"AntiMEV";
    string private constant _symbol = unicode"AntiMEV";
    uint256 public _maxWalletSize =  _tTotal.mul(49).div(1000); // maxWallet is 4.9% supply
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1123581321 * 10**_decimals; // supply is Fibonnaci

    address private _devWallet = 0xc2657176e213DDF18646eFce08F36D656aBE3396;
    address private _burnWallet = 0x8B30998a9492610F074784Aed7aFDd682B23B416;
    address private _airdropWallet = 0xe276d3ea57c5AF859e52d51C2C11f5deCb4C4838;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen;

    constructor () {
        _balances[_msgSender()] = _tTotal.mul(90).div(100); // 90%
        _balances[_devWallet] = _tTotal.mul(25).div(1000); // 2.5%
        _balances[_burnWallet] =_tTotal.mul(35).div(1000); // 3.5%
        _balances[_airdropWallet] = _tTotal.mul(40).div(1000); // 4%

        isVIP[owner()] = true;
        isVIP[address(this)] = true;
    }
    function _checkMEV(
        address from,
        address to
    ) private  {
      // test for known bot
      require(!isBOT[from] && !isBOT[to], "AntiMEV: Known MEV Bot");
      // test for sandwich attack
      require(_lastTxBlock[from] + _mineBlocks < block.number,
        "AntiMEV: Detected sandwich attack, mine more blocks");
      _lastTxBlock[from] = block.number;
      // calculate rolling average gas price
      _txCounter += 1;
      _avgGasPrice =
        (_avgGasPrice * (_txCounter - 1)) / _txCounter + tx.gasprice / _txCounter;
      // test for gas bribe (front-run)
      require(
        tx.gasprice <= _avgGasPrice.add(_avgGasPrice.mul(_gasDelta).div(100)),
        "AntiMEV: Detected gas bribe, possible front-run");
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner()) {
            require(tradingOpen,"Trading not open");
            if (_detectMEV) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { 
                      _checkMEV(from, to);
                  }
              }
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! isVIP[to] ) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            }
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount);
        emit Transfer(from, to, amount);
    }    
    function setMEV(
        bool detectMEV,
        uint256 mineBlocks,
        uint256 gasDelta,
        uint256 maxSample,
        uint256 avgGasPrice
    ) external onlyOwner {
        _detectMEV = detectMEV;
        _mineBlocks = mineBlocks;
        _gasDelta = gasDelta;
        _maxSample = maxSample;
        _avgGasPrice = avgGasPrice;
    }
    function setMaxWallet(uint256 maxWallet) external onlyOwner {
        _maxWalletSize = maxWallet;
    }    
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setBOT(address _address, bool _isBot) external onlyOwner{
        require(!isVIP[_address] && _address != uniswapV2Pair && _address != address(uniswapV2Router), 
            "AntiMEV: Cannot set VIP to BOT");
        isBOT[_address] = _isBot;
    }
    function setVIP(address _address, bool _isVIP) external onlyOwner{
        require(!isBOT[_address], "AntiMEV: Cannot set BOT to VIP");
        isVIP[_address] = _isVIP;
    }
    function setWallets(
        address dev,
        address burn,
        address airdrop
    ) external onlyOwner {
        _devWallet = dev;
        _burnWallet = burn;
        _airdropWallet = airdrop;
    }
    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        tradingOpen = true;
    }
    receive() external payable {}
}