/* 

TG: https://t.me/PPPPortal

WEBSITE: https://pepepool.party

TWITTER: https://twitter.com/PEPE_Pool_Party

TAX: 1.5% / 1.5% (All taxes go to automated Liquidity provisioning, 1% to $PEPE .5% to $PPP.)
                                                                                                    
                     :~7??77?!^.                                            
                    ?YJYYYYYY55Y?~                                          
                   !YJJJ?JJJJJYYY5J:                                        
               .:^~YYJJJJJJJJJYYYY5J                                        
             !JYYYYYY5YYYYYJJJYYYYYJ                                        
             .^!JYYYYYYYYYYY555YYY5^                                        
             .!JY55555555Y5555555YY7                                        
            .!~^?BPGPYJJYP55555YYYYY7.                                      
             ^!~!GGBY!^.:GGBBJY55YYY5Y!                                     
              .75YYYYY5YJYPPPYYYYYYYYYY!                                    
             :?YYYYYYYYYYYYYYYYYYYYYYYYY^                                   
             .!?YP555555555555P555YYYYYY!                                   
              !7?BBBBBBBBGGGPPP55555YYYY7                                   
              :^7Y555555555YYYYYYYYYYYYJ^                                   
                  :!YYYYYYYYYYYYYYYYYY5~                                    
                .^~?YYYYYYYYYYYYYYYYYYYY7:                                  
          :~!!!JY5YYYYYYYYYYYYYYYYYYYYYYYY?^                                
       :~~!!!!!Y5YYYYYYYYYYYYYYYYYYYYYYYYYYY?:                              
       .J?!!!~JYYYYYYYYYYYYYYYYYYYYYYYYY5YYYY57~~.                          
      .?5P7!!75YYYYYYYYYYYYYYYYYYYYYYYYYJ.^YYJ?!7J:                         
    .^?YJJJ?J?J5YYYYYYYYYYYYYYYYYYYY5YYY?^!7!!~!!!J                         
   ~??!~^^^~^^75YYYYYYYYYYYYY5YY5P555YYY!^?!!!!!!!J.                        
  ^!~Y7^^^^^^!5YYYYYYYYY5YYYYYYYYYYYYYYY: 7!!~~!?J:                         
  !~~5!^^^^^~YYYYYYYYYYYYYYYYYYYYYYYYYYY? :77JY55^                          
  !~^~^^^^^^75YYYYYYYYYYYYYYYYYYYYYYYYYYY: .^5YYJ                           
  :7^^!~^^^^JYYYYYYYYYYYYYYYYYYYYYYYYYYYY:  !YY5~                           
   ^!~75J~^^JYYYYYYYYYYYYYYYYYYYYYYYYYYYJ. :YYYJ                            
    :~~77~~~YYYYYYY5P5YYYYYYYYYYYYYYYYYY7 .JYYY:                            
       .... ~YYYYYYYYYYYYYYYYYYYYYYYYYYY: 7YYY~                             
             ?YYYYYYYYYYYYYYYYYYYYYYY5YY.75YYY.                             
             .!YYYYYYYYYYYYYYYY55Y5555P?~GYYY5Y7                            
               !P5P5P555555555555555555..7Y!Y?:^                            
               :5Y5555PPP5YY55555555YPJ   . .                               
               ^PYYYYYYYP^. 7YYYYYYYY5~                                     
               :5YYYYYYYY   !YYYYYYYYY.                                     
                YYYYYYYP7   7YYYYYYYY^                                      
                ~5YYYYYJ.   75YYYYYY!                                       
                 ?5YYY5^    :YYYYYY?                                        
                  7YYYY.     .75YYY^                                        
                  .5YY5:       !5YY?                                        
                  .5YY5:        75Y5:                                       
                  ^PYY5:        ~5Y5^                                       
                  75YY5:        ^5Y5!                                       
                 :55YY5~        .YYYJ                                       
           ..:~7JYY5YY5!        .5YY5^                                      
        ^7YYYYYYYYYYY7~.       :Y55Y5:                                      
        ^75YY5PYY5J~.         ~5YYYY?                                       
           .::!77^          .J5YYYYY7                                       
                            :YY5J5YY7                                       
                              .....:.        

                              */                               
                                
pragma solidity 0.8.19;

import "./dependencies/IUniswapV2Pair.sol";
import "./dependencies/IUniswapV2Factory.sol";
import "./dependencies/ERC20.sol";
import "./dependencies/Ownable.sol";
import "./dependencies/IUniswapV2Router02.sol";
import "./dependencies/PepeToken.sol";

contract PepePoolParty is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    

    bool private swapping;

    address public devWallet;
    address public lpWallet;
    
    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    
    
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public launchTime;

    uint256 private buyTotalFees;
    uint256 public buyLiquidityFee;  
    uint256 public buyPepeFee;
    
    uint256 private sellTotalFees;
    uint256 public sellLiquidityFee;
    uint256 public sellPepeFee;
    
    uint256 public tokensForLiquidity;
    uint256 public tokensForPepe;
    uint256 public ethForPepe;

    PepeToken public pepeToken;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event PepeLiquidityAdded(uint256 indexed pepeTokensAdded, uint256 indexed ethAdded);


    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    

    constructor() ERC20("Pepe Pool Party", "PPP") {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pepeToken = PepeToken(0x6982508145454Ce325dDbE47a25d4ec3d2311933);

        
        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        

        // Fees are in 10ths of a percent e.g; 12 = 1.2% 
        uint256 _buyLiquidityFee = 5;
        uint256 _buyPepeFee = 10;

        uint256 _sellLiquidityFee = 5;
        uint256 _sellPepeFee = 10;

        
        uint256 totalSupply = 42069 * 1e10 * 1e18; 
        
        maxTransactionAmount = totalSupply * 25 / 1000; // 2.5% Of token supply per transaction (to be disabled sometime after launch this allows for fair entries)
        maxWallet = totalSupply * 25 / 1000; // 2.5% maxWallet
        swapTokensAtAmount = totalSupply * 5 / 10000; // Swap when contract has 0.05% of supply

        buyLiquidityFee = _buyLiquidityFee;
        buyPepeFee = _buyPepeFee;
        buyTotalFees =  buyLiquidityFee + buyPepeFee;
        
        sellLiquidityFee = _sellLiquidityFee; 
        sellPepeFee = _sellPepeFee;
        sellTotalFees = sellLiquidityFee + sellPepeFee;
        
        devWallet = address(owner()); // To clean up excess eth if price changes during liquidity provisioning

        lpWallet = address(0xdead); // set burn address to receive minted LP tokens

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */

        _mint(msg.sender, totalSupply);




    }

    receive() external payable {

  	}


    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        launchTime = block.timestamp;

    }
    
    // remove limits permanently
    function removeLimits() external onlyOwner returns (bool){
        limitsInEffect = false;
        return limitsInEffect;
    }
    
     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
  	    swapTokensAtAmount = newAmount;
  	    return true;
  	}
    
    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100)/1e18, "Cannot set maxTransactionAmount lower than 1%");
        maxTransactionAmount = newNum * (10**18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 25 / 1000)/1e18, "Cannot set maxWallet lower than 2.5%");
        maxWallet = newNum * (10**18);
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function checkSellTotalFees() public view returns(uint256) {
        return sellTotalFees;
    }

    function checkBuyTotalFees() public view returns(uint256) {
        return buyTotalFees;
    }
   
    event BoughtEarly(address indexed sniper);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        ){
            if(limitsInEffect){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                }
                else if(!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }
        
        
        
        
		uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }
        

        bool takeFee = !swapping;

        // if either address belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount.mul(sellTotalFees).div(1000);
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForPepe += fees * sellPepeFee / sellTotalFees;
                

                
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount.mul(buyTotalFees).div(1000); // Burns are not accounted for in buyTotalFees internal value
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForPepe += fees * buyPepeFee / buyTotalFees;
                
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
    }

    function swapEthForPepe(uint256 ethAmt) private {
      address [] memory path = new address[](2);
      path[0] = uniswapV2Router.WETH();
      path[1] = address(pepeToken); // Pepe Contract Address

      _approve(address(this), address(uniswapV2Router), ethAmt);

      uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmt}(
        0,
        path,
        address(this),
        block.timestamp
      );
    }


    function addPepeLiquidity(uint256 pepeAmount, uint256 ethAmount) private {
      // Approve pepe token spend

      pepeToken.approve(address(uniswapV2Router), pepeAmount);

      uniswapV2Router.addLiquidityETH{value: ethAmount}(
        address(pepeToken),
        pepeAmount,
        0,
        0,
        address(0xdead),
        block.timestamp
      );

    }
    
    
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpWallet,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForPepe;
        bool success;
        
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
          contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        ethForPepe += ethBalance.mul(tokensForPepe).div(totalTokensToSwap);
        
        
        uint256 ethForLiquidity = ethBalance * tokensForLiquidity / totalTokensToSwap / 2;

        


        
        
        tokensForLiquidity = 0;
        tokensForPepe = 0;

        // Only add pepe liq if eth value is over .5 eth to save gas and because pepe market cap so large 😲

        if(ethForPepe >= 5e17){
          // Buy Pepe token for liquidity provisioning
          uint256 ethForPepeLiq = ethForPepe / 2;

          swapEthForPepe(ethForPepeLiq);
          ethForPepe = 0;

          uint256 pepeBalance = pepeToken.balanceOf(address(this));
          addPepeLiquidity(pepeBalance, ethForPepeLiq);

          emit PepeLiquidityAdded(pepeBalance, ethForPepeLiq);

        }


        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
            ethForLiquidity = 0;
        }

        //check for trapped excess ether, in case of price change during liquidity provisioning, and remove it from the contract.

        uint256 excess = (address(this).balance) -  (ethForLiquidity + ethForPepe);

        if(excess > 0){
          (success,) = address(devWallet).call{value:excess}("");
        }      
    }
}