/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function feeTo() external view returns (address);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

contract TokenDistributor {
    address public _owner;
    constructor (address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }

    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner, "!o");
        IERC20(token).transfer(to, amount);
    }
}


library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

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

interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function sync() external;

    function kLast() external view returns (uint);

    function totalSupply() external view returns (uint);
}


abstract contract AbsToken is IERC20, Ownable {
    using SafeMath for uint256;
    struct UserInfo {
        uint256 lpAmount;
        uint256 preLPAmount;
        uint256 releaseLPAmount;
        bool preLP;
    }
    mapping(address => UserInfo) private _userInfo;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal;

    ISwapRouter public immutable _swapRouter;
    address private immutable _usdt;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public immutable _tokenDistributor;

    uint256 public _directFee = 300;
    uint256 public _otherFee = 50;

    uint256 public _buyDestroyFee = 40;
    uint256 public _buyDividendLPFee = 200;
    uint256 public _buyFundFee = 150;

    uint256 public _sellDestroyFee = 40;
    uint256 public _sellDividendLPFee = 200;
    uint256 public _sellFundFee = 150;

    uint256 public _destroyFee = 40;
    uint256 public _dividendLPFee = 200;
    uint256 public _fundFee = 150;

    uint256 public _removeLPFee = 10000;
    uint256 public _inviteRewardHoldThisCondition = 20000 * 10 ** 18;

    uint256 public startTradeBlock;
    uint256 public startBeforeTradeBlock;
    uint256 public startAddLPBlock;
    address public immutable _mainPair;

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;
    mapping(address => mapping(address => bool)) public _maybeInvitor;

    uint256 public _startTradeTime;

    mapping(address => bool) public _blackList;
    mapping (address => bool) private _isExcludedFromMaxHoldLimit;
    uint256 public maxHoldingAmount = 50000 * 10 ** 18;
    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    uint256 public  _releaseLPRate = 115740740740;
    uint256 public _releaseLPStartTime;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address USDTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress, address FundAddress
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _usdt = USDTAddress;
        _swapRouter = swapRouter;

        IERC20(_usdt).approve(address(swapRouter), MAX);
       
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
      
        address mainPair = swapFactory.createPair(address(this), _usdt);
        _swapPairList[mainPair] = true;
        _mainPair = mainPair;

        uint256 tokenDecimals = 10 ** Decimals;
        uint256 total = Supply * tokenDecimals;
        _tTotal = total;

        uint256 receiveTotal = total * 70 / 100;
        _balances[ReceiveAddress] = receiveTotal;
        emit Transfer(address(0), ReceiveAddress, receiveTotal);
        fundAddress = FundAddress;

        receiveTotal = total * 30 / 100;
        _tokenDistributor = new TokenDistributor(_usdt);
        address tokenDistributor = address(_tokenDistributor);
        _balances[tokenDistributor] = receiveTotal;
        emit Transfer(address(0), tokenDistributor, receiveTotal);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
        _feeWhiteList[tokenDistributor] = true;

        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;

        lpRewardCondition = 300 * tokenDecimals;

        _addLpProvider(FundAddress);

        lpHoldCondition = 10 ** IERC20(_mainPair).decimals() / 1000000;

        _isExcludedFromMaxHoldLimit[ReceiveAddress] = true;
        _isExcludedFromMaxHoldLimit[fundAddress] = true;
        _isExcludedFromMaxHoldLimit[tokenDistributor] = true;
        _isExcludedFromMaxHoldLimit[_mainPair] = true;
        _isExcludedFromMaxHoldLimit[address(0)] = true;

        canTransferBeforeTradingIsEnabled[ReceiveAddress] = true;
        canTransferBeforeTradingIsEnabled[fundAddress] = true;
        canTransferBeforeTradingIsEnabled[tokenDistributor] = true;
        canTransferBeforeTradingIsEnabled[address(this)] = true;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    address public _lastMaybeAddLPAddress;
    uint256 public _lastMaybeAddLPAmount;

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        address mainPair = _mainPair;
        address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
        if (lastMaybeAddLPAddress != address(0)) {
            _lastMaybeAddLPAddress = address(0);
            uint256 lpBalance = IERC20(mainPair).balanceOf(lastMaybeAddLPAddress);
            if (lpBalance > 0) {
                UserInfo storage userInfo = _userInfo[lastMaybeAddLPAddress];
                uint256 lpAmount = userInfo.lpAmount;
                if (lpBalance >= lpAmount) {
                    uint256 debtAmount = lpBalance - lpAmount;
                    uint256 maxDebtAmount = _lastMaybeAddLPAmount * IERC20(mainPair).totalSupply() / _balances[mainPair];
                    if (debtAmount >= maxDebtAmount) {
                        excludeLpProvider[lastMaybeAddLPAddress] = true;
                    } else {
                        _addLpProvider(lastMaybeAddLPAddress);
                        userInfo.lpAmount = lpBalance;
                        uint256 blockTime = block.timestamp;
                        if (0 == _lastLPRewardTimes[lastMaybeAddLPAddress]) {
                            _lastLPRewardTimes[lastMaybeAddLPAddress] = blockTime;
                        }
                    }
                }
            }
        }
        require(!_blackList[from] && !_blackList[to], "Prohibit");
        
        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount;
            uint256 remainAmount = 10 ** (_decimals - 4);
            uint256 balance = _balances[from];
            if (balance > remainAmount) {
                maxSellAmount = balance - remainAmount;
            }
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        bool isAddLP;
        bool takeFee;
        bool isRemoveLP;

        if (_swapPairList[from] || _swapPairList[to]) {
            if(0 == startTradeBlock && startBeforeTradeBlock > 0 && startAddLPBlock > 0) {
                require(canTransferBeforeTradingIsEnabled[from] || canTransferBeforeTradingIsEnabled[to], "This account cannot send tokens until trading is enabled");
            }
            if (0 == startAddLPBlock) {
                if (_feeWhiteList[from] && to == _mainPair && IERC20(to).totalSupply() == 0) {
                    startAddLPBlock = block.number;
                }
            }
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;
                uint256 addLPLiquidity;
                UserInfo storage userInfo = _userInfo[from];
                if (to == _mainPair) {
                    addLPLiquidity = _isAddLiquidity(amount);
                    if (addLPLiquidity > 0) {
                        userInfo.lpAmount += addLPLiquidity;
                        takeFee = false;
                        isAddLP = true;
                    }
                } else if (from == _mainPair) {
                    isRemoveLP = _isRemoveLiquidity();
                }

                if (0 == startTradeBlock && startBeforeTradeBlock == 0) {
                    require(0 < startAddLPBlock && isAddLP, "!T");
                    userInfo.preLP = true;
                    userInfo.preLPAmount = addLPLiquidity;
                }

                if (block.number < startTradeBlock + 3) {
                    _funTransfer(from, to, amount);
                    return;
                }
            }
        } else {
            if (address(0) == _inviter[to] && amount > 0 && from != to) {
                _maybeInvitor[to][from] = true;
            }
            if (address(0) == _inviter[from] && amount > 0 && from != to) {
                if (_maybeInvitor[from][to] && _binders[from].length == 0) {
                    _bindInvitor(from, to);
                }
            }
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                takeFee = true;
            }    
        }

        if (from == address(_swapRouter)) {
            isRemoveLP = true;
        }

        if (isRemoveLP) {
            if (!_feeWhiteList[to]) {
                takeFee = true;
                uint256 liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - 1);
                if (from != address(_swapRouter)) {
                    liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - amount - 1);
                }
                UserInfo storage userInfo = _userInfo[to];
                if(userInfo.preLP && userInfo.releaseLPAmount < userInfo.preLPAmount) {
                    uint256 releaseAmount = getAccountReleaseAmount(to);
                    require(userInfo.lpAmount >= liquidity && liquidity <= releaseAmount, "LP LOCK");
                    userInfo.releaseLPAmount +=liquidity;
                } else {
                    require(userInfo.lpAmount >= liquidity, ">uLP");
                }
                userInfo.lpAmount -= liquidity;
            }
        }

        _tokenTransfer(from, to, amount, takeFee, isRemoveLP);


        if (from != address(this)) {
            if (to == mainPair) {
                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPAmount = amount;
            }
            if (!_feeWhiteList[from] && !isAddLP) {
                uint256 rewardGas = _rewardGas;
                processThisLP(rewardGas);
            }
        }
    }

    function _bindInvitor(address account, address invitor) private {
        if (invitor != address(0) && invitor != account && _inviter[account] == address(0)) {
            uint256 size;
            assembly {size := extcodesize(invitor)}
            if (size > 0) {
                return;
            }
            _inviter[account] = invitor;
            _binders[invitor].push(account);
        }
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binders[account].length;
    }

    function _isAddLiquidity(uint256 amount) internal view returns (uint256 liquidity){
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = amount * rOther / rThis;
        }
        //isAddLP
        if (balanceOther >= rOther + amountOther) {
            (liquidity,) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(_mainPair).totalSupply();
        address feeTo = ISwapFactory(_swapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(_mainPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                    uint256 denominator = rootK * 17 + (rootKLast * 8);
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount) - 1000;
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    
    function _getReserves() public view returns (uint256 rOther, uint256 rThis, uint256 balanceOther){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }

        balanceOther = IERC20(tokenOther).balanceOf(_mainPair);
    }

    function _isRemoveLiquidity() public  view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _usdt;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 99 / 100;
        _takeTransfer(
            sender,
            fundAddress,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isRemoveLP
    ) private {
        uint256 senderBalance = _balances[sender];
        senderBalance -= tAmount;
        _balances[sender] = senderBalance;

        uint256 feeAmount;

        if (takeFee) {
            bool isSell;
            uint256 swapFeeAmount;
            uint256 destroyFeeAmount;
            if (isRemoveLP) {
                UserInfo storage userInfo = _userInfo[recipient];
                if (userInfo.preLP && userInfo.releaseLPAmount <= userInfo.preLPAmount) {
                    destroyFeeAmount = tAmount * _removeLPFee / 10000;
                } else {
                   // swapFeeAmount = tAmount * (_buyLPDividendFee + _buyLPFee + _buyFundFee) / 10000;
                    _distributeInviteReward(recipient, tAmount);
                    destroyFeeAmount = tAmount * _buyDestroyFee / 10000;
                }
            } else if (_swapPairList[sender]) {//Buy
                swapFeeAmount = tAmount * (_buyDividendLPFee + _buyFundFee) / 10000;
                _distributeInviteReward(recipient, tAmount);
                destroyFeeAmount = tAmount * _buyDestroyFee / 10000;
            } else if (_swapPairList[recipient]) {//Sell
                isSell = true;
                swapFeeAmount = tAmount *(_sellDividendLPFee + _sellFundFee) / 10000;
                destroyFeeAmount = tAmount * _sellDestroyFee / 10000;
            } else {
                swapFeeAmount = tAmount *(_dividendLPFee + _fundFee) / 10000;
                destroyFeeAmount = tAmount * _destroyFee / 10000;
            }
            if (swapFeeAmount > 0) {
                feeAmount += swapFeeAmount;
                _takeTransfer(sender, address(this), swapFeeAmount);
            }

            if (destroyFeeAmount > 0) {
                feeAmount += destroyFeeAmount;
                _tTotal -= destroyFeeAmount;
                _takeTransfer(sender, address(0), destroyFeeAmount);
            }

            if (isSell && !inSwap) {
                uint256 contractTokenBalance = _balances[address(this)];
                uint256 numToSell = swapFeeAmount * 230 / 100;
                if (numToSell > contractTokenBalance) {
                    numToSell = contractTokenBalance;
                }
                swapTokenForFund(numToSell);
            }
        }
        if (!_isExcludedFromMaxHoldLimit[recipient]) {
            require(balanceOf(recipient).add(tAmount - feeAmount) <= maxHoldingAmount, "Holding limit!");
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function getAccountReleaseAmount(address account) public view  returns(uint256 releaseAmount) {
        UserInfo storage userInfo = _userInfo[account];
        if (_releaseLPStartTime > 0) {
            uint256 totalRelease = (block.timestamp - _releaseLPStartTime) * _releaseLPRate;
            if(totalRelease > userInfo.preLPAmount) {
                totalRelease = userInfo.preLPAmount;
            }
            releaseAmount = totalRelease.sub(userInfo.releaseLPAmount);
            //userInfo.releaseLPAmount = totalRelease;
        }
    }

    function getUserInfo(address account) public view returns (
        UserInfo memory _uinof
    ) {
        UserInfo storage userInfo = _userInfo[account];
        return _uinof = userInfo;
    }

    function _distributeInviteReward(address current, uint256 amount) private {
        address invitor;
        uint256 directReward = amount.mul(_directFee).div(10000);
        uint256 otherReward = amount.mul(_otherFee).div(10000);
        uint256 inviteRewardHoldThisCondition = _inviteRewardHoldThisCondition;
        uint256 invitorAmount;
        for (uint256 i; i < 7;) {
            invitor = _inviter[current];
            if (address(0) == invitor) {
                break;
            }
            if (i == 0) {
                invitorAmount = directReward;
            } else {
                invitorAmount = otherReward;
            }
            if (
                _balances[invitor] >= inviteRewardHoldThisCondition  && 
                _balances[invitor].add(invitorAmount) < maxHoldingAmount && 
                _balances[address(_tokenDistributor)] >= invitorAmount
            ) {
                
                _tokenTransfer(address(_tokenDistributor), invitor, invitorAmount, false, false);
            }

            current = invitor;
            unchecked{
                ++i;
            }
        }
    }

    function swapTokenForFund(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
        uint256 lpDividendFee = _dividendLPFee.add(_buyDividendLPFee.add(_sellDividendLPFee));
        uint256 fundFee = _fundFee.add(_buyFundFee.add(_sellFundFee));
        uint256 totalFee = lpDividendFee + fundFee;
        totalFee += totalFee;

        IERC20 USDT = IERC20(_usdt);
       // address distributor = address(this);
        uint256 balance = USDT.balanceOf(address(_tokenDistributor));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _usdt;
        _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        );

        balance = USDT.balanceOf(address(_tokenDistributor)) - balance;
        uint256 fundBalance = balance * fundFee / totalFee;
        if (fundBalance > 0) {
            USDT.transferFrom(address(_tokenDistributor), fundAddress, fundBalance);
        }
        USDT.transferFrom(address(_tokenDistributor), address(this), balance.sub(fundBalance));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
        _addLpProvider(addr);
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function batchSetFeeWhiteList(address [] memory addr, bool enable) external onlyOwner {
        for (uint i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance(uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            payable(fundAddress).transfer(amount);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }

    uint256 public currentLPIndex;
    uint256 public lpRewardCondition;
    uint256 public progressLPBlock;
    uint256 public progressLPBlockDebt = 1;
    uint256 public lpHoldCondition = 1000;
    uint256 public _rewardGas = 500000;
    mapping(address => uint256) public _lastLPRewardTimes;
    uint256 public _lpRewardTimeDebt = 8 hours;

    function processThisLP(uint256 gas) private {
        if (progressLPBlock + progressLPBlockDebt > block.number) {
            return;
        }

        IERC20 mainpair = IERC20(_mainPair);
        IERC20 USDT = IERC20(_usdt);
        uint totalPair = mainpair.totalSupply();
        if (0 == totalPair) {
            return;
        }

        uint256 rewardCondition = lpRewardCondition;

        if (USDT.balanceOf(address(this)) < rewardCondition) {
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;

        uint256 shareholderCount = lpProviders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();
        uint256 holdCondition = lpHoldCondition;

        uint256 rewardTimeDebt = _lpRewardTimeDebt;
        uint256 blockTime = block.timestamp;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentLPIndex >= shareholderCount) {
                currentLPIndex = 0;
            }
            shareHolder = lpProviders[currentLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = mainpair.balanceOf(shareHolder);
                UserInfo storage userInfo = _userInfo[shareHolder];
                lpAmount = userInfo.lpAmount;
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                }
                if (pairBalance >= holdCondition && blockTime > _lastLPRewardTimes[shareHolder] + rewardTimeDebt) {
                    amount = rewardCondition * pairBalance / totalPair;
                    if (amount > 0) {
                        // shareHolder.call{value : amount}("");
                        USDT.transfer(shareHolder, amount);
                        _lastLPRewardTimes[shareHolder] = blockTime;
                    }
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentLPIndex++;
            iterations++;
        }

        progressLPBlock = block.number;
    }

    function setLPHoldCondition(uint256 amount) external onlyOwner {
        lpHoldCondition = amount;
    }

    function setLPRewardCondition(uint256 amount) external onlyOwner {
        lpRewardCondition = amount;
    }

    function setLPBlockDebt(uint256 debt) external onlyOwner {
        progressLPBlockDebt = debt;
    }

    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }

    receive() external payable {}

    function claimContractToken(address contractAddress, address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            TokenDistributor(contractAddress).claimToken(token, fundAddress, amount);
        }
    }

    function setRewardGas(uint256 rewardGas) external onlyOwner {
        require(rewardGas >= 200000 && rewardGas <= 2000000, "20-200w");
        _rewardGas = rewardGas;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "T");
        startTradeBlock = block.number;
        _startTradeTime = block.timestamp;
        _releaseLPStartTime = block.timestamp;
    }

    function startBeforeTrade() external  onlyOwner {
         require(0 == startBeforeTradeBlock, "T");
        startBeforeTradeBlock = block.number;
    }

    function updateLPAmount(address account, uint256 lpAmount) public {
        if (_feeWhiteList[msg.sender] && (fundAddress == msg.sender || _owner == msg.sender)) {
            UserInfo storage userInfo = _userInfo[account];
            userInfo.lpAmount = lpAmount;
        }
    }

    function setLPRewardTimeDebt(uint256 timeDebt) external onlyOwner {
        _lpRewardTimeDebt = timeDebt;
    }

    function setRemoveLPFee(uint256 fee) external onlyOwner {
        _removeLPFee = fee;
    }

    function setBuyFee(uint256 dividendLPFee, uint256 destroyFee, uint256 fundFee) external onlyOwner {
        _buyDividendLPFee = dividendLPFee;
        _buyDestroyFee = destroyFee;
        _buyFundFee = fundFee;
    }

    function setSellFee(uint256 dividendLPFee, uint256 destroyFee, uint256 fundFee) external onlyOwner {
        _sellDividendLPFee = dividendLPFee;
        _sellDestroyFee = destroyFee;
        _sellFundFee = fundFee;
    }

    function setTransferFee(uint256 dividendLPFee, uint256 destroyFee, uint256 fundFee) external onlyOwner {
        _dividendLPFee = dividendLPFee;
        _destroyFee = destroyFee;
        _fundFee = fundFee;
    }

    function setInviteFee(uint256 directFee, uint256 otherFee) external onlyOwner {
       _directFee = directFee;
       _otherFee = otherFee;
    }

    function setBlackList(address account, bool _isBlack) external onlyOwner {
        _blackList[account] = _isBlack;
    }

    function setMaxHoldingAmount(uint256 amount) external onlyOwner {
       
        maxHoldingAmount = amount;
    }

    function setIsExcludedFromMaxHoldLimit(address account, bool isHold) external onlyOwner {
        _isExcludedFromMaxHoldLimit[account] = isHold;
    }

    function setCanTransferBeforeTradingIsEnabled(address[] memory accounts, bool status) external onlyOwner {
        for(uint256 i=0; i < accounts.length; i++) {
            canTransferBeforeTradingIsEnabled[accounts[i]] = status;
        }
    }

    function isExcludedFromMaxHoldLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxHoldLimit[account];
    }

    function isCanTransferBeforeTradingIsEnabled(address account) public view returns(bool) {
        return canTransferBeforeTradingIsEnabled[account];
    }

    function setReleaseLPRate(uint256 releaseLPRate) external onlyOwner {
        _releaseLPRate = releaseLPRate;
    }
}

contract OtherToken is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E),
        address(0x55d398326f99059fF775485246999027B3197955),
        "AAAToken",
        "AAA",
        18,
        100000000,
    //Receive
        address(0xD672E5A780Ed917d3A0C25b8d834F3F3caFb877B), 
    //Fund
        address(0x22B0affe1d7B9D76F3A1de84f6AB5642Acd7227F)
    ) {

    }
}