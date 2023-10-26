/**
 *Submitted for verification at Etherscan.io on 2023-10-05
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.21;

interface IdexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface In {
    //events
    event SwapThresholdChange(uint threshold);
    event OverLiquifiedThresholdChange(uint threshold);
    event OnSetTaxes(
        uint buy, 
        uint sell, 
        uint transfer_, 
        uint ins, 
        uint b3_1, 
        uint b3_2
    );
    event ManualSwapChange(bool status);
    event MaxWalletBalanceUpdated(uint256 percent);
    event MaxTransactionAmountUpdated(uint256 percent);
    event ExcludeAccount(address indexed account, bool indexed exclude);
    event ExcludeFromWalletLimits(address indexed account, bool indexed exclude);
    event ExcludeFromTransactionLimits(address indexed account, bool indexed exclude);
    event OwnerSwap();
    event OnEnableTrading();
    event OnProlongLPLock(uint UnlockTimestamp);
    event OnReleaseLP();
    event RecoverETH();
    event NewPairSet(address Pair, bool Add);
    event LimitTo20PercentLP();
    event NewRouterSet(address _newdex);
    event NewFeeWalletsSet(
        address indexed NewInsWallet, 
        address indexed NewB3_1Wallet, 
        address indexed NewB3_2Wallet
                    );
    event RecoverTokens(uint256 amount);
    event TokensAirdroped(address indexed sender, uint256 total, uint256 amount);
}

interface IdexRouter {
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
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

// File @openzeppelin/contracts/utils/[email protected]
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract N is IERC20, Ownable, In {
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => bool) private excludedFromWalletLimits;
    mapping(address => bool) private excludedFromTransactionLimits;
    mapping(address => bool) public excludedFromFees;

    mapping(address=>bool) public isPair;

    //strings
    string private constant _name = 'nsurance';
    string private constant _symbol = 'n';

    //uints
    uint private constant InitialSupply= 1_000_000_000_000 * 10**_decimals;

    //Tax by divisor of MAXTAXDENOMINATOR
    uint public buyTax = 4500;
    uint public sellTax = 4500;
    uint public transferTax = 100;

    //insPct+b3_1Pct+b3_2Pct must equal TAX_DENOMINATOR
    uint[] private taxStructure = [3500, 3500, 3000, 2500, 1500, 1000, 400];
    uint public insPct=3333;
    uint public b3_1Pct=3334;
    uint public b3_2Pct=3333;
    uint constant TAX_DENOMINATOR=10000;
    uint constant MAXBUYTAXDENOMINATOR=1000;
    uint constant MAXTRANSFERTAXDENOMINATOR=1000;
    uint constant MAXSELLTAXDENOMINATOR=1000;
    uint public currentTaxIndex = 0;
    //swapTreshold dynamic by LP pair balance
    uint public swapTreshold=4;
    uint private LaunchBlock;
    uint public tokensForInsurance;
    uint public tokensForB3_1;
    uint public tokensForB3_2;
    uint8 private constant _decimals = 18;
    uint256 public maxTransactionAmount;
    uint256 public maxWalletBalance;

    IdexRouter private  _dexRouter;

    //addresses
    address private dexRouter;
    address private _dexPairAddress;
    address constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address private insuranceWallet;
    address private b3_1Wallet;
    address private b3_2Wallet;

    //bools
    bool public _b3_2tokenrcvr;
    bool private _isSwappingContractModifier;
    bool public manualSwap;

    //modifiers
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    constructor (
        address _DexRouter, 
        address _insWallet, 
        address _b3_1Wallet, 
        address _b3_2Wallet
    ) {
        // Assigning parameters to state variables
        insuranceWallet = _insWallet;
        b3_1Wallet = _b3_1Wallet;
        b3_2Wallet = _b3_2Wallet;
        dexRouter = _DexRouter;

        // Hardcoded addresses for allocations
        address[5] memory initialAddresses = [
            0xbe25b92099D428F959549cBE8deab0e20a82918d,
            0xC9E7c47bF63c71452f50EAA1a69545a170278998,
            0x85aE03A5846324F053BD07e28D7c14B75e90E26D,
            0x3Ec897771308c83f3a442ab275a1F0Fec82e365a,
            0x44762b347bE037d5C0f098530FdfD5370f19E471
        ];

        uint[5] memory initialAmounts = [
            36_666_666_667 * 10**_decimals,
            25_000_000_000 * 10**_decimals,
            36_666_666_667 * 10**_decimals,
            93_958_333_333 * 10**_decimals,
            146_666_666_667 * 10**_decimals
        ];

        SetInitialBalances(initialAddresses, initialAmounts);

        // Setting exclusions
        SetExclusions(
            [msg.sender, dexRouter, address(this), 
            0xbe25b92099D428F959549cBE8deab0e20a82918d,
            0xC9E7c47bF63c71452f50EAA1a69545a170278998,
            0x85aE03A5846324F053BD07e28D7c14B75e90E26D,
            0x3Ec897771308c83f3a442ab275a1F0Fec82e365a,
            0x44762b347bE037d5C0f098530FdfD5370f19E471,
            0x5E1EcF03D1D776CAff4f47150610519dFb014161,
            0xA576463273E4A459B39a518be7fc79EbecF6B7c7],
            [msg.sender, deadWallet, address(this), 
            0xbe25b92099D428F959549cBE8deab0e20a82918d,
            0xC9E7c47bF63c71452f50EAA1a69545a170278998,
            0x85aE03A5846324F053BD07e28D7c14B75e90E26D,
            0x3Ec897771308c83f3a442ab275a1F0Fec82e365a,
            0x44762b347bE037d5C0f098530FdfD5370f19E471,
            0x5E1EcF03D1D776CAff4f47150610519dFb014161,
            0xA576463273E4A459B39a518be7fc79EbecF6B7c7],
            [msg.sender, deadWallet, address(this), 
            0xbe25b92099D428F959549cBE8deab0e20a82918d,
            0xC9E7c47bF63c71452f50EAA1a69545a170278998,
            0x85aE03A5846324F053BD07e28D7c14B75e90E26D,
            0x3Ec897771308c83f3a442ab275a1F0Fec82e365a,
            0x44762b347bE037d5C0f098530FdfD5370f19E471,
            0x5E1EcF03D1D776CAff4f47150610519dFb014161,
            0xA576463273E4A459B39a518be7fc79EbecF6B7c7]
        );
    }

    function setB3_2tokenRCVR (bool yesNo) external onlyOwner {
        _b3_2tokenrcvr = yesNo;
    }

    /**
    * @notice Set Initial Balances
    * @dev This function is for set initial balances.
    * @param addresses The array of address to be set initial balances.
    * @param amounts The array of amount to be set initial balances.
     */
    function SetInitialBalances(address[5] memory addresses, uint[5] memory amounts) internal {
        require(addresses.length == amounts.length, "Mismatched arrays length");
        uint256 totalAllocatedAmount = 0;
        for (uint256 i = 0; i < addresses.length; i++) {
            _balances[addresses[i]] = amounts[i];
            totalAllocatedAmount += amounts[i];
            emit Transfer(address(0), addresses[i], amounts[i]);
        }
        uint contractBalance = 50_000_000_000 * 10**_decimals;
        _balances[address(this)] = contractBalance;
        emit Transfer(address(0), address(this), contractBalance);
        uint256 deployerBalance = InitialSupply - totalAllocatedAmount - contractBalance;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
    }

    /** 
    * @notice Set Exclusions
    * @dev This function is for set exclusions.
    * @param feeExclusions The array of address to be excluded from fees.
    * @param walletLimitExclusions The array of address to be excluded from wallet limits.
    * @param transactionLimitExclusions The array of address to be excluded from transaction limits.
     */
    function SetExclusions(
        address[10] memory feeExclusions, 
        address[10] memory walletLimitExclusions, 
        address[10] memory transactionLimitExclusions
    ) internal {
        for (uint256 i = 0; i < feeExclusions.length; i++) {
            excludedFromFees[feeExclusions[i]] = true;
        }
        for (uint256 i = 0; i < walletLimitExclusions.length; i++) {
            excludedFromWalletLimits[walletLimitExclusions[i]] = true;
        }
        for (uint256 i = 0; i < transactionLimitExclusions.length; i++) {
            excludedFromTransactionLimits[transactionLimitExclusions[i]] = true;
        }
    }

    /**
     * @dev Decrease the tax rates for both buy and sell operations to the next lower value in the structure
     */
    function decreaseTaxRate() external payable onlyOwner {
        require(currentTaxIndex < taxStructure.length - 1, "Already at the lowest tax rate");

        // Move to the next lower tax rate in the tax structure
        currentTaxIndex++;

        // Update the buy and sell tax rates
        buyTax = taxStructure[currentTaxIndex];
        sellTax = taxStructure[currentTaxIndex];
    }

    /**
    * @notice Internal function to transfer tokens from one address to another.
     */
    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        if(excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);

        else {
            require(LaunchBlock>0,"trading not yet enabled");
            _taxedTransfer(sender,recipient,amount);
        }
    }

    /**
    * @notice Transfer amount of tokens with fees.
    * @param sender The address of user to send tokens.
    * @param recipient The address of user to be recieved tokens.
    * @param amount The token amount to transfer.
    */
    function _taxedTransfer(address sender, address recipient, uint amount) internal {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        bool excludedFromWalletLimitsAccount = excludedFromWalletLimits[sender] || excludedFromWalletLimits[recipient];
        bool excludedFromTXNLimitsAccount = excludedFromTransactionLimits[sender] || excludedFromTransactionLimits[recipient];
        if (
            isPair[sender] &&
            !excludedFromWalletLimitsAccount
        ) {
            if(!excludedFromTXNLimitsAccount){
                require(
                amount <= maxTransactionAmount,
                "Transfer amount exceeds the maxTxAmount."
                );
            }
            uint256 contractBalanceRecepient = balanceOf(recipient);
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
            );
        } else if (
            isPair[recipient] &&
            !excludedFromTXNLimitsAccount
        ) {
            require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

        bool isBuy=isPair[sender];
        bool isSell=isPair[recipient];
        uint tax;

        if(isSell) {  // in case that sender is dex token pair.
            uint SellTaxDuration=10;
            if(block.number<LaunchBlock+SellTaxDuration){
                tax=_getStartTax();
            } else tax=sellTax;
        }
        else if(isBuy) {    // in case that recieve is dex token pair.
            uint BuyTaxDuration=10;
            if(block.number<LaunchBlock+BuyTaxDuration){
                tax=_getStartTax();
            } else tax=buyTax;
        } else { 
            uint256 contractBalanceRecepient = balanceOf(recipient);
            if(!excludedFromWalletLimitsAccount){
            require(
                contractBalanceRecepient + amount <= maxWalletBalance,
                "Exceeds maximum wallet token amount."
                );
            }
            uint TransferTaxDuration=10;
            if(block.number<LaunchBlock+TransferTaxDuration){
                tax=_getStartTax();
            } else tax=transferTax;
        }

        if((sender!=_dexPairAddress)&&(!manualSwap)&&(!_isSwappingContractModifier))
        _swapContractToken(false);
        uint contractToken=_calculateFee(amount, tax, insPct+b3_1Pct+b3_2Pct);
        tokensForInsurance+=_calculateFee(amount, tax, insPct);
        tokensForB3_1+=_calculateFee(amount, tax, b3_1Pct);
        tokensForB3_2+=_calculateFee(amount, tax, b3_2Pct);
        uint taxedAmount=amount-contractToken;

        _balances[sender]-=amount;
        _balances[address(this)] += contractToken;
        _balances[recipient]+=taxedAmount;
        
        emit Transfer(sender,recipient,taxedAmount);
    }

    /**
    * @notice Provides start tax to transfer function.
    * @return The tax to calculate fee with.
    */
    function _getStartTax() internal pure returns (uint){
        uint startTax=9000;
        return startTax;
    }

    /**
    * @notice Calculates fee based of set amounts
    * @param amount The amount to calculate fee on
    * @param tax The tax to calculate fee with
    * @param taxPercent The tax percent to calculate fee with
    */
    function _calculateFee(uint amount, uint tax, uint taxPercent) internal pure returns (uint) {
        return (amount*tax*taxPercent) / (TAX_DENOMINATOR*TAX_DENOMINATOR);
    }

    /**
    * @notice Transfer amount of tokens without fees.
    * @dev In feelessTransfer, there isn't limit as well.
    * @param sender The address of user to send tokens.
    * @param recipient The address of user to be recieveid tokens.
    * @param amount The token amount to transfer.
    */
    function _feelessTransfer(address sender, address recipient, uint amount) internal {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender]-=amount;
        _balances[recipient]+=amount;
        emit Transfer(sender,recipient,amount);
    }

    /**
    * @notice Swap tokens for eth.
    * @dev This function is for swap tokens for eth.
    * @param newSwapTresholdPermille Set the swap % of LP pair holdings.
     */
    function setSwapTreshold(uint newSwapTresholdPermille) external payable onlyOwner{
        require(newSwapTresholdPermille<=10);//MaxTreshold= 1%
        swapTreshold=newSwapTresholdPermille;
        emit SwapThresholdChange(newSwapTresholdPermille);
    }

    /**
    * @notice Set the current taxes. ins+b3_1+b3_2 must equal TAX_DENOMINATOR. 
    * @notice buy must be less than MAXBUYTAXDENOMINATOR.
    * @notice sell must be less than MAXSELLTAXDENOMINATOR.
    * @notice transfer_ must be less than MAXTRANSFERTAXDENOMINATOR.
    * @dev This function is for set the current taxes.
    * @param buy The buy tax.
    * @param sell The sell tax.
    * @param transfer_ The transfer tax.
    * @param ins The insurance tax.
    * @param b3_1 The b3_1 tax.
    * @param b3_2 The b3_2 tax.
     */
    function SetTaxes(
        uint buy, 
        uint sell, 
        uint transfer_, 
        uint ins, 
        uint b3_1, 
        uint b3_2
    ) external payable onlyOwner{
        require(
            buy<=MAXBUYTAXDENOMINATOR &&
            sell<=MAXSELLTAXDENOMINATOR &&
            transfer_<=MAXTRANSFERTAXDENOMINATOR,
            "Tax exceeds maxTax"
        );
        require(
            ins+b3_1+b3_2==TAX_DENOMINATOR,
            "Taxes don't add up to denominator"
        );

        buyTax=buy;
        sellTax=sell;
        transferTax=transfer_;
        insPct=ins;
        b3_1Pct=b3_1;
        b3_2Pct=b3_2;
        emit OnSetTaxes(buy, sell, transfer_, ins, b3_1, b3_2);
    }

    /**
     * @dev Swaps contract tokens based on various parameters.
     * @param ignoreLimits Whether to ignore the token swap limits.
     */
  function _swapContractToken(bool ignoreLimits) internal lockTheSwap {
        uint contractBalance = _balances[address(this)];
        uint totalTax = insPct + b3_1Pct + b3_2Pct;
        uint tokensToSwap = (_balances[_dexPairAddress] * swapTreshold) / 1000;

        if (totalTax == 0) return;

        if (ignoreLimits) {
            tokensToSwap = _balances[address(this)];
        } else if (contractBalance < tokensToSwap) {
            return;
        }

        uint initialETHBalance = address(this).balance;

        _swapTokenForETH(tokensToSwap);

        uint newETH = address(this).balance - initialETHBalance;
        uint ethBalance = newETH;

        uint tokensForThisInsurance = (tokensToSwap * insPct) / totalTax;
        uint tokensForThisB3_1 = (tokensToSwap * b3_1Pct) / totalTax;
        uint tokensForThisB3_2 = (tokensToSwap * b3_2Pct) / totalTax;
        uint ethForInsurance = (ethBalance * tokensForThisInsurance) / tokensToSwap;
        uint ethForB3_1 = (ethBalance * tokensForThisB3_1) / tokensToSwap;
        uint ethForB3_2 = (ethBalance * tokensForThisB3_2) / tokensToSwap;

        if (tokensForThisInsurance != 0) {
            (bool sent,) = insuranceWallet.call{value: ethForInsurance}("");
            require(sent, "Failed to send ETH to Insurance wallet");
            tokensForInsurance -= tokensForThisInsurance;
        }

        if (tokensForThisB3_1 != 0) {
            (bool sent,) = b3_1Wallet.call{value: ethForB3_1}("");
            require(sent, "Failed to send ETH to B3_1 wallet");
            tokensForB3_1 -= tokensForThisB3_1;
        }

        if (tokensForThisB3_2 != 0) {
            if (_b3_2tokenrcvr) {
                _balances[b3_2Wallet] += tokensForThisB3_2;
                tokensForB3_2 -= tokensForThisB3_2;
                emit Transfer(address(this), b3_2Wallet, tokensForThisB3_2);
            } else {
                (bool sent,) = b3_2Wallet.call{value: ethForB3_2}("");
                require(sent, "Failed to send ETH to B3_2 wallet");
                tokensForB3_2 -= tokensForThisB3_2;
            }
        }
    }

    /**
    * @notice Swap tokens for eth.
    * @dev This function is for swap tokens for eth.
    * @param amount The token amount to swap.
    */
    function _swapTokenForETH(uint amount) private {
        _approve(address(this), address(_dexRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();

        try _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        ){}
        catch{}
    }

    /**
    * @notice Add initial liquidity to dex.
    * @dev This function is for add liquidity to dex.
     */
    function _addInitLiquidity() private {
        uint tokenAmount = balanceOf(address(this));
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    /**
    * @notice Get Burned tokens.
    * @dev This function is for get burned tokens.
    */
    function getBurnedTokens() public view returns(uint){
        return _balances[address(0xdead)];
    }

    /**
    * @notice Get circulating supply.
    * @dev This function is for get circulating supply.
     */
    function getCirculatingSupply() public view returns(uint){
        return InitialSupply-_balances[address(0xdead)];
    }

    /**
    * @notice Set the current Pair.
    * @dev This function is for set the current Pair.
    * @param Pair The pair address.
    * @param Add The status of add or remove.
     */
    function SetPair(address Pair, bool Add) internal {
        require(Pair!=_dexPairAddress,"can't readd pair");
        require(Pair != address(0),"Address should not be 0");
        isPair[Pair]=Add;
        emit NewPairSet(Pair,Add);
    }

    /**
    * @notice Add a pair.
    * @dev This function is for add a pair.
    * @param Pair The pair address.
     */
    function AddPair(address Pair) external payable onlyOwner{
        SetPair(Pair,true);
    }

    /**
    * @notice Add a pair.
    * @dev This function is for add a pair.
    * @param Pair The pair address.
     */
    function RemovePair(address Pair) external payable onlyOwner{
        SetPair(Pair,false);
    }

    /**
    * @notice Set Manual Swap Mode
    * @dev This function is for set manual swap mode.
    * @param manual The status of manual swap mode.
     */
    function SwitchManualSwap(bool manual) external payable onlyOwner{
        manualSwap=manual;
        emit ManualSwapChange(manual);
    }

    /**
    * @notice Swap contract tokens.
    * @dev This function is for swap contract tokens.
    * @param all The status of swap all tokens in contract.
     */
    function SwapContractToken(bool all) external payable onlyOwner{
        _swapContractToken(all);
        emit OwnerSwap();
    }

    /**
    * @notice Set a new router address
    * @dev This function is for set a new router address.
    * @param _newdex The new router address.
     */
    function SetNewRouter(address _newdex) external payable onlyOwner{
        require(_newdex != address(0),"Address should not be 0");
        require(_newdex != dexRouter,"Address is same");
        dexRouter = _newdex;
        emit NewRouterSet(_newdex);
    }

    /**
    * @notice Set new tax receiver wallets.
    * @dev This function is for set new tax receiver wallets.
    * @param NewInsWallet The new insurance wallet address.
    * @param NewB3_1Wallet The new b3_1 wallet address.
    * @param NewB3_2Wallet The new b3_2 wallet address.
     */
    function SetFeeWallets(
        address NewInsWallet, 
        address NewB3_1Wallet, 
        address NewB3_2Wallet
    ) external payable onlyOwner{
        require(NewInsWallet != address(0),"Address should not be 0");
        require(NewB3_1Wallet != address(0),"Address should not be 0");
        require(NewB3_2Wallet != address(0),"Address should not be 0");

        insuranceWallet = NewInsWallet;
        b3_1Wallet = NewB3_1Wallet;
        b3_2Wallet = NewB3_2Wallet;
        emit NewFeeWalletsSet(
            NewInsWallet, 
            NewB3_1Wallet, 
            NewB3_2Wallet
        );
    }

    /**
    * @notice Set Wallet Limits
    * @dev This function is for set wallet limits.
    * @param walPct The max wallet balance percent.
    * @param txnPct The max transaction amount percent.
     */
    function SetLimits(uint256 walPct, uint256 txnPct) external payable onlyOwner {
        require(walPct >= 10, "min 0.1%");
        require(walPct <= 10000, "max 100%");
        maxWalletBalance = InitialSupply * walPct / 10000;
        emit MaxWalletBalanceUpdated(walPct);

        require(txnPct >= 10, "min 0.1%");
        require(txnPct <= 10000, "max 100%");
        maxTransactionAmount = InitialSupply * txnPct / 10000;
        emit MaxTransactionAmountUpdated(txnPct);
    }

    /**
    * @notice AirDrop Tokens
    * @dev This function is for airdrop tokens.
    * @param accounts The array of address to be airdroped.
    * @param amounts The array of amount to be airdroped.
     */
    function Airdropper(address[] calldata accounts, uint256[] calldata amounts) external payable onlyOwner {
        uint256 length = accounts.length;
        require (length == amounts.length, "array length mismatched");
        uint256 airdropAmount = 0;
        
        for (uint256 i = 0; i < length; i++) {
            // updating balance directly instead of calling transfer to save gas
            _balances[accounts[i]] += amounts[i];
            airdropAmount += amounts[i];
            emit Transfer(msg.sender, accounts[i], amounts[i]);
        }
        _balances[msg.sender] -= airdropAmount;

        emit TokensAirdroped(msg.sender, length, airdropAmount);
    }

    /**
    * @notice Set to exclude an address from fees.
    * @dev This function is for set to exclude an address from fees.
    * @param account The address of user to be excluded from fees.
    * @param exclude The status of exclude.
    */
    function ExcludeAccountFromFees(address account, bool exclude) external payable onlyOwner{
        require(account!=address(this),"can't Include the contract");
        require(account != address(0),"Address should not be 0");
        excludedFromFees[account]=exclude;
        emit ExcludeAccount(account,exclude);
    }

    /**
    * @notice Set to exclude an address from transaction limits.
    * @dev This function is for set to exclude an address from transaction limits.
    * @param account The address of user to be excluded from transaction limits.
    * @param exclude The status of exclude.
    */
    function SetExcludedAccountFromTransactionLimits(address account, bool exclude) external payable onlyOwner{
        require(account != address(0),"Address should not be 0");
        excludedFromTransactionLimits[account]=exclude;
        emit ExcludeFromTransactionLimits(account,exclude);
    }

    /** 
    * @notice Set to exclude an address from wallet limits.
    * @dev This function is for set to exclude an address from wallet limits.
    * @param account The address of user to be excluded from wallet limits.
    * @param exclude The status of exclude.
    */
    function SetExcludedAccountFromWalletLimits(address account, bool exclude) external payable onlyOwner{
        require(account != address(0),"Address should not be 0");
        excludedFromWalletLimits[account]=exclude;
        emit ExcludeFromWalletLimits(account,exclude);
    }

    /**
    * @notice Used to start trading.
    * @dev This function is for used to start trading.
    */
    function SetupEnableTrading() external payable onlyOwner{
        require(LaunchBlock==0,"AlreadyLaunched");

        _dexRouter = IdexRouter(dexRouter);
        _dexPairAddress = IdexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        isPair[_dexPairAddress]=true;

        _addInitLiquidity();

        LaunchBlock=block.number;

        maxWalletBalance = InitialSupply * 12 / 10000; // 0.12%
        maxTransactionAmount = InitialSupply * 12 / 10000; // 0.12%
        emit OnEnableTrading();
    }

    receive() external payable {}

    function getOwner() external view override returns (address) {return owner();}
    function name() external pure override returns (string memory) {return _name;}
    function symbol() external pure override returns (string memory) {return _symbol;}
    function decimals() external pure override returns (uint8) {return _decimals;}
    function totalSupply() external pure override returns (uint) {return InitialSupply;}
    function balanceOf(address account) public view override returns (uint) {return _balances[account];}
    function isExcludedFromWalletLimits(address account) public view returns(bool) {return excludedFromWalletLimits[account];}
    function isExcludedFromTransferLimits(address account) public view returns(bool) {return excludedFromTransactionLimits[account];}
    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }
    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address _owner, address spender, uint amount) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /**
    * @notice Used to remove excess ETH from contract
    * @dev This function is for used to remove excess ETH from contract.
    * @param amountPercentage The amount percentage to recover.
     */
    function emergencyETHrecovery(uint256 amountPercentage) external payable onlyOwner {
        uint256 amountETH = address(this).balance;
        (bool sent,)=msg.sender.call{value:amountETH * amountPercentage / 100}("");
            sent=true;
        emit RecoverETH();
    }
    
    /**
    * @notice Used to remove excess Tokens from contract
    * @dev This function is for used to remove excess Tokens from contract.
    * @param tokenAddress The token address to recover.
    * @param amountPercentage The amount percentage to recover.
     */
    function emergencyTokenrecovery(address tokenAddress, uint256 amountPercentage) external payable onlyOwner {
        require(tokenAddress!=address(0));
        require(tokenAddress!=address(_dexPairAddress));
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = token.balanceOf(address(this));
        token.transfer(msg.sender, tokenAmount * amountPercentage / 100);

        emit RecoverTokens(tokenAmount);
    }

}