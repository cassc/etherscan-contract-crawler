/**
 *Submitted for verification at BscScan.com on 2023-03-21
*/

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/// @title bit library
/// @notice old school bit bits
library bits {

    /// @notice check if only a specific bit is set
    /// @param slot the bit storage slot
    /// @param bit the bit to be checked
    /// @return return true if the bit is set
    function only(uint slot, uint bit) internal pure returns (bool) {
        return slot == bit;
    }

    /// @notice checks if all bits ares set and cleared
    function all(uint slot, uint set_, uint cleared_) internal pure returns (bool) {
        return all(slot, set_) && !all(slot, cleared_);
    }

    /// @notice checks if any of the bits_ are set
    /// @param slot the bit storage to slot
    /// @param bits_ the or list of bits_ to slot
    /// @return true of any of the bits_ are set otherwise false
    function any(uint slot, uint bits_) internal pure returns(bool) {
        return (slot & bits_) != 0;
    }

    /// @notice checks if any of the bits are set and all of the bits are cleared
    function check(uint slot, uint set_, uint cleared_) internal pure returns(bool) {
        return slot != 0 ?  ((set_ == 0 || any(slot, set_)) && (cleared_ == 0 || !all(slot, cleared_))) : (set_ == 0 || any(slot, set_));
    }

    /// @notice checks if all of the bits_ are set
    /// @param slot the bit storage
    /// @param bits_ the list of bits_ required
    /// @return true if all of the bits_ are set in the sloted variable
    function all(uint slot, uint bits_) internal pure returns(bool) {
        return (slot & bits_) == bits_;
    }

    /// @notice set bits_ in this storage slot
    /// @param slot the storage slot to set
    /// @param bits_ the list of bits_ to be set
    /// @return a new uint with bits_ set
    /// @dev bits_ that are already set are not cleared
    function set(uint slot, uint bits_) internal pure returns(uint) {
        return slot | bits_;
    }

    function toggle(uint slot, uint bits_) internal pure returns (uint) {
        return slot ^ bits_;
    }

    function isClear(uint slot, uint bits_) internal pure returns(bool) {
        return !all(slot, bits_);
    }

    /// @notice clear bits_ in the storage slot
    /// @param slot the bit storage variable
    /// @param bits_ the list of bits_ to clear
    /// @return a new uint with bits_ cleared
    function clear(uint slot, uint bits_) internal pure returns(uint) {
        return slot & ~(bits_);
    }

    /// @notice clear & set bits_ in the storage slot
    /// @param slot the bit storage variable
    /// @param bits_ the list of bits_ to clear
    /// @return a new uint with bits_ cleared and set
    function reset(uint slot, uint bits_) internal pure returns(uint) {
        slot = clear(slot, type(uint).max);
        return set(slot, bits_);
    }

}

/// @notice Emitted when a check for
error FlagsInvalid(address account, uint256 set, uint256 cleared);

/// @title UsingFlags contract
/// @notice Use this contract to implement unique permissions or attributes
/// @dev you have up to 255 flags you can use. Be careful not to use the same flag more than once. Generally a preferred approach is using
///      pure virtual functions to implement the flags in the derived contract.
abstract contract UsingFlags {
    /// @notice a helper library to check if a flag is set
    using bits for uint256;
    event FlagsChanged(address indexed, uint256, uint256);

    /// @notice checks of the required flags are set or cleared
    /// @param account_ the account to check
    /// @param set_ the flags that must be set
    /// @param cleared_ the flags that must be cleared
    modifier requires(address account_, uint256 set_, uint256 cleared_) {
        if (!(_getFlags(account_).check(set_, cleared_))) revert FlagsInvalid(account_, set_, cleared_);
        _;
    }

    /// @notice getFlags returns the currently set flags
    /// @param account_ the account to check
    function getFlags(address account_) public virtual view returns (uint256) {
        return _getFlags(account_);
    }

    function _getFlags(address account_) internal virtual view returns (uint256) {
        return _getFlagStorage()[account_];
    }

    /// @notice set and clear flags for the given account
    /// @param account_ the account to modify flags for
    /// @param set_ the flags to set
    /// @param clear_ the flags to clear
    function _setFlags(address account_, uint256 set_, uint256 clear_) internal virtual {
        uint256 before = _getFlags(account_);
        _getFlagStorage()[account_] = _getFlags(account_).set(set_).clear(clear_);
        emit FlagsChanged(account_, before, _getFlags(account_));
    }

    function _checkFlags(address account_, uint set_, uint cleared_) internal view returns (bool) {
        return _getFlags(account_).check(set_, cleared_);
    }

    /// @notice get the storage for flags
    function _getFlagStorage() internal view virtual returns (mapping(address => uint256) storage);
}

abstract contract UsingDefaultFlags is UsingFlags {
    using bits for uint256;

    struct DefaultFlags {
        uint initializedFlag;
        uint transferDisabledFlag;
        uint providerFlag;
        uint serviceFlag;
        uint networkFlag;
        uint serviceExemptFlag;
        uint adminFlag;
        uint blockedFlag;
        uint routerFlag;
        uint feeExemptFlag;
        uint servicesDisabledFlag;
        uint permitsEnabledFlag;
    }

    /// @notice the value of the initializer flag
    function _INITIALIZED_FLAG() internal pure virtual returns (uint256) {
        return 1 << 255;
    }

    function _TRANSFER_DISABLED_FLAG() internal pure virtual returns (uint256) {
        return _INITIALIZED_FLAG() >> 1;
    }

    function _PROVIDER_FLAG() internal pure virtual returns (uint256) {
        return _TRANSFER_DISABLED_FLAG() >> 1;
    }

    function _SERVICE_FLAG() internal pure virtual returns (uint256) {
        return _PROVIDER_FLAG() >> 1;
    }

    function _NETWORK_FLAG() internal pure virtual returns (uint256) {
        return _SERVICE_FLAG() >> 1;
    }

    function _SERVICE_EXEMPT_FLAG() internal pure virtual returns(uint256) {
        return _NETWORK_FLAG() >> 1;
    }

    function _ADMIN_FLAG() internal virtual pure returns (uint256) {
        return _SERVICE_EXEMPT_FLAG() >> 1;
    }

    function _BLOCKED_FLAG() internal pure virtual returns (uint256) {
        return _ADMIN_FLAG() >> 1;
    }

    function _ROUTER_FLAG() internal pure virtual returns (uint256) {
        return _BLOCKED_FLAG() >> 1;
    }

    function _FEE_EXEMPT_FLAG() internal pure virtual returns (uint256) {
        return _ROUTER_FLAG() >> 1;
    }

    function _SERVICES_DISABLED_FLAG() internal pure virtual returns (uint256) {
        return _FEE_EXEMPT_FLAG() >> 1;
    }

    function _PERMITS_ENABLED_FLAG() internal pure virtual returns (uint256) {
        return _SERVICES_DISABLED_FLAG() >> 1;
    }

    function _TOKEN_FLAG() internal pure virtual returns (uint256) {
        return _PERMITS_ENABLED_FLAG() >> 1;
    }

    function _isFeeExempt(address account_) internal view virtual returns (bool) {
        return _checkFlags(account_, _FEE_EXEMPT_FLAG(), 0);
    }

    function _isFeeExempt(address from_, address to_) internal view virtual returns (bool) {
        return _isFeeExempt(from_) || _isFeeExempt(to_);
    }

    function _isServiceExempt(address from_, address to_) internal view virtual returns (bool) {
        return _checkFlags(from_, _SERVICE_EXEMPT_FLAG(), 0) || _checkFlags(to_, _SERVICE_EXEMPT_FLAG(), 0);
    }

    function defaultFlags() external view returns (DefaultFlags memory) {
        return DefaultFlags(
            _INITIALIZED_FLAG(),
            _TRANSFER_DISABLED_FLAG(),
            _PROVIDER_FLAG(),
            _SERVICE_FLAG(),
            _NETWORK_FLAG(),
            _SERVICE_EXEMPT_FLAG(),
            _ADMIN_FLAG(),
            _BLOCKED_FLAG(),
            _ROUTER_FLAG(),
            _FEE_EXEMPT_FLAG(),
            _SERVICES_DISABLED_FLAG(),
            _PERMITS_ENABLED_FLAG()
        );
    }
}

error AdminRequired();

abstract contract UsingAdmin is UsingDefaultFlags {
    using bits for uint256;

    modifier requiresAdmin() virtual {
        if (!_isAdmin(msg.sender)) revert AdminRequired();
        _;
    }

    function _initializeAdmin(address admin_) internal virtual {
        _setFlags(admin_, _ADMIN_FLAG(), 0);
    }

    function setFlags(
        address account_,
        uint256 set_,
        uint256 clear_
    ) external virtual requires(msg.sender, _ADMIN_FLAG(), 0) {
        _setFlags(account_, set_, clear_);
    }

    function _isAdmin(address account_) internal view returns (bool) {
        return _getFlags(account_).all(_ADMIN_FLAG());
    }
}

library collections {
    using bits for uint16;
    using collections for CircularSet;
    using collections for Dict;
    using collections for DictItem;
    using collections for AddressSet;

    error KeyExists();
    error KeyError();

    struct AddressSet {
        address[] items;
        mapping(address => uint) indices;
    }

    function add(AddressSet storage set_, address item_) internal {
        if (set_.contains(item_)) revert KeyExists();
        set_.items.push(item_);
        set_.indices[item_] = set_.items.length;
    }

    function replace(AddressSet storage set_, address oldItem_, address newItem_) internal {
        if (set_.indices[oldItem_] == 0) {
            revert KeyError();
        }
        set_.items[set_.indices[oldItem_] - 1] = newItem_;
        set_.indices[newItem_] = set_.indices[oldItem_];
        set_.indices[oldItem_] = 0;
    }

    function pop(AddressSet storage set_) internal returns (address) {
        address last = set_.items[set_.length() - 1];
        delete set_.indices[last];
        return last;
    }

    function get(AddressSet storage set_, uint index_) internal view returns (address) {
        return set_.items[index_];
    }

    function length(AddressSet storage set_) internal view returns (uint) {
        return set_.items.length;
    }

    function remove(AddressSet storage set_, address item_) internal  {
        if (set_.indices[item_] == 0) {
            revert KeyError();
        }
        uint index = set_.indices[item_];
        if (index != set_.length()) {
            set_.items[index - 1] = set_.items[set_.length() - 1];
            set_.indices[set_.items[index - 1]] = index;
        }
        set_.items.pop();
        set_.indices[item_] = 0;
    }

    function clear(AddressSet storage set_) internal {
        for (uint i=0; i < set_.length(); i++) {
            address key = set_.items[i];
            set_.indices[key] = 0;
        }
        delete set_.items;
    }

    function contains(AddressSet storage set_, address item_) internal view returns (bool) {
        return set_.indices[item_] > 0;
    }

    function indexOf(AddressSet storage set_, address item_) internal view returns (uint) {
        return set_.indices[item_] - 1;
    }

    struct CircularSet {
        uint[] items;
        mapping(uint => uint) indices;
        uint iter;
    }

    function add(CircularSet storage set_, uint item_) internal {
        if (set_.contains(item_)) revert KeyExists();
        set_.items.push(item_);
        set_.indices[item_] = set_.items.length;
    }

    function add(CircularSet storage set_, address item_) internal {
        add(set_, uint(uint160(item_)));
    }

    function replace(CircularSet storage set_, uint oldItem_, uint newItem_) internal {
        if (set_.indices[oldItem_] == 0) {
            revert KeyError();
        }
        set_.items[set_.indices[oldItem_] - 1] = newItem_;
        set_.indices[newItem_] = set_.indices[oldItem_];
        set_.indices[oldItem_] = 0;
    }

    function replace(CircularSet storage set_, address oldItem_, address newItem_) internal {
        set_.replace(uint(uint160(oldItem_)), uint(uint160(newItem_)));
    }

    function pop(CircularSet storage set_) internal returns (uint) {
        uint last = set_.items[set_.length() - 1];
        delete set_.indices[last];
        return last;
    }

    function get(CircularSet storage set_, uint index_) internal view returns (uint) {
        return set_.items[index_];
    }

    function getAsAddress(CircularSet storage set_, uint index_) internal view returns (address) {
        return address(uint160(get(set_, index_)));
    }

    function next(CircularSet storage set_) internal returns (uint) {
        uint item =  set_.items[set_.iter++];
        if (set_.iter >= set_.length()) {
            set_.iter = 0;
        }
        return item;
    }

    function current(CircularSet storage set_) internal view returns (uint) {
        return set_.items[set_.iter];
    }

    function currentAsAddress(CircularSet storage set_) internal view returns (address) {
        return address(uint160(set_.items[set_.iter]));
    }

    function nextAsAddress(CircularSet storage set_) internal returns (address) {
        return address(uint160(next(set_)));
    }

    function length(CircularSet storage set_) internal view returns (uint) {
        return set_.items.length;
    }

    function remove(CircularSet storage set_, uint item_) internal  {
        if (set_.indices[item_] == 0) {
            revert KeyError();
        }
        uint index = set_.indices[item_];
        if (index != set_.length()) {
            set_.items[index - 1] = set_.items[set_.length() - 1];
            set_.indices[set_.items[index - 1]] = index;
        }
        set_.items.pop();
        set_.indices[item_] = 0;
        if (set_.iter == index) {
            set_.iter = set_.length();
        }
    }

    function remove(CircularSet storage set_, address item_) internal  {
        remove(set_, uint(uint160(item_)));
    }

    function clear(CircularSet storage set_) internal {
        for (uint i=0; i < set_.length(); i++) {
            uint key = set_.items[i];
            set_.indices[key] = 0;
        }
        delete set_.items;
        set_.iter = 0;
    }

    function itemsAsAddresses(CircularSet storage set_) internal view returns (address[] memory) {
        address[] memory items = new address[](set_.length());
        for (uint i = 0; i < set_.length(); i++) {
            items[i] = address(uint160(set_.items[i]));
        }
        return items;
    }

    function contains(CircularSet storage set_, uint item_) internal view returns (bool) {
        return set_.indices[item_] > 0;
    }

    function contains(CircularSet storage set_, address item_) internal view returns (bool) {
        return set_.contains(uint(uint160(item_)));
    }

    function indexOf(CircularSet storage set_, address item_) internal view returns (uint) {
        return set_.indices[uint(uint160(item_))] - 1;
    }

    struct DictItem {
        bytes32 key;
        uint value;
    }

    struct Dict {
        DictItem[] items;
        mapping(bytes32 => uint) indices;
    }

    function set(DictItem storage keyValue, bytes32 key, uint value) internal {
        (keyValue.key, keyValue.value) = (key, value);
    }

    function set(DictItem storage keyValue, uint value) internal {
        keyValue.value = value;
    }

    function _set(Dict storage dct, bytes32 key, uint value) private returns (uint index) {
        dct.items.push();
        index = dct.indices[key] = dct.items.length;
        dct.items[index-1].set(key, value);
    }

    function _update(Dict storage dct, bytes32 key, uint value) private returns (uint index) {
        index = dct.indices[key] - 1;
        dct.items[index].value = value;
    }

    function set(Dict storage dct, bytes32 key, uint value) internal returns (uint) {
        if (!dct.hasKey(key)) {
            return _set(dct, key, value);
        } else {
            return _update(dct, key, value);
        }
    }

    function values(Dict storage dct) internal view returns (uint[] memory) {
        uint size = dct.length();
        uint[] memory dctValues = new uint[](size);
        for (uint i = 0; i < size; i++) {
            dctValues[i] = dct.items[i].value;
        }
        return dctValues;
    }

    function keys(Dict storage dct) internal view returns (bytes32[] memory) {
        uint size = dct.length();
        bytes32[] memory dctKeys = new bytes32[](size);
        for (uint i = 0; i < size; i++) {
            dctKeys[i] = dct.items[i].key;
        }
        return dctKeys;
    }

    function length(Dict storage dct) internal view returns (uint){
        return dct.items.length;
    }

    function set(Dict storage dct, address key, uint value) internal {
        dct.set(bytes32(uint256(uint160(key))), value);
    }

    function set(Dict storage dct, uint key, uint value) internal {
        dct.set(bytes32(key), value);
    }

    function set(Dict storage dct, bytes32 key, address value) internal {
        dct.set(key, uint256(uint160(value)));
    }

    function set(Dict storage dct, bytes32 key, bytes32 value) internal {
        dct.set(key, uint256(value));
    }

    function set(Dict storage dct, uint key, address value) internal {
        dct.set(bytes32(key), uint(uint160(value)));
    }

    function set(Dict storage dct, uint key, bytes32 value) internal {
        dct.set(bytes32(key), value);
    }

    function set(Dict storage dct, address key, bytes32 value) internal {
        dct.set(key, uint256(value));
    }

    function get(Dict storage dct, bytes32 key) internal view returns (uint) {
        return dct.items[dct.indices[key] - 1].value;
    }

    function cross(Dict storage dct, bytes32 key, uint value) internal {
        uint index = dct.set(key, value);
        dct.set(value, key);
    }

    function get(Dict storage dct, bytes32 key, uint value) internal view returns (uint) {
        uint index = dct.indices[key];
        return index > 0 ? dct.items[index - 1].value : value;
    }

    function get(Dict storage dct, uint key) internal view returns (uint) {
        return dct.get(bytes32(key));
    }

    function get(Dict storage dct, address key) internal view returns (uint) {
        return dct.get(bytes32(uint256(uint160(key))));
    }

    function get(Dict storage dct, address key, uint value) internal view returns (uint) {
        return dct.get(bytes32(uint256(uint160(key))), value);
    }

    function update(Dict storage dct, DictItem calldata item) internal {
        dct.set(item.key, item.value);
    }

    function getAddress(Dict storage dct, bytes32 key) internal view returns (address) {
        return address(uint160(dct.getAddress(key)));
    }

    function getAddress(Dict storage dct, bytes32 key, address value) internal view returns (address) {
        uint index = dct.indices[key];
        return index > 0 ? address(uint160(dct.items[index - 1].value)) : value;
    }

    function getAddress(Dict storage dct, uint key) internal view returns (address) {
        return dct.getAddress(bytes32(key));
    }

    function getAddress(Dict storage dct, uint key, address value) internal view returns (address) {
        return dct.getAddress(bytes32(key), value);
    }

    function getAddress(Dict storage dct, address key) internal view returns (address) {
        return dct.getAddress(bytes32(uint256(uint160(key))));
    }

    function getAddress(Dict storage dct, address key, address value) internal view returns (address) {
        return dct.getAddress(bytes32(uint256(uint160(key))), value);
    }

    function getBytes32(Dict storage dct, bytes32 key) internal view returns (bytes32) {
        return bytes32(dct.get(key));
    }

    function getBytes32(Dict storage dct, bytes32 key, bytes32 value) internal view returns (bytes32) {
        uint index = dct.indices[key];
        return index > 0 ? bytes32(dct.items[index - 1].value) : value;
    }

    function getBytes32(Dict storage dct, uint key) internal view returns (bytes32) {
        return dct.getBytes32(bytes32(key));
    }

    function getBytes32(Dict storage dct, uint key, bytes32 value) internal view returns (bytes32) {
        return dct.getBytes32(bytes32(key), value);
    }

    function getBytes32(Dict storage dct, address key) internal view returns (bytes32) {
        return dct.getBytes32(bytes32(uint256(uint160(key))));
    }

    function getBytes32(Dict storage dct, address key, bytes32 value) internal view returns (bytes32) {
        return dct.getBytes32(bytes32(uint256(uint160(key))), value);
    }

    function hasKey(Dict storage dct, bytes32 key) internal view returns (bool) {
        return dct.indices[key] > 0;
    }

    function hasKey(Dict storage dct, uint key) internal view returns (bool) {
        return dct.hasKey(bytes32(key));
    }

    function hasKey(Dict storage dct, address key) internal view returns (bool) {
        return dct.hasKey(uint256(uint160(key)));
    }

    function update(Dict storage dct, DictItem[] memory pairs) internal {
        for (uint i = 0; i < pairs.length; i++) {
            dct.set(pairs[i].key, pairs[i].value);
        }
    }

    function del(Dict storage dct, bytes32 key) internal {
        uint index = dct.indices[key];
        require(index > 0, "dict: key error");

        dct.items[index - 1] = dct.items[dct.items.length - 1];
        dct.items.pop();
    }

    function del(Dict storage dct, uint key) internal {
        dct.del(bytes32(key));
    }

    function del(Dict storage dct, address key) internal {
        dct.del(bytes32(uint256(uint160(key))));
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract UsingERC1967UpgradeUpgradeable {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// @title UsingUUPS upgradeable proxy contract
/// @notice this is just a renamed from OpenZeppelin (UUPSUpgradeable)
abstract contract UsingUUPS is IERC1822ProxiableUpgradeable, UsingERC1967UpgradeUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// @title UsingFlagsWithStorage contract
/// @dev use this when creating a new contract
abstract contract UsingFlagsWithStorage is UsingFlags {
    using bits for uint256;

    /// @notice the mapping to store the flags
    mapping(address => uint256) internal _flags;

    function _getFlagStorage() internal view override returns (mapping(address => uint256) storage) {
        return _flags;
    }
}

error ExceededSellLimit();
error SwapUnderPriced();

interface ProcessDataInterface {
    struct ProcessData {
        uint128 fee;
        uint128 state;
    }
}

interface AdminInterface {
    function setFlags(address account_, uint256 set_, uint256 clear_) external;

    function getFlags(address account_) external view returns (uint256);
}

interface AffinityTokenInterface is AdminInterface {
    function burn(uint256 amount_) external;

    function pause() external;

    function unpause() external;

    function setProvider(address provider_) external;
}

interface AffinityProvider is ProcessDataInterface {
    function process(
        address from,
        address to,
        uint256 amount,
        ProcessData memory data
    ) external returns (ProcessData memory);
}

interface AffinityRewardsInterface is AdminInterface, AffinityProvider {
    function getDistributionRates()
        external
        view
        returns (uint256, uint256, uint256);

    function getMaxedSelectableRewards() external view returns (uint256);

    function setMaxedSelectableRewards(uint256 amount_) external;

    function addAccounts(address[] calldata accounts_) external;

    function removeAccounts(address[] calldata accounts_) external;

    function setRewardRouter(address rewardToken_, address router_) external;

    function setDistributions(
        uint80 distributionsPerBuy_,
        uint80 distributionsPerSell_,
        uint80 distributionsPerTransfer_
    ) external;

    function replaceReward(
        address oldRewardToken_,
        address newRewardToken_,
        uint256 ratio_,
        address router_
    ) external;

    function addReward(
        address rewardToken_,
        uint256[] calldata ratio_,
        address router_
    ) external;

    function claim(address account_) external;

    function selectRewards(address[] calldata rewards_) external;

    function selected(
        address account_
    ) external view returns (address[] memory);

    function selectable() external view returns (address[] memory);

    function distribute(uint256 count_) external;
}

interface AffinitySwapInterface is IUniswapV2Router02, AdminInterface {
    struct SellLimits {
        uint256 txSellLimitPerHolder;
        uint256 sellLimitPer24hrs;
    }

    function withdrawTokens(
        address token_,
        address to_,
        uint256 amount_
    ) external;

    function setSellLimitPerTx(uint256 txSellLimitPerHolder_) external;

    function set24hrSellLimitPerHolder(uint256 sellLimitPer24hrs_) external;

    function getSellLimits() external view returns (SellLimits memory);

    function withdraw(address to_) external;

    function setSwapFee(uint256 fee_) external;
}

interface AffinityStakingInterface {
    function autoStake(address, uint) external;
}

error Initialized();
error TokenRequired();

abstract contract DefaultFlags is UsingFlagsWithStorage {
    uint constant TRANSFERS_ENABLED = 1; // 0
    uint constant PERMITS_ENABLED = TRANSFERS_ENABLED << 1; // 1
    uint constant INITIALIZED = PERMITS_ENABLED << 1; // 2
    uint constant ADMIN = INITIALIZED << 1; // 3
    uint constant LIQUIDITY_PAIR = ADMIN << 1; // 5
    uint constant FEE_EXEMPT = LIQUIDITY_PAIR << 1; // 7
    uint constant BLOCKED = FEE_EXEMPT << 1; // 8
    uint constant REWARD_EXEMPT = BLOCKED << 1; // 9
    uint constant REWARD_SWAPPING_DISABLED = REWARD_EXEMPT << 1;
    uint constant REWARD_DISTRIBUTION_EXEMPT = REWARD_SWAPPING_DISABLED << 1;
    uint constant STAKING_POOL = REWARD_DISTRIBUTION_EXEMPT << 1;
    uint constant TOKEN = STAKING_POOL << 1;
    uint constant SELL_LIMIT_EXEMPT = TOKEN << 1;
    uint constant SELL_LIMIT_DISABLED = SELL_LIMIT_EXEMPT << 1;
    uint constant SELL_LIMIT_PER_24HRS_DISABLED = SELL_LIMIT_DISABLED << 1;

    uint constant THIS_OFFSET = 95;
    uint constant SENDER_OFFSET = THIS_OFFSET - 32;
    uint constant SOURCE_OFFSET = SENDER_OFFSET - 32;
    uint constant TARGET_OFFSET = SOURCE_OFFSET - 32;

    uint constant THIS_TRANSFERS_ENABLED = TRANSFERS_ENABLED << THIS_OFFSET;
    uint constant THIS_PERMITS_ENABLED = PERMITS_ENABLED << THIS_OFFSET;
    uint constant THIS_INITIALIZED = INITIALIZED << THIS_OFFSET;
    uint constant THIS_REWARD_SWAPPING_DISABLED =
        REWARD_SWAPPING_DISABLED << THIS_OFFSET;
    uint constant THIS_SELL_LIMIT_DISABLED = SELL_LIMIT_DISABLED << THIS_OFFSET;
    uint constant THIS_SELL_LIMIT_PER_24HRS_DISABLED =
        SELL_LIMIT_PER_24HRS_DISABLED << THIS_OFFSET;
    uint constant SENDER_IS_ADMIN = ADMIN << SENDER_OFFSET;

    uint constant SOURCE_IS_LIQUIDITY_PAIR = LIQUIDITY_PAIR << SOURCE_OFFSET;
    uint constant SOURCE_IS_FEE_EXEMPT = FEE_EXEMPT << SOURCE_OFFSET;
    uint constant SOURCE_IS_BLOCKED = BLOCKED << SOURCE_OFFSET;
    uint constant SOURCE_TRANSFERS_ENABLED = TRANSFERS_ENABLED << SOURCE_OFFSET;
    uint constant SOURCE_IS_REWARD_EXEMPT = REWARD_EXEMPT << SOURCE_OFFSET;
    uint constant SOURCE_IS_REWARD_DISTRIBUTION_EXEMPT =
        REWARD_DISTRIBUTION_EXEMPT << SOURCE_OFFSET;
    uint constant SOURCE_IS_STAKING_POOL = STAKING_POOL << SOURCE_OFFSET;
    uint constant SOURCE_IS_SELL_LIMIT_EXEMPT =
        SELL_LIMIT_EXEMPT << SOURCE_OFFSET;

    uint constant TARGET_IS_LIQUIDITY_PAIR = LIQUIDITY_PAIR << TARGET_OFFSET;
    uint constant TARGET_IS_FEE_EXEMPT = FEE_EXEMPT << TARGET_OFFSET;
    uint constant TARGET_IS_BLOCKED = BLOCKED << TARGET_OFFSET;
    uint constant TARGET_IS_REWARD_EXEMPT = REWARD_EXEMPT << TARGET_OFFSET;
    uint constant TARGET_IS_REWARD_DISTRIBUTION_EXEMPT =
        REWARD_DISTRIBUTION_EXEMPT << TARGET_OFFSET;
    uint constant TARGET_IS_STAKING_POOL = STAKING_POOL << TARGET_OFFSET;

    uint constant PRECISION = 10 ** 5;

    modifier requiresAdmin() {
        if (!_checkFlags(msg.sender, ADMIN, 0)) revert AdminRequired();
        _;
    }

    modifier initializer() {
        if (_checkFlags(address(this), INITIALIZED, 0)) revert Initialized();
        _setFlags(address(this), INITIALIZED, 0);
        _;
    }

    modifier requiresToken() {
        require(
            _checkFlags(msg.sender, TOKEN, 0),
            "only token can call this function"
        );
        _;
    }

    function _getTransferState(
        address sender_,
        address source_,
        address target_
    ) internal view returns (uint128) {
        return
            uint128(
                (_getFlags(address(this)) << THIS_OFFSET) |
                    (_getFlags(sender_) << SENDER_OFFSET) |
                    (_getFlags(source_) << SOURCE_OFFSET) |
                    (_getFlags(target_) << TARGET_OFFSET)
            );
    }

    /// @notice set and clear any arbitrary flag
    /// @dev only use this if you know what you are doing
    function setFlags(
        address account_,
        uint256 set_,
        uint256 clear_
    ) external requiresAdmin {
        _setFlags(account_, set_, clear_);
    }
}

contract AffinityProviderFailsafe is DefaultFlags, ProcessDataInterface {
    AffinityProvider _currentProvider;
    AffinityProvider _newProvider;

    constructor(address token, address newProvider, address currentProvider) {
        _setFlags(address(this), ADMIN, 0);
        _setFlags(token, TOKEN, 0);
        _currentProvider = AffinityProvider(currentProvider);
        _newProvider = AffinityProvider(newProvider);
    }

    function setNewProvider(address newProvider) external requiresAdmin {
        _setFlags(newProvider, TOKEN, 0);
    }

    function process(
        address from_,
        address to_,
        uint256 amount_,
        ProcessData memory data_
    ) external requiresToken returns (ProcessData memory) {
        try _newProvider.process(from_, to_, amount_, data_) returns (
            ProcessData memory data
        ) {
            return data;
        } catch {
            return _currentProvider.process(from_, to_, amount_, data_);
        }
    }
}

contract AffinityExternalService is
    DefaultFlags,
    UsingUUPS,
    ProcessDataInterface
{
    using collections for collections.AddressSet;
    using bits for uint256;
    using bits for uint128;
    bytes32 constant BUY_KEY = keccak256("buy");
    bytes32 constant SELL_KEY = keccak256("sell");
    bytes32 constant TRANSFER_KEY = keccak256("transfer");

    struct SellTxData {
        uint128 total;
        uint128 timestamp;
    }

    struct Allocations {
        uint48 staking;
        uint48 rewards;
        uint48 liquidity;
        uint48 operations;
    }

    struct FeeAndAllocations {
        uint48 value;
        Allocations allocations;
    }

    uint256 _perTxSellLimit; // 20M Token TX Limit
    uint256 _24HourSellLimit; // 50M Token Total Sell Limit per 24 Hours
    AffinitySwapInterface _swap;
    AffinityRewardsInterface _rewards;
    IUniswapV2Router02 _router;
    IERC20 _token;
    bool _initialized;
    uint256 constant SECONDS_PER_24HRS = 28800;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address[] _path;
    FeeAndAllocations _buyFee;
    FeeAndAllocations _sellFee;
    FeeAndAllocations _transferFee;
    address _feeReceiver;
    AffinityStakingInterface _staking;
    mapping(uint256 => collections.AddressSet) _flaggedAccounts;
    mapping(address => SellTxData) _sellTxData;

    struct Balances {
        uint256 staking;
        uint256 operations;
        uint256 rewards;
        uint256 liquidity;
        uint256 total;
    }

    Balances _balances;

    function initialize(
        address token_,
        address router_,
        address feeReceiver_,
        address rewards_,
        address staking_,
        address swap_
    ) external initializer {
        _setFlags(msg.sender, ADMIN, 0);
        _token = IERC20(token_);
        _router = IUniswapV2Router02(router_);
        _feeReceiver = feeReceiver_;
        _rewards = AffinityRewardsInterface(rewards_);
        _staking = AffinityStakingInterface(staking_);
        _path = new address[](2);
        _path[0] = WBNB;
        _path[1] = token_;
        _swap = AffinitySwapInterface(swap_);
    }

    function pauseTransfers() external requiresAdmin {
        _setFlags(address(this), TRANSFERS_ENABLED, 0);
    }

    function unpauseTransfers() external requiresAdmin {
        _setFlags(address(this), 0, TRANSFERS_ENABLED);
    }

    function exemptAccountFromFees(address account_) external requiresAdmin {
        _setFlags(account_, FEE_EXEMPT, 0);
        _flaggedAccounts[FEE_EXEMPT].add(account_);
    }

    function exemptAccountFromDistributing(
        address account_
    ) external requiresAdmin {
        _setFlags(account_, REWARD_DISTRIBUTION_EXEMPT, 0);
        _flaggedAccounts[REWARD_DISTRIBUTION_EXEMPT].add(account_);
    }

    function blockAccount(address account_) external requiresAdmin {
        _setFlags(account_, BLOCKED, 0);
        _flaggedAccounts[BLOCKED].add(account_);
    }

    function unblockAccount(address account_) external requiresAdmin {
        _setFlags(account_, 0, BLOCKED);
        _flaggedAccounts[BLOCKED].remove(account_);
    }

    function isBlocked(address account_) public view returns (bool) {
        return _getFlags(account_).any(BLOCKED);
    }

    function exemptAccountFromRewards(address account_) external requiresAdmin {
        _rewards.setFlags(account_, REWARD_EXEMPT, 0);
        _flaggedAccounts[REWARD_EXEMPT].add(account_);
    }

    function unexemptAccountFromRewards(
        address account_
    ) external requiresAdmin {
        _rewards.setFlags(account_, 0, REWARD_EXEMPT);
        _flaggedAccounts[REWARD_EXEMPT].remove(account_);
    }

    function isExemptedFromRewards(
        address account_
    ) public view returns (bool) {
        return _rewards.getFlags(account_).any(REWARD_EXEMPT);
    }

    function setFeesAndAllocations(
        string calldata feeType_,
        FeeAndAllocations memory feeAndAllocation_
    ) external requiresAdmin {
        if (keccak256(bytes(feeType_)) == BUY_KEY) {
            _buyFee = feeAndAllocation_;
        } else if (keccak256(bytes(feeType_)) == "sell") {
            _sellFee = feeAndAllocation_;
        } else if (keccak256(bytes(feeType_)) == "transfer") {
            _transferFee = feeAndAllocation_;
        }
    }

    function getFeesAndAllocation(
        string calldata feeType_
    ) external view returns (FeeAndAllocations memory) {
        if (keccak256(bytes(feeType_)) == "buy") {
            return _buyFee;
        } else if (keccak256(bytes(feeType_)) == "sell") {
            return _sellFee;
        } else if (keccak256(bytes(feeType_)) == "transfer") {
            return _transferFee;
        }
        revert("Invalid fee type");
    }

    function setSwapFee(uint32 fee_) external requiresAdmin {
        _swap.setSwapFee(fee_);
    }

    function setPerTxSellLimit(uint256 perTxSellLimit_) external requiresAdmin {
        _perTxSellLimit = perTxSellLimit_;
    }

    function getSellLimitPerTx() external view returns (uint256) {
        return _perTxSellLimit;
    }

    function set24HourSellLimit(
        uint256 sellLimitPer24hrs_
    ) external requiresAdmin {
        _24HourSellLimit = sellLimitPer24hrs_;
    }

    function get24HourSellLimit() external view returns (uint256) {
        return _24HourSellLimit;
    }

    function getFlaggedAccounts(
        uint256 flag_
    ) external view returns (address[] memory) {
        return _flaggedAccounts[flag_].items;
    }

    function process(
        address from_,
        address to_,
        uint256 amount_,
        ProcessData memory data_
    ) external requiresToken returns (ProcessData memory) {
        data_.state = _getTransferState(msg.sender, from_, to_);
        require(data_.state.all(TRANSFERS_ENABLED), "Transfers are paused");
        require(
            data_.state.any(SOURCE_IS_BLOCKED | TARGET_IS_BLOCKED) == false,
            "Account is blocked"
        );
        if (data_.state.any(SOURCE_IS_STAKING_POOL)) {
            return _process(from_, to_, amount_, data_);
        } else if (data_.state.any(TARGET_IS_STAKING_POOL)) {
            _staking.autoStake(from_, amount_);
            return _process(from_, to_, amount_, data_);
        } else if (
            !data_.state.check(SOURCE_IS_FEE_EXEMPT | TARGET_IS_FEE_EXEMPT, 0)
        ) {
            FeeAndAllocations storage feeAndAllocations = _getFeeAndAllocations(
                data_.state
            );
            data_.fee = feeAndAllocations.value;
            uint fee = _calculateFee(amount_, feeAndAllocations);
            if (fee > 0) {
                _depositTokens(fee, feeAndAllocations);
            }
        }
        _rewards.process(from_, to_, amount_, data_);
        return data_;
    }

    function _process(
        address from_,
        address to_,
        uint256 amount_,
        ProcessData memory data_
    ) internal virtual returns (ProcessData memory) {
        if (data_.state.all(TARGET_IS_LIQUIDITY_PAIR)) {
            if (!data_.state.all(SOURCE_IS_SELL_LIMIT_EXEMPT)) {
                if (
                    !data_.state.all(THIS_SELL_LIMIT_DISABLED) &&
                    amount_ > _perTxSellLimit
                ) {
                    revert ExceededSellLimit();
                }
                if (!data_.state.all(THIS_SELL_LIMIT_PER_24HRS_DISABLED)) {
                    SellTxData storage txData = _sellTxData[from_];
                    uint128 current = _timestamp();
                    if (
                        txData.timestamp == 0 ||
                        (current - txData.timestamp) > SECONDS_PER_24HRS
                    ) {
                        _sellTxData[from_] = SellTxData(
                            uint128(amount_),
                            current
                        );
                    } else if (txData.total + amount_ > _24HourSellLimit) {
                        revert ExceededSellLimit();
                    } else {
                        txData.total += uint128(amount_);
                    }
                }
            }
            uint tokenBalance = _balances.liquidity +
                _balances.rewards +
                _balances.operations;
            IERC20(_token).approve(address(_router), tokenBalance + 1);
            uint256 balance = address(this).balance;
            if (_balances.liquidity > 0 && balance > 0) {
                _router.addLiquidityETH{value: balance}(
                    address(_token),
                    _balances.liquidity,
                    0,
                    0,
                    address(this),
                    block.timestamp + 1
                );
                _balances.liquidity = 0;
            } else {
                try
                    _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                        tokenBalance,
                        0,
                        _path,
                        address(this),
                        block.timestamp + 1
                    )
                {
                    _distributeFunds(
                        tokenBalance,
                        address(this).balance - balance
                    );
                } catch {}
            }
        }
        return data_;
    }

    function _timestamp() internal view returns (uint128) {
        return uint128(block.timestamp);
    }

    function _calculatePercentage(
        uint256 amount_,
        uint48 allocation_
    ) internal pure returns (uint256) {
        return (amount_ * allocation_) / PRECISION;
    }

    function _calculateFee(
        uint256 amount_,
        FeeAndAllocations storage feeAndAllocations_
    ) internal view returns (uint256) {
        return _calculatePercentage(amount_, feeAndAllocations_.value);
    }

    function _getFeeAndAllocations(
        uint128 state_
    ) internal view returns (FeeAndAllocations storage) {
        if (state_.all(SOURCE_IS_LIQUIDITY_PAIR)) {
            return _buyFee;
        } else if (state_.all(TARGET_IS_LIQUIDITY_PAIR)) {
            return _sellFee;
        }
        return _transferFee;
    }

    function _calculateAllocation(
        uint256 balance_,
        uint256 total_
    ) internal pure returns (uint256) {
        return (balance_ * PRECISION) / total_;
    }

    function _send(address account_, uint256 amount_) internal {
        require(account_ != address(0), "send to zero address");
        (bool success, ) = payable(account_).call{value: amount_}("");
        require(success, "send failed");
    }

    function _distributeAllocation(
        address account_,
        uint256 balance_,
        uint256 value_,
        uint256 total_
    ) internal returns (uint256) {
        if (balance_ > 0) {
            value_ =
                (value_ * _calculateAllocation(balance_, total_)) /
                PRECISION;
            _send(account_, value_);
            return value_;
        }
        return 0;
    }

    function _distributeFunds(uint total_, uint256 value_) internal {
        uint256 distributed;
        _token.transfer(address(_staking), _balances.staking);
        distributed += _distributeAllocation(
            address(_rewards),
            _balances.rewards,
            value_,
            total_
        );
        distributed += _distributeAllocation(
            _feeReceiver,
            _balances.operations,
            value_,
            total_
        );
    }

    function _depositTokens(
        uint256 amount_,
        FeeAndAllocations storage fee_
    ) internal {
        uint256 remaining = amount_;
        uint256 fee;
        if (fee_.allocations.staking > 0) {
            fee = _calculatePercentage(amount_, fee_.allocations.staking);
            _balances.staking += fee;
            remaining -= fee;
        }
        if (fee_.allocations.rewards > 0) {
            fee = _calculatePercentage(amount_, fee_.allocations.rewards);
            _balances.rewards += fee;
            remaining -= fee;
        }
        if (fee_.allocations.liquidity > 0) {
            fee = _calculatePercentage(amount_, fee_.allocations.liquidity);
            _balances.liquidity += fee;
            remaining -= fee;
        }
        if (fee_.allocations.operations > 0) {
            _balances.operations += remaining;
        }
        _balances.total += amount_;
    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal override requiresAdmin {}
}