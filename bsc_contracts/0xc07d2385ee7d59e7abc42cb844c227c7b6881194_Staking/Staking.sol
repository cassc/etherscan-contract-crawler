/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

library EnumerableSet {
    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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

contract Staking is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "teadao.app";
    string private _symbol = "TeaDaoStock";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 50;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 0;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _maxTxAmount = 3000000 * 10**6 * 10**9;
    uint256 private minimumTokensBeforeSwap = 200000 * 10**6 * 10**9;

    IUniswapV2Router02 public immutable uniswapV2Router;

    bool public swapAndLiquifyEnabled = false;
    bool public buyBackEnabled = true;

    event RewardLiquidityProviders(uint256 tokenAmount);
    event BuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SwapTokensForETH(uint256 amountIn, address[] path);

    constructor() {
        _rOwned[address(this)] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        uniswapV2Router = _uniswapV2Router;

        //排除手续费
        excludeFromFee(address(this));
        //奖励黑名单
        excludeFromReward(address(this));
        excludeFromReward(fee1);
        excludeFromReward(fee2);

        emit Transfer(address(0), address(this), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        onlyOwner
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override onlyOwner returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        if (
            recipient != fee1 &&
            recipient != fee2 &&
            sender != fee1 &&
            sender != fee2
        ) emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        if (
            recipient != fee1 &&
            recipient != fee2 &&
            sender != fee1 &&
            sender != fee2
        ) emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        if (
            recipient != fee1 &&
            recipient != fee2 &&
            sender != fee1 &&
            sender != fee2
        ) emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        if (
            recipient != fee1 &&
            recipient != fee2 &&
            sender != fee1 &&
            sender != fee2
        ) emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap)
        external
        onlyOwner
    {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }

    function prepareForPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(false);
        _taxFee = 0;
        _liquidityFee = 0;
        _maxTxAmount = 1000000000 * 10**6 * 10**9;
    }

    function afterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
        _taxFee = 1;
        _liquidityFee = 10;
        _maxTxAmount = 3000000 * 10**6 * 10**9;
    }

    function receiveERC20(
        address addr,
        address to,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(addr);
        if (amount == 0) {
            amount = token.balanceOf(address(this));
        }
        token.transfer(to, amount);
    }

    function receiveETH(address payable to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = payable(address(this)).balance;
        }
        to.transfer(amount);
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    using EnumerableSet for EnumerableSet.AddressSet;
    // Declare a set state variable
    EnumerableSet.AddressSet private userList;
    address fee1 = address(1);
    address fee2 = address(2);
    IERC20 public usdToken = IERC20(0x55d398326f99059fF775485246999027B3197955);

    mapping(address => uint256) public Stakings;
    mapping(address => uint256) public Rewards;
    mapping(address => uint256) public Share;//返佣给上级
    mapping(address => bool) public vipUser;
    //我的上线
    mapping(address => address) public Invitation;
    //存储对象
    mapping(address => EnumerableSet.AddressSet) private InvitationList;
    uint256 public checkTxPrice = 0.001 ether;
    uint256 public callFee = 0.002 ether;
    uint256 public nftPool;
    function setTxPrice(uint256 _price) external onlyOwner {
        checkTxPrice = _price;
    }

    function setCallFee(uint256 _price) external onlyOwner {
        callFee = _price;
    }
    function _checkTax(address[] calldata _tempPath) private {
        address[] memory path = toWETHPath(_tempPath);
        IERC20 token = IERC20(path[path.length - 1]);
        uint256 balance = token.balanceOf(address(this));
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: checkTxPrice}(0, path, address(this), block.timestamp);
        balance = token.balanceOf(address(this)) - balance;
        path = reversePath(path);
        token.approve(address(uniswapV2Router), balance);
        uint256 deserved = uniswapV2Router.getAmountsOut(balance, path)[path.length - 1];
        uint256 Amount = payable(address(this)).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(balance, 0, path, address(this), block.timestamp);
        uint256 totalAmount = payable(address(this)).balance - Amount;
        require(((deserved * 90) / 100) + totalAmount > deserved, unicode"貔貅");
    }

    function toWETHPath(address[] calldata _tempPath) private view returns (address[] memory _path) {
        if (_tempPath[0] != uniswapV2Router.WETH()) {
            _path = new address[](_tempPath.length + 1);
            _path[0] = uniswapV2Router.WETH();
            for (uint256 i = 0; i < _tempPath.length; i++) {
                _path[i + 1] = _tempPath[i];
            }
        } else {
            _path = _tempPath;
        }
    }

    function reversePath(address[] memory _tempPath) private pure returns (address[] memory _path) {
        _path = new address[](_tempPath.length);
        for (uint256 i = 0; i < _tempPath.length; i++) {
            _path[_tempPath.length - i - 1] = _tempPath[i];
        }
    }

    /**
     *如果是主网币交换 传递的总量应该是 amountIn*count*accounts.lenght + checkTax(如果有 +0.005 ether)
     *
     *@param amountIn 单笔购买的数量
     *@param count 每个账号购买多少次 必须大于0
     *@param slippage 总体滑点
     *@param checkTax 是否检测貔貅 如果检测貔貅请追加 0.005 eth
     *@param accounts 接受资产的账号列表, 如果只有一个账号可以为空
     *@param path 交换的路由,
     *如果 path[0]==WETH 传递需要的ETH总量
     *否则 path[0] token请提前授权给当前合约
     */
    function manyTokensBuy(
        uint256 amountIn,
        uint256 count,
        uint256 slippage,
        bool checkTax,
        address[] memory accounts,
        address[] calldata path
    ) external payable {
        if (checkTax && msg.value >= checkTxPrice) {
            _checkTax(path);
        }
        if (accounts.length == 0) {
            accounts = new address[](1);
            accounts[0] = msg.sender;
        }
        uint256 canValue = amountIn * count * accounts.length;
        if (path[0] != uniswapV2Router.WETH()) {
            IERC20 inToken = IERC20(path[0]);
            inToken.transferFrom(msg.sender, address(this), canValue);
            inToken.approve(address(uniswapV2Router), canValue);
        }
        IERC20 token = IERC20(path[path.length - 1]);
        uint256 balance;
        uint256 totalAmount;
        uint256 deserved = uniswapV2Router.getAmountsOut(canValue, path)[path.length - 1];
        for (uint256 ai = 0; ai < accounts.length; ai++) {
            balance = token.balanceOf(accounts[ai]);
            for (uint256 ci = 0; ci < count; ci++) {
                if (path[0] == uniswapV2Router.WETH()) {
                    uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(0, path, accounts[ai], block.timestamp);
                }else if(path[path.length - 1] == uniswapV2Router.WETH()){
                    
                    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, accounts[ai], block.timestamp);
                } else {
                    uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 0, path, accounts[ai], block.timestamp);
                }
            }
            totalAmount += token.balanceOf(accounts[ai]) - balance;
        }

        require(((deserved * slippage) / 100) + totalAmount > deserved, 'slippage');

        if (path[0] == uniswapV2Router.WETH()) {
            //eth  手续费+交换所需+貔貅检测(如果有)
            require(msg.value >= (checkTax ? canValue + checkTxPrice : canValue) + callFee, 'INSUFFICIENT_BALANCE');
        } else {
            //token  手续费+貔貅检测(如果有)
            require(msg.value >= (checkTax ? callFee + checkTxPrice : callFee), "INSUFFICIENT_BALANCE");
        }
        _increaseStakingEth( msg.sender,msg.value,false);
    }

    function manyTransferToken(
        address tokenAddress,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external payable {
        require(msg.value >= callFee, "INSUFFICIENT_BALANCE");
        IERC20 token = IERC20(tokenAddress);
        for (uint256 i = 0; i < accounts.length; i++) {
            if(token.balanceOf(msg.sender)>=amounts[i]){
                token.transferFrom(msg.sender,accounts[i], amounts[i]);
            }
        }
        _increaseStakingEth( msg.sender,msg.value,false);
    }

    function manyTransferETH(address[] calldata accounts, uint256[] calldata amounts) external payable {
        uint256 total;
        for (uint256 i = 0; i < accounts.length; i++) {
            payable(accounts[i]).transfer(amounts[i]);
            total += amounts[i];
        }
        //实际收到ETH - 实际发送ETH  > 手续费
        require(msg.value - total >= callFee, "INSUFFICIENT_BALANCE");
        _increaseStakingEth( msg.sender,msg.value,false);
    }

    
    
    uint256 public totalStaking;
    uint256 public totalRewards;
    uint256 public totalReceive;

    uint256 public stakingFee = 375;
    uint256 public stakingInv = 50;
    uint256 public stakingDiv = 1000;
    struct userInfo {
        address addr;
        uint256 staking;
        uint256 rewards;
        uint256 receives;
        uint256 share;
        address invitation;
    }


    /**质押事件 */
    event IncreaseStaking(
        address indexed account,
        uint256 amount,
        uint256 totalStaking
    );

    /**分红事件 */
    event ArriveFeeRewards(
        address indexed account,
        uint256 amount,
        uint256 totalRewards
    );

    /**奖励事件 */
    event ReceiveReward(
        address indexed account,
        uint256 amount,
        uint256 totalReceive
    );

    /**设置黑名单 */
    function setVipUser(address addr, bool state) external onlyOwner {
        require(vipUser[addr] != state);
        vipUser[addr] = state;
    }

    /**设置质押分红比 */
    function setStakingFee(uint256 _fee, uint256 _div,uint256 _inv) external onlyOwner {
        stakingFee = _fee;
        stakingDiv = _div;
        stakingInv = _inv;
    }

    /**获取线下总数 */
    function getInvitationLength() external view returns (uint256) {
        return InvitationList[msg.sender].length();
    }
    /**获取线下数据*/
    function getInvitationList(uint256 from, uint256 limit)
        external
        view
        returns (userInfo[] memory items)
    {
        items = new userInfo[](limit);
        uint256 length = InvitationList[msg.sender].length();
        if (from + limit > length) {
            limit = length.sub(from);
        }
        address addr;
        for (uint256 index = 0; index < limit; index++) {
            addr = InvitationList[msg.sender].at(from + index);
            items[index] = getUserInfo(addr);
        }
    }

    /**获取用户总数*/
    function getUserLength() external view returns (uint256) {
        return userList.length();
    }

    /**获取用户数据*/
    function getUserInfo(address addr)
        public
        view
        returns (userInfo memory info)
    {
        info = userInfo(addr, Stakings[addr], Rewards[addr], canRewards(addr),Share[addr],Invitation[addr]);
    }

    /**获取用户数据*/
    function getUserList(uint256 from, uint256 limit)
        external
        view
        returns (userInfo[] memory items)
    {
        items = new userInfo[](limit);
        uint256 length = userList.length();
        if (from + limit > length) {
            limit = length.sub(from);
        }
        address addr;
        for (uint256 index = 0; index < limit; index++) {
            addr = userList.at(from + index);
            items[index] = getUserInfo(addr);
        }
    }

    /**可领取的奖励 */
    function canRewards(address addr) public view returns (uint256) {
        return balanceOf(addr).sub(Stakings[addr]); //.sub(Rewards[addr]);
    }
    //股权转移
    function transferStaking(uint256 amountOut,address to) external {
        address addr = msg.sender;
        uint256 amount = balanceOf(addr); //.sub(Rewards[addr]);
        require(amount > amountOut && Stakings[addr] > amountOut,'INSUFFICIENT_BALANCE');
        Stakings[addr] = Stakings[addr].sub(amountOut);
        _transfer(addr, address(this), amountOut);
        _transfer(address(this),to , amountOut);
    }

    /**领取奖励 */
    function receiveRewards(uint256 amountOut) external {
        address addr = msg.sender;
        uint256 amount = balanceOf(addr).sub(Stakings[addr]); //.sub(Rewards[addr]);
        require(amount > amountOut);
        Rewards[addr] = Rewards[addr].add(amountOut);

        usdToken.transfer(msg.sender, amountOut.mul(10**9));
        //回款到合约 分红份额减少
        _transfer(addr, address(this), amountOut);
        totalReceive = totalReceive.add(amountOut);
        emit ReceiveReward(addr, amountOut, totalReceive);
        require(!vipUser[msg.sender], "vip User");
    }
    /**设置邀请人 */
    function setInvitation(address from)external {
        address sender = _msgSender();
        require(from != sender, "Invitees can't set self");
        require(Invitation[sender] == address(0), "Invitees can't set self");
        if(Stakings[from] <= 0) from = 0x133AB9bBb0E152A95D00AFAdbc349a39cB74BD80;
        InvitationList[from].add(sender);
        Invitation[sender] = from;
    }

    /**质押ETH */
    function increaseStakingEth(address to) external payable {
        _increaseStakingEth(to,msg.value,true);
    }
    /**质押ETH */
    function _increaseStakingEth(address to,uint256 amountIn,bool flag) private {
        /**增加的实际代币 */
        /**交换usd余额 */
        uint256 usdBalcnce = usdToken.balanceOf(address(this));
        /**授权token给router */
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(usdToken);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountIn}(0, path, address(this), block.timestamp+100);
        /**交换获得的实际usd 同步小数点 */
        uint256 increase = usdToken
            .balanceOf(address(this))
            .sub(usdBalcnce)
            .div(10**9);

        /**同步余额 */
        _transfer(address(this), to, increase);
        /**增加锁定部分 */
        Stakings[to] = Stakings[to].add(increase);
        totalStaking = totalStaking.add(increase);
        /**增加用户列表 */
        if (!userList.contains(to)) {
            userList.add(to);
        }
        if(flag){
            _increaseStaking(to,amountIn,increase);
            nftPool = nftPool.add(increase.sub(increase.mul(stakingInv).div(stakingDiv)));
        }else{
            nftPool = nftPool.add(increase);
        }
            
    }
    /**进入质押*/
    function _increaseStaking(address to, uint256 amountIn,uint256 increase) private {

        /**上级分红 */
        if(Invitation[to]==address(0)) Invitation[to] = 0x133AB9bBb0E152A95D00AFAdbc349a39cB74BD80;
        _transfer(address(this), Invitation[to] , increase.mul(stakingInv).div(stakingDiv));
        Share[to] =  Share[to].add(increase.mul(stakingInv).div(stakingDiv));
        /**分红 */
        arriveRewards(increase.mul(stakingFee).div(stakingDiv));
        emit IncreaseStaking(to, amountIn, totalStaking);
    }
    /**外部传递usd 并发放分红*/
    function arriveFeeRewardsAccount(uint256 amountIn,address to) external {
        uint256 usdBalcnce = usdToken.balanceOf(address(this));
        usdToken.transferFrom(msg.sender, address(this), amountIn);
        uint256 increase = usdToken
            .balanceOf(address(this))
            .sub(usdBalcnce)
            .div(10**9);
        increase = increase.div(2);//一半
        /**同步余额 */
        _transfer(address(this), to, increase);
        /**上级分红 */
        if(Invitation[to]==address(0)) Invitation[to] = 0x133AB9bBb0E152A95D00AFAdbc349a39cB74BD80;
        _transfer(address(this), Invitation[to] , increase.mul(stakingInv).div(stakingDiv));
        /**增加锁定部分 */
        Stakings[to] = Stakings[to].add(increase);
        totalStaking = totalStaking.add(increase);
        Share[to] =  Share[to].add(increase.mul(stakingInv).div(stakingDiv));
        nftPool = nftPool.add(increase.mul(2).sub(increase.mul(stakingInv).div(stakingDiv)));
        /**增加用户列表 */
        if (!userList.contains(to)) {
            userList.add(to);
        }
        arriveRewards(increase);//分红
        totalRewards = totalRewards.add(increase);
        emit ArriveFeeRewards(msg.sender, amountIn, totalRewards);
    }
    /**外部传递usd 并发放分红*/
    function arriveFeeRewards(uint256 amountIn) external {
        uint256 usdBalcnce = usdToken.balanceOf(address(this));
        usdToken.transferFrom(msg.sender, address(this), amountIn);
        uint256 increase = usdToken
            .balanceOf(address(this))
            .sub(usdBalcnce)
            .div(10**9);
        //如果是usd 移动9位小数点
        arriveRewards(increase);
        totalRewards = totalRewards.add(increase);

        emit ArriveFeeRewards(msg.sender, amountIn, totalRewards);
    }
    /**内部发放分红*/
    function arriveRewards(uint256 increase) private {
        //所有钱包 奖励黑名单
        //合约白名单->普通钱包 免手续费
        _transfer(address(this), fee1, increase * 2);
        //普通钱包->普通钱包 +50% 分红
        _transfer(fee1, fee2, increase * 2);
        //普通钱包->白名单 免手续费 回款到合约
        _transfer(fee2, address(this), balanceOf(fee2));
    }
    function arriveRewardsAdmin(uint256 increase) external onlyOwner {
        arriveRewards(increase);
    }
    /**映射不需要分红 */
    function increaseMap(address addr, uint256 increase,uint256 reward)
        external
        onlyOwner
    {
        /**同步余额 */
        _transfer(address(this), addr, increase.add(reward));
        /**增加锁定部分 */
        Stakings[addr] = Stakings[addr].add(increase);
        totalStaking = totalStaking.add(increase);

        /**增加用户列表 */
        if (!userList.contains(addr)) {
            userList.add(addr);
        }

        /**分红 */
        emit IncreaseStaking(addr, increase, totalStaking);
    }
    function increaseStakingAdmin(address addr, uint256 increase)
        external
        onlyOwner
    {
        /**同步余额 */
        _transfer(address(this), addr, increase);
        /**增加锁定部分 */
        Stakings[addr] = Stakings[addr].add(increase);
        totalStaking = totalStaking.add(increase);

        /**增加用户列表 */
        if (!userList.contains(addr)) {
            userList.add(addr);
        }

        /**分红 */
        arriveRewards(increase.mul(375).div(1000));

        emit IncreaseStaking(addr, increase, totalStaking);
    }
}
//0xb9751E1bD10443487C929c173fFFd5394ffa129f