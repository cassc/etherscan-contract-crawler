/**
 *Submitted for verification at Etherscan.io on 2023-10-11
*/

// SPDX-License-Identifier: Unlicensed 
// This contract is not open source and can not be used/forked without permission
// Contract created at TokensByGen.com

/*


http://t.me/champiooontoken
www.champiooon.com
https://twitter.com/Champiooon2?s=09 
    

*/

pragma solidity 0.8.19;
 
interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);
}

interface IUniswapV2Router02 {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}





contract CHAMP is Context, IERC20 { /// Change contratc name to name of token!

    // Contract Wallets
    address public _owner = 0x5deA306c51aFC23cB6Df672f4F7eFa045593bfF0; 
    address public Wallet_Liquidity = 0x5deA306c51aFC23cB6Df672f4F7eFa045593bfF0; 
    address payable public Wallet_Marketing = payable(0x5deA306c51aFC23cB6Df672f4F7eFa045593bfF0);  
    address public constant Wallet_Burn = 0x000000000000000000000000000000000000dEaD;


    // Token Info
    string private  _name = "CHAMP"; 
    string private  _symbol = "CMP"; 
    uint256 private _decimals = 9; 
    uint256 private _tTotal = 100_000_000 * 10 ** _decimals;

    // Fees
    uint8 public _fee__Liquidity = 4;
    uint8 public _fee__Marketing = 2;


    // Total Fee for Swap
    uint8 private _SwapFeeTotal = 6;


    // Set factory
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;


    constructor () {

        // Whitelist owner so they can add initial liquidity 
        _isWhiteListed[_owner] = true;

        // Wallets excluded from fees
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Burn] = true;

        _tOwned[_owner] = _tTotal;
      
        emit Transfer(address(0), _owner, _tTotal);
        emit OwnershipTransferred(address(0), _owner);

    }

    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event updated_fees(uint8 Marketing, uint8 Liquidity);
    event updated_SwapAndLiquify_Enabled(bool Swap_and_Liquify_Enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TokenCreated(address indexed Token_CA);
    event LiquidityAdded(uint256 Tokens_Amount, uint256 BNB_Amount);


    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Address mappings
    mapping (address => uint256) private _tOwned;                               // Tokens Owned
    mapping (address => mapping (address => uint256)) private _allowances;      // Allowance to spend another wallets tokens
    mapping (address => bool) public _isExcludedFromFee;                        // Wallets that do not pay fees
    mapping (address => bool) public _isWhiteListed;                            // Wallets that have access before trade is open
    mapping (address => bool) public _isPair;                                   // Address is liquidity pair

    // Fee Processing Triggers
    uint256 private swapTrigger = 11; 
    uint256 private swapCounter = 1;    
    
    // Fee processing (SwapAndLiquify) Switch                  
    bool public processingFees;
    bool public feeProcessingEnabled; 

    // Launch Settings
    bool public Trade_Open;
    bool public no_Fee_Transfers = true;   // True at launch (Wallet to wallet transfers do not incur a fee)
    bool public noFeeWhenProcessing;        // False at launch (The sell that triggers fee processing still needs to pay the transaction fee)

    // Fee Tracker
    bool private takeFee;
    
    // Set Buy and Sell Fees
    function Set_Fees(

        uint8 Marketing,
        uint8 Liquidity

        ) external onlyOwner {

        // Buyer Protection: Max Fee 6% 
        require (Marketing + Liquidity <= 6, "FEE6");  // Max fee 6%

      
        // Update Fees
        _fee__Liquidity = Liquidity;
        _fee__Marketing = Marketing;

        // Fees For Processing
        _SwapFeeTotal = _fee__Liquidity + _fee__Marketing;

        emit updated_fees(_fee__Marketing, _fee__Liquidity);
    
    }

  

    // Open Trade
    function Open_Trade() external onlyOwner {

        require(!Trade_Open, "TradeOpen"); // Trade is already open - Trade can not be paused 
        feeProcessingEnabled = true;
        Trade_Open = true;

        // Check if router and pair have been set
        if (uniswapV2Router == IUniswapV2Router02(0x0000000000000000000000000000000000000000)){


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Eth Chain

                    uniswapV2Router = _uniswapV2Router;
        }

        if (uniswapV2Pair == address(0x0000000000000000000000000000000000000000)) {

            address pairCreated = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());

                // Check if pair has been created
                if (pairCreated == address(0x0000000000000000000000000000000000000000)){

                    // Create and set the pair
                    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

                } else {

                    // Set the pair
                    uniswapV2Pair = pairCreated;
                }
            
        }

        // Set as pair and make limit exempt
        if (!_isPair[uniswapV2Pair]){_isPair[uniswapV2Pair] = true;} 

    }


    /*

    --------------
    FEE PROCESSING 
    --------------

    */


    // Add Liquidity Pair - required for correct fee calculations 
    function addNewLiquidityPair(

        address Wallet_Address,
        bool true_or_false)

        external onlyOwner {

        _isPair[Wallet_Address] = true_or_false;

    } 

    /*
    
    ---------------------------------
    NO FEE WALLET TO WALLET TRANSFERS
    ---------------------------------

    Default = true

    Having no fee on wallet-to-wallet transfers means that people can move tokens between wallets, 
    or send them to friends etc without incurring a fee. 

    If false, the 'Buy' fee will apply to all wallet to wallet transfers.

    */


    function no_Fee_Wallet_Transfers(bool true_or_false) external onlyOwner {

        no_Fee_Transfers = true_or_false;

    }


    // Auto Fee Processing Switch (SwapAndLiquify)
    function swapAndLiquifySwtich(bool true_or_false) external onlyOwner {
        feeProcessingEnabled = true_or_false;
        emit updated_SwapAndLiquify_Enabled(true_or_false);
    }
    
    function swapTriggerCount(uint256 Transaction_Count) external onlyOwner {

        require(Transaction_Count <= 20, "Max is 20 Transacitons to trigger fees");
        swapTrigger = Transaction_Count + 1; // Reset to 1 (not 0) to save gas
    }

    // Manually Process Fees
    function swapAndLiquifyNow(uint256 Percent_of_Tokens_to_Process) external onlyOwner {

        require(!processingFees); // Already in swap, try later

        if (Percent_of_Tokens_to_Process > 100){Percent_of_Tokens_to_Process = 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract * Percent_of_Tokens_to_Process / 100;
        processFees(sendTokens);

    }  


    /*

    --------------------------
    REMOVE FEE WHEN PROCESSING
    --------------------------

    Default = false

    When the contract needs to process fees the 'sell fee' displayed on a DEX will include the sell fee and the price drop caused by the contract sell.
    Setting this to true will help to mitigate that increase. For details see https://www.youtube.com/watch?v=PKyACFILwhI 

    */


    // Remove fee for wallet that triggers processing
    function removeFeeWhenProcessing(bool true_or_false) external onlyOwner {

        noFeeWhenProcessing = true_or_false;

    }

    function rescueTokens(

        address random_Token_Address,
        uint256 number_of_Tokens

        ) external onlyOwner {

            require (random_Token_Address != address(this), "RNT"); // Can not remove the native token
            IERC20(random_Token_Address).transfer(msg.sender, number_of_Tokens);
            
    }

 

    function Project_Update_Wallet_Liquidity(

        address Liquidity_Collection_Wallet

        ) external onlyOwner {

        // Update LP Collection Wallet
        require(Liquidity_Collection_Wallet != address(0), "WL"); // Enter a valid BSC Address
        Wallet_Liquidity = Liquidity_Collection_Wallet;

    }

    function Project_Update_Wallet_Marketing(

        address payable Marketing_Wallet

        ) external onlyOwner {

        // Update Marketing Wallet
        require(Marketing_Wallet != address(0), "WM"); // Enter a valid BSC Address
        Wallet_Marketing = payable(Marketing_Wallet);

    }


    /*

    ---------------
    WALLET SETTINGS
    ---------------

    */


    // Exclude From Fees
    function Wallet_Exclude_From_Fees(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {
        _isExcludedFromFee[Wallet_Address] = true_or_false;

    }

    // Grant Pre-Launch Access (Whitelist)
    function Wallet_Pre_Launch_Access(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {    
        _isWhiteListed[Wallet_Address] = true_or_false;
    }


    /* 

    ----------------------------
    CONTRACT OWNERSHIP FUNCTIONS
    ----------------------------

    Before renouncing ownership, set the freeWalletTransfers to false 

    */

  
    // Renounce Ownership - To prevent accidental renounce, you must enter the Confirmation_Code: 1234
    function ownership_RENOUNCE(uint256 Confirmation_Code) public virtual onlyOwner {

        require(Confirmation_Code == 1234, "E12"); // Renounce confirmation not correct

        // Remove old owner status 
        _isExcludedFromFee[owner()] = false;
        _isWhiteListed[owner()]     = false;

        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    // Transfer to New Owner - To prevent accidental renounce, you must enter the Confirmation_Code: 1234
    function ownership_TRANSFER(address payable newOwner, uint256 Confirmation_Code) public onlyOwner {

        require(Confirmation_Code == 1234, "E12"); // Renounce confirmation not correct
        require(newOwner != address(0), "E13"); // Enter a valid BSC wallet

        // Revoke old owner status
        _isExcludedFromFee[owner()] = false;
        _isWhiteListed[owner()]     = false;

        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;

        // Set up new owner status 
        _isExcludedFromFee[owner()] = true;
        _isWhiteListed[owner()]     = true;

    }


    /*

    -----------------------------
    BEP20 STANDARD AND COMPLIANCE
    -----------------------------

    */

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    function send_BNB(address _to, uint256 _amount) internal returns (bool SendSuccess) {
                                
        (SendSuccess,) = payable(_to).call{value: _amount}("");

    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - balanceOf(address(Wallet_Burn)));
    }



    /*

    ---------------
    TOKEN TRANSFERS
    ---------------

    */

    function _transfer(
        address from,
        address to,
        uint256 amount
      ) private {




        require(balanceOf(from) >= amount, "TO1"); // Sender does not have enough tokens!

       

        if (!Trade_Open && from != address(this)){

            require(_isWhiteListed[from] || _isWhiteListed[to], "TO2");  // Trade closed, only whitelisted wallets can move tokens


        }



        // Compliance and safety checks
        require(from != address(0), "FROM0"); // Not a valid BSC wallet address
        require(to != address(0), "TO0"); // Not a valid BSC wallet address
        require(amount > 0, "AMT0"); // Amount must be greater than 0

      
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (no_Fee_Transfers && !_isPair[to] && !_isPair[from])){
            takeFee = false;
        } else {
            takeFee = true;
        }

        // Trigger Fee Processing
        if (_isPair[to] && !processingFees && feeProcessingEnabled) {

            // Check Transaction Count
            if(swapCounter >= swapTrigger){

                // Check Contract Tokens
                uint256 contractTokens = balanceOf(address(this));

                if (contractTokens > 0) {

                    // Check if fee is removed during processing
                    if (noFeeWhenProcessing && takeFee){takeFee = false;}

                    // Limit Swap to Max Transaction
                    if (contractTokens <= (_tTotal / 100)) {

                        processFees (contractTokens);

                        } else {

                        processFees (_tTotal / 100);

                    }
                }
            }  
        }


        _tokenTransfer(from, to, amount, takeFee);




    }


    /*
    
    ------------
    PROCESS FEES
    ------------

    */

    function processFees(uint256 Tokens) private {

        // Lock Swap
        processingFees = true;

        // Totals for buy and sell fees - (Double all fees to remove odd number rounding errors)
        uint8 _LiquidityTotal   = _fee__Liquidity * 2;
        uint8 _FeesTotal        = _SwapFeeTotal * 2;

        // Calculate tokens for swap
        uint256 LP_Tokens       = Tokens * _LiquidityTotal / _FeesTotal / 2;
        uint256 Swap_Tokens     = Tokens - LP_Tokens;

        // Swap Tokens
        uint256 contract_BNB    = address(this).balance;
        swapTokensForBNB(Swap_Tokens);
        uint256 returned_BNB    = address(this).balance - contract_BNB;

        // Avoid Rounding Errors on LP Fee if Odd Number
        uint256 fee_Split       = _FeesTotal * 2 - _LiquidityTotal;

        // Add auto liquidity 
        if (_LiquidityTotal > 0 ) {

            uint256 BNB_Liquidity = returned_BNB * _LiquidityTotal / fee_Split;
            addLiquidity(LP_Tokens, BNB_Liquidity);
            emit SwapAndLiquify(LP_Tokens, BNB_Liquidity, LP_Tokens);
        
        }

        
        // Flush Remaining BNB to Marketing Wallet
        contract_BNB = address(this).balance;

        if (contract_BNB > 0){

            send_BNB(Wallet_Marketing, contract_BNB);
        }


        // Reset Counter
        swapCounter = 1;

        // Unlock Swap
        processingFees = false;


    }

    // Swap tokens for BNB
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

    // Add liquidity and send Cake LP tokens to liquidity collection wallet
    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_Liquidity, 
            block.timestamp
        );
    } 

    /*
    
    ----------------------------------
    TRANSFER TOKENS AND CALCULATE FEES
    ----------------------------------

    */


    // Transfer Tokens and Calculate Fees
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool Fee) private {

        uint256 tSwapFeeTotal = 0;
        
        if (Fee){

                // Sell fees
                tSwapFeeTotal   = tAmount * _SwapFeeTotal / 100;

            } 
    

        uint256 tTransferAmount = tAmount - tSwapFeeTotal;

        // Transfer tokens
        _tOwned[sender] -= tAmount;

        // Send tokens to recipient
        _tOwned[recipient] += tTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);


        // Take fees that require processing during swap and liquify
        if(tSwapFeeTotal > 0){

            _tOwned[address(this)] += tSwapFeeTotal;
            emit Transfer(sender, address(this), tSwapFeeTotal);

            // Increase the transaction counter
            if(swapCounter < swapTrigger){
                unchecked{swapCounter++;}
            }
                
        }

    }


    // This function is required so that the contract can receive BNB during fee processing
    receive() external payable {}

}



/*


    Token Created at www.TokensByGen.com
    This contract is not open source - Can not be used or forked without permission.
    Fees from the creation of this token help to support the GEN project for more information please visit www.gentokens.com
    

*/