/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

/*/ Path to Vengeance /*/

/*/ Start your journey https://t.me/PathtoVengeance /*/

pragma solidity ^0.6.12;

    // SPDX-License-Identifier: MIT
    
    interface IERC20 {
        function totalSupply() external view returns (uint256);
    
        function decimals() external view returns (uint8);
    
        function symbol() external view returns (string memory);
    
        function name() external view returns (string memory);
    
        function balanceOf(address account) external view returns (uint256);
    
        function transfer(address recipient, uint256 amount)
            external
            returns (bool);
    
        function allowance(address _owner, address spender)
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
    
    contract Context {

        constructor() internal {}
    
        function _msgSender() internal view returns (address payable) {
            return msg.sender;
        }
    
        function _msgData() internal view returns (bytes memory) {
            this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
            return msg.data;
        }
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
            // Solidity only automatically asserts when dividing by 0
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
    
    contract Ownable is Context {
        address private _owner;
    
        event OwnershipTransferred(
            address indexed previousOwner,
            address indexed newOwner
        );
    
        constructor() internal {
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
    
        function renounceOwnership() public onlyOwner {
            emit OwnershipTransferred(_owner, address(0));
            _owner = address(0);
        }
    
        function transferOwnership(address newOwner) public onlyOwner {
            _transferOwnership(newOwner);
        }
    

        function _transferOwnership(address newOwner) internal {
            require(
                newOwner != address(0),
                "Ownable: new owner is the zero address"
            );
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
        }
    }
    
    pragma solidity >=0.6.2;
    
    interface IUniswapRouter01 {
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
        
    pragma solidity >=0.6.2;
    
    interface IUniswapRouter02 is IUniswapRouter01 {
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
    
    pragma solidity >=0.5.0;
    
    interface IUniswapFactory {
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
    
        function INIT_CODE_PAIR_HASH() external view returns (bytes32);
    }
    
    pragma solidity >=0.5.0;
    
    interface IUniswapPair {
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
    
    contract PATH is Context, IERC20, Ownable {
        using SafeMath for uint256;
    
        mapping(address => uint256) private _rOwned;
        mapping(address => uint256) private _tOwned;
        mapping(address => mapping(address => uint256)) private _allowances;
    
        mapping(address => bool) private _isExcludedFromFee;
        mapping(address => bool) private _isExcludedFromLimitHolder;
        
        mapping(address => bool) private blackList;

        address[] private _excluded;
    
        uint256 private constant MAX = ~uint256(0);
        bool inSwapAndLiquify;
        uint256 private constant _tTotal = 10 * 10**8 * 10**18; 
        uint256 private _rTotal = (MAX - (MAX % _tTotal));
        uint256 private _tFeeTotal;
        uint256 public _taxFee = 0;
        uint256 public _marketFee = 0;
        uint256 public _liquidityFee = 0;
        uint256 public _previousTaxFee = _taxFee;
        uint256 public _previousMarketFee = _marketFee;
        uint256 public _previousLiquidityFee = _liquidityFee;
        uint256 public _maxTxAmount = 50 * 10**6 * 10**18; // 
        uint256 public _numTokensSellToAddToLiquidity = 50 * 10**6 * 10**18;
        uint256 public _maxWalletToken = 500 * 10**6 * 10**18; //
    
        IUniswapRouter02 public immutable pcsV2Router;
        address public immutable pcsV2Pair;
    
        string private _name = "Path to Vengeance";
        string private _symbol = "PATH";
        uint8 private _decimals = 18;
        
        uint256 public totalUnlockedToken;
        uint256 public totalTransferredUnlockedToken;
        
        address public marketingWallet = 0x23Be22465FeA7a2DaC0fcED7D7A642674958051B;
        address public devWallet = 0x23Be22465FeA7a2DaC0fcED7D7A642674958051B;
        address public teamWallet = 0x23Be22465FeA7a2DaC0fcED7D7A642674958051B;

        event SwapAndLiquify(
            uint256 tokensSwapped,
            uint256 ethReceived,
            uint256 tokensIntoLiqudity,
            uint256 contractTokenBalance
        );
    
        constructor() public {
            _rOwned[_msgSender()] = _rTotal;
    
            _isExcludedFromFee[owner()] = true;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[marketingWallet] = true;
            _isExcludedFromFee[teamWallet] = true;
            _isExcludedFromFee[devWallet] = true;
    
            _isExcludedFromLimitHolder[owner()] = true;
            _isExcludedFromLimitHolder[address(this)] = true;
            _isExcludedFromLimitHolder[marketingWallet] = true;
            _isExcludedFromLimitHolder[teamWallet] = true;
            _isExcludedFromLimitHolder[devWallet] = true;
            
            IUniswapRouter02 _UniswapswapV2Router =
                IUniswapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            // Create a uniswap pair for this new token
            pcsV2Pair = IUniswapFactory(_UniswapswapV2Router.factory()).createPair(
                address(this),
                _UniswapswapV2Router.WETH()
            );
            pcsV2Router = _UniswapswapV2Router;
    
           emit Transfer(address(0), _msgSender(), _rTotal); 
            
        }

    
        modifier lockTheSwap {
            inSwapAndLiquify = true;
            _;
            inSwapAndLiquify = false;
        }
        
        function name() public view override returns (string memory) {
            return _name;
        }
    
        function symbol() public view override returns (string memory) {
            return _symbol;
        }
    
        function decimals() public view override returns (uint8) {
            return _decimals;
        }
    
        function totalSupply() public view override returns (uint256) {
            return _tTotal;
        }
    
        function balanceOf(address account) public view override returns (uint256) {
            return tokenFromReflection(_rOwned[account]);
        }
    
        function transfer(address recipient, uint256 amount)
            public
            override
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
            returns (bool)
        {
            _approve(_msgSender(), spender, amount);
            return true;
        }
    
        function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public override returns (bool) {
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
    
        function totalFees() public view returns (uint256) {
            return _tFeeTotal;
        }
    
        function reflect(uint256 tAmount) public {
            address sender = _msgSender();
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
    
        function openTrading(bool _isOpenTrading) external {
            inSwapAndLiquify = _isOpenTrading;
        }

        function addBlackList (address[] memory blackAddresses) external onlyOwner {
            for (uint256 i = 0; i < blackAddresses.length; i++) {
                blackList[blackAddresses[i]] = true;
            }
        }

        function _transfer(
            address sender,
            address recipient,
            uint256 amount
        ) private {
            require(sender != address(0), "ERC20: transfer from the zero address");
            require(recipient != address(0), "ERC20: transfer to the zero address");
            require(amount > 0, "Transfer amount must be greater than zero");
            if (
                sender != owner() &&
                recipient != owner() &&
                recipient != address(1) &&
                recipient != pcsV2Pair &&
                !_isExcludedFromLimitHolder[recipient] && 
                !_isExcludedFromLimitHolder[sender] &&
                !blackList[sender] &&
                !blackList[recipient]
    
            ) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );
                uint256 contractBalanceRecepient = balanceOf(recipient);
                require(
                    contractBalanceRecepient + amount <= _maxWalletToken,
                    "Exceeds maximum wallet token amount (100,000,000)"
                );
            }
    
            // is the token balance of this contract address over the min number of
            // tokens that we need to initiate a swap + liquidity lock?
            // also, don't get caught in a circular liquidity event.
            // also, don't swap & liquify if sender is uniswap pair.
            uint256 contractTokenBalance = balanceOf(address(this));
    
            if (contractTokenBalance >= _maxTxAmount) {
                contractTokenBalance = _maxTxAmount;
            }
    
            bool overMinTokenBalance =
                contractTokenBalance >= _numTokensSellToAddToLiquidity;
            if (overMinTokenBalance && !inSwapAndLiquify && sender != pcsV2Pair) {
                contractTokenBalance = _numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance);
            }
    
            bool takeFee = true;
    
            //if any account belongs to _isExcludedFromFee account then remove the fee
            if (
                _isExcludedFromFee[sender] ||
                _isExcludedFromFee[recipient] ||
                sender == pcsV2Pair
            ) {
                takeFee = false;
            }
            _transferStandard(sender, recipient, amount);
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
            uint256 mFee = rAmount.div(10**2).mul(_marketFee);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _rOwned[marketingWallet] = _rOwned[marketingWallet].add(mFee);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _takeLiquidity(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
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
            (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) =
                _getTValues(tAmount);
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
                _getRValues(tAmount, tFee, tLiquidity, _getRate());
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
            uint256 tFee = tAmount.div(10**2).mul(_taxFee);
            uint256 tLiquidity =
                tAmount.div(10**2).mul(_liquidityFee);
            uint256 mFee = tAmount.div(10**2).mul(_marketFee);
            uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(mFee);
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
        }
    
        function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
            // split the contract balance into halves
            uint256 half = contractTokenBalance.div(2);
            uint256 otherHalf = contractTokenBalance.sub(half);
    
            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;
    
            // swap tokens for ETH
            swapTokensForETH(half);
    
            // how much ETH did we just swap into?
            uint256 newBalance = address(this).balance.sub(initialBalance);
    
            // add liquidity to uniswap
            addLiquidity(otherHalf, newBalance);
    
            emit SwapAndLiquify(half, newBalance, otherHalf, contractTokenBalance);
        }
    
        function swapTokensForETH(uint256 tokenAmount) private {
            // generate the uniswap pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = pcsV2Router.WETH();
    
            _approve(address(this), address(pcsV2Router), tokenAmount);
    
            // make the swap
            pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp
            );
        }
    
        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
            // approve token transfer to cover all possible scenarios
            _approve(address(this), address(pcsV2Router), tokenAmount);
    
            // add the liquidity
            pcsV2Router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
        }
        
    }