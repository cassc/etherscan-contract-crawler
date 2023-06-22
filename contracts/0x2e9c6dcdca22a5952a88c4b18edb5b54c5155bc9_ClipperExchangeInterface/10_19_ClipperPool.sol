// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

import "./libraries/UniERC20.sol";
import "./libraries/Sqrt.sol";
import "./libraries/SafeAggregatorInterface.sol";

import "./ClipperExchangeInterface.sol";
import "./ClipperEscapeContract.sol";
import "./ClipperDeposit.sol";

/*
    ClipperPool is the central "vault" contract of the Clipper exchange.
    
    Its job is to hold and track the pool assets, and is the referenceable ERC20
    pool token address as well.

    It is the "center" of the set of contracts, and its owner has owner-level controls
    of the exchange interface and deposit contracts.

    To perform swaps, we use the "deposit / swap / sync" modality of Uniswapv2 and Matcha.
    The idea is that a swapper inititally places their liquidity into our pool to initiate a swap.
    We will then check current balances against last known good values, then perform the swap.
    Following the swap, we then sync so that last known good values match balances.

    Our numeraire asset in the pool is ETH.
*/

contract ClipperPool is ERC20, ReentrancyGuard, Ownable {
    using Sqrt for uint256;
    using UniERC20 for ERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeAggregatorInterface for AggregatorV3Interface;

    address constant CLIPPER_ETH_SIGIL = address(0);

    // fullyDilutedSupply tracks the *actual* size of our pool, including locked-up deposits
    // fullyDilutedSupply >= ERC20 totalSupply
    uint256 public fullyDilutedSupply;

    // These contracts are created by the constructor
    // depositContract handles token deposit, locking, and transfer to the pool
    address public depositContract;
    // escapeContract is where the escaped tokens go
    address public escapeContract;

    address public triage;
    
    // Passed to the constructor
    ClipperExchangeInterface public exchangeInterfaceContract;

    uint constant FIVE_DAYS_IN_SECONDS = 432000;
    uint256 constant MAXIMUM_MINT_IN_FIVE_DAYS_BASIS_POINTS = 500;
    uint lastMint;

    // Asset represents an ERC20 token in our pool (not ETH)
    struct Asset {
        AggregatorV3Interface oracle; // Chainlink oracle interface
        uint256 marketShare; // Where 100 in market share is equal to ETH in pool weight. Higher numbers = Less of a share.
        uint256 marketShareDecimalsAdjusted;
        uint256 lastBalance; // last recorded balance (for deposit / swap / sync modality)
        uint removalTime; // time at which we can remove this asset (0 by default, meaning can't remove it)
    }

    mapping(ERC20 => Asset) assets;
    
    EnumerableSet.AddressSet private assetSet;

    // corresponds to "lastBalance", but for ETH
    // Note the other fields in Asset are not necessary:
    // marketShare is always 1e18*100 (if not otherwise set)
    // ETH is not removable, and there is no nextAsset
    uint256 lastETHBalance;
    AggregatorV3Interface public ethOracle;
    uint256 private ethMarketShareDecimalsAdjusted;

    uint256 constant DEFAULT_DECIMALS = 18;
    uint256 constant ETH_MARKET_WEIGHT = 100;
    uint256 constant WEI_PER_ETH = 1e18;
    uint256 constant ETH_WEIGHT_DECIMALS_ADJUSTED = 1e20;
    
    event UnlockedDeposit(
        address indexed account,
        uint256 amount
    );

    event TokenRemovalActivated(
        address token,
        uint timestamp
    );

    event TokenModified(
        address token,
        uint256 marketShare,
        address oracle
    );

    event ContractModified(
        address newContract,
        bytes contractType
    );

    modifier triageOrOwnerOnly() {
        require(msg.sender==this.owner() || msg.sender==triage, "Clipper: Only owner or triage");
        _;
    }

    modifier depositContractOnly() {
        require(msg.sender==depositContract, "Clipper: Deposit contract only");
        _;
    }

    modifier exchangeContractOnly() {
        require(msg.sender==address(exchangeInterfaceContract), "Clipper: Exchange contract only");
        _;
    }

    modifier depositOrExchangeContractOnly() {
        require(msg.sender==address(exchangeInterfaceContract) || msg.sender==depositContract, "Clipper: Deposit or Exchange Only");
        _;
    }

    /*
        Constructor must take ETH (to start the pool).
        Exchange Interface must already be created.
    */ 
    constructor(ClipperExchangeInterface initialExchangeInterface) payable ERC20("Clipper Pool Token", "CLPRPL") {
        require(msg.value > 0, "Clipper: Must deposit ETH");
        
        _mint(msg.sender, msg.value*10);
        lastETHBalance = msg.value;
        fullyDilutedSupply = totalSupply();
        
        exchangeInterfaceContract = initialExchangeInterface;

        // Create the deposit and escape contracts
        // Can't do this for the exchangeInterfaceContract because it's too large
        depositContract = address(new ClipperDeposit());
        escapeContract = address(new ClipperEscapeContract());
    }

    // We want to be able to receive ETH, either from deposit or swap
    // Note that we don't update lastETHBalance here (b/c that would invalidate swap)
    receive() external payable {
    }

    /* TOKEN AND ASSET FUNCTIONS */
    function nTokens() public view returns (uint) {
        return assetSet.length();
    }

    function tokenAt(uint i) public view returns (address) {
        return assetSet.at(i);
    } 


    function isToken(ERC20 token) public view returns (bool) {
        return assetSet.contains(address(token));
    }

    function isTradable(ERC20 token) public view returns (bool) {
        return token.isETH() || isToken(token);
    }

    function lastBalance(ERC20 token) public view returns (uint256) {
        return token.isETH() ? lastETHBalance : assets[token].lastBalance;
    }

    // marketShare is an inverse weighting for the market maker's desired portfolio:
    // 100 = ETH weight.
    // 200 = half the weight of ETH
    // 50 = twice the weight of ETH
    function upsertAsset(ERC20 token, AggregatorV3Interface oracle, uint256 rawMarketShare) external onlyOwner {
        require(rawMarketShare > 0, "Clipper: Market share must be positive");
        // Oracle returns a response that is in base oracle.decimals()
        // corresponding to one "unit" of input, in base token.decimals()

        // We want to return an adjustment figure with DEFAULT_DECIMALS

        // When both of these are 18 (DEFAULT_DECIMALS), we let the marketShare go straight through
        // We need to adjust the oracle's response so that it corresponds to 

        uint256 sumDecimals = token.decimals()+oracle.decimals();
        uint256 marketShareDecimalsAdjusted = rawMarketShare*WEI_PER_ETH;
        if(sumDecimals < 2*DEFAULT_DECIMALS){
            // Make it larger
            marketShareDecimalsAdjusted = marketShareDecimalsAdjusted*(10**(2*DEFAULT_DECIMALS-sumDecimals));
        } else if(sumDecimals > 2*DEFAULT_DECIMALS){
            // Make it smaller
            marketShareDecimalsAdjusted = marketShareDecimalsAdjusted/(10**(sumDecimals-2*DEFAULT_DECIMALS));
        }

        assetSet.add(address(token));
        assets[token] = Asset(oracle, rawMarketShare, marketShareDecimalsAdjusted, token.balanceOf(address(this)), 0);
        
        emit TokenModified(address(token), rawMarketShare, address(oracle));  
    }

    function getOracle(ERC20 token) public view returns (AggregatorV3Interface) {
        if(token.isETH()){
            return ethOracle;
        } else{
            return assets[token].oracle;
        }
    }

    function getMarketShare(ERC20 token) public view returns (uint256) {
        if(token.isETH()){
            return ETH_MARKET_WEIGHT;
        } else {
            return assets[token].marketShare;
        }
    }

    /*
        Only tokens that are not traded can be escaped.
        This means Token Removal is a serious issue for security.

        We emit an event prior to removing the token, and mandate a five-day cool off.
        This allows pool holders to potentially withdraw. 
    */
    function activateRemoval(ERC20 token) external onlyOwner {
        require(isToken(token), "Clipper: Asset not present");
        assets[token].removalTime = block.timestamp + FIVE_DAYS_IN_SECONDS;
        emit TokenRemovalActivated(address(token), assets[token].removalTime);
    }

    function clearRemoval(ERC20 token) external triageOrOwnerOnly {
        require(isToken(token), "Clipper: Asset not present");
        delete assets[token].removalTime;
    }

    function removeToken(ERC20 token) external onlyOwner {
        require(isToken(token), "Clipper: Asset not present");
        require(assets[token].removalTime > 0 && (assets[token].removalTime < block.timestamp), "Not ready");
        assetSet.remove(address(token));
        delete assets[token];
    }

    // Can escape ETH only if all the tokens have been removed
    // i.e., just ETH left in the assetSet
    function escape(ERC20 token) external onlyOwner {
        require(!isTradable(token) || (assetSet.length()==0 && address(token)==CLIPPER_ETH_SIGIL), "Can only escape nontradable");
        // No need to _sync here since it's not tradable
        token.uniTransfer(escapeContract, token.uniBalanceOf(address(this)));
    }

    function modifyExchangeInterfaceContract(address newContract) external onlyOwner {
        exchangeInterfaceContract = ClipperExchangeInterface(newContract);
        emit ContractModified(newContract, "exchangeInterfaceContract modified");
    }

    function modifyDepositContract(address newContract) external onlyOwner {
        depositContract = newContract;
        emit ContractModified(newContract, "depositContract modified");
    }

    function modifyTriage(address newTriageAddress) external onlyOwner {
        triage = newTriageAddress;
        emit ContractModified(newTriageAddress, "triage address modified");
    }

    function modifyEthOracle(AggregatorV3Interface newOracle) external onlyOwner {
        if(address(newOracle)==address(0)){
            delete ethOracle;
            ethMarketShareDecimalsAdjusted=ETH_WEIGHT_DECIMALS_ADJUSTED;
        } else {
            uint256 sumDecimals = DEFAULT_DECIMALS+newOracle.decimals();
            ethMarketShareDecimalsAdjusted = ETH_WEIGHT_DECIMALS_ADJUSTED;
            if(sumDecimals < 2*DEFAULT_DECIMALS){
                // Make it larger
                ethMarketShareDecimalsAdjusted = ethMarketShareDecimalsAdjusted*(10**(2*DEFAULT_DECIMALS-sumDecimals));
            } else if(sumDecimals > 2*DEFAULT_DECIMALS){
                // Make it smaller
                ethMarketShareDecimalsAdjusted = ethMarketShareDecimalsAdjusted/(10**(sumDecimals-2*DEFAULT_DECIMALS));
            }
            ethOracle = newOracle;
        }
        emit TokenModified(CLIPPER_ETH_SIGIL, ETH_MARKET_WEIGHT, address(newOracle));
    }

    // We allow minting, but:
    // (1) need to keep track of the fullyDilutedSupply
    // (2) only limited minting is allowed (5% every 5 days)
    function mint(address to, uint256 amount) external onlyOwner {
        require(block.timestamp > lastMint+FIVE_DAYS_IN_SECONDS, "Clipper: Pool token can mint once in 5 days");
        // amount+fullyDilutedSupply <= 1.05*fullyDilutedSupply 
        // amount <= 0.05*fullyDilutedSupply
        require(amount < (MAXIMUM_MINT_IN_FIVE_DAYS_BASIS_POINTS*fullyDilutedSupply)/1e4, "Clipper: Mint amount exceeded");
        _mint(to, amount);
        fullyDilutedSupply = fullyDilutedSupply+amount;
        lastMint = block.timestamp;
    }

    // Optimized function for exchange - avoids two external calls to the below function
    function balancesAndMultipliers(ERC20 inputToken, ERC20 outputToken) external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        require(isTradable(inputToken) && isTradable(outputToken), "Clipper: Untradable asset(s)");
        (uint256 x, uint256 M, uint256 marketWeightX) = findBalanceAndMultiplier(inputToken);
        (uint256 y, uint256 N, uint256 marketWeightY) = findBalanceAndMultiplier(outputToken);

        return (x,y,M,N,marketWeightX,marketWeightY);
    }

    // Returns the last balance and oracle multiplier for ETH or ERC20
    function findBalanceAndMultiplier(ERC20 token) public view returns(uint256 balance, uint256 M, uint256 marketWeight){
        if(token.isETH()){
            balance = lastETHBalance;
            marketWeight = ETH_MARKET_WEIGHT;
            // If ethOracle is unset our numeraire is ETH
            if(address(ethOracle)==address(0)){
                M = WEI_PER_ETH;
            } else {
                uint256 weiPerInput = ethOracle.safeUnsignedLatest();
                M = (ethMarketShareDecimalsAdjusted*weiPerInput)/ETH_WEIGHT_DECIMALS_ADJUSTED;
            }
        } else {
            Asset memory the_asset = assets[token];
            uint256 weiPerInput = the_asset.oracle.safeUnsignedLatest();
            marketWeight = the_asset.marketShare;
            // "marketShareDecimalsAdjusted" is the market share times 10**(18-token.decimals())
            uint256 marketWeightDecimals = the_asset.marketShareDecimalsAdjusted;
            balance = the_asset.lastBalance;
            // divide by the market base weight of 100*1e18 
            M = (marketWeightDecimals*weiPerInput)/ETH_WEIGHT_DECIMALS_ADJUSTED;
        }
    }

    function _sync(ERC20 token) internal {
        if(token.isETH()){
            lastETHBalance = address(this).balance;
        } else {
            assets[token].lastBalance = token.balanceOf(address(this));
        }
    }

    /* DEPOSIT CONTRACT ONLY FUNCTIONS */
    function recordDeposit(uint256 amount) external depositContractOnly {
        fullyDilutedSupply = fullyDilutedSupply+amount;
    }

    function recordUnlockedDeposit(address depositor, uint256 amount) external depositContractOnly {
        // Don't need to modify fullyDilutedSupply, since that was done above
        _mint(depositor, amount);
        emit UnlockedDeposit(depositor, amount);
    }

    /* EXCHANGE CONTRACT OR DEPOSIT CONTRACT ONLY FUNCTIONS */
    function syncAll() external depositOrExchangeContractOnly {
        _sync(ERC20(CLIPPER_ETH_SIGIL));
        uint i;
        while(i < assetSet.length()) {
            _sync(ERC20(assetSet.at(i)));
            i++;
        }
    }

    function sync(ERC20 token) external depositOrExchangeContractOnly {
        _sync(token);
    }

    /* EXCHANGE CONTRACT ONLY FUNCTIONS */
    // transferAsset() and syncAndTransfer() are the two ways tokens leave the pool without escape.
    // Since they transfer tokens, they are both marked as nonReentrant
    function transferAsset(ERC20 token, address recipient, uint256 amount) external nonReentrant exchangeContractOnly {
        token.uniTransfer(recipient, amount);
        // We never want to transfer an asset without sync'ing
        _sync(token);
    }

    function syncAndTransfer(ERC20 inputToken, ERC20 outputToken, address recipient, uint256 amount) external nonReentrant exchangeContractOnly {
        _sync(inputToken);
        outputToken.uniTransfer(recipient, amount);
        _sync(outputToken);
    }

    // This is activated when burning pool tokens for a single asset
    function swapBurn(address burner, uint256 amount) external exchangeContractOnly {
        // Reverts if not enough tokens
        _burn(burner, amount);
        fullyDilutedSupply = fullyDilutedSupply-amount;
    }

    /* Matcha PLP API */
    function getSellQuote(address inputToken, address outputToken, uint256 sellAmount) external view returns (uint256 outputTokenAmount){
        outputTokenAmount=exchangeInterfaceContract.getSellQuote(inputToken, outputToken, sellAmount);
    }
    function sellTokenForToken(address inputToken, address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount) {
        boughtAmount = exchangeInterfaceContract.sellTokenForToken(inputToken, outputToken, recipient, minBuyAmount, auxiliaryData);
    }

    function sellEthForToken(address outputToken, address recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external payable returns (uint256 boughtAmount){
        boughtAmount=exchangeInterfaceContract.sellEthForToken(outputToken, recipient, minBuyAmount, auxiliaryData);
    }
    function sellTokenForEth(address inputToken, address payable recipient, uint256 minBuyAmount, bytes calldata auxiliaryData) external returns (uint256 boughtAmount){
        boughtAmount=exchangeInterfaceContract.sellTokenForEth(inputToken, recipient, minBuyAmount, auxiliaryData);
    }
}