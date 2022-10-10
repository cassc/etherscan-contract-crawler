/*
  
  Proof Of Decentralization | $BEP-2.0
  Medium - https://proofofdecentralization.medium.com/
  Telegram - https://t.me/proofofdecentralization/

  // Phase 1: Launching a truly decentralized token.

  Problem:
  After the BNB exploit, Binance halted the chain and there were even talks of a rollback.
  Being able to halt a chain and roll it back defeats the purpose of blockchain and decentralization.

  Solution:
  We are launching Proof Of Hack (BEP-2.0) to be represantative and exemplar of true decentralization.
  This token will be a true 2.0 version of the BEP-20 protocol with respects to using a truly
  decentralized protocol. The following measures will be taken to ensure a truly decentralized token.
     - Launch on Ethereum blockchain.
     - Liquidity locked.
     - Contract renounced.



  // Phase 2: The fight for decentralization through community and utility.

  Problem:
  BEP-2.0's mission is to become the leading exemplar to true decentralization. Just launching a token 
  may make a statement momentarily, but it will not accomplish our mission in the long run.

  Solution:
  Building an strong and passionate community paired with useful DeFi utility. A big community enables
  us to spread the word on decentralization, and when the community is big, it is not just BEP-2.0
  that is exemplar of decentralization. It is the whole community. To maintain and continue to grow
  a community in the long term, we need to give them a reason to stay. That is why we decided to pair
  this token with useful DeFi utility. Utilities like token trackers and transaction monitors are 
  coming. We also plan to do strategic partnerships with other utility tokens.


*/


import "@openzeppelin/contracts/utils/math/SafeMath.sol";  
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


pragma solidity ^0.8.14;


// SPDX-License-Identifier: MIT


interface IUniswapV2Factory {  
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract Ownable is Context {  
    address private _owner;


    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {  
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {  
        return _owner;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {  
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {  
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {  
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}


library SafeMathInt {  
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);


    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {  
        int256 c = a * b;

          // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }


    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {  
          // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

          // Solidity already throws when dividing by 0.
        return a / b;
    }


    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {  
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {  
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }


    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {  
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {  
        require(a >= 0);
        return uint256(a);
    }

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


contract ProofOfDecentralization is ERC20, Ownable {  

    using SafeMath for uint256;


    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;


    bool private swapping;


    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch


    uint256 public swapTokensAtAmount;
    uint256 public maxTransactionAmount;


    uint256 public liquidityActiveBlock = 0;   // 0 means liquidity is not active yet
    uint256 public tradingActiveBlock = 0;   // 0 means trading is not active


    bool public tradingActive = false;
    bool public limitsInEffect = true;
    bool public swapEnabled = false;


    address public constant burnWallet = 0x000000000000000000000000000000000000dEaD;


    address public marketingWallet;


    uint256 public constant feeDivisor = 1000;


    uint256 public marketingBuyFee;
    uint256 public totalBuyFees;


    uint256 public marketingSellFee;
    uint256 public totalSellFees;


    uint256 public tokensForFees;
    uint256 public tokensForMarketing;


    bool public transferDelayEnabled = true;
    uint256 public maxWallet;




    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;


    mapping(address => bool) public automatedMarketMakerPairs;


    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);


    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);


    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    constructor() ERC20("Proof of Decentralization", "BEP-2.0") {  
        marketingWallet = owner();
        uint256 totalSupply = 1 * 1e9 * 1e18;

        swapTokensAtAmount = (totalSupply * 1) / 10000;   // 0.01% swap tokens amount. 
        maxTransactionAmount = (totalSupply * 10) / 1000;   // 1% maxTransactionAmountTxn. 
        maxWallet = (totalSupply * 20) / 1000;   // 2% maxWallet. 

        marketingBuyFee = 40;   // 4%. 
        totalBuyFees = marketingBuyFee;    

        marketingSellFee = 40;   // 4%. 
        totalSellFees = marketingSellFee;


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );


          // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());


        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;


        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
 

          // exclude from paying fees or having max transaction amount
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
        excludeFromMaxTransaction(address(marketingWallet), true);
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(_uniswapV2Router), true);
        excludeFromFees(address(marketingWallet), true);


        _mint(address(owner()), totalSupply);
    }

    receive() external payable {}
 
    // --- funcs start
    function updateSellFees(uint256 _marketinSellFee) external onlyOwner {  
        marketingSellFee = _marketinSellFee;
        totalSellFees = marketingSellFee;
        require(totalSellFees <= 100, "ERREQ: Must keep fees at 10% or less");
    }

    function updateBuyFees(uint256 _marketinBuyFee) external onlyOwner {  
        marketingBuyFee = _marketinBuyFee;
        totalBuyFees = marketingBuyFee;
        require(totalSellFees <= 100, "ERREQ: Must keep fees at 10% or less");
    }


    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {  
        require(
            newNum >= ((totalSupply() * 10) / 1000) / 1e18,
            "ERREQ: Cannot set maxTransactionAmount lower than 1.0%"
        );
        maxTransactionAmount = newNum * (10**18);
    }


    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {  
        require(
            newNum >= ((totalSupply() * 20) / 1000) / 1e18,
            "ERREQ: Cannot set maxWallet lower than 2.0%"
        );
        maxWallet = newNum * (10**18);
    }
 

    function enableTrading() external onlyOwner {  
        require(!tradingActive, "ERREQ: Cannot re-enable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
    }

 
    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {  
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }


    function excludeFromFees(address account, bool excluded) public onlyOwner {  
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }


    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) external onlyOwner {  
        for (uint256 i = 0; i < accounts.length; i++) {  
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }


    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {  
        require(
            pair != uniswapV2Pair,
            "ERREQ: The Uniswap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }


    function _setAutomatedMarketMakerPair(address pair, bool value) private {  
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }


    function isExcludedFromFees(address account) external view returns (bool) {  
        return _isExcludedFromFees[account];
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {  
        require(from != address(0), "ERREQ: ERC20: transfer from the zero address");
        require(to != address(0), "ERC20 ERREQ: transfer to the zero address");



        if (amount == 0) {  
            super._transfer(from, to, 0);
            return;
        }


        if (!tradingActive) {  
            require(
                _isExcludedFromFees[from] || _isExcludedFromFees[to],
                "ERREQ: Trading is not active yet."
            );
        }


        if (limitsInEffect) {  
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {  
                if (!tradingActive) {  
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "ERREQ: Trading is not active."
                    );
                }
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != owner() && to != address(uniswapV2Router) && to != address(uniswapV2Pair)){
                      require(_holderLastTransferTimestamp[tx.origin] < block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed.");
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                  //event buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {  
                    require(
                        amount <= maxTransactionAmount + 1 * 1e18,
                        "ERREQ: Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                  //event sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {  
                    require(
                        amount <= maxTransactionAmount + 1 * 1e18,
                        "ERREQ: Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {  
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "ERREQ: Max wallet exceeded"
                    );
                }
            }
        }


        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;


        if (
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


          // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {  
            takeFee = false;
        }


        uint256 fees = 0;


          // no fee on transfers (non buys/sells)
        if (takeFee) {  
              // on sell take fees, purchase token and burn it
            if (automatedMarketMakerPairs[to] && totalSellFees > 0) {  
                fees = amount.mul(totalSellFees).div(feeDivisor);
                tokensForFees += fees;
                tokensForMarketing += (fees * marketingSellFee) / totalSellFees;
            }
              // on buy
            else if (automatedMarketMakerPairs[from]) {  
                fees = amount.mul(totalBuyFees).div(feeDivisor);
                tokensForFees += fees;
                tokensForMarketing += (fees * marketingBuyFee) / totalBuyFees;
            }

            if (fees > 0) {  
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
            0,   // accept any amount of ETH
            path,
            address(this),
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
            0,   // slippage is unavoidable
            0,   // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function manualSwap() external onlyOwner {  
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

      // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {  
        limitsInEffect = false;
        return true;
    }

    function swapBack() private {  
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {  
            return;
        }

        uint256 amountToSwapForETH = contractBalance;
        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(marketingWallet).call{  
            value: address(this).balance
        }("");

        tokensForMarketing = 0;
        tokensForFees = 0;
    }

    function withdrawStuckEth() external onlyOwner {  
        (bool success, ) = address(msg.sender).call{  
            value: address(this).balance
        }("");
        require(success, "ERREQ: failed to withdraw");
    }
}