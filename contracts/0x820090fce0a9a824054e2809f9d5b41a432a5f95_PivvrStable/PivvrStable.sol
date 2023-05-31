/**
 *Submitted for verification at Etherscan.io on 2020-07-22
*/

pragma solidity ^0.5.0;
 
interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
 
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract PivvrStable is ERC20 {
  using SafeMath for uint256;
 
  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  string public constant name  = "PivvrStable";
  string public constant symbol = "PS";
  uint8 public constant decimals = 18;
 
  ERC20 public PDS;
 
  address public minter;
  uint256 public floorPrice = 0.001 ether;
 
  uint256 _totalSupply = 0;
 
  constructor(address pds_token_addr) public {
    minter = msg.sender;
    PDS = ERC20(pds_token_addr);
  }
 
  function mint(uint256 amount) external payable {
    require(msg.sender == minter);
 
    // Tranfer ETH, so that that every stablecoin is backed by ETH based on the floor price.
    require(msg.value == amount * floorPrice / 10**18);
 
    // Transfer PDS, accounting for the 0.2% burn so that every stablecoin is backed by 1 PDS token.
    require(PDS.transferFrom(msg.sender, address(this), amount * 100000 / 99799));
 
    _totalSupply = _totalSupply.add(amount);
    balances[msg.sender] = balances[msg.sender].add(amount);
    emit Transfer(address(0), msg.sender, amount);
  }
 
  function redeemForETH(uint256 amount) public {
    require(amount != 0);
    require(amount <= balances[msg.sender]);
 
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
 
    msg.sender.transfer(amount * floorPrice / 10**18);
  }
 
  function redeemForPDS(uint256 amount) public {
    require(amount != 0);
    require(amount <= balances[msg.sender]);
 
    _totalSupply = _totalSupply.sub(amount);
    balances[msg.sender] = balances[msg.sender].sub(amount);
    emit Transfer(msg.sender, address(0), amount);
 
    PDS.transfer(msg.sender, amount);
  }
 
  function redeemAllForETH() external {
    redeemForETH(balanceOf(msg.sender));
  }
 
  function redeemAllForPDS() external {
    redeemForPDS(balanceOf(msg.sender));
  }
 
  function retrieveExcessFunds() external {
    // When someone redeems a stablecoin, they pick to receive either ETH or PDS.
    // This leaves extra funds in the contract, allow the minter to retrieve them.
    require(msg.sender == minter);
 
    uint256 excessETH = address(this).balance.sub(totalSupply() * floorPrice / 10**18);
    uint256 excessPDS = PDS.balanceOf(address(this)).sub(totalSupply());
     
    if (excessETH > 0)
      msg.sender.transfer(excessETH);
    if (excessPDS > 0)
      PDS.transfer(msg.sender, excessPDS);
  }
 
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
 
  function balanceOf(address player) public view returns (uint256) {
    return balances[player];
  }
 
  function allowance(address player, address spender) public view returns (uint256) {
    return allowed[player][spender];
  }
 
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= balances[msg.sender]);
    require(to != address(0));
 
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(value);
 
    emit Transfer(msg.sender, to, value);
    return true;
  }
 
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
 
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
 
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));
   
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);
   
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
   
    emit Transfer(from, to, value);
    return true;
  }
 
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }
 
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
    emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
    return true;
  }
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
 
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}