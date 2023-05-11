/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
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
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
       
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
library EnumerableSet {

    struct Set {
        
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastvalue;
                set._indexes[lastvalue] = valueIndex; 
            }
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
        return set._values[index];
    }
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    constructor() {
        _paused = false;
    }
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
interface IWhiteLock {
    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external returns (uint256 lockId);

    function vestingLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external returns (uint256 lockId);

    function multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        bool isLpToken,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external returns (uint256[] memory);

    function unlock(uint256 lockId) external;

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external;
}
interface IUniswapV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}
interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(
    address indexed sender,
    uint256 amount0,
    uint256 amount1,
    address indexed to
  );
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}
interface IUniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint256
  );

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}
library FullMath {
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }
    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }
    require(denominator > prod1);
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }
    unchecked {
      uint256 twos = (type(uint256).max - denominator + 1) & denominator;
      assembly {
        denominator := div(denominator, twos)
      }
      assembly {
        prod0 := div(prod0, twos)
      }
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;
      uint256 inv = (3 * denominator) ^ 2;
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256
      result = prod0 * inv;
      return result;
    }
  }
}
contract WhiteLock is IWhiteLock, Pausable {
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeERC20 for IERC20;

    struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 lockDate;
        uint256 tgeDate;
        uint256 tgeBps;
        uint256 cycle;
        uint256 cycleBps;
        uint256 unlockedAmount;
        string description;
    }

    struct CumulativeLockInfo {
        address token;
        address factory;
        uint256 amount;
    }
    uint256 private constant ID_PADDING = 1_000_000;

    Lock[] private _locks;
    mapping(address => EnumerableSet.UintSet) private _userLpLockIds;
    mapping(address => EnumerableSet.UintSet) private _userNormalLockIds;

    EnumerableSet.AddressSet private _lpLockedTokens;
    EnumerableSet.AddressSet private _normalLockedTokens;
    mapping(address => CumulativeLockInfo) public cumulativeLockInfo;
    mapping(address => EnumerableSet.UintSet) private _tokenToLockIds;

    event LockAdded(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 unlockDate
    );
    event LockUpdated(
        uint256 indexed id,
        address token,
        address owner,
        uint256 newAmount,
        uint256 newUnlockDate
    );
    event LockRemoved(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 unlockedAt
    );
    event LockVested(
        uint256 indexed id,
        address token,
        address owner,
        uint256 amount,
        uint256 total,
        uint256 timestamp
    );
    event LockDescriptionChanged(uint256 lockId);
    event LockOwnerChanged(uint256 lockId, address owner, address newOwner);

    modifier validLock(uint256 lockId) {
        _getActualIndex(lockId);
        _;
    }

    function lock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 unlockDate,
        string memory description
    ) external override returns (uint256 id) {
        require(
            unlockDate > block.timestamp,
            "Unlock date should be in the future"
        );
        require(amount > 0, "Amount should be greater than 0");
        id = _createLock(
            owner,
            token,
            isLpToken,
            amount,
            unlockDate,
            0,
            0,
            0,
            description
        );
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            amount
        );
        emit LockAdded(id, token, owner, amount, unlockDate);
        return id;
    }

    function vestingLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external override returns (uint256 id) {
        require(tgeDate > block.timestamp, "TGE date should be in the future");
        require(cycle > 0, "Invalid cycle");
        require(tgeBps > 0 && tgeBps < 10_000, "Invalid bips for TGE");
        require(cycleBps > 0 && cycleBps < 10_000, "Invalid bips for cycle");
        require(
            tgeBps + cycleBps <= 10_000,
            "Sum of TGE bps and cycle should be less than 10000"
        );
        require(amount > 0, "Amount should be greater than 0");
        id = _createLock(
            owner,
            token,
            isLpToken,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            amount
        );
        emit LockAdded(id, token, owner, amount, tgeDate);
        return id;
    }

    function multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        bool isLpToken,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) external override returns (uint256[] memory) {
        require(owners.length == amounts.length, "Length mismatched");
        require(tgeDate > block.timestamp, "TGE date should be in the future");
        require(cycle > 0, "Invalid cycle");
        require(tgeBps > 0 && tgeBps < 10_000, "Invalid bips for TGE");
        require(cycleBps > 0 && cycleBps < 10_000, "Invalid bips for cycle");
        require(
            tgeBps + cycleBps <= 10_000,
            "Sum of TGE bps and cycle should be less than 10000"
        );
        return
            _multipleVestingLock(
                owners,
                amounts,
                token,
                isLpToken,
                [tgeDate, tgeBps, cycle, cycleBps],
                description
            );
    }
    function _multipleVestingLock(
        address[] calldata owners,
        uint256[] calldata amounts,
        address token,
        bool isLpToken,
        uint256[4] memory vestingSettings,
        string memory description
    ) internal returns (uint256[] memory) {
        uint256 sumAmount = _sumAmount(amounts);
        uint256 count = owners.length;
        uint256[] memory ids = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            ids[i] = _createLock(
                owners[i],
                token,
                isLpToken,
                amounts[i],
                vestingSettings[0],
                vestingSettings[1],
                vestingSettings[2],
                vestingSettings[3],
                description
            );
            emit LockAdded(
                ids[i],
                token,
                owners[i],
                amounts[i],
                vestingSettings[0]
            );
        }
        _safeTransferFromEnsureExactAmount(
            token,
            msg.sender,
            address(this),
            sumAmount
        );
        return ids;
    }

    function _sumAmount(uint256[] calldata amounts)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] == 0) {
                revert("Amount cant be zero");
            }
            sum += amounts[i];
        }
        return sum;
    }
    function _createLock(
        address owner,
        address token,
        bool isLpToken,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) internal returns (uint256 id) {
        if (isLpToken) {
            address possibleFactoryAddress = _parseFactoryAddress(token);
            id = _lockLpToken(
                owner,
                token,
                possibleFactoryAddress,
                amount,
                tgeDate,
                tgeBps,
                cycle,
                cycleBps,
                description
            );
        } else {
            id = _lockNormalToken(
                owner,
                token,
                amount,
                tgeDate,
                tgeBps,
                cycle,
                cycleBps,
                description
            );
        }
        return id;
    }
    function _lockLpToken(
        address owner,
        address token,
        address factory,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _registerLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _userLpLockIds[owner].add(id);
        _lpLockedTokens.add(token);

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[token];
        if (tokenInfo.token == address(0)) {
            tokenInfo.token = token;
            tokenInfo.factory = factory;
        }
        tokenInfo.amount = tokenInfo.amount + amount;

        _tokenToLockIds[token].add(id);
    }

    function _lockNormalToken(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private returns (uint256 id) {
        id = _registerLock(
            owner,
            token,
            amount,
            tgeDate,
            tgeBps,
            cycle,
            cycleBps,
            description
        );
        _userNormalLockIds[owner].add(id);
        _normalLockedTokens.add(token);

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[token];
        if (tokenInfo.token == address(0)) {
            tokenInfo.token = token;
            tokenInfo.factory = address(0);
        }
        tokenInfo.amount = tokenInfo.amount + amount;

        _tokenToLockIds[token].add(id);
    }

    function _registerLock(
        address owner,
        address token,
        uint256 amount,
        uint256 tgeDate,
        uint256 tgeBps,
        uint256 cycle,
        uint256 cycleBps,
        string memory description
    ) private whenNotPaused returns (uint256 id) {
        id = _locks.length + ID_PADDING;
        Lock memory newLock = Lock({
            id: id,
            token: token,
            owner: owner,
            amount: amount,
            lockDate: block.timestamp,
            tgeDate: tgeDate,
            tgeBps: tgeBps,
            cycle: cycle,
            cycleBps: cycleBps,
            unlockedAmount: 0,
            description: description
        });
        _locks.push(newLock);
    }
    function unlock(uint256 lockId) external override validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not Authorized for this lock"
        );
        if (userLock.tgeBps > 0) {
            _vestingUnlock(userLock);
        } else {
            _normalUnlock(userLock);
        }
    }
    function _normalUnlock(Lock storage userLock) internal {
        require(
            block.timestamp >= userLock.tgeDate,
            "It is not time to unlock"
        );
        require(userLock.unlockedAmount == 0, "Nothing to unlock");

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];

        bool isLpToken = tokenInfo.factory != address(0);

        if (isLpToken) {
            _userLpLockIds[msg.sender].remove(userLock.id);
        } else {
            _userNormalLockIds[msg.sender].remove(userLock.id);
        }

        uint256 unlockAmount = userLock.amount;

        if (tokenInfo.amount <= unlockAmount) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount - unlockAmount;
        }

        if (tokenInfo.amount == 0) {
            if (isLpToken) {
                _lpLockedTokens.remove(userLock.token);
            } else {
                _normalLockedTokens.remove(userLock.token);
            }
        }
        userLock.unlockedAmount = unlockAmount;

        _tokenToLockIds[userLock.token].remove(userLock.id);

        IERC20(userLock.token).safeTransfer(msg.sender, unlockAmount);

        emit LockRemoved(
            userLock.id,
            userLock.token,
            msg.sender,
            unlockAmount,
            block.timestamp
        );
    }

    function _vestingUnlock(Lock storage userLock) internal {
        uint256 withdrawable = _withdrawableTokens(userLock);
        uint256 newTotalUnlockAmount = userLock.unlockedAmount + withdrawable;
        require(
            withdrawable > 0 && newTotalUnlockAmount <= userLock.amount,
            "Nothing to unlock"
        );

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];
        bool isLpToken = tokenInfo.factory != address(0);

        if (newTotalUnlockAmount == userLock.amount) {
            if (isLpToken) {
                _userLpLockIds[msg.sender].remove(userLock.id);
            } else {
                _userNormalLockIds[msg.sender].remove(userLock.id);
            }
            _tokenToLockIds[userLock.token].remove(userLock.id);
            emit LockRemoved(
                userLock.id,
                userLock.token,
                msg.sender,
                newTotalUnlockAmount,
                block.timestamp
            );
        }

        if (tokenInfo.amount <= withdrawable) {
            tokenInfo.amount = 0;
        } else {
            tokenInfo.amount = tokenInfo.amount - withdrawable;
        }

        if (tokenInfo.amount == 0) {
            if (isLpToken) {
                _lpLockedTokens.remove(userLock.token);
            } else {
                _normalLockedTokens.remove(userLock.token);
            }
        }
        userLock.unlockedAmount = newTotalUnlockAmount;

        IERC20(userLock.token).safeTransfer(userLock.owner, withdrawable);

        emit LockVested(
            userLock.id,
            userLock.token,
            msg.sender,
            withdrawable,
            userLock.amount,
            block.timestamp
        );
    }

    function withdrawableTokens(uint256 lockId)
        external
        view
        returns (uint256)
    {
        Lock memory userLock = getLockById(lockId);
        return _withdrawableTokens(userLock);
    }

    function _withdrawableTokens(Lock memory userLock)
        internal
        view
        returns (uint256)
    {
        if (userLock.amount == 0) return 0;
        if (userLock.unlockedAmount >= userLock.amount) return 0;
        if (block.timestamp < userLock.tgeDate) return 0;
        if (userLock.cycle == 0) return 0;

        uint256 tgeReleaseAmount = (userLock.amount * userLock.tgeBps) / 10_000;
        uint256 cycleReleaseAmount = FullMath.mulDiv(
            userLock.amount,
            userLock.cycleBps,
            10_000
        );
        uint256 currentTotal = 0;
        if (block.timestamp >= userLock.tgeDate) {
            currentTotal =
                (((block.timestamp - userLock.tgeDate) / userLock.cycle) *
                    cycleReleaseAmount) +
                tgeReleaseAmount;
        }
        uint256 withdrawable = 0;
        if (currentTotal > userLock.amount) {
            withdrawable = userLock.amount - userLock.unlockedAmount;
        } else {
            withdrawable = currentTotal - userLock.unlockedAmount;
        }
        return withdrawable;
    }

    function editLock(
        uint256 lockId,
        uint256 newAmount,
        uint256 newUnlockDate
    ) external override validLock(lockId) {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not Authorized for this lock"
        );
        require(userLock.unlockedAmount == 0, "Lock was unlocked");

        if (newUnlockDate > 0) {
            require(
                newUnlockDate >= userLock.tgeDate &&
                    newUnlockDate > block.timestamp,
                "New unlock time should not be before old unlock time or current time"
            );
            userLock.tgeDate = newUnlockDate;
        }

        if (newAmount > 0) {
            require(
                newAmount >= userLock.amount,
                "New amount should not be less than current amount"
            );

            uint256 diff = newAmount - userLock.amount;

            if (diff > 0) {
                userLock.amount = newAmount;
                CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
                    userLock.token
                ];
                tokenInfo.amount = tokenInfo.amount + diff;
                _safeTransferFromEnsureExactAmount(
                    userLock.token,
                    msg.sender,
                    address(this),
                    diff
                );
            }
        }

        emit LockUpdated(
            userLock.id,
            userLock.token,
            userLock.owner,
            userLock.amount,
            userLock.tgeDate
        );
    }

    function editLockDescription(uint256 lockId, string memory description)
        external
        validLock(lockId)
    {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        require(
            userLock.owner == msg.sender,
            "You are not Authorized for this lock"
        );
        userLock.description = description;
        emit LockDescriptionChanged(lockId);
    }

    function transferLockOwnership(uint256 lockId, address newOwner)
        public
        validLock(lockId)
    {
        Lock storage userLock = _locks[_getActualIndex(lockId)];
        address currentOwner = userLock.owner;
        require(
            currentOwner == msg.sender,
            "You are not Authorized for this lock"
        );

        userLock.owner = newOwner;

        CumulativeLockInfo storage tokenInfo = cumulativeLockInfo[
            userLock.token
        ];

        bool isLpToken = tokenInfo.factory != address(0);

        if (isLpToken) {
            _userLpLockIds[currentOwner].remove(lockId);
            _userLpLockIds[newOwner].add(lockId);
        } else {
            _userNormalLockIds[currentOwner].remove(lockId);
            _userNormalLockIds[newOwner].add(lockId);
        }

        emit LockOwnerChanged(lockId, currentOwner, newOwner);
    }

    function renounceLockOwnership(uint256 lockId) external {
        transferLockOwnership(lockId, address(0));
    }

    function _safeTransferFromEnsureExactAmount(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        uint256 oldRecipientBalance = IERC20(token).balanceOf(recipient);
        IERC20(token).safeTransferFrom(sender, recipient, amount);
        uint256 newRecipientBalance = IERC20(token).balanceOf(recipient);
        require(
            newRecipientBalance - oldRecipientBalance == amount,
            "Not enough token was transfered"
        );
    }

    function getTotalLockCount() external view returns (uint256) {
        // Returns total lock count, regardless of whether it has been unlocked or not
        return _locks.length;
    }

    function getLockAt(uint256 index) external view returns (Lock memory) {
        return _locks[index];
    }

    function getLockById(uint256 lockId) public view returns (Lock memory) {
        return _locks[_getActualIndex(lockId)];
    }

    function allLpTokenLockedCount() public view returns (uint256) {
        return _lpLockedTokens.length();
    }

    function allNormalTokenLockedCount() public view returns (uint256) {
        return _normalLockedTokens.length();
    }

    function getCumulativeLpTokenLockInfoAt(uint256 index)
        external
        view
        returns (CumulativeLockInfo memory)
    {
        return cumulativeLockInfo[_lpLockedTokens.at(index)];
    }

    function getCumulativeNormalTokenLockInfoAt(uint256 index)
        external
        view
        returns (CumulativeLockInfo memory)
    {
        return cumulativeLockInfo[_normalLockedTokens.at(index)];
    }

    function getCumulativeLpTokenLockInfo(uint256 start, uint256 end)
        external
        view
        returns (CumulativeLockInfo[] memory)
    {
        if (end >= _lpLockedTokens.length()) {
            end = _lpLockedTokens.length() - 1;
        }
        uint256 length = end - start + 1;
        CumulativeLockInfo[] memory lockInfo = new CumulativeLockInfo[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            lockInfo[currentIndex] = cumulativeLockInfo[_lpLockedTokens.at(i)];
            currentIndex++;
        }
        return lockInfo;
    }

    function getCumulativeNormalTokenLockInfo(uint256 start, uint256 end)
        external
        view
        returns (CumulativeLockInfo[] memory)
    {
        if (end >= _normalLockedTokens.length()) {
            end = _normalLockedTokens.length() - 1;
        }
        uint256 length = end - start + 1;
        CumulativeLockInfo[] memory lockInfo = new CumulativeLockInfo[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            lockInfo[currentIndex] = cumulativeLockInfo[
                _normalLockedTokens.at(i)
            ];
            currentIndex++;
        }
        return lockInfo;
    }

    function totalTokenLockedCount() external view returns (uint256) {
        return allLpTokenLockedCount() + allNormalTokenLockedCount();
    }

    function lpLockCountForUser(address user) public view returns (uint256) {
        return _userLpLockIds[user].length();
    }

    function lpLocksForUser(address user)
        external
        view
        returns (Lock[] memory)
    {
        uint256 length = _userLpLockIds[user].length();
        Lock[] memory userLocks = new Lock[](length);
        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userLpLockIds[user].at(i));
        }
        return userLocks;
    }

    function lpLockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (Lock memory)
    {
        require(lpLockCountForUser(user) > index, "Invalid index");
        return getLockById(_userLpLockIds[user].at(index));
    }

    function normalLockCountForUser(address user)
        public
        view
        returns (uint256)
    {
        return _userNormalLockIds[user].length();
    }

    function normalLocksForUser(address user)
        external
        view
        returns (Lock[] memory)
    {
        uint256 length = _userNormalLockIds[user].length();
        Lock[] memory userLocks = new Lock[](length);

        for (uint256 i = 0; i < length; i++) {
            userLocks[i] = getLockById(_userNormalLockIds[user].at(i));
        }
        return userLocks;
    }

    function normalLockForUserAtIndex(address user, uint256 index)
        external
        view
        returns (Lock memory)
    {
        require(normalLockCountForUser(user) > index, "Invalid index");
        return getLockById(_userNormalLockIds[user].at(index));
    }

    function totalLockCountForUser(address user)
        external
        view
        returns (uint256)
    {
        return normalLockCountForUser(user) + lpLockCountForUser(user);
    }

    function totalLockCountForToken(address token)
        external
        view
        returns (uint256)
    {
        return _tokenToLockIds[token].length();
    }

    function getLocksForToken(
        address token,
        uint256 start,
        uint256 end
    ) public view returns (Lock[] memory) {
        if (end >= _tokenToLockIds[token].length()) {
            end = _tokenToLockIds[token].length() - 1;
        }
        uint256 length = end - start + 1;
        Lock[] memory locks = new Lock[](length);
        uint256 currentIndex = 0;
        for (uint256 i = start; i <= end; i++) {
            locks[currentIndex] = getLockById(_tokenToLockIds[token].at(i));
            currentIndex++;
        }
        return locks;
    }

    function _getActualIndex(uint256 lockId) internal view returns (uint256) {
        if (lockId < ID_PADDING) {
            revert("Invalid lock id");
        }
        uint256 actualIndex = lockId - ID_PADDING;
        require(actualIndex < _locks.length, "Invalid lock id");
        return actualIndex;
    }

    function _parseFactoryAddress(address token)
        internal
        view
        returns (address)
    {
        address possibleFactoryAddress;
        try IUniswapV2Pair(token).factory() returns (address factory) {
            possibleFactoryAddress = factory;
        } catch {
            revert("This token is not a LP token");
        }
        require(
            possibleFactoryAddress != address(0) &&
                _isValidLpToken(token, possibleFactoryAddress),
            "This token is not a LP token."
        );
        return possibleFactoryAddress;
    }

    function _isValidLpToken(address token, address factory)
        private
        view
        returns (bool)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        address factoryPair = IUniswapV2Factory(factory).getPair(
            pair.token0(),
            pair.token1()
        );
        return factoryPair == token;
    }
}