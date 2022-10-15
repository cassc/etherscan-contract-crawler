/**
 *Submitted for verification at BscScan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBEP20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
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

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract GEToken is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  event TokenStaked(address account, uint256 amount, uint256 months);

  struct StakedUsers {
  	bool exist;
    address user;
    uint stkAmt;
    uint expTime;
  }

  uint256 firstMintTime;
  uint256 secondMindTime;
  uint256 thirdMintTime;

  mapping (address => StakedUsers) public stakings;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(address management,address marketing) {
    _name = "GE Token";
    _symbol = "GE";
    _decimals = 18;
    _totalSupply = 40000000 ether;
    uint256 companyAmt = 5000000 ether;
    uint256 ownerBal = _totalSupply.sub(companyAmt).sub(companyAmt);
    _balances[msg.sender] = ownerBal;
    emit Transfer(address(0), msg.sender, ownerBal);

    _balances[management] = companyAmt;
    emit Transfer(address(0), management, companyAmt);

    _balances[marketing] = companyAmt;
    emit Transfer(address(0), marketing, companyAmt);

    firstMintTime = block.timestamp + 365 days;
    secondMindTime = block.timestamp + 365 days + 365 days;
    thirdMintTime = block.timestamp + 365 days + 365 days + 365 days;
  }

  function getStakingUserInfo(address account) external view returns(bool,uint,uint) {
    return (stakings[account].exist,stakings[account].stkAmt,stakings[account].expTime);
  }

  function doStaking(address account, uint256 amount, uint256 months) public onlyOwner returns(bool) {
  	require(!stakings[account].exist,"BEP20 : already staked");
  	require(amount > 0,"BEP20: amount not valid");
  	require(_balances[account]>=amount,"BEP20: not sufficient balance");
  	uint256 stkdays=0;
  	if(months==6){
  		stkdays = 180 days;
  	}else if(months==9){
  		stkdays = 270 days;
  	}else{
        revert("month not correct");
    }
  	StakedUsers memory stkUsers = StakedUsers(true,account,amount,block.timestamp + stkdays);
  	stakings[account] = stkUsers;
  	emit TokenStaked(account,amount,months);
  	return true;

  }

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

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    if(stakings[sender].exist){
    	if(block.timestamp < stakings[sender].expTime){
    		uint256 realBal = _balances[sender].sub(stakings[sender].stkAmt);
    		require(amount <= realBal,"BEP20: amount has staked");
    	}
    }
    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");
    require(_totalSupply <= 80000000 ether, "BEP20: mint closed");
    require(amount==20000000 ether,"BEP20: mint amount not correct");
    bool mintFlag = false;
    if(_totalSupply==40000000 ether && block.timestamp>=firstMintTime){
    	mintFlag = true;
    }else if(_totalSupply==60000000 ether && block.timestamp>=secondMindTime){
    	mintFlag = true;
    }else if(_totalSupply==80000000 ether && block.timestamp>=thirdMintTime){
    	mintFlag = true;
    }
    if(mintFlag){
    	_totalSupply = _totalSupply.add(amount);
	    _balances[account] = _balances[account].add(amount);
	    emit Transfer(address(0), account, amount);
    }else{
    	revert("BEP20: mint not possible");
    }
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
}