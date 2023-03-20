/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

pragma solidity 0.5.16;

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

interface Irt {
  function mint(address sender, uint256 amount) external;
}

interface IOracle {
  function getCurrentPrice() external view returns (uint256);
}

contract Context {
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
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

  constructor () internal {
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

contract BEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 public _decimals;
  string public _symbol;
  string public _name;

  uint256 private lastUpdate = now;
  uint256 private lastUpdate2 = now;
  uint256 private launchTime = now;
  uint256 private totalBurns;
  uint256 private totalMints;
  uint256 private totalBurnsMA;
  uint256 private minBalance;
  mapping (address => bool) public isRedeemable;
  IOracle private grtOracle = IOracle(0xeCcA631E96E7BeB702d675927a32Ec8f5705BD34);
  IOracle private bnbOracle = IOracle(0x53Fb68eEC2926fAC096F93E371e89D88e43B461F);

  mapping (address => uint256) private timeTokenAdded;
  mapping (address => bool) private redeemableForever;
  mapping (address => uint256) private mints;
  mapping (address => uint256) private burns;
  mapping (address => uint256) private lastClaim;
  mapping (address => uint256) public totalLocked;
  mapping (address => uint256) public totalClaims;
  mapping (address => mapping(address => uint256)) public locked;

  address[] public validLps;
  address[] public redeemList;
  address private updatedOracleAddr;
  address private gCoinAddr;

  event Redeem(address token, uint256 amount);
  event NewOracle(address addr);

  constructor() public {
    _name = "GRT";
    _symbol = "GRT";
    _decimals = 18;
    totalBurnsMA = 100 * 1e18 * 100;
    _totalSupply = 10 * 1e25;
    minBalance = _totalSupply / 10;
    _balances[msg.sender] = _totalSupply;
    gCoinAddr = address(this);
    emit Transfer(address(0), msg.sender, _totalSupply);
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

  function burn(uint256 amount) public returns (bool) {
    _burn(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");
    update();
    if(isRedeemable[recipient]) {
      Irt redeemableToken = Irt(recipient);
      _burnTo(sender, amount, recipient);
      emit Transfer(recipient, address(0), amount);      
      redeemableToken.mint(sender, amount);
      burns[recipient] = burns[recipient].add(amount);
    } else {
      _balances[recipient] = _balances[recipient].add(amount);
      emit Transfer(sender, recipient, amount);
    }
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    totalBurns = totalBurns.add(amount);
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _burnTo(address account, uint256 amount, address _to) internal {
    require(account != address(0), "BEP20: burn from the zero address");
    totalBurns = totalBurns.add(amount);
    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, _to, amount);
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

  function settings(address _grtOracle, address _gCoinAddr, address _bnbOracle, uint256 _minBalance) external onlyOwner {
    grtOracle = IOracle(_grtOracle);
    minBalance = _minBalance;
    gCoinAddr = _gCoinAddr;
    if(_bnbOracle != address(bnbOracle)) {
      updatedOracleAddr = _bnbOracle;
      lastUpdate2 = now;
      emit NewOracle(updatedOracleAddr);
    }
  }

  function setValidLps(address [] calldata _validLps) external onlyOwner {
    require(_validLps.length == 5);
    validLps = _validLps;
  }

  function setNewOracleAddress() external {
    require(updatedOracleAddr != address(0x0));
    require(now.sub(lastUpdate2) > 604800 && lastUpdate2 > 0);
    bnbOracle = IOracle(updatedOracleAddr);
    lastUpdate2 = 0;
    updatedOracleAddr = address(0x0);
  }

  function removeToken(address addr) internal {
    isRedeemable[addr] = false;
    timeTokenAdded[addr] = 0; 
    removeDisabledTokens();
  }

  function setRedeemStatus(address addr, bool status) public onlyOwner {
    if(status) {
      if(isRedeemable[addr]) {
        redeemableForever[addr] = true;
        return;
      }
      uint256 allowedTokenAmount = (2 + now.sub(launchTime) / 3000000);
      if(redeemList.length > 0) {
        address lastAddedToken = redeemList[redeemList.length - 1];
        if(allowedTokenAmount > 4) require(now.sub(timeTokenAdded[lastAddedToken]) > 86400);
      }
      require(redeemList.length < allowedTokenAmount);
      isRedeemable[addr] = true;
      redeemList.push(addr);
      timeTokenAdded[addr] = now;
    } else {
      require(isRedeemable[addr]);
      require(!redeemableForever[addr]);
      removeToken(addr);
    }
  }

  function removeDisabledTokens() internal {
    uint256 _l = redeemList.length;
    address[] memory newRedeemList = new address[](_l);
    uint256 index = 0;
    for(uint256 i; i < _l; i++) {
      if(isRedeemable[redeemList[i]]) {
        newRedeemList[index++] = redeemList[i];
      }
    }
    redeemList = newRedeemList;
    for(uint256 i; i < (_l - index); i++) {
      redeemList.pop();
    }
  }

  function update() public {
    uint256 timePassed = now.sub(lastUpdate); 
    if(timePassed > 86400) {
      totalBurnsMA = getTotalBurnsMA();
      lastUpdate = now; 
    }
  }
  
  function lockLP(uint256 index, uint256 amount) public {
    require(index < 5);
    require(validLps[index] != address(0x0));
    address _tokenAddr = validLps[index];
    IBEP20 _token = IBEP20(_tokenAddr);    
    uint256 balanceBefore = _token.balanceOf(address(this));    
    _token.transferFrom(_msgSender(), address(this), amount);
    uint256 balanceAfter = _token.balanceOf(address(this));
    uint256 diff = balanceAfter.sub(balanceBefore);  
    locked[_tokenAddr][msg.sender] = locked[_tokenAddr][msg.sender].add(diff);
    totalLocked[_tokenAddr] = totalLocked[_tokenAddr].add(diff);
  }

  function withdrawBNB() public {
    address payable account = _msgSender();
    require(aboveMinBalance(account));
    uint256 ndays = now.sub(lastClaim[msg.sender]) / 86400;
    if(ndays > 0 && lastClaim[msg.sender] > 0) {
      if(ndays > 7) ndays = 7;
      lastClaim[account] = now; 
      uint256 transferAmount = ndays * withdrawableDailyAmount(account);
      if(transferAmount > 0) {
        totalClaims[account] = totalClaims[account].add(transferAmount);
        account.transfer(transferAmount);
      }
    }
  }

  function aboveMinBalance(address account) private view returns(bool) {
    return (IBEP20(gCoinAddr).balanceOf(account) > minBalance);
  }

  function withdrawableDailyAmount(address account) public view returns(uint256) {
    uint256 transferAmount;
    for(uint256 i = 0; i < 5; i++) {
      address _token = validLps[i];
      if(_token != address(0x0)) {
        uint256 _a = locked[_token][account] * address(this).balance / (totalLocked[_token] * 100);
        transferAmount = transferAmount.add(_a);
      }
    }
    return transferAmount;
  }
  
  function getTotalBurnsMA() internal view returns(uint256) {
    uint256 timePassed = now.sub(lastUpdate); 
    return (totalBurnsMA * 5184000 + totalBurns * timePassed) / (5184000 + timePassed);
  }

  function mintCeilingA(address addr) public view returns(uint256) {
    if(!isRedeemable[addr]) return 0;
    uint256 timePassed = now.sub(timeTokenAdded[addr]); 
    if(timePassed > 31536000) return uint256(-1);
    return burns[addr].add((((timePassed / 200) ** 2) / 100000 + 1) * 100 * 1e18);
  }

  function mintCeilingB(address addr) public view returns(uint256) {
    if(!isRedeemable[addr] || redeemList.length == 0) return 0;
    uint256 avgBurn = totalBurnsMA / redeemList.length;
    uint256 c1 = 10 * burns[addr];
    uint256 c2 = 15 * avgBurn + burns[addr];
    uint256 c = (c1 < c2) ? c1 : c2;
    c = c.add(1e24);
    return (totalBurnsMA > totalMints) ? c * 3 : c;
  }

  function getRedeemableAmount(address addr) internal view returns(uint256) {
    uint256 ca = mintCeilingA(addr);
    uint256 cb = mintCeilingB(addr);
    return cb < ca ? cb : ca; 
  }

  function mint(address account, uint256 amount) public returns(bool){
    require(isRedeemable[msg.sender]);
    require(account != address(0), "BEP20: mint to the zero address");
    uint256 totalTokenMints = mints[msg.sender].add(amount);
    uint256 ca = mintCeilingA(msg.sender);
    uint256 cb = mintCeilingB(msg.sender);
    require(totalTokenMints < ca);
    if(totalTokenMints > cb) {
      removeToken(msg.sender);
      return true;
    } 
    totalMints = totalMints.add(amount);
    mints[msg.sender] = totalTokenMints;
    _mint(msg.sender, amount);
    emit Transfer(address(0), account, amount);
    return false;
  }

  function getCurrentPrice() public view returns (uint256) {
    return grtOracle.getCurrentPrice();
  }

  function getBnbPrice() public view returns (uint256) {
    return bnbOracle.getCurrentPrice();
  }

  function getGlobals() external view returns (uint256[4] memory) {
    return [totalMints, totalBurns, getTotalBurnsMA(), minBalance];
  }  

  function getTokenInfo(address addr) external view returns (uint256[4] memory) {
    return [mints[addr], burns[addr], getRedeemableAmount(addr), timeTokenAdded[addr]];
  }  

  function mintGRT() public payable {
    uint256 _amount = (msg.sender == owner() ? msg.value * 12 / 10 : msg.value) * getBnbPrice() * 100 / 1e18;
    _mint(_msgSender(), _amount);
  }

  function () external payable {
    uint256 _amount = (msg.sender == owner() ? msg.value * 12 / 10 : msg.value) * getBnbPrice() * 100 / 1e18;
    _mint(_msgSender(), _amount);
  }

}