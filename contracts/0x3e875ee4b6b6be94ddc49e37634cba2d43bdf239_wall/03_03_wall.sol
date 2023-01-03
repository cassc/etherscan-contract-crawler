// SPDX-License-Identifier: MIT


/* 
      _____                    _____                    _____                    _____                    _____                    _____            _____  
     /\    \                  /\    \                  /\    \                  /\    \                  /\    \                  /\    \          /\    \ 
    /::\    \                /::\____\                /::\    \                /::\____\                /::\    \                /::\____\        /::\____\
    \:::\    \              /:::/    /               /::::\    \              /:::/    /               /::::\    \              /:::/    /       /:::/    /
     \:::\    \            /:::/    /               /::::::\    \            /:::/   _/___            /::::::\    \            /:::/    /       /:::/    / 
      \:::\    \          /:::/    /               /:::/\:::\    \          /:::/   /\    \          /:::/\:::\    \          /:::/    /       /:::/    /  
       \:::\    \        /:::/____/               /:::/__\:::\    \        /:::/   /::\____\        /:::/__\:::\    \        /:::/    /       /:::/    /   
       /::::\    \      /::::\    \              /::::\   \:::\    \      /:::/   /:::/    /       /::::\   \:::\    \      /:::/    /       /:::/    /    
      /::::::\    \    /::::::\    \   _____    /::::::\   \:::\    \    /:::/   /:::/   _/___    /::::::\   \:::\    \    /:::/    /       /:::/    /     
     /:::/\:::\    \  /:::/\:::\    \ /\    \  /:::/\:::\   \:::\    \  /:::/___/:::/   /\    \  /:::/\:::\   \:::\    \  /:::/    /       /:::/    /      
    /:::/  \:::\____\/:::/  \:::\    /::\____\/:::/__\:::\   \:::\____\|:::|   /:::/   /::\____\/:::/  \:::\   \:::\____\/:::/____/       /:::/____/       
   /:::/    \::/    /\::/    \:::\  /:::/    /\:::\   \:::\   \::/    /|:::|__/:::/   /:::/    /\::/    \:::\  /:::/    /\:::\    \       \:::\    \       
  /:::/    / \/____/  \/____/ \:::\/:::/    /  \:::\   \:::\   \/____/  \:::\/:::/   /:::/    /  \/____/ \:::\/:::/    /  \:::\    \       \:::\    \      
 /:::/    /                    \::::::/    /    \:::\   \:::\    \       \::::::/   /:::/    /            \::::::/    /    \:::\    \       \:::\    \     
/:::/    /                      \::::/    /      \:::\   \:::\____\       \::::/___/:::/    /              \::::/    /      \:::\    \       \:::\    \    
\::/    /                       /:::/    /        \:::\   \::/    /        \:::\__/:::/    /               /:::/    /        \:::\    \       \:::\    \   
 \/____/                       /:::/    /          \:::\   \/____/          \::::::::/    /               /:::/    /          \:::\    \       \:::\    \  
                              /:::/    /            \:::\    \               \::::::/    /               /:::/    /            \:::\    \       \:::\    \ 
                             /:::/    /              \:::\____\               \::::/    /               /:::/    /              \:::\____\       \:::\____\
                             \::/    /                \::/    /                \::/____/                \::/    /                \::/    /        \::/    /
                              \/____/                  \/____/                  ~~                       \/____/                  \/____/          \/____/ 
                                                                                                                                                           
*
*
* The Wall - Stability growth 
* Created by Colangius 2022
* Official Website: https://thewall.finance
* Github: https://github.com/wallfinance
* Twitter: https://twitter.com/wall_financeETH
* Medium: https://medium.com/@thewallfinance
*/

pragma solidity 0.8.13;

import './IUniswapV2Pair.sol';
import './IERC20.sol';


interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
            address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
            ) external payable returns (
                uint256 amountToken, uint256 amountETH, uint256 liquidity
                );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
            ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract wall is IERC20, Ownable {
    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Wall Finance";
    string private constant _symbol = "WALL";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    // Token number and initial supply
    uint256 private _totalSupply = 21000000000 * 10**18; 
    uint256 private constant _initialTotalSupply = 21000000000 * 10**18; 
    mapping (address => bool) public automatedMarketMakerPairs;
    bool private isLiquidityAdded = false;
    address public liquidityWallet;
    address public marketingWallet;
    address public investmentWallet;
    address public devWallet;
    uint256 private _launchTimestamp;
    mapping (address => uint256) private addressAmount;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWalletAmount = _totalSupply;
    uint private launchBlock;   // When contract was launched
    /* Invariable TAX AMOUNT */
    uint constant buyTaxCostant = 4;
    uint constant sellTaxCostant = 4;
    /* Tax for operations */
    uint sellTax = sellTaxCostant;
    uint buyTax = buyTaxCostant;
    /* Tax percentage for different use */
    uint256 toMarketing;
    uint256 toDev;
    uint256 toInvestment;
    /* Value of the new calculated wall */
    uint256 calculatedNewWall = 0;         // Initial state
    uint arrayOfETHLPValueLength;       // Will contain the lenth of the LPETH value array
    /* Setting up whitelist */
    mapping (address =>bool) private whitelistedWallet;
    mapping (address =>bool) private sniperkiller;
    /* This will create the wall based on market cap */
    uint256 ethWallCurrent;             // WEI 10**18 precision
    uint256 ethInLPBeforeTransfer;          // WEI 10**18 precision
    uint256 tokenToAllocateForMarketing = (_totalSupply * 25)/100;
    uint256 amountAllocatedForPublicSale = _totalSupply - (_totalSupply * 25)/100;

    uint256 minimumTokensBeforeSwap = amountAllocatedForPublicSale * 250 / 1000000; // .025%
    // Track pair address
    address public pairAddressOfTokenETH;
    // Register LPETH -> Block Number in an array
    uint256[] public ETHLPVariationOnBlocks;
    address public _owner ;
    
   
    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Router = _uniswapV2Router;
        liquidityWallet = owner();
        whitelistedWallet[address(uniswapV2Router)] = true;
        whitelistedWallet[address(this)] = true;
        whitelistedWallet[devWallet] = true;
        whitelistedWallet[marketingWallet] = true;
        whitelistedWallet[investmentWallet] = true;
        whitelistedWallet[owner()] = true;
        whitelistedWallet[deadWallet] = true;
        // Set the owner
        _owner = msg.sender;
        // Fill owner's wallet with 20% of token for marketing and staking purpose
        balances[liquidityWallet] = tokenToAllocateForMarketing;
        emit Transfer(address(this), liquidityWallet, tokenToAllocateForMarketing);

        // Fill contract with tokens
        balances[address(this)] = amountAllocatedForPublicSale;
        emit Transfer(address(0), address(this), amountAllocatedForPublicSale);
    }

    receive() external payable {
        /* Contract can receive ETH and other token to its address */
        balances[msg.sender] += msg.value;
    } 

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance.");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[_msgSender()][spender], "ERC20: decreased allownace below zero.");
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function withdrawStuckETH() external {
        require(msg.sender == _owner);
        require(address(this).balance > 0, "cannot send more than contract balance.");
        uint256 amount = address(this).balance;
        (bool success,) = _owner.call{value : amount}("");
        require(success, "error withdrawing ETH from contract.");
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, "cannot update maxWalletAmount to same value.");
        require(newValue > amountAllocatedForPublicSale * 1 / 100, "maxWalletAmount must be >1% of total supply.");
        maxWalletAmount = newValue;
    }

    function setMaxTransactionAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "cannot update maxTxAmount to same value.");
        require(newValue > amountAllocatedForPublicSale * 1 / 1000, "maxTxAmount must be > .1% of total supply.");
        maxTxAmount = newValue;
    }
    function activateTrading() external onlyOwner {
        require(!isLiquidityAdded, "you can only add liquidity once.");
        isLiquidityAdded = true;
       _approve(address(this), address(uniswapV2Router), amountAllocatedForPublicSale);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), amountAllocatedForPublicSale, 0, 0, _msgSender(), block.timestamp);
        // Get the pair on Uniswap
        address _uniswapV2Pair = IFactory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH() );
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        _launchTimestamp = block.timestamp;
        maxWalletAmount = amountAllocatedForPublicSale * 2 / 100; //  2%
        maxTxAmount = amountAllocatedForPublicSale * 2 / 100;     //  2%
        // Exclude system wallet to limit
        whitelistedWallet[_uniswapV2Pair] = true;
        // Register pair in global variable
        pairAddressOfTokenETH = _uniswapV2Pair;
        // Register when trading was activated
        launchBlock = block.number;
        // Set the wall initially to 0
        ethWallCurrent = 0;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "automated market maker pair is already set to that value.");
        automatedMarketMakerPairs[pair] = value;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address.");
        require(to != address(0), "cannot transfer to the zero address.");
        require(amount > 0, "transfer amount must be greater than zero.");
        require(amount <= balanceOf(from), "cannot transfer more than balance.");

        if (from == uniswapV2Pair)  {

            // Check if the wallet is whitelisted or not
            if(checkWalletForWhitelisting(to))  { buyTax = 0; }

            if (!whitelistedWallet[to]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "expected wallet amount exceeds the maxWalletAmount.");
                require(amount <= maxTxAmount, "transfer amount exceeds the maxTxAmount.");
            }
            // Execute transaction
            balances[from] -= amount;
            balances[to] += amount - (amount * (buyTax) / 100);
            
            /* Send TAX to contract*/
            balances[address(this)] += (amount * (buyTax)) / 100;
            emit Transfer(from, address(this), (amount * (buyTax) / 100));              
            /* End of sending TAX to contract */

            emit Transfer(from, to, amount - (amount * (buyTax) / 100));              
            // End of transaction

            /* Register the LP value of ETH in the array */
            ETHLPVariationOnBlocks.push(extractETHValueDynamicallyDiscovered());
            // Calculate length of array
            arrayOfETHLPValueLength = ETHLPVariationOnBlocks.length;
        
            /* New wall calculation based on math of previous transactions */
            
            // To avoid overflow
            if (arrayOfETHLPValueLength >= 3)  {
                uint256 previousValue = ETHLPVariationOnBlocks[arrayOfETHLPValueLength-3];
                calculatedNewWall = previousValue + ((previousValue * 1) / 1000);
                if(extractETHValueDynamicallyDiscovered() >= calculatedNewWall) {
                    ethWallCurrent = previousValue;
                }
            }

        
            if (balanceOf(address(this)) > minimumTokensBeforeSwap) {
                _swapTokensForETH(balanceOf(address(this)));
                /* 
                 *
                 * Tax division:
                 *
                 * Marketing: 30%
                 * Dev: 30%
                 * Investment: 40% (will be diverted to selected staking pool for community)
                 *
                 */ 
                
                // Calculate correct percentage. Little correction are to guarantee that fees are always paid to ERC20 system
                toMarketing = (address(this).balance * 29) / 100;
                toDev = (address(this).balance * 29) / 100;
                toInvestment = (address(this).balance * 39) / 100;

                // Execute funds transfer
                payable(marketingWallet).transfer(toMarketing);
                payable(devWallet).transfer(toDev);
                payable(investmentWallet).transfer(toInvestment);

            }
        }

        if (to == uniswapV2Pair)    {

            if (!whitelistedWallet[from]) {
                require(amount <= maxTxAmount, "transfer amount exceeds the maxTxAmount.");
            }
            
            // Check if we can sell, based on calculation over the wall. If selling is forbidden, tax is elevated to 28%
            if (extractETHValueDynamicallyDiscovered() < ethWallCurrent)    {
                // Tax is 25% but selling is possibile
                sellTax = 25;
            }

            // Sniperkille on sell check
            if(sniperkiller[from]) {
                require(sniperkiller[from] == false);
            }
            
            // Check if the wallet is whitelisted or not
            if(checkWalletForWhitelisting(from))  { sellTax = 0; }
            
            // Execute transfer
            balances[from] -= amount;
            balances[to] += amount - (amount * (sellTax) / 100);
            
            /* Send TAX to contract*/
            balances[address(this)] += (amount * (sellTax)) / 100;
            emit Transfer(from, address(this), (amount * (sellTax) / 100));              
            /* End of sending TAX to contract */

            emit Transfer(from, to, amount - (amount * (sellTax) / 100));

            /* Register the LP value of ETH in the array */
            ETHLPVariationOnBlocks.push(extractETHValueDynamicallyDiscovered());

            if (balanceOf(address(this)) > minimumTokensBeforeSwap) {
                _swapTokensForETH(balanceOf(address(this)));
                /* 
                 *
                 * Tax division:
                 *
                 * Marketing: 30%
                 * Dev: 30%
                 * Investment: 40% (will be diverted to selected staking pool for community)
                 *
                 */ 
                
                // Calculate correct percentage. Little correction are to guarantee that fees are always paid to ERC20 system
                toMarketing = (address(this).balance * 29) / 100;
                toDev = (address(this).balance * 29) / 100;
                toInvestment = (address(this).balance * 39) / 100;

                // Execute funds transfer
                payable(marketingWallet).transfer(toMarketing);
                payable(devWallet).transfer(toDev);
                payable(investmentWallet).transfer(toInvestment);
            }
            // Set sell tax to normal value
            sellTax = sellTaxCostant;
        }

        if (to != uniswapV2Pair && from != uniswapV2Pair)    {
            // Check if the wallet is whitelisted or not

            if (!whitelistedWallet[to] || !whitelistedWallet[from]) {
                require((balanceOf(to) + amount) <= maxWalletAmount, "expected wallet amount exceeds the maxWalletAmount.");
            }
            // Execute transfer Wallet to Wallet
            balances[from] -= amount;
            balances[to] += amount;              
            emit Transfer(from, to, amount);    
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function withdrawStuckToken(IERC20 token, address to) public {
        require(msg.sender == _owner);
        // If someone send some wrong token to this contract, this function allow the owner to save that funds
        uint256 erc20balance = token.balanceOf(address(this));
        token.transfer(to, erc20balance);
        emit TransferSent(msg.sender, to, erc20balance);
    }  

    /* Function for PAIR manipulation and calculation over MarketCap */


   function extractETHValueDynamicallyDiscovered() public view returns (uint)   {
       IUniswapV2Pair pair = IUniswapV2Pair(pairAddressOfTokenETH);
        //IERC20 token1 = IERC20(pair.token1()); // function `token1()`
        (uint Res0, uint Res1,) = pair.getReserves();
        // Problem is: i dont know and cannot know if is Res0 or Res1 the Wall token. It's quite random and i need to calculate what i'm extracting 
        // This method will return WALL. Given that i exactply know it's number.. should be easy. We know that WALL are > than ETH
        // return variable. This will be read by dAPP!
        uint returnValueOfEth;

        if (Res0 > Res1)    {
            returnValueOfEth = Res1;
        }
        else {
            returnValueOfEth = Res0;
        }
        return returnValueOfEth;
   }

    function tokenPrice() public view returns(uint)  {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddressOfTokenETH);
        //IERC20 token1 = IERC20(pair.token1()); // function `token1()`
        (uint Res0, uint Res1,) = pair.getReserves();

        // Get the right ETH variable
        uint256 whoIsEth;
        uint256 whoIsWall;

        if (Res0 > Res1)    {
            whoIsEth = Res1;
            whoIsWall = 0;
        }
        else {
            whoIsEth = Res0;
            whoIsWall = Res1;
        }

        // decimals
        uint ethInLP = whoIsEth*(10**pair.decimals());
        // Return token price (will be read by dAPP!
        return((1*ethInLP)/whoIsWall);
   }

    /* Here all the function for varius common services */


    function setSystemWallettAddress(address newMarketing, address newDev, address newInvestment) public onlyOwner    {
        marketingWallet = newMarketing;
        devWallet = newDev;
        investmentWallet = newInvestment;
        whitelistedWallet[newMarketing] = true;
        whitelistedWallet[newDev] = true;
        whitelistedWallet[newInvestment] = true;
    }

    function getTax() public view returns(uint,uint)   {
        return (buyTax, sellTax);
    }
    
    function setTax(uint newBuyTax, uint newSellTax) public onlyOwner   {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function getCurrentEthWall() public view returns(uint256)   {
        return ethWallCurrent;
    }

    function setCurrentEthWall(uint256 newWall) public onlyOwner   {
        ethWallCurrent = newWall;
    }
    

    function addToWhitelist(address addressToWhitelist) public onlyOwner    {
        // Add to whitelist
        whitelistedWallet[addressToWhitelist] = true;
    }
    
    function removeFromWhitelist(address addressToRemove) public onlyOwner    {
        // Remove from whitelist
        whitelistedWallet[addressToRemove] = false;
    }

    function checkWalletForWhitelisting(address addressToCheck) public view returns(bool)   {
        return whitelistedWallet[addressToCheck];
    }
    
    function tokenInContract() public view returns (uint256)    {
        return balances[address(this)];
    }

    function getSystemWallet() public view returns (address, address, address)  {
        return (marketingWallet, devWallet, investmentWallet);
    }

    function addToSniperkiller(address addressToAddSniperkiller) public onlyOwner    {
        // Add to sniperkiller
        sniperkiller[addressToAddSniperkiller] = true;
    }
    
    function removeFromSniperkiller(address addressToRemoveSniperkiller) public onlyOwner    {
        // Remove from sniperkiller
        sniperkiller[addressToRemoveSniperkiller] = false;
    }
    // Check for sniperkiller list
    function checkWalletForSniperkiller(address addressToCheckSniperkiller) public view returns(bool)   {
        return sniperkiller[addressToCheckSniperkiller];
    }
    
}