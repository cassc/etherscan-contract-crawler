// contracts/LeapToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";


contract JasonInuToken is ERC20, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    uint16 public constant denominator = 10000;
    
    struct BuyFee {
        uint16 liquidityFee;
        uint16 devFee;
        uint16 burnFee;
    }

    struct SellFee {
        uint16 liquidityFee;
        uint16 devFee;
        uint16 burnFee;
    }

    bool private swapping;

    BuyFee public buyFee;
    SellFee public sellFee;

    uint256 public halloweenBurnBalance = 0;

    uint256 public initialTotalSupply = 10**9 * (10**18);

    uint256 public swapTokensAtAmount = initialTotalSupply.mul(100).div(denominator);

    uint256 public maxBuyAmount = initialTotalSupply.mul(200).div(denominator); // 2% of the supply
    uint256 public maxWalletAmount = initialTotalSupply.mul(200).div(denominator); // 2% of the supply

    uint16 private totalBuyFee;
    uint16 private totalSellFee;

    bool public swapEnabled;

    address payable public devWallet = payable(address(0xA49559bb6C1efaFDf01bB5c7abF64E0E21bbD573)); //  DEV WALLET

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimit;

    // store addresses that are automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() ERC20("Jason Voorhees Inu", "JVI") {
       
        buyFee.liquidityFee = 300;
        buyFee.devFee = 200;
        buyFee.burnFee = 500;
        totalBuyFee = 1000;
        
        sellFee.liquidityFee = 300;
        sellFee.devFee = 200;
        sellFee.burnFee = 500;
        totalSellFee = 1000;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D// Uniswap Router
            0x10ED43C718714eb63d5aA57B78B54704E256024E// Pancakeswap Router
        );
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        swapEnabled = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), initialTotalSupply); // 1,000,000,000 Tokens
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "Token: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Token: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this), "Can't withdraw this token meaning can't rug");
        if (_token == address(0x0)) {
            (bool successOne,) = payable(owner()).call{value: (address(this).balance)}("");
            require(successOne);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        (bool success) = erc20token.transfer(owner(), balance);
        require(success);
    }

    function excludefromLimit(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromLimit[account] = excluded;
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "Token: The UniSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Token: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

      
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setBuyFees(
    
       uint16 liquidity,
       uint16 dev,
       uint16 burn
       
    ) external onlyOwner {
       
        buyFee.liquidityFee = liquidity;
        buyFee.devFee = dev;
        buyFee.burnFee = burn;
        
        totalBuyFee = burn + liquidity + dev;
        require (totalBuyFee <= 1100, "max fees should be less than or equal to 11%");
    }

     function setSellFees(
    
       uint16 liquidity,
       uint16 dev,
       uint16 burn
       
    ) external onlyOwner {
       
        sellFee.liquidityFee = liquidity;
        sellFee.devFee = dev;
        sellFee.burnFee = burn;
        
        totalSellFee = burn + liquidity + dev;
        require (totalSellFee <= 1100, "max fees should be less than or equal to 11%");
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setDevWallet(address newWallet) external onlyOwner {
        require (newWallet != (address(0)), "dev wallet can't be a zero address");
        devWallet = payable(newWallet);
    }

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        maxWalletAmount = amount * 10**18;
    }

    function setMaxBuyAmount(uint256 amount) external onlyOwner {
        maxBuyAmount = amount * 10**18;
    }

    function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
       swapTokensAtAmount =  amount * 10**18;
    }

    function burnHalloweenBalance() external onlyOwner {
        _burn(_msgSender(), halloweenBurnBalance);
        halloweenBurnBalance = 0;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "Token: transfer from the zero address");
        require(to != address(0), "Token: transfer to the zero address");
        require(to != address(0xdead), "Token: transfer to the dead address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this)).sub(halloweenBurnBalance);
        bool overMinimumTokenBalance = contractTokenBalance >=
            swapTokensAtAmount;

        if (
            swapEnabled &&
            !swapping &&
            from != uniswapV2Pair &&
            overMinimumTokenBalance
        ) {
            contractTokenBalance = swapTokensAtAmount;
            uint16 totalFee = totalBuyFee + totalSellFee;
            uint256 swapTokens = contractTokenBalance.mul(buyFee.liquidityFee + sellFee.liquidityFee).div(totalFee);
            swapAndLiquify(swapTokens);
            uint256 devTokens = contractTokenBalance.mul(buyFee.devFee + sellFee.devFee).div(totalFee);
            swapAndSendToDev(devTokens);
            // Calculate the burn tokens
            uint256 burnTokens = contractTokenBalance.mul(buyFee.burnFee + sellFee.burnFee).div(totalFee);
            halloweenBurnBalance += burnTokens;
        }

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees;

            if (automatedMarketMakerPairs[to]) {
                fees = totalSellFee;
            } else if (automatedMarketMakerPairs[from]) {
                fees = totalBuyFee;
            }

            if (!_isExcludedFromLimit[from] && !_isExcludedFromLimit[to]) {
                if (automatedMarketMakerPairs[from]) {
                    require(amount <= maxBuyAmount, "Buy exceeds limit");
                }

                if (!automatedMarketMakerPairs[to]) {
                    require(
                        balanceOf(to) + amount <= maxWalletAmount,
                        "Balance exceeds limit"
                    );
                }
            }

            uint256 feeAmount = amount.mul(fees).div(denominator);
            amount = amount.sub(feeAmount);

            super._transfer(from, address(this), feeAmount);
        }

        super._transfer(from, to, amount);

       
    }

    function swapAndSendToDev(uint256 tokens) private lockTheSwap {
        uint256 oldbalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 newBalance = address(this).balance - oldbalance;
        (bool mw, ) = payable(devWallet).call{value: newBalance}("");
        require(mw);
    }
    
   function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
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
            owner(),
            block.timestamp
        );
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

}