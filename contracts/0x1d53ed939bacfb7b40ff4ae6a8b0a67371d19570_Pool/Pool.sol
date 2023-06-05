/**
 *Submitted for verification at Etherscan.io on 2023-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }
    
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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



interface IFactory {
    function lpFee() external returns (uint);
    function feeTo() external returns (address);
    function totalPairs() external view returns (uint);
    function getPair(address tokenAddress) external view returns (address pair);

    function createPair(address tokenAddress) external returns (address pair);
    function createPairWithAddExactEthLP(address tokenAddress, uint tokenAmountMin, address to, uint deadline) payable external returns (address pair, uint lpAmount);

    event lpFeeUpdated(uint previousFee, uint newFee);
    event PairCreated(address indexed tokenAddress, address pair, uint);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}





contract ERC20 {
    using SafeMath for uint;

    string public constant name = 'PeppSwap LP';
    string public constant symbol = 'PEPP-LP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() {}

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value, 'PeppSwap: INSUFFICIENT_BALANCE');
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value, 'PeppSwap: INSUFFICIENT_BALANCE');
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value, 'PeppSwap: INSUFFICIENT_ALLOWANCE');
        }
        _transfer(from, to, value);
        return true;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


contract Pool is ERC20, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public token;
    address public factory;
    bool initialized;

    event Sync(uint reserve0, uint reserve1);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PeppSwap: EXPIRED');
        _;
    }

    constructor() { 
        
    }

    function initialize(address _token) external {
        require(!initialized, 'PeppSwap: ALREADY_INITIALIZED');

        initialized = true;
        factory = msg.sender;
        token = _token;
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'PeppSwap: ETH_TXN_FAILED');
    }

    function token0() external pure returns (address _token) {
        _token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function token1() external view returns (address _token) {
        _token = token;
    }

    function reserve0() external view returns (uint _reserve0) {
        _reserve0 = address(this).balance;
    }

    function reserve1() external view returns (uint _reserve1) {
        _reserve1 = IERC20(token).balanceOf(address(this));
    }

    function getReserves() external view returns(uint _reserve0, uint _reserve1, uint _blockTimestampLast) {
        return (
            address(this).balance,
            IERC20(token).balanceOf(address(this)),
            block.timestamp
        );
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'PeppSwap: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PeppSwap: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure returns (uint amountIn) {
        require(amountOut > 0, 'PeppSwap: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'PeppSwap: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    function swapExactETHForTokens(uint amount1min, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint amount1) {
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount1 = getAmountOut(msg.value, reserve0_, reserve1_);
        require(amount1min <= amount1, 'PeppSwap: SLIPPAGE_REACHED');
        IERC20(_token).safeTransfer(to, amount1);

        emit Swap(msg.sender, msg.value, 0, 0, amount1, to);
        emit Sync(reserve0_.add(msg.value), reserve1_.sub(amount1));
    }
    
    function swapETHForExactTokens(uint amount1, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint amount0) {
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount0 = getAmountIn(amount1, reserve0_, reserve1_);
        require(amount0 <= msg.value, 'PeppSwap: SLIPPAGE_REACHED');
        IERC20(_token).safeTransfer(to, amount1);

        if(msg.value > amount0){ safeTransferETH(msg.sender, msg.value.sub(amount0)); }

        emit Swap(msg.sender, amount0, 0, 0, amount1, to);
        emit Sync(reserve0_.add(amount0), reserve1_.sub(amount1));
    }

    function swapExactTokensForETH(uint amount1, uint amount0min, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount0) {
        address _token = token;        // gas savings
        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));

        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount1);
        amount1 = (IERC20(_token).balanceOf(address(this))).sub(reserve1_);
        amount0 = getAmountOut(amount1, reserve1_, reserve0_);
        require(amount0min <= amount0, 'PeppSwap: SLIPPAGE_REACHED');
        
        safeTransferETH(to, amount0);

        emit Swap(msg.sender, 0, amount1, amount0, 0, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.add(amount1));
    }

    function swapTokensForExactETH(uint amount0, uint amount1max, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount1) {
        address _token = token;        // gas savings
        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        
        amount1 = getAmountIn(amount0, reserve1_, reserve0_);
        require(amount1 <= amount1max, 'PeppSwap: SLIPPAGE_REACHED');
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amount1);
        require(amount1 == (IERC20(_token).balanceOf(address(this))).sub(reserve1_), 'PeppSwap: DEFLATIONARY_TOKEN_USE_EXACT_TOKENS');
        
        safeTransferETH(to, amount0);

        emit Swap(msg.sender, 0, amount1, amount0, 0, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.add(amount1));
    }

    function _addLPinternal(uint amount0min, uint amount1, address from, address to) internal returns (uint lpAmount) {
        require(msg.value > 0 && amount1 > 0, 'PeppSwap: INVALID_AMOUNT');
        address _token = token;        // gas savings
        uint reserve0_ = (address(this).balance).sub(msg.value);
        uint reserve1_ = IERC20(_token).balanceOf(address(this));
        uint _totalSupply = totalSupply;

        IERC20(_token).safeTransferFrom(from, address(this), amount1);
        amount1 = (IERC20(_token).balanceOf(address(this))).sub(reserve1_);

        uint amount0;
        if(_totalSupply > 0){
            amount0 = ( amount1.mul( reserve0_ ) ).div(reserve1_);
            require(amount0 <= msg.value, 'PeppSwap: SLIPPAGE_REACHED_DESIRED');
            require(amount0 >= amount0min, 'PeppSwap: SLIPPAGE_REACHED_MIN');
        } 
        else {
            amount0 = msg.value;
        }

        if (_totalSupply == 0) {
            lpAmount = Math.sqrt(amount0.mul(amount1)).sub(10**3);
           _mint(address(0), 10**3);
        } else {
            lpAmount = Math.min(amount0.mul(_totalSupply) / reserve0_, amount1.mul(_totalSupply) / reserve1_);
        }
        
        require(lpAmount > 0, 'PeppSwap: INSUFFICIENT_LIQUIDITY_MINTED');

        // refund only if value is > 1000 wei
        if(msg.value > amount0.add(1000)){
            safeTransferETH(from, msg.value.sub(amount0));
        }

        uint _fee = IFactory(factory).lpFee();
        if(_fee > 0){
            uint _feeAmount = ( lpAmount.mul(_fee) ).div(10**4);
            _mint(IFactory(factory).feeTo(), _feeAmount);
            lpAmount = lpAmount.sub(_feeAmount);
        }

        _mint(to, lpAmount);

        emit Mint(from, amount0, amount1);
        emit Sync(reserve0_.add(amount0), reserve1_.add(amount1));
    }

    function addLPfromFactory(uint amount0min, uint amount1, address from, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint lpAmount) {
        require(msg.sender == factory, 'PeppSwap: FORBIDDEN');
        lpAmount = _addLPinternal(amount0min, amount1, from, to);
    }

    function addLP(uint amount0min, uint amount1, address to, uint deadline) payable external ensure(deadline) nonReentrant returns (uint lpAmount) {
        lpAmount = _addLPinternal(amount0min, amount1, msg.sender, to);
    }

    function removeLiquidity(uint lpAmount, address to, uint deadline) external ensure(deadline) nonReentrant returns (uint amount0, uint amount1) {
        require(lpAmount > 0, 'PeppSwap: INSUFFICIENT_LIQUIDITY');
        address _token = token;        // gas savings

        uint reserve0_ = address(this).balance;
        uint reserve1_ = IERC20(_token).balanceOf(address(this));

        uint _totalSupply = totalSupply; 
        amount0 = lpAmount.mul(reserve0_) / _totalSupply; 
        amount1 = lpAmount.mul(reserve1_) / _totalSupply; 
        require(amount0 > 0 && amount1 > 0, 'PeppSwap: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(msg.sender, lpAmount);

        IERC20(_token).safeTransfer(to, amount1);
        safeTransferETH(to, amount0);

        emit Burn(msg.sender, amount0, amount1, to);
        emit Sync(reserve0_.sub(amount0), reserve1_.sub(amount1));
    }
    
}