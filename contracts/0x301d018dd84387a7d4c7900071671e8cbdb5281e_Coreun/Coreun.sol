/**
 *Submitted for verification at Etherscan.io on 2023-07-15
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-03
*/

// SPDX-License-Identifier: Unlicensed 

/*

    Coreun - Core
    http://coreuncore.com/

    A.k
*/

pragma solidity 0.8.19;
 

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IERC20 {


    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address recipient, uint256 amount) external returns(bool);
    function allowance(address owner, address spender) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner, address indexed spender, uint256 value);
}



abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

}

 
contract Ownable is Context {

    address private _owner = 0xb9f2DAe4F00fe40B1Ae2fA4D04a2007289c6B8B1; 
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function owner() public view returns(address) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}
 

 
contract ERC20 is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint8 private constant _decimals = 9; 
    uint256 private constant _totalSupply = 100_000_000_000_000 * 10 ** _decimals; 

    string private constant _name = "Coreun"; 
    string private constant _symbol = "Core"; 

    function name() public view virtual override returns(string memory) {
        return _name;
    }

    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns(uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased cannot be below zero"));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    constructor() {
        
        _balances[owner()] = totalSupply(); 
        emit Transfer(address(0), owner(), totalSupply());
        emit OwnershipTransferred(address(0), owner());

    }

    
}
 
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

 
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
   
}
 
interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
 
contract Coreun is ERC20 { 
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable router;
    address public immutable uniswapV2Pair;

    address public liquidityWallet = 0xb9f2DAe4F00fe40B1Ae2fA4D04a2007289c6B8B1; 
    address payable public marketingWallet = payable(0xb9f2DAe4F00fe40B1Ae2fA4D04a2007289c6B8B1);

    address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 private maxTran;
    uint256 private maxHold;

    bool private tradeOpen = false;
    bool public swapEnabled = false;
    bool public procesingFees;

    uint8 private tCount = 1;
    uint8 private tTrigger = 11; 


    struct Fees {
        uint8 buyMarketingFee;
        uint8 buyLiquidityFee;
        uint8 buyBurnFee;
        uint8 buyTotalFee;

        uint8 sellMarketingFee;
        uint8 sellLiquidityFee;
        uint8 sellBurnFee;
        uint8 sellTotalFee;
    }  

    Fees public _fees = Fees({
        buyMarketingFee: 0,
        buyLiquidityFee: 0,
        buyBurnFee: 0,
        buyTotalFee: 0,

        sellMarketingFee: 0,
        sellLiquidityFee: 0,
        sellBurnFee: 0,
        sellTotalFee: 0
    });

    mapping(address => bool) public _isFeeExempt;
    mapping(address => bool) public _isLimitExempt;
    mapping(address => bool) public _isPair;
    mapping(address => bool) public _isWhitelisted;
 
  
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );


    constructor() ERC20() {
 
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
     
        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

        maxTran = totalSupply();
        maxHold = totalSupply();

        _isLimitExempt[address(router)] = true;
        _isLimitExempt[address(uniswapV2Pair)] = true;        
        _isLimitExempt[owner()] = true;
        _isLimitExempt[address(this)] = true;

        _isFeeExempt[owner()] = true;
        _isFeeExempt[address(this)] = true;

        _isWhitelisted[owner()] = true;

        _isPair[address(uniswapV2Pair)] = true;

        approve(address(router), type(uint256).max);

    }

    receive() external payable {

    }


    // Setting the buy and sell fees - (marketing fee includes team and development fee)
    function Contract_fees(uint8 _marketingFeeBuy, 
                           uint8 _liquidityFeeBuy,
                           uint8 _burnFeeBuy,
                           uint8 _marketingFeeSell, 
                           uint8 _liquidityFeeSell,
                           uint8 _burnFeeSell) external onlyOwner{
        
        uint8 buyCheck = _marketingFeeBuy + _liquidityFeeBuy + _burnFeeBuy;
        uint8 sellCheck = _marketingFeeSell + _liquidityFeeSell + _burnFeeSell;

        require(buyCheck <= 10, "E01"); // Max possible buy fee is 10%
        require(sellCheck <= 10, "E02"); // Max possible sell fee is 10%

        _fees.buyMarketingFee = _marketingFeeBuy;
        _fees.buyLiquidityFee = _liquidityFeeBuy;
        _fees.buyBurnFee = _burnFeeBuy;

        _fees.sellMarketingFee = _marketingFeeSell;
        _fees.sellLiquidityFee = _liquidityFeeSell;
        _fees.sellBurnFee = _burnFeeSell;

        _fees.buyTotalFee = buyCheck;
        _fees.sellTotalFee = sellCheck;
     
    }

    // Setting the wallet and transaction limits must be done as a number of tokens (excluding decimals)
    function Contract_limits(uint256 maxTokensPerTransaction, uint256 maxTokensPerWallet) external onlyOwner {

        uint256 tranDecimals = maxTokensPerTransaction * 10 ** decimals();
        uint256 wallDecimals = maxTokensPerWallet * 10 ** decimals();

        require(tranDecimals >= (totalSupply() / 200), "E03" ); // Transaction limit must be 0.5% or more
        require(wallDecimals >= (totalSupply() / 200), "E04" ); // Wallet limit must be 0.5% or more

        maxTran = tranDecimals;
        maxHold = wallDecimals;

    }

    // Open trade - One way switch!
    function Contract_openTrade() external onlyOwner {
        tradeOpen = true;
        swapEnabled = true;
    }





    /*

    --------------------
    PROCESSING FUNCTIONS
    --------------------

    */

    // Add new liquidity pair address for fee tracking 
    function Process_addPair(address _newPair, bool true_or_false) external onlyOwner {
        require(_newPair != uniswapV2Pair, "E05"); // Can not remove the native pair
        _isPair[_newPair] = true_or_false;
    }

    // Toggle 'swapAndLiquify' 
    function Process_autoProcess(bool true_or_false) external onlyOwner {
        swapEnabled = true_or_false;
    }

    function Process_manualProcess(uint256 percent) external onlyOwner {
        require(!procesingFees, "E06"); // Already processing fees
        require(percent <= 100,"E07"); // Over 100 percent entered!
        uint256 tokensOnContract = balanceOf(address(this));
        processFees(tokensOnContract * percent / 100);
    }

    // Remember to include the decimals when entering the amount of tokens
    function Process_rescueTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require (tokenAddress != address(this), "E08"); // Can not remove the native token
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
    }

    // Adjust the number of transactions required to trigger fee processing (default is 10)
    function Process_triggerCount(uint8 reqTransactions) external onlyOwner {
        tTrigger = reqTransactions + 1;
    }


    

    /*

    ----------------
    WALLET FUNCTIONS
    ----------------

    */
   
    function Wallet_feeExempt(address _wallet, bool true_or_false) public onlyOwner {
        _isFeeExempt[_wallet] = true_or_false;
    }

    function Wallet_limitExempt(address _wallet, bool true_or_false) public onlyOwner {
        _isLimitExempt[_wallet] = true_or_false;
    }

    function Wallet_whitelist(address _wallet, bool true_or_false) public onlyOwner {
        _isWhitelisted[_wallet] = true_or_false;
    }

    function Wallet_setMarketingWallet(address payable _marketingWallet) external onlyOwner{
        require(_marketingWallet != address(0), "E09"); // Enter a valid BSC wallet
        marketingWallet = _marketingWallet;
    }

    function Wallet_setLiquidityWallet(address _liquidityWallet) external onlyOwner{
        require(_liquidityWallet != address(0), "E10"); // Enter a valid BSC wallet
        liquidityWallet = _liquidityWallet;
    }






    function _transfer(
        address sender,
        address recipient,
        uint256 amount
        
    ) internal override {
        
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (!tradeOpen) {
            require(_isWhitelisted[sender] || _isWhitelisted[recipient], "E11"); // Trade is not open, only whitelisted wallets can transfer tokens
        }



        // Wallet Limit
        if (!_isLimitExempt[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= maxHold, "E12"); // Over max wallet limit
            
        }

        // Transaction limit - To send over the transaction limit the sender AND the recipient must be limit exempt
        if (!_isLimitExempt[recipient] || !_isLimitExempt[sender]) {
            require(amount <= maxTran, "E13"); // Over max transaction limit
        
        }
 
        bool canSwap = tCount >= tTrigger;

        if (canSwap &&
            swapEnabled &&
            !procesingFees &&
            _isPair[recipient] &&
            !_isFeeExempt[sender] &&
            !_isFeeExempt[recipient]) {

                procesingFees = true;

                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance > maxTran) {contractTokenBalance = maxTran;}
                    processFees(contractTokenBalance);

                procesingFees = false;
        }
    
        bool takeFee = true;

        // Check if wallet is fee exempt 
        if (_isFeeExempt[sender] || _isFeeExempt[recipient] || procesingFees) {
            takeFee = false;
        }
 
        
        // Calculate fees
        if (takeFee) {

            uint256 swapFees = 0;
            uint256 burnFees = 0;


            // Sell
            if (_isPair[recipient] && _fees.sellTotalFee > 0) {
                swapFees = amount * (_fees.buyMarketingFee + _fees.buyLiquidityFee) / 100;
                burnFees = amount * _fees.buyBurnFee / 100;

            }

            // Buy
            else if (_isPair[sender] && _fees.buyTotalFee > 0) {
                swapFees = amount * (_fees.sellMarketingFee + _fees.sellLiquidityFee) / 100;
                burnFees = amount * _fees.sellBurnFee / 100;
                
            }

            // Remove fees from token amount
            amount -= (swapFees + burnFees);


            // Send burn fees to burn wallet
            if (burnFees > 0) {
                super._transfer(sender, burnWallet, burnFees);
            }


            // Deposit fees for swap onto contract
            if (swapFees > 0) {
                super._transfer(sender, address(this), swapFees);

                // Increase fee processing counter
                if (tCount < tTrigger){
                    tCount++;
                }

            }

        }

        // Complete the transfer
        super._transfer(sender, recipient, amount);
    }




    function send_Eth(address _to, uint256 _amount) internal returns (bool SendSuccess) {
        (SendSuccess,) = payable(_to).call{value: _amount}("");
    }

    function swapTokensForEth(uint256 tAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tAmount);

        // add the liquidity
        router.addLiquidityETH{ value: ethAmount } (address(this), tAmount, 0, 0 , address(this), block.timestamp);
    }





    // Process the fees
    function processFees(uint256 processTokens) private {

        // Get fee total and double to avoid odd fee rounding error
        uint256 swapTotal = (_fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.sellMarketingFee + _fees.sellLiquidityFee) * 2;

        // Calculate tokens for liquidity 
        uint256 tokensLiquidity = processTokens * (_fees.buyLiquidityFee + _fees.sellLiquidityFee) / swapTotal / 2;

        // Swap tokens
        uint256 contract_Eth = address(this).balance;
        swapTokensForEth(processTokens - tokensLiquidity);
        uint256 returned_Eth = address(this).balance - contract_Eth;

        // Calculate splits
        uint256 feeSplit = swapTotal - (_fees.buyLiquidityFee + _fees.sellLiquidityFee);

        // Calculate Eth Value for liquidity
        uint256 Eth_Liquidity = returned_Eth * (_fees.buyLiquidityFee + _fees.sellLiquidityFee) / feeSplit;

        // Add Liquidity 
        if (Eth_Liquidity > 0){
            addLiquidity(tokensLiquidity, Eth_Liquidity);
            emit SwapAndLiquify(tokensLiquidity, Eth_Liquidity);
        }
      
        // Flush remaining Eth into marketing wallet
        contract_Eth = address(this).balance;

        if (contract_Eth > 0){
            send_Eth(marketingWallet, contract_Eth);
        }

        tCount = 1;
    }

}



// Custom Contract by Gen - tokensByGen.com - t.me/GenTokens_GEN - Not Open Source.