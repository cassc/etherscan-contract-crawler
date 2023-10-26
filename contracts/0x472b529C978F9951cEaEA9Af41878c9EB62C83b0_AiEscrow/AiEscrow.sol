/**
 *Submitted for verification at Etherscan.io on 2023-10-24
*/

//SPDX-License-Identifier:Unlicensed
pragma solidity 0.8.17;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

contract AiEscrow is Context, IERC20, Ownable{

    uint256 private _totalSupply; 
    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string private _name; 
    string private _symbol;
    uint8 private _decimals;

        
    uint256 private _buyTax; 
    uint256 private _sellTax; 
    uint256 private _tokensToSell;
    bool private _sellStatus;
    bool private _inSwapAndLiquify;
    mapping(address => bool) private _excludedFromFee;

    address payable private _marketingWallet;

    mapping(address => bool) private _marketPairs;

    bool private _tradingEnabled;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public currentRouter; 
    address public immutable uniswapV2Pair;
    event Log(string, uint256);
    event AuditLog(string, address);
    event SellStatusLog(string,bool);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event SwapTokensForETH(uint256 amountIn, address[] path);
    event LimitEnabled(uint256 atBlock, bool limitEnabled);
    
    

    constructor() Ownable(_msgSender()){

        _decimals = 18;
        _totalSupply = 20_000_000 * 10** _decimals;
        _name = "AiESCROW";
        _symbol = "AiEBOT";
        _balances[_msgSender()] = _totalSupply;
                    
        _tokensToSell = 20_000 * 10** _decimals; // 0.1% of total supply
        _excludedFromFee[_msgSender()] = true;
        _excludedFromFee[address(this)] = true; 
        _tradingEnabled = false;
        _sellStatus = false;

        _buyTax = 4; // initial buy tax 4%
        _sellTax = 4; // initial sell tax 4%

        _marketingWallet = payable(_msgSender());

        currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(currentRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()) 
                        .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _marketPairs[uniswapV2Pair] = true; 

        emit Transfer(address(0), _msgSender(), _totalSupply);
        emit LimitEnabled(block.number, true);
    }

    modifier secureSwapAndLiquify() {

        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    function name() external view returns (string memory){

        return _name;
    }

    function symbol() external view returns (string memory){

        return _symbol;
    }

  
    function totalSupply() external view returns (uint256){

        return _totalSupply;
    }

    function decimals() external view returns (uint8){

        return _decimals;
    }

    function balanceOf(address account) public view returns (uint256){

        return _balances[account];
        
    }

    function transfer(address to, uint256 amount) external returns (bool){

        _transfer(_msgSender(),to,amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256){

        return _allowances[owner][spender];

    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
        ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(!_excludedFromFee[from] && !_excludedFromFee[to]){
         
            if(_marketPairs[from] || _marketPairs[to]){

                require(_tradingEnabled,"Owner must enable trading");
            }
        }


        if(
            !_inSwapAndLiquify && 
            _sellStatus &&
            !_marketPairs[from]
        ){

            swapAndLiquify();
        }


        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 caculatedAmount = handleFees(from,to,amount);
        _balances[from] = fromBalance - amount;
        _balances[to] += caculatedAmount;
        emit Transfer(from, to, amount);

    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function handleFees(address from,address to,uint256 amount_) private returns(uint256) {

        uint256 feeToTake = 0;

        if(_excludedFromFee[from] || _excludedFromFee[to]){

            return amount_;
        }
        

        if(!_marketPairs[from] && !_marketPairs[to]){

            return amount_;
        }

        if(_marketPairs[from]){

            feeToTake = (amount_ * _buyTax) / 100; 

        }

        if(_marketPairs[to]){

            feeToTake = (amount_ * _sellTax) / 100; 

        }

        _balances[address(this)] += feeToTake;
        uint256 amountAfterFee = amount_ - feeToTake;
        return amountAfterFee;

    }

    function excludeFromFee(address account) external onlyOwner{

        _excludedFromFee[account] = true;
        emit AuditLog(
            "We have excluded the following wallet from paying tax",
            account
        );
        
    }

    function includeFee(address account) external onlyOwner{

        _excludedFromFee[account] = false;
        emit AuditLog("We have included the following wallet to pay tax", account);

    }

    function isExcludedFromFee(address account) external view returns(bool){

        return _excludedFromFee[account];

    }


    function setTokensToSell(uint256 amount_) external onlyOwner{

        _tokensToSell = amount_ * 10** _decimals;
        emit Log(
            "tokens to sell has been updated",
            _tokensToSell
        );
        
    }

    function tokensToSell() external view returns(uint256){

        return _tokensToSell;

    }

    function updateSellStatus(bool status_) external onlyOwner{

        _sellStatus = status_;
        emit SellStatusLog("Token Selling status has changed to", status_);
    }

    function sellStatus() external view returns(bool){

        return _sellStatus;
    }


    function setMarketingWallet(address wallet_) external onlyOwner{

        require(
            wallet_ != address(0),
            "cannot be ZERO wallet"
        );
        _marketingWallet = payable(wallet_);

        emit AuditLog("Marketing wallet updated", wallet_);
    }


    function marketingWallet() external view returns(address){

        return _marketingWallet;

    }

    function swapAndLiquify() private secureSwapAndLiquify{

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractETHBalance = address(this).balance;
        uint256 tokenAmountToSell;

        if(contractTokenBalance == 0){

            return;
        }

        if(contractTokenBalance >= _tokensToSell){

            tokenAmountToSell = _tokensToSell;

        }

        if(contractTokenBalance < _tokensToSell){

            tokenAmountToSell = contractTokenBalance;
        }

        uint256 tokensForLiquidity = (tokenAmountToSell * 10) / 100; // 10% of tokens for liquidity

        uint256 remainingTokens = tokenAmountToSell - tokensForLiquidity;

        swapTokensForEth(remainingTokens);

        uint256 ETHCollected = address(this).balance - contractETHBalance;
        
        uint256 ETHForLiquidity = (ETHCollected * 10) / 100; // 10% of ETH for liquidity
        uint256 ETHForMarketing = (ETHCollected * 80) / 100; // 80% of ETH for marketing

        addLiquidity(tokensForLiquidity,ETHForLiquidity); 

        transferToAddressETH(_marketingWallet,ETHForMarketing);


        if(address(this).balance != 0){

            uint256 remainingETH = address(this).balance;
            transferToAddressETH(_marketingWallet,remainingETH);

        }


    }

    function swapAndLiquifyExternal() external onlyOwner{

        swapAndLiquify();
    }

    function swapTokensForEth(uint256 tokenAmount) private {

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

        emit SwapTokensForETH(tokenAmount, path);


    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private { 


        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private{
        recipient.transfer(amount);
    }



    function setMarketPairs(address marketPair_, bool value_) external onlyOwner{

        _marketPairs[marketPair_] = value_;
    }

    function marketPairs(address marketPair_) public view returns(bool){

        return _marketPairs[marketPair_];
    }

    
    function enableBuyTax() external onlyOwner{

        _buyTax = 4;
    }

    function disableBuyTax() external onlyOwner{

        _buyTax = 0;
    }

    function enableSellTax() external onlyOwner{

        _sellTax = 4;
    }

    function disableSellTax() external onlyOwner{

        _sellTax = 0;
    }

    function buyTax() public view returns(uint256){

        return _buyTax;
    }

    function sellTax() public view returns(uint256){

        return _sellTax;
    }

    function enableTrading() external onlyOwner{

        require(!_tradingEnabled,"trading is already active");
        _tradingEnabled = true;
        _sellStatus = true;
    }

    function tradingEnabled() public view returns(bool){

        return _tradingEnabled;
    }
    
    receive() external payable {}

}