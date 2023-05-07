/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: Unlicensed 

/*

    Telegram Group: https://t.me/GiftyCoin_GIFTS 
    Telegram Channel: https://t.me/GiftyCoin_Announcements
    Website: https://giftycoin.com

    For Twitter, Discord and more social media links please click Read Contract > Social_Media_Links > Query

*/


pragma solidity 0.8.19;

interface IERC20 {
    

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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


contract GiftyCoin_GIFTS is Context, IERC20 { 

    // Contract Wallets
    address private _owner                  = 0x4D5557380D09427F0543bC3D54Fb6BC1eef6D2A0;
    address public Wallet_Co_Owner          = 0x11F068E9D60538817cedbD7A45aED032f3873e1B;
    address public Wallet_Liquidity         = 0x4D5557380D09427F0543bC3D54Fb6BC1eef6D2A0;
    address public Wallet_Tokens            = 0x4D5557380D09427F0543bC3D54Fb6BC1eef6D2A0;
    address private constant Wallet_Burn    = 0x000000000000000000000000000000000000dEaD;
    address payable public Wallet_Marketing = payable(0x4D5557380D09427F0543bC3D54Fb6BC1eef6D2A0); 
 
    // Token Info
    string private constant  _name       = "GiftyCoin";
    string private constant  _symbol     = "GIFTS";
    uint8 private constant _decimals     = 9;
    uint256 private constant _tTotal     = 1_000_000_000 * 10 ** _decimals;
    uint256 private max_Hold             = _tTotal / 100; // Max hold set to 1% at launch (can be updated - min possible 0.5%)

    // Social links
    string private _Website;
    string private _Telegram_Group;
    string private _Telegram_Channel;
    string private _Twitter;
    string private _Discord;
    string private _Instagram;
    string private _YouTube;
    string private _Facebook;
    string private _Reddit;
    string private _Medium;


    string private _LP_Lock;

    // Fees
    uint8 public _Fee__Buy_Burn;
    uint8 public _Fee__Buy_Liquidity;
    uint8 public _Fee__Buy_Marketing;
    uint8 public _Fee__Buy_Reflection;
    uint8 public _Fee__Buy_Tokens;

    uint8 public _Fee__Sell_Burn;
    uint8 public _Fee__Sell_Liquidity;
    uint8 public _Fee__Sell_Marketing;
    uint8 public _Fee__Sell_Reflection;
    uint8 public _Fee__Sell_Tokens;

    // Total Fee for Swap
    uint8 private _SwapFeeTotal_Buy;
    uint8 private _SwapFeeTotal_Sell;


    // Supply Tracking for RFI
    uint256 private _tFeeTotal;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    // Set factory
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor () {

    // Transfer token supply to owner wallet
    _rOwned[_owner]     = _rTotal;

    // Set PancakeSwap Router Address
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    // Create initial liquidity pair with BNB on PancakeSwap factory
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;

    // Wallets excluded from holding limits
    _isLimitExempt[_owner] = true;
    _isLimitExempt[address(this)] = true;
    _isLimitExempt[Wallet_Burn] = true;
    _isLimitExempt[uniswapV2Pair] = true;
    _isLimitExempt[Wallet_Tokens] = true;

    // Wallets excluded from fees
    _isExcludedFromFee[_owner] = true;
    _isExcludedFromFee[address(this)] = true;
    _isExcludedFromFee[Wallet_Burn] = true;

    // Set the initial liquidity pair
    _isPair[uniswapV2Pair] = true;    

    // Exclude from Rewards
    _isExcluded[Wallet_Burn] = true;
    _isExcluded[uniswapV2Pair] = true;
    _isExcluded[address(this)] = true;

    // Push excluded wallets to array
    _excluded.push(Wallet_Burn);
    _excluded.push(uniswapV2Pair);
    _excluded.push(address(this));

    // Wallets granted access before trade is open
    _isWhiteListed[_owner] = true;

    // Emit Supply Transfer to Owner
    emit Transfer(address(0), _owner, _tTotal);

    // Emit ownership transfer
    emit OwnershipTransferred(address(0), _owner);

    }

    
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event updated_Wallet_Limits(uint256 max_Hold);
    event updated_Buy_fees(uint256 Marketing, uint256 Liquidity, uint256 Reflection, uint256 Burn, uint256 Tokens);
    event updated_Sell_fees(uint256 Marketing, uint256 Liquidity, uint256 Reflection, uint256 Burn, uint256 Tokens);
    event updated_SwapAndLiquify_Enabled(bool Swap_and_Liquify_Enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event OwnershipTransferRequest(address indexed suggested_newOwner);
    event renounceOwnership_Requested(bool renounceOwnership_Requested);
    event requestUpdate_MultiSig_Wallet(address indexed suggested_Co_Owner_Wallet);
    event multiSig_Wallet_Updated(address indexed old_Co_Owner_Wallet, address indexed new_Co_Owner_Wallet);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    // Restrict function to contract owner only 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Address mappings
    mapping (address => uint256) private _tOwned;                               // Tokens Owned
    mapping (address => uint256) private _rOwned;                               // Reflected balance
    mapping (address => mapping (address => uint256)) private _allowances;      // Allowance to spend another wallets tokens
    mapping (address => bool) public _isExcludedFromFee;                        // Wallets that do not pay fees
    mapping (address => bool) public _isExcluded;                               // Excluded from RFI rewards
    mapping (address => bool) public _isWhiteListed;                            // Wallets that have access before trade is open
    mapping (address => bool) public _isLimitExempt;                            // Wallets that are excluded from HOLD and TRANSFER limits
    mapping (address => bool) public _isPair;                                   // Address is liquidity pair
    address[] private _excluded;                                                // Array of wallets excluded from rewards



    // Fee Processing Triggers
    uint256 private swapTrigger = 11;   
    uint256 private swapCounter = 1;    
    
    // SwapAndLiquify Switch                  
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled; 

    // Launch Settings
    bool public trade_Open;
    bool public freeWalletTransfers = true;

    // Fee Tracker
    bool private takeFee;







    // Social Links

    function Social_Media_Links() external view returns(string memory Website,
                                                        string memory Telegram_Group,
                                                        string memory Telegram_Channel,
                                                        string memory Twitter,
                                                        string memory Discord,
                                                        string memory Instagram,
                                                        string memory YouTube,
                                                        string memory Facebook,
                                                        string memory Reddit,
                                                        string memory Medium) {
                                                           
        return (_Website,
                _Telegram_Group,
                _Telegram_Channel,
                _Twitter,
                _Discord,
                _Instagram,
                _YouTube,
                _Facebook,
                _Reddit,
                _Medium);

    }

  






    // Token info
    function Token_Information() external view returns(address Owner_Wallet,
                                                       uint256 Transaction_Limit,
                                                       uint256 Max_Wallet,
                                                       uint256 Fee_When_Buying,
                                                       uint256 Fee_When_Selling,
                                                       string memory Liquidity_Lock) {
                                                           

        uint256 Total_buy =  _Fee__Buy_Burn         +
                             _Fee__Buy_Liquidity    +
                             _Fee__Buy_Marketing    +
                             _Fee__Buy_Reflection   +
                             _Fee__Buy_Tokens       ;

        uint256 Total_sell = _Fee__Sell_Burn        +
                             _Fee__Sell_Liquidity   +
                             _Fee__Sell_Marketing   +
                             _Fee__Sell_Reflection  +
                             _Fee__Sell_Tokens      ;

        uint256 _max_Hold = max_Hold / (10 ** _decimals);


        // Return Token Data
        return (_owner,
                _max_Hold,
                _max_Hold,
                Total_buy,
                Total_sell,
                _LP_Lock);

    }






    // Set fees
    function F01_Set_Fees_on_BUY(

        uint8 Marketing_on_BUY, 
        uint8 Liquidity_on_BUY, 
        uint8 Burn_on_BUY,  
        uint8 Tokens_on_BUY,
        uint8 Reflection_on_BUY

        ) external onlyOwner {

        // Buyer Protection: Max Fee 15%
        require (Marketing_on_BUY    + 
                 Liquidity_on_BUY    + 
                 Burn_on_BUY         + 
                 Tokens_on_BUY       +
                 Reflection_on_BUY   <= 15, "E01"); // Total buy fee must be 15 or less


        // Update Buy Fees
        _Fee__Buy_Marketing   = Marketing_on_BUY;
        _Fee__Buy_Liquidity   = Liquidity_on_BUY;
        _Fee__Buy_Burn        = Burn_on_BUY;
        _Fee__Buy_Tokens      = Tokens_on_BUY;
        _Fee__Buy_Reflection  = Reflection_on_BUY;

        // Fees For Processing
        _SwapFeeTotal_Buy     = _Fee__Buy_Marketing + _Fee__Buy_Liquidity;

        emit updated_Buy_fees(_Fee__Buy_Marketing, _Fee__Buy_Liquidity, _Fee__Buy_Burn, _Fee__Buy_Tokens, _Fee__Buy_Reflection);
    }



    // Set fees
    function F02_Set_Fees_on_SELL(

        uint8 Marketing_on_SELL,
        uint8 Liquidity_on_SELL, 
        uint8 Burn_on_SELL,
        uint8 Tokens_on_SELL,
        uint8 Reflection_on_SELL

        ) external onlyOwner {

        require (Marketing_on_SELL   + 
                 Liquidity_on_SELL   + 
                 Burn_on_SELL        + 
                 Tokens_on_SELL      +
                 Reflection_on_SELL  <= 15, "E02"); // Total sell fee must be 15 or less 


        // Update Sell Fees
        _Fee__Sell_Marketing  = Marketing_on_SELL;
        _Fee__Sell_Liquidity  = Liquidity_on_SELL;
        _Fee__Sell_Burn       = Burn_on_SELL;
        _Fee__Sell_Tokens     = Tokens_on_SELL;
        _Fee__Sell_Reflection = Reflection_on_SELL;

        // Fees For Processing
        _SwapFeeTotal_Sell    = _Fee__Sell_Marketing + _Fee__Sell_Liquidity;

        emit updated_Sell_fees(_Fee__Sell_Marketing, _Fee__Sell_Liquidity, _Fee__Sell_Burn, _Fee__Sell_Tokens, _Fee__Sell_Reflection);
    }



    /*
    
    ----------------------
    SET MAX HOLDING LIMITS
    ----------------------

    Wallet limits are set as a number of tokens, not as a percent of supply!

    Total Supply = 1,000,000,000 

    Common Percent Values in Tokens

        0.5% = 5000000 (This is the lowest permitted value for wallet limits)
        1.0% = 10000000
        1.5% = 15000000
        2.0% = 20000000
        2.5% = 25000000
        3.0% = 30000000

        100% = 1000000000 (Only used when setting up the contract for pre-sale etc.)

    */

    function F03_Set_Wallet_Limits(

        uint256 Max_Total_Tokens_Per_Wallet 

        ) external onlyOwner {

        require(Max_Total_Tokens_Per_Wallet >= 5000000, "E03"); // 0.05% minimum limit        
        max_Hold = Max_Total_Tokens_Per_Wallet * 10**_decimals;

        emit updated_Wallet_Limits(max_Hold);

    }

    // Open Trade
    function F04_Open_Trade() external onlyOwner {

        swapAndLiquifyEnabled = true;
        trade_Open = true;

    }



      // Update Social Links

    function Update_Social_Links (string memory __Discord,
                                  string memory __Facebook,
                                  string memory __Instagram,
                                  string memory __Medium,
                                  string memory __Reddit,
                                  string memory __TelegramChannel,
                                  string memory __TelegramGroup,
                                  string memory __Twitter,
                                  string memory __Website,
                                  string memory __YouTube

        ) external onlyOwner{

        _Discord = __Discord;
        _Facebook = __Facebook;
        _Instagram = __Instagram;
        _Medium = __Medium;
        _Reddit = __Reddit;
        _Telegram_Channel = __TelegramChannel;
        _Telegram_Group = __TelegramGroup;
        _Twitter = __Twitter;
        _Website = __Website;
        _YouTube = __YouTube;

    }
    

    /*

    ----------------------
    UPDATE PROJECT WALLETS
    ----------------------

    */

    function Update_Wallet__Liquidity(

        address Liquidity_Collection_Wallet

        ) external onlyOwner {

        require(Liquidity_Collection_Wallet != address(0), "E04"); // Enter a valid BSC wallet
        Wallet_Liquidity = Liquidity_Collection_Wallet;

    }

    function Update_Wallet__Marketing(

        address payable Marketing_Fee_Wallet

        ) external onlyOwner {

        require(Marketing_Fee_Wallet != address(0), "E05"); // Enter a valid BSC wallet
        Wallet_Marketing = payable(Marketing_Fee_Wallet);


    }

    function Update_Wallet__Tokens(

        address Token_Fee_Wallet

        ) external onlyOwner {

        require(Token_Fee_Wallet != address(0), "E06"); // Enter a valid BSC wallet
        Wallet_Tokens = Token_Fee_Wallet;

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

    function Maintenance__Free_Wallet_Transfers(bool true_or_false) public onlyOwner {
        freeWalletTransfers = true_or_false;

    }

    // Add Liquidity Pair - required for correct fee calculations 
    function Maintenance__Liquidity_Pair_ADD(address LP_Address) external onlyOwner {
        _isPair[LP_Address] = true;
        _isLimitExempt[LP_Address] = true;

    } 

    // Remove Liquidity Pair - Only used is a non-pair is added by mistake
    function Maintenance__Liquidity_Pair_REMOVE(address LP_Address) external onlyOwner {
        require(LP_Address != uniswapV2Pair, "E07"); // Can not remove the original pair
        _isPair[LP_Address] = false;
        _isLimitExempt[LP_Address] = false;

    } 

    /* 

    -----------------------------------------------------------------
    CONTRACT OWNERSHIP FUNCTIONS - PROTECTED BY MULTISIG CONFIRMATION
    -----------------------------------------------------------------

    Before renouncing ownership, set the freeWalletTransfers to false 

    */


    // Used for MultiSig - Ownership transfer, renounce and confirmation wallet updates
    bool public multiSig_Renounce_Ownership_ASKED   = false;
    bool public multiSig_Transfer_Ownership_ASKED   = false;
    bool public multiSig_Update_Wallet_ASKED        = false;

    // Suggested wallets are set to current wallets to avoid the appearance of the zero address being suggested during deployment

    // Transfer Ownership - Suggested new owner wallet (must be confirmed)
    address public suggested_New_Owner_Wallet = _owner;

    // Update Confirmation Wallet for Multi-Sig - Suggested new wallet (must be confirmed)
    address public suggested_New_Co_Owner_Wallet = Wallet_Co_Owner;

    // Transfer Ownership - Requires Co_Owner to Confirm
    function Ownership_Transfer_REQUEST_by_Owner(address newOwner_Request) external onlyOwner {

        require(!multiSig_Transfer_Ownership_ASKED, "E08"); // Already asked, wait confirmation
        require(newOwner_Request != address(0), "E09"); // New owner can not be zero address
        multiSig_Transfer_Ownership_ASKED = true;
        suggested_New_Owner_Wallet = newOwner_Request;
        emit OwnershipTransferRequest(newOwner_Request);
    }

    function Ownership_Transfer_CONFIRM_by_CoOwner(uint256 Confirmation_Code, bool true_or_false) external {

        require(Confirmation_Code == 30072022, "E10"); // Renounce confirmation not correct

        require(msg.sender == Wallet_Co_Owner, "E11"); // Confirmation wallet must confirm
        require (multiSig_Transfer_Ownership_ASKED, "E12"); // Transferring Ownership not requested

        if (true_or_false){

        // Revoke old owner status
        _isLimitExempt[owner()]     = false;
        _isExcludedFromFee[owner()] = false;
        _isWhiteListed[owner()]     = false;

        // Transfer ownership and emit the transfer
        emit OwnershipTransferred(_owner, suggested_New_Owner_Wallet);
        _owner = suggested_New_Owner_Wallet;

        // Set up new owner status 
        _isLimitExempt[owner()]     = true;
        _isExcludedFromFee[owner()] = true;
        _isWhiteListed[owner()]     = true;

        // Reset ask permissions
        multiSig_Transfer_Ownership_ASKED = false;

        } else {

        // Reset ask permissions
        multiSig_Transfer_Ownership_ASKED = false;

        }
    }

    // Renounce Ownership - Requires Co_Owner to Confirm
    function Ownership_Renounce_REQUEST_by_Owner() external onlyOwner {

        require (!multiSig_Renounce_Ownership_ASKED, "E13"); // Already asked, wait confirmation
        multiSig_Renounce_Ownership_ASKED = true;
        emit renounceOwnership_Requested(multiSig_Renounce_Ownership_ASKED);
    }

    function Ownership_Renounce_CONFIRM_by_CoOwner(uint256 Confirmation_Code, bool true_or_false) external {

        require(Confirmation_Code == 30072022, "E14"); // Renounce confirmation not correct

        require(msg.sender == Wallet_Co_Owner, "E15"); // Confirmation wallet must confirm
        require(multiSig_Renounce_Ownership_ASKED, "E16"); // Renounce not requested

        if (true_or_false){

        // Remove old owner status 
        _isLimitExempt[owner()]     = false;
        _isExcludedFromFee[owner()] = false;
        _isWhiteListed[owner()]     = false;

        // Renounce ownership of contract
        emit OwnershipTransferred(owner(), address(0));
        _owner = address(0);

        } else {

        // Reset ask permissions
        multiSig_Renounce_Ownership_ASKED = false;

        }
    }

    // Update MultiSig Confirmation Wallet - Requires Multi-Sig
    function Ownership_Change_CoOwner_REQUEST_by_Owner(address payable new_Co_Owner_Wallet) external onlyOwner {

        require(new_Co_Owner_Wallet != address(0), "E17"); // Can not be zero address
        require(!multiSig_Update_Wallet_ASKED, "E18"); // Already asked, wait confirmation
        suggested_New_Co_Owner_Wallet = new_Co_Owner_Wallet;
        multiSig_Update_Wallet_ASKED = true;
        emit requestUpdate_MultiSig_Wallet(new_Co_Owner_Wallet);

    }

    function Ownership_Change_CoOwner_CONFIRM_by_CoOwner(bool true_or_false) external {

        require(msg.sender == Wallet_Co_Owner, "E19"); // Confirmation wallet must confirm
        require(multiSig_Update_Wallet_ASKED, "E20"); // Change not requested
        if(true_or_false){
                multiSig_Update_Wallet_ASKED = false;
                emit multiSig_Wallet_Updated(Wallet_Co_Owner, suggested_New_Co_Owner_Wallet);
                Wallet_Co_Owner = suggested_New_Co_Owner_Wallet;
            } else {
                multiSig_Update_Wallet_ASKED = false;
            }
        }
    

    /*

    --------------
    FEE PROCESSING
    --------------

    */

    // Auto Fee Processing Switch (SwapAndLiquify)
    function Processing__Auto_Process(bool true_or_false) external onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit updated_SwapAndLiquify_Enabled(true_or_false);
    }

    // Manually Process Fees
    function Processing__Process_Now (uint256 Percent_of_Tokens_to_Process) external onlyOwner {

        require(!inSwapAndLiquify, "E21"); // Already in swap, try later

        if (Percent_of_Tokens_to_Process > 100){Percent_of_Tokens_to_Process == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract * Percent_of_Tokens_to_Process / 100;
        swapAndLiquify(sendTokens);

    }

    // Update Swap Count Trigger
    function Processing__Swap_Trigger_Count(uint256 Transaction_Count) external onlyOwner {

        swapTrigger = Transaction_Count + 1; // Reset to 1 (not 0) to save gas
    }

    // Rescue Trapped Tokens
    function Processing__Rescue_Tokens(

        address Token_Address,
        uint256 Number_of_Tokens

        ) external onlyOwner {

            require (Token_Address != address(this), "E22"); // Can not remove the native token
            IERC20(Token_Address).transfer(msg.sender, Number_of_Tokens);
            
    }



    /*

    ------------------
    REFLECTION REWARDS
    ------------------

    The following functions are used to exclude or include a wallet in the reflection rewards.
    By default, all wallets are included. 

    Wallets that are excluded:

            The Burn address 
            The Liquidity Pair
            The Contract Address

    ----------------------------------------
    *** WARNING - DoS 'OUT OF GAS' Risk! ***
    ----------------------------------------

    A reflections contract needs to loop through all excluded wallets to correctly process several functions. 
    This loop can break the contract if it runs out of gas before completion.

    To prevent this, keep the number of wallets that are excluded from rewards to an absolute minimum. 
    In addition to the default excluded wallets, you may need to exclude the address of any locked tokens.

    */


    // Wallet will not get reflections
    function Rewards_Exclude_Wallet(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }


    // Wallet will get reflections - DEFAULT
    function Rewards_Include_Wallet(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    


   




    /*

    ---------------
    WALLET SETTINGS
    ---------------

    */

    // Exclude From Fees
    function Wallet_Settings__Exclude_From_Fees(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {
        _isExcludedFromFee[Wallet_Address] = true_or_false;

    }

    // Exclude From Transaction and Holding Limits
    function Wallet_Settings__Exempt_From_Limits(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {  
        _isLimitExempt[Wallet_Address] = true_or_false;
    }

    // Grant Pre-Launch Access (Whitelist)
    function Wallet_Settings__Pre_Launch_Access(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {    
        _isWhiteListed[Wallet_Address] = true_or_false;
    }






    /*

    -----------------------------
    BEP20 STANDARD AND COMPLIANCE
    -----------------------------

    */

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
   
    function tokenFromReflection(uint256 _rAmount) internal view returns(uint256) {
        require(_rAmount <= _rTotal, "rAmount can not be greater than rTotal");
        uint256 currentRate =  _getRate();
        return _rAmount / currentRate;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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


        require(balanceOf(from) >= amount, "E23"); // Sender does not have enough tokens!


        if (!trade_Open){

            require(_isWhiteListed[from] || _isWhiteListed[to], "E24");
        }

        // Wallet Limit
        if (!_isLimitExempt[to] && from != owner()) {

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= max_Hold, "E25"); // Over max wallet limit

        }


        // Transaction limit - To send over the transaction limit the sender AND the recipient must be limit exempt
        if (!_isLimitExempt[to] || !_isLimitExempt[from]){

            require(amount <= max_Hold, "E26"); // Over max transaction limit
            
        }


        // Compliance and safety checks
        require(from != address(0), "E27"); // Not a valid BSC wallet address
        require(to != address(0), "E28"); // Not a valid BSC wallet address
        require(amount > 0, "E29"); // Amount must be greater than 0



        // Check if fee processing is possible
        if( _isPair[to] && !inSwapAndLiquify && swapAndLiquifyEnabled) {

            // Check that enough transactions have passed since last swap
            if(swapCounter >= swapTrigger){

                // Check number of tokens on contract
                uint256 contractTokens = balanceOf(address(this));

                // Only trigger fee processing if there are tokens to swap!
                if (contractTokens > 0){

                    // Limit number of tokens that can be swapped 
                    if (contractTokens <= max_Hold){

                        swapAndLiquify (contractTokens);
                        
                        } else {
                        
                        swapAndLiquify (max_Hold);
                        
                    }
                }
            }  
        }


    if (!takeFee){
        takeFee = true;
    }

    if(inSwapAndLiquify || _isExcludedFromFee[from] || _isExcludedFromFee[to] || (freeWalletTransfers && !_isPair[to] && !_isPair[from])){
        takeFee = false;
    }

    _tokenTransfer(from, to, amount, takeFee);

    }


    /*
    
    ------------
    PROCESS FEES
    ------------

    */

    function swapAndLiquify(uint256 Tokens) private {

        // Lock swapAndLiquify function
        inSwapAndLiquify        = true;  

        uint256 _FeesTotal      = _SwapFeeTotal_Buy + _SwapFeeTotal_Sell;
        uint256 LP_Tokens       = Tokens * (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity) / _FeesTotal / 2;
        uint256 Swap_Tokens     = Tokens - LP_Tokens;

        // Swap tokens for BNB
        uint256 contract_BNB    = address(this).balance;
        swapTokensForBNB(Swap_Tokens);
        uint256 returned_BNB    = address(this).balance - contract_BNB;

        // Double fees instead of halving LP fee to prevent rounding errors if fee is an odd number
        uint256 fee_Split = _FeesTotal * 2 - (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity);

        // Calculate the BNB values for each fee (excluding BNB wallet)
        uint256 BNB_Liquidity   = returned_BNB * (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity)    / fee_Split;

        // Add liquidity 
        if (LP_Tokens != 0){

            addLiquidity(LP_Tokens, BNB_Liquidity);
            emit SwapAndLiquify(LP_Tokens, BNB_Liquidity, LP_Tokens);
        }
        
        // Flush remaining BNB to Marketing wallet
        contract_BNB = address(this).balance;

        if(contract_BNB > 0){

            send_BNB(Wallet_Marketing, contract_BNB);
        }

        // Reset transaction counter (reset to 1 not 0 to save gas)
        swapCounter = 1;

        // Unlock swapAndLiquify function
        inSwapAndLiquify = false;
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


    uint256 private rAmount;

    uint256 private tBurn;
    uint256 private tTokens;
    uint256 private tReflect;
    uint256 private tSwapFeeTotal;

    uint256 private rBurn;
    uint256 private rTokens;
    uint256 private rReflect;
    uint256 private rSwapFeeTotal;
    uint256 private tTransferAmount;
    uint256 private rTransferAmount;

    

    // Transfer Tokens and Calculate Fees
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool Fee) private {

        
        if (Fee){

            if(_isPair[recipient]){

                // Sell fees
                tBurn           = tAmount * _Fee__Sell_Burn       / 100;
                tTokens         = tAmount * _Fee__Sell_Tokens     / 100;
                tReflect        = tAmount * _Fee__Sell_Reflection / 100;
                tSwapFeeTotal   = tAmount * _SwapFeeTotal_Sell    / 100;

            } else {

                // Buy fees
                tBurn           = tAmount * _Fee__Buy_Burn        / 100;
                tTokens         = tAmount * _Fee__Buy_Tokens      / 100;
                tReflect        = tAmount * _Fee__Buy_Reflection  / 100;
                tSwapFeeTotal   = tAmount * _SwapFeeTotal_Buy     / 100;

            }

        } else {

                // No fee
                tBurn           = 0;
                tTokens         = 0;
                tReflect        = 0;
                tSwapFeeTotal   = 0;

        }

        // Calculate reflected fees for RFI
        uint256 RFI     = _getRate(); 

        rAmount         = tAmount       * RFI;
        rBurn           = tBurn         * RFI;
        rTokens         = tTokens       * RFI;
        rReflect        = tReflect      * RFI;
        rSwapFeeTotal   = tSwapFeeTotal * RFI;

        tTransferAmount = tAmount - (tBurn + tTokens + tReflect + tSwapFeeTotal);
        rTransferAmount = rAmount - (rBurn + rTokens + rReflect + rSwapFeeTotal);

        
        // Swap tokens based on RFI status of sender and recipient
        if (_isExcluded[sender] && !_isExcluded[recipient]) {

            _tOwned[sender] -= tAmount;
            _rOwned[sender] -= rAmount;
            
            _rOwned[recipient] += rTransferAmount;

            emit Transfer(sender, recipient, tTransferAmount);

        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {

            _rOwned[sender] -= rAmount;

            _tOwned[recipient] += tTransferAmount;
            _rOwned[recipient] += rTransferAmount;

            emit Transfer(sender, recipient, tTransferAmount);

        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {

            _rOwned[sender] -= rAmount;

            _rOwned[recipient] += rTransferAmount;

            emit Transfer(sender, recipient, tTransferAmount);

        } else if (_isExcluded[sender] && _isExcluded[recipient]) {

            _tOwned[sender] -= tAmount;
            _rOwned[sender] -= rAmount;

            _tOwned[recipient] += tTransferAmount;
            _rOwned[recipient] += rTransferAmount;

            emit Transfer(sender, recipient, tTransferAmount);

        } else {

            _rOwned[sender] -= rAmount;

            _rOwned[recipient] += rTransferAmount;

            emit Transfer(sender, recipient, tTransferAmount);

        }


        // Take reflections
        if(tReflect > 0){

            _rTotal -= rReflect;
            _tFeeTotal += tReflect;
        }

        // Take token fee
        if(tTokens > 0){

            _rOwned[Wallet_Tokens] += rTokens;
            if(_isExcluded[Wallet_Tokens])
            _tOwned[Wallet_Tokens] += tTokens;

            emit Transfer(sender, Wallet_Tokens, tTokens);

        }

        // Take fees that require processing during swap and liquify
        if(tSwapFeeTotal > 0){

            _rOwned[address(this)] += rSwapFeeTotal;
            if(_isExcluded[address(this)])
            _tOwned[address(this)] += tSwapFeeTotal;

            emit Transfer(sender, address(this), tSwapFeeTotal);

            // Increase the transaction counter
            swapCounter++;
                
        }

        // Handle tokens for burn
        if(tBurn > 0){

            _rOwned[Wallet_Burn] += rBurn;
            if(_isExcluded[Wallet_Burn])
            _tOwned[Wallet_Burn] += tBurn;
            
            emit Transfer(sender, Wallet_Burn, tBurn);

            

        }



    }


   

    // This function is required so that the contract can receive BNB during fee processing
    receive() external payable {}




}



/*

Custom Contract by Gen - Fully Doxed Developer
Telegram: https://t.me/GenTokens_GEN

*/