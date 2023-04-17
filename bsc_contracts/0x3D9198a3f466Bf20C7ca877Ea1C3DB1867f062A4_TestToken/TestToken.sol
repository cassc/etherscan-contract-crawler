/**
 *Submitted for verification at BscScan.com on 2023-04-16
*/

pragma solidity 0.8;


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

interface IERC20Metadata is IERC20 {
    
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

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

library Math {
    enum Rounding {
        Down, 
        Up, 
        Zero 
    }

    
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return (a & b) + (a ^ b) / 2;
    }

    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            
            
            
            uint256 prod0; 
            uint256 prod1; 
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            
            if (prod1 == 0) {
                
                
                
                return prod0 / denominator;
            }

            
            require(denominator > prod1, "Math: mulDiv overflow");

            
            
            

            
            uint256 remainder;
            assembly {
                
                remainder := mulmod(x, y, denominator)

                
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            
            

            
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                
                denominator := div(denominator, twos)

                
                prod0 := div(prod0, twos)

                
                twos := add(div(sub(0, twos), twos), 1)
            }

            
            prod0 |= prod1 * twos;

            
            
            
            uint256 inverse = (3 * denominator) ^ 2;

            
            
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 
            inverse *= 2 - denominator * inverse; 

            
            
            
            
            result = prod0 * inverse;
            return result;
        }
    }

    
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        
        
        
        
        
        
        
        
        
        
        uint256 result = 1 << (log2(a) >> 1);

        
        
        
        
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

library SignedMath {
    
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    
    function average(int256 a, int256 b) internal pure returns (int256) {
        
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            
            return uint256(n >= 0 ? n : -n);
        }
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

contract AbsToken is Ownable, IERC20, IERC20Metadata {

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _userBalances; 
    mapping(address => mapping(address => uint256)) private _allowances; 

    address private immutable _whiteListCreatorAddress; 
    address private immutable _marketWalletAddress; 

    address private immutable _swapRouterAddress;

    uint256 private _totalSupply; 
    uint8 private _decimals = 18; 
    string private _name;
    string private _symbol;
    uint256 private constant _blackHoleAndInviteRewardUpperLimitMultiple = 3;

    uint256 private _directDestroyTotal; 
    uint256 private _tradeFeeDestroyTotal; 
    uint256 private _transferFeeDestroyTotal; 

    mapping(address => uint256) private _userDirectDestroyAmount; 
    mapping(address => uint256) private _userLPFeeDestroyAmount; 
    mapping(address => uint256) private _userTransferFeeDestroyAmount; 
    mapping(address => uint256) private _userTxAndBlackHoleAndInviteRewardAmount;


    mapping(address => uint256) private _userLPMiningSum; 
    mapping(address => uint256) private _userLastMiningTime; 
    mapping(address => bool) private _userWhiteList; 
    mapping(address => bool) private _isExcludedTxFee; 
    mapping(address => bool) private _isExcludedTransferFee; 
    mapping(address => bool) private _isExcludedReward; 
    mapping(address => bool) private _isMiner; 
    mapping(address => uint256) private _userInviteCount; 
    mapping(address => uint256) private _userMinerCount; 
    mapping(address => bool) private uniswapV2Pairs; 

    mapping(address => mapping(address => bool)) private _tempInviter; 
    mapping(address => address) private _userInviter; 

    mapping(address => EnumerableSet.AddressSet) private _userChildren; 

    bool private _takeFee = true;
    uint256 private constant _denominator = 10000;
    uint256 private _transferFee; 
    uint256 private _txDestroyFee; 
    uint256 private _txMarketFee; 

    uint256 private _minDestroyTokenAmount; 

    IUniswapV2Router02 private uniswapV2Router;
    address private tokenUsdtPair;
    address private dead = 0x000000000000000000000000000000000000dEaD;
    address private usdt; 

    event Log(string msg);

    function _log(string memory m) private {emit Log(m);}

    constructor(
        address usdtAddress,
        address swapRouterAddress,
        address whitelistAddress,
        address marketWalletAddress,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 supply,
        uint256 transferFee,
        uint256 txDestroyFee,
        uint256 txMarketFee,
        uint256 minDestroyTokenAmount
    ) {

        require(usdtAddress != address(0));
        require(swapRouterAddress != address(0));
        require(whitelistAddress != address(0));
        require(marketWalletAddress != address(0));
        require(bytes(tokenName).length > 0);
        require(bytes(tokenSymbol).length > 0);
        require(supply > 0);
        require(transferFee > 0);
        require(minDestroyTokenAmount > 0);
        require(txDestroyFee >= 0);
        require(txMarketFee >= 0);

        
        usdt = usdtAddress;
        _name = tokenName;
        _transferFee = transferFee;
        _txDestroyFee = txDestroyFee;
        _txMarketFee = txMarketFee;


        _symbol = tokenSymbol;
        _whiteListCreatorAddress = whitelistAddress;
        _marketWalletAddress = marketWalletAddress;
        _minDestroyTokenAmount = minDestroyTokenAmount * 10 ** _decimals;


        _swapRouterAddress = swapRouterAddress;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swapRouterAddress);

        
        tokenUsdtPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdtAddress);

        uniswapV2Pairs[tokenUsdtPair] = true;
        uniswapV2Router = _uniswapV2Router;

        _isExcludedTxFee[msg.sender] = true;
        _isExcludedTxFee[address(this)] = true;
        _isExcludedTxFee[dead] = true;
        _isExcludedTxFee[address(0)] = true;
        _isExcludedTxFee[whitelistAddress] = true;
        _isExcludedTxFee[swapRouterAddress] = true;
        _isExcludedTxFee[tokenUsdtPair] = true;

        _isExcludedTransferFee[msg.sender] = true;
        _isExcludedTransferFee[address(this)] = true;
        _isExcludedTransferFee[dead] = true;
        _isExcludedTransferFee[address(0)] = true;
        _isExcludedTransferFee[whitelistAddress] = true;
        _isExcludedTransferFee[swapRouterAddress] = true;
        _isExcludedTransferFee[tokenUsdtPair] = true;

        _isExcludedReward[msg.sender] = true;
        _isExcludedReward[address(this)] = true;
        _isExcludedReward[dead] = true;
        _isExcludedReward[address(0)] = true;
        _isExcludedReward[whitelistAddress] = true;
        _isExcludedReward[swapRouterAddress] = true;
        _isExcludedReward[tokenUsdtPair] = true;

        uint256 _total = supply * (10 ** decimals());

        
        _mint(msg.sender, _total);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply + amount;

        _userBalances[account] = _userBalances[account] + amount;
        emit Transfer(address(0), account, amount);
    }


    
    function getUserChildren(address _user) public view returns (address[] memory) {
        return _userChildren[_user].values();
    }

    function name() public view virtual override returns (string memory) {return _name;}

    function symbol() public view virtual override returns (string memory) {return _symbol;}

    function decimals() public view virtual override returns (uint8) {return _decimals;}

    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _userBalances[account];
    }

    
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }
        return true;
    }

    
    function _bind(address _from, address _to) internal {

         address _owner = owner();

         if (_from == _whiteListCreatorAddress
         || _from == _swapRouterAddress
         || _from == address(this)
         || _from == _owner
         || _from == address(0)
         || _from == dead
             || _from == tokenUsdtPair
         ) {
             return;
         }

         if (_to == _whiteListCreatorAddress
         || _to == _swapRouterAddress
         || _to == address(this)
         || _to == _owner
         || _to == address(0)
         || _to == dead
             || _to == tokenUsdtPair
         ) {
             return;
         }


        if (!uniswapV2Pairs[_from] && !uniswapV2Pairs[_to] && !_tempInviter[_from][_to]) {

            bool ok = true;

            address currentUser = _from;
            
            for (uint256 i = 1; i <= 9;) {
                currentUser = _userInviter[currentUser];
                if (currentUser == address(0)) {
                    break;
                }

                
                if (currentUser == _to) {
                    ok = false;
                    _log("bind fail");
                    break;
                }

            unchecked {
                i++;
            }
            }

            if (ok) {
                _tempInviter[_from][_to] = true;
            }
        }

        if (!uniswapV2Pairs[_from] && _tempInviter[_to][_from] && _userInviter[_from] == address(0) && _userInviter[_to] != _from) {
             






            _userInviter[_from] = _to;
            _userChildren[_to].add(_from);
            _userInviteCount[_to] = _userInviteCount[_to] + 1;
          
        }
    }


    
    
    

    address _lastMaybeAddLPAddress; 
    uint256 _lastMaybeAddLPTokenAmount; 
    mapping(address => uint256) private _userLPAmount; 
    mapping(address => uint256) private _userLPTTAmount; 

    address _lastMaybeRemoveLPAddress; 
    uint256 _lastMaybeRemoveLPTokenAmount; 

    
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer to the zero amount");

        uint256 balanceOfFrom = _userBalances[from];
        require(balanceOfFrom >= amount, "ERC20: transfer amount exceeds balance");

        
        
        

        
        
        
        
        

        

        
        _doAddLp();

        
        _doRemoveLp();

        
        if (from == _whiteListCreatorAddress) {
            
            if (to == address(tokenUsdtPair)) {
                _transferStandard(from, to, amount);
                emit Transfer(from, to, amount);
                return;
            }
            else {
                _doCreateWhiteList(from, to, amount);
                return;
            }

        }

        
        if (to == address(this) || to == _whiteListCreatorAddress) {
            _transferStandard(from, to, amount);
            emit Transfer(from, to, amount);
            return;
        }

        
        if (to == dead) {
            
            _doTransferToDead(from, to, amount);
            
            _doMiningAll(from);
            return;
        }

        uint256 realTransferAmount = amount;
        bool takeFee = _takeFee;


        
        if (to == tokenUsdtPair) {
            if (takeFee) {
                takeFee = !_isExcludedTxFee[from];

                if (takeFee) {
                    realTransferAmount = _takeTxFeeReward(from, amount);
                }
            }
        }

        if (from == tokenUsdtPair) {
            if (takeFee) {
                takeFee = !_isExcludedTxFee[to];
                if (takeFee) {
                    realTransferAmount = _takeTxFeeReward(to, amount);
                }
            }
        }

        
        if (from != tokenUsdtPair && to != tokenUsdtPair) {
            if (takeFee) {
                takeFee = !_isExcludedTxFee[from] && !_isExcludedTxFee[to];

                if (takeFee) {
                    realTransferAmount = _takeTransferFeeReward(from, amount);
                }
            }
        }

        
        
        
        
        

        
        _transferStandard(from, to, realTransferAmount);
        
        _bind(from, to);
        
        if (amount > realTransferAmount) {
            _userBalances[from] = _userBalances[from] - (amount - realTransferAmount);
        }
        emit Transfer(from, to, realTransferAmount);


        if (from != address(this)) {
            
            if (to == tokenUsdtPair) {

                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPTokenAmount = realTransferAmount;

                
                
                
                
            }

        }

        if (to != address(this)) {

            
            if (from == tokenUsdtPair) {

                _lastMaybeRemoveLPAddress = to;
                _lastMaybeRemoveLPTokenAmount = realTransferAmount;

                
                
                
                
            }
        }
    }

    
    function _takeTxFeeReward(address user, uint256 amount) private returns (uint256 realTransferAmount) {
        uint256 txDestroyFeeAmount = (amount * _txDestroyFee) / _denominator;
        uint256 txMarketFeeAmount = (amount * _txMarketFee) / _denominator;

        if (txMarketFeeAmount > 0) {

            
            _tradeFeeDestroyTotal += txDestroyFeeAmount;

            
            _userTransferFeeDestroyAmount[user] += txDestroyFeeAmount;

            
            _userBalances[_marketWalletAddress] += txMarketFeeAmount;
            
            realTransferAmount = amount - txDestroyFeeAmount - txMarketFeeAmount;

            _log("takeTxFeeReward:amount,txDestroyFeeAmount,txMarketFeeAmount,realTransferAmount");
            _log(Strings.toString(amount));
            _log(Strings.toString(txDestroyFeeAmount));
            _log(Strings.toString(txMarketFeeAmount));
            _log(Strings.toString(realTransferAmount));

        }
        return realTransferAmount;
    }


    
    function _takeTransferFeeReward(address user, uint256 amount) private returns (uint256 realTransferAmount) {
        uint256 txTransferFeeAmount = (amount * _transferFee) / _denominator;

        
        _transferFeeDestroyTotal += txTransferFeeAmount;

        
        _userTransferFeeDestroyAmount[user] += txTransferFeeAmount;

        realTransferAmount = amount - txTransferFeeAmount;
        
        
        
        

        return realTransferAmount;

    }

    
    function _doTransferToDead(address from, address to, uint256 amount) private {
        
        _transferStandard(from, to, amount);
        
        _increaseUserDestroyAmount(from, amount);
        
        _decreaseTotalSupply(amount);
        
        _tryActivateOrDeActiveMiner(from);

        emit Transfer(from, to, amount);
    }


    
    
    
    
    
    
    function _doCreateWhiteList(address from, address to, uint256 amount) private {
        require(_userBalances[from] >= amount, "Insufficient balance");
        require(_userWhiteList[to] != true, "User already in white list");

        uint256 lpContractTokenAmount = (amount * 10) / 100;


        _increaseUserDestroyAmount(to,amount);


        _userLPTTAmount[to] += lpContractTokenAmount;
        _decreaseUserBalance(from, amount + lpContractTokenAmount);

        
        uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(to);
        _userLPAmount[to] = lpBalanceInChain;

        
        
        if (amount >= _minDestroyTokenAmount) {
            _isMiner[to] = true;
            _userMinerCount[_userInviter[to]] += 1;
        }

        
        _userWhiteList[to] = true;
    }

    
    function _doAddLp() private {
        address user = _lastMaybeAddLPAddress;
        
        if (user == address(0)) {
            return;
        }

        
        _lastMaybeAddLPAddress = address(0);

        
        uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);

        
        if (lpBalanceInChain > 0) {
            uint256 lpAmountInContract = _userLPAmount[user];
            
            if (lpBalanceInChain > lpAmountInContract) {
                
                _userLPTTAmount[user] += _lastMaybeAddLPTokenAmount;
            }
            _userLPAmount[user] = lpBalanceInChain;
        } else {
            
            _userLPTTAmount[user] = 0;
            _userLPAmount[user] = 0;
        }

        _lastMaybeAddLPTokenAmount = 0;
    }

    
    function _doRemoveLp() private {

        address user = _lastMaybeRemoveLPAddress;
        
        if (user == address(0)) {return;}

        
        _lastMaybeRemoveLPAddress = address(0);

        uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);

        
        if (lpBalanceInChain > 0) {

            
            uint256 lpAmountInContract = _userLPAmount[user];

            
            if (lpAmountInContract == 0) {
                
                _userLPTTAmount[user] = 0;
                _userLPAmount[user] = 0;
            } else if (lpBalanceInChain < lpAmountInContract) {
                
                if (_userLPTTAmount[user] > _lastMaybeRemoveLPTokenAmount) {
                    _userLPTTAmount[user] -= _lastMaybeRemoveLPTokenAmount;
                } else {
                    _userLPTTAmount[user] = _lastMaybeRemoveLPTokenAmount;
                }

                _userLPAmount[user] = lpBalanceInChain;
            }


        } else {
            
            _userLPTTAmount[user] = 0;
            _userLPAmount[user] = 0;
        }

        _lastMaybeRemoveLPTokenAmount = 0;
    }



    
    function _doMiningAll(address user) private {

        
        if (_isExcludedReward[user]) {
            _log("excluded reward");
            return;
        }

        uint256 nextMiningTime = getNextMiningTime(user);
        if (nextMiningTime != 0) {
            
            if (block.timestamp < nextMiningTime) {
                _log("can only mine once in a 24 hour period");
                return;
            }
        }

        if (!_isMiner[user]) {
            _log("not miner");
            return;
        }

        uint256 lpMiningAmount = _doLPMining(user);
        uint256 blackHoleMiningAmount = _doBlackHoleMining(user);

        uint256 total = lpMiningAmount + blackHoleMiningAmount;

        _userLastMiningTime[user] = block.timestamp;

        _log("total mining amount");
        _log(Strings.toString(total));

        if (total == 0) {return;}

        _transferThisTo(user, total);

        
        _distributeInviteReward(user, total);

    }

    
    function _doBlackHoleMining(address user) private returns (uint256) {

        _log("doBlackHoleMining");

        if (!_isMiner[user]) {
            _log("not miner");
            return 0;
        }

        uint256 userDestroyAmount = _userDirectDestroyAmount[user];

        
        
        
        
        
        
        
        


        
        uint256 ratio = getBlackHoleMiningRatio();
        _log("ratio");
        _log(Strings.toString(ratio));
        uint256 blackHoleMiningAmount = userDestroyAmount * ratio / _denominator;

        _log("blackHoleMiningAmount");
        _log(Strings.toString(blackHoleMiningAmount));

        _userTxAndBlackHoleAndInviteRewardAmount[user] += blackHoleMiningAmount;

        return blackHoleMiningAmount;

    }

    
    uint256 private constant _blackHoleMiningRatioStep = 50000000 * 10 ** 18;

    
    function getBlackHoleMiningRatio() private view returns (uint256) {
        uint256 total = _directDestroyTotal;
        if (total <= _blackHoleMiningRatioStep) {
            return 100;
            
        }

        
        
        
        
        
        
        
        
        uint256 step = total / _blackHoleMiningRatioStep;
        if (step >= 7) {
            return 30;
            
        }

        uint256 ratio = 100 - step * 10;
        return ratio;

    }

    
    function _doLPMining(address user) internal returns (uint256) {

        _log("doLPMining");

        
        
        uint256 lpTT = _userLPTTAmount[user];

        _log("lpTT");
        _log(Strings.toString(lpTT));

        if (lpTT == 0) {
            return 0;
        }

        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        

        uint256 miningAmount = lpTT * 5 / 1000;

        _log("LP miningAmount");
        _log(Strings.toString(miningAmount));

        return miningAmount;
    }

    
    function _distributeInviteReward(address user, uint256 amount) private {

        if (0 == amount) {return;}


        


        address invitor;
        uint256 total;
        address currentUser = user;
        uint256 currentReward = 0;
        uint256 ratio = 0;
        uint256 denominator = 1000000;

        for (uint256 i = 1; i <= 9;) {
            invitor = _userInviter[currentUser];
            if (address(0) == invitor) {
                break;
            }

            currentUser = invitor;
            
            



            if(getUserMinerCount(invitor) < i){
                continue;
            }

            
            if (_isMiner[invitor]) {
                continue;
            }

            if (1 == i) {
                ratio = 5000;
            } else if (2 == i) {
                ratio = 4000;
            } else if (3 == i) {
                ratio = 3000;
            } else if (4 == i) {
                ratio = 2000;
            } else if (5 == i) {
                ratio = 1000;
            } else if (6 == i) {
                ratio = 500;
            } else if (7 == i) {
                ratio = 250;
            } else if (8 == i) {
                ratio = 125;
            } else if (9 == i) {
                ratio = 3000;
            }

            currentReward = amount * ratio / denominator;

            
            if (currentReward > 0) {
                total += currentReward;
                _userTxAndBlackHoleAndInviteRewardAmount[invitor] += currentReward;
                _userBalances[invitor] += currentReward;
                
                

                _log("distributeInviteReward");
                _log(Strings.toString(i));
                _log(Strings.toString(currentReward));
                _log(Strings.toHexString(invitor));
            }

        unchecked {i++;}
        }

        
        if (total > 0) {
            _decreaseThisBalance(total);
        }

    }

    
    function _increaseUserDestroyAmount(address user, uint256 amount) private {
        _userDirectDestroyAmount[user] = _userDirectDestroyAmount[user] + amount;
        _directDestroyTotal = _directDestroyTotal + amount;
    }

    
    function _increaseTransferDestroyAmount(uint256 amount) private {
        _transferFeeDestroyTotal = _transferFeeDestroyTotal + amount;
    }

    
    function getTransferFee() public view returns (uint256) {
        return _transferFee;
    }

    
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    
    function getNextMiningTime(address user) public view returns (uint256) {
        uint256 lastMiningTime = _userLastMiningTime[user];
        if (0 == lastMiningTime) {
            return 0;
        }

    unchecked{
        
        return (lastMiningTime - 1 minutes);
    }

    }

    
    function _decreaseTotalSupply(uint256 amount) private {
        if (_totalSupply > amount) {
        unchecked {
            _totalSupply = _totalSupply - amount;
        }
        } else {
            _totalSupply = 0;
        }

    }

    
    function _decreaseThisBalance(uint256 amount) private {
        _decreaseUserBalance(address(this), amount);
    }

    
    function _decreaseUserBalance(address user, uint256 amount) private {
        if (_userBalances[user] > amount) {
        unchecked {
            _userBalances[user] = _userBalances[user] - amount;
        }
        } else {
            _userBalances[user] = 0;
        }

    }

    
    function getTransferFeeDestroyTotal() public view returns (uint256) {
        return _transferFeeDestroyTotal;
    }

    
    function getDirectDestroyTotal() public view returns (uint256) {
        return _directDestroyTotal;
    }

    
    function getTradeFeeDestroyTotal() public view returns (uint256) {
        return _tradeFeeDestroyTotal;
    }

    
    function getIsExcludedTransferFee(address account) public view returns (bool) {
        return _isExcludedTxFee[account];
    }

    
    function getUserDestroyAmount(address user) public view returns (uint256) {
        return _userDirectDestroyAmount[user];
    }

    
    function getIsMiner(address user) public view returns (bool){
        return _isMiner[user];
    }

    
    function getIsInWhiteList(address user) public view returns (bool){
        return _userWhiteList[user];
    }

    
    function getUserLiquidityContractTokenAmount(address user) public view returns (uint256) {
        return _userLPTTAmount[user];
    }

    
    function getUserInviteCount(address user) public view returns (uint256) {
        return _userInviteCount[user];
    }

    
    function getUserMinerCount(address user) public view returns (uint256) {

        address[] memory miners = _userChildren[user].values();
        return miners.length;

        
    }

    
    function getUserTxAndBlackHoleAndInviteRewardAmount(address user) public view returns (uint256) {
        return _userTxAndBlackHoleAndInviteRewardAmount[user];
    }


    
    function _transferStandard(address from, address to, uint256 amount) internal virtual {
        uint256 fromBalance = _userBalances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

    unchecked {
        _userBalances[from] = fromBalance - amount;
    }

        _userBalances[to] = _userBalances[to] + amount;

        emit Transfer(from, to, amount);
    }

    function _transferThisTo(address to, uint256 amount) internal virtual {
        _transferStandard(address(this), to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    
    function _tryActivateOrDeActiveMiner(address user) private {

        
        if (_isExcludedReward[user]) {return;}

        
        uint256 userTotalDirectDestroyAmount = _userDirectDestroyAmount[user];


        
        bool canMiner = userTotalDirectDestroyAmount >= _minDestroyTokenAmount;

        
        if (canMiner) {
            
            uint256 maxReward = userTotalDirectDestroyAmount * _blackHoleAndInviteRewardUpperLimitMultiple;
            
            uint256 userTotalReward = _userTxAndBlackHoleAndInviteRewardAmount[user];

            canMiner = maxReward > userTotalReward;
        }

        
        if (canMiner) {
            
            
            uint256 lpBalanceInChain = IERC20(tokenUsdtPair).balanceOf(user);
            if (lpBalanceInChain == 0) {
                _log("lpBalance (blockchain) is 0");
                canMiner = false;
            }
            else {

                
                uint256 lpBalanceInContract = _userLPAmount[user];
                if (lpBalanceInContract > lpBalanceInChain) {
                    _log("lpBalance (contract) > lpBalance (blockchain)");
                    canMiner = false;
                }
            }
        }


        
        if (!_isMiner[user]) {
            if (canMiner) {
                _isMiner[user] = true;
                _userMinerCount[_userInviter[user]] += 1;
            }
        } else 
        {
            if (!canMiner) {
                _isMiner[user] = false;
                if (_userMinerCount[_userInviter[user]] > 0) {
                unchecked {
                    _userMinerCount[_userInviter[user]] -= 1;
                }
                } else {
                    _userMinerCount[_userInviter[user]] = 0;
                }
            }
        }
    }

}

contract TestToken is AbsToken {
    constructor() AbsToken(

       
       
       
       
       
       
       address( 0xFA43288c7B0675A9D9D316A9558DbB10226ca9d9 ),

        
        
        
        
        
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),

        
        address(0x0F7Dc680F5181eba2DC6FaCe5981aaaB5ea761e4),

        
        address(0x3eb67B92CB284855e40A3b98ECAe84A304AC7215),        

        "Test9",
        "TEST9",


        
        
        

        500000000,

        2000, 

        200, 

        100,

        2000 

    ){
        

    }
}