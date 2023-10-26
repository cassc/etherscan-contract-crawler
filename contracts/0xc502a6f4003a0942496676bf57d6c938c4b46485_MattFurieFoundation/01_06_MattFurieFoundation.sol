// SPDX-License-Identifier: MIT

/*
Tg: https://t.me/MattFurieFoundation

Twitter: Twitter.com/mff_eth_

Web: http://www.mattfurie.tech/

*/

pragma solidity =0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract MattFurieFoundation is ERC20, Ownable {


    address public devwallet;
    bool private swapping;
    bool public swapEnabled = true;
    bool public tradingEnabled;
    address public MattsWallet = 0xc52351897E3295286ce38775e3741fb81bEE928d;


    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;
    uint256 public AmountSentToMatt;

    address public pair;

    struct Taxes {
        uint256 dev;
        uint256 MattTax;
    }

    Taxes public buyTaxes = Taxes(1, 4);
    Taxes public sellTaxes = Taxes(1, 4);
    uint256 public totalBuyTax = 5;
    uint256 public totalSellTax = 5;

    IUniswapRouter public router;
    uint256 public swapTokensAtAmount;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public _Bot;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor(address dev_wallet) ERC20("Matt Furie Foundation", "MFF") {
        IUniswapRouter _router = IUniswapRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _pair = IUniswapFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        setSwapTokensAtAmount(35000);
        updateMaxWalletAmount(2000000);
        setDeveloperwallet(dev_wallet);
        setbuySell(2000000, 2000000);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromMaxWallet(_pair, true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(_router), true);
        _setAutomatedMarketMakerPair(_pair, true);

        _mint(owner(), 100000000 * (10**18));
    }

    receive() external payable {}

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            " Account is already'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
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

    function setDeveloperwallet(address wallet) public onlyOwner {
        devwallet = wallet;
    }

    function SetMattsWallet(address _wallet) public onlyOwner {
        MattsWallet = _wallet;
    }

    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        require(newNum > (1000000), "Cannot set lower than 1%");
        maxWallet = newNum * (10**18);
    }

    function set_bot(address bot, bool value) external onlyOwner {
        require(_Bot[bot] != value);
        _Bot[bot] = value;
    }

    function setmultiplebots(address[] memory bots, bool value)
        external
        onlyOwner
    {
        for (uint256 i; i < bots.length; i++) {
            _Bot[bots[i]] = value;
        }
    }

    function setbuySell(uint256 maxBuy, uint256 maxSell) public onlyOwner {
        require(maxBuy >= 1000000, "Cannot set lower than 1% ");
        require(maxSell >= 500000, "Cannot set lower than 0.5% ");
        maxBuyAmount = maxBuy * 10**18;
        maxSellAmount = maxSell * 10**18;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10**18;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function GetERCToOwner(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function forceSendTodev() external onlyOwner {
        (bool success, ) = payable(devwallet).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function setBuytax(uint256 _new_dev, uint256 _new_matt) external onlyOwner {
        require(_new_dev + _new_matt <= 20);
        buyTaxes = Taxes(_new_dev, _new_matt);
        totalBuyTax = _new_dev + _new_matt;
    }

    function setSellTax(uint256 _new_dev, uint256 _new_matt)
        external
        onlyOwner
    {
        require(_new_dev + _new_matt <= 20);
        sellTaxes = Taxes(_new_dev, _new_matt);
        totalSellTax = _new_dev + _new_matt;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading active");
        tradingEnabled = true;
    }

    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value);
        automatedMarketMakerPairs[newPair] = value;

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_Bot[from] && !_Bot[to]);

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= maxSellAmount,
                    "You are exceeding max-sell-amount"
                );
            } else if (automatedMarketMakerPairs[from])
                require(
                    amount <= maxBuyAmount,
                    "You are exceeding max-buy-amount"
                );
            if (!_isExcludedFromMaxWallet[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed max-wallet"
                );
            }
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if (totalSellTax > 0) {
                swapforFees(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 100;
            else if (automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 100;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);
    }

    function swapforFees(uint256 tokens) private {
        uint256 toSwap = tokens;
        swapTokensForETH(toSwap);

        uint256 contractrewardbalance = address(this).balance;

        uint256 devAmt = (contractrewardbalance * sellTaxes.dev) / totalSellTax;
        if (devAmt > 0) {
            (bool success, ) = payable(devwallet).call{value: devAmt}("");
            require(success, "Failed to send Ether to dev wallet");
        }
        uint256 mattAmt = (contractrewardbalance * sellTaxes.MattTax) /
            totalSellTax;
        if (mattAmt > 0) {
            (bool success, ) = payable(MattsWallet).call{value: mattAmt}("");
            require(success, "Failed to send Ether to dev wallet");
            AmountSentToMatt += mattAmt;
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}