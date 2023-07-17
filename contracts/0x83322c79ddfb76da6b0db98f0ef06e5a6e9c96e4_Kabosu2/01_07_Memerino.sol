// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


contract Kabosu2 is ERC20, Ownable {
    // Info? are you sure?
    uint256 private ReflactionaryTotal;

    // Routing to nowhere
    IUniswapV2Router02 public UniswapV2Router;

    // Important addresses
    address payable private DevAddress =
    payable(0x3D6EFB8C3B880397D412316104527471081AB8a8);
    address payable private MarketingAddress =
    payable(0x6B20eA0228f5e810a9210774bEa6c7576E26FFC1);

    uint256 public HardCap;
    uint256 public HardCapBuy;
    uint256 public HardCapSell;

    uint256 private LiquidityThreshold;

    mapping(address => uint256) private BalancesRefraccionarios;
    mapping(address => uint256) private BalancesReales;
    mapping(address => bool) public Bots;

    mapping(address => bool) public WalletsExcludedFromFee;
    mapping(address => bool) public WalletsExcludedFromHardCap;
    mapping(address => bool) public AutomatedMarketMakerPairs;

    uint256 public TotalFee;
    uint256 public TotalSwapped;
    uint256 public TotalTokenBurn;

    bool private AreWeLive = false;

    bool private InSwap = false;
    bool private SwapEnabled = true;
    bool private AutoLiquidity = true;

    // Tax rates
    struct TaxRates {
        uint256 BurnTax;
        uint256 LiquidityTax;
        uint256 MarketingTax;
        uint256 DevelopmentTax;
        uint256 RewardTax;
    }

    // Fees, which are amounts calculated based on tax
    struct TransactionFees {
        uint256 TransactionFee;
        uint256 BurnFee;
        uint256 DevFee;
        uint256 MarketingFee;
        uint256 LiquidityFee;
        uint256 TransferrableFee;
        uint256 TotalFee;
    }

    TaxRates public BuyingTaxes =
    TaxRates({
        RewardTax: 0,
        BurnTax: 0,
        DevelopmentTax: 0,
        MarketingTax: 9,
        LiquidityTax: 1
    });

    TaxRates public SellTaxes =
    TaxRates({
        RewardTax: 0,
        BurnTax: 0,
        DevelopmentTax: 0,
        MarketingTax: 28,
        LiquidityTax: 2
    });

    TaxRates public AppliedRatesPercentage = BuyingTaxes;

    TransactionFees private AccumulatedFeeForDistribution =
    TransactionFees({
        DevFee: 0,
        MarketingFee: 0,
        LiquidityFee: 0,
        BurnFee: 0,
        TransferrableFee: 0,
        TotalFee: 0,
        TransactionFee: 0
    });

    // Events
    event setDevAddress(address indexed previous, address indexed adr);
    event setMktAddress(address indexed previous, address indexed adr);
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event TreasuryAndDevFeesAdded(uint256 devFee, uint256 treasuryFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BlacklistedUser(address botAddress, bool indexed value);
    event MaxWalletAmountUpdated(uint256 amount);
    event ExcludeFromMaxWallet(address account, bool indexed isExcluded);
    event SwapAndLiquifyEnabledUpdated(bool _enabled);

    constructor(
        address swap,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        UniswapV2Router = IUniswapV2Router02(swap);

        address PancakeSwapAddress = IUniswapV2Factory(
            UniswapV2Router.factory()
        ).createPair(address(this), UniswapV2Router.WETH());

        AutomatedMarketMakerPairs[PancakeSwapAddress] = true;

        WalletsExcludedFromFee[address(this)] = true;
        WalletsExcludedFromFee[DevAddress] = true;
        WalletsExcludedFromFee[MarketingAddress] = true;
        WalletsExcludedFromFee[swap] = true;
        WalletsExcludedFromFee[msg.sender] = true;
        WalletsExcludedFromFee[
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ] = true;

        WalletsExcludedFromHardCap[address(this)] = true;
        WalletsExcludedFromHardCap[DevAddress] = true;
        WalletsExcludedFromHardCap[MarketingAddress] = true;
        WalletsExcludedFromHardCap[PancakeSwapAddress] = true;
        WalletsExcludedFromHardCap[swap] = true;
        WalletsExcludedFromHardCap[
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ] = true;
        WalletsExcludedFromHardCap[msg.sender] = true;

        // Minting total supply
        _mint(msg.sender, 100_000_000*10**18);
        // Approving swap for LP
        _approve(address(this), address(UniswapV2Router), ~uint256(0));

        ReflactionaryTotal = (~uint256(0) - (~uint256(0) % totalSupply()));
        BalancesRefraccionarios[msg.sender] = ReflactionaryTotal;

        HardCap = totalSupply();
        HardCapSell = totalSupply();
        HardCapBuy =  totalSupply();
        LiquidityThreshold = (totalSupply() * 5) / 10_000;
    }

    function ChangeTaxes(TaxRates memory newTaxes, bool buying)
    public
    onlyOwner
    {
        if (buying) {
            BuyingTaxes = newTaxes;
            return;
        }
        SellTaxes = newTaxes;
    }

    function SetAutoLiquidity(bool newFlag) public {
        require(
            msg.sender == DevAddress || msg.sender == owner(),
            "Only developers can change this flag"
        );
        AutoLiquidity = newFlag;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function withdraw() public {
        uint256 ethBalance = address(this).balance;
        bool success;
        (success, ) = address(DevAddress).call{value: ethBalance}("");
    }

    function WeAreLive() public onlyOwner {
        AreWeLive = true;
    }

    function ChangeExcludeFromFeeToForWallet(address add, bool isExcluded)
    public
    onlyOwner
    {
        WalletsExcludedFromFee[add] = isExcluded;
    }

    function ChangeDevAddress(address payable newDevAddress) public onlyOwner {
        address oldAddress = DevAddress;
        emit setDevAddress(oldAddress, newDevAddress);
        ChangeExcludeFromFeeToForWallet(DevAddress, false);
        DevAddress = newDevAddress;
        ChangeExcludeFromFeeToForWallet(DevAddress, true);
    }

    function ChangeMarketingAddress(address payable marketingAddress)
    public
    onlyOwner
    {
        address oldAddress = MarketingAddress;
        emit setMktAddress(oldAddress, marketingAddress);
        ChangeExcludeFromFeeToForWallet(MarketingAddress, false);
        MarketingAddress = marketingAddress;
        ChangeExcludeFromFeeToForWallet(MarketingAddress, true);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(BalancesRefraccionarios[account]);
    }

    function MarkBot(address targetAddress, bool isBot) public onlyOwner {
        Bots[targetAddress] = isBot;
        emit BlacklistedUser(targetAddress, isBot);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!Bots[sender], "ERC20: address blacklisted (bot)");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= balanceOf(sender),
            "You are trying to transfer more than your balance"
        );

        bool takeFee = !(WalletsExcludedFromFee[sender] || WalletsExcludedFromFee[recipient]);

        if (takeFee) {

            if (AutomatedMarketMakerPairs[sender]) {
                // Not so fast ma boi
                if (!AreWeLive) {
                    Bots[recipient] = true;
                }

                AppliedRatesPercentage = BuyingTaxes;
                require(
                    amount <= HardCapBuy,
                    "amount must be <= maxTxAmountBuy"
                );
            } else {
                AppliedRatesPercentage = SellTaxes;
                require(
                    amount <= HardCapSell,
                    "amount must be <= maxTxAmountSell"
                );
            }
        }

        if (
            !InSwap &&
        !AutomatedMarketMakerPairs[sender] &&
        SwapEnabled &&
        sender != owner() &&
        recipient != owner() &&
        sender != address(UniswapV2Router) &&
        balanceOf(address(this)) >= LiquidityThreshold
        ) {
            InSwap = true;
            SwapAccumulatedFees();
            InSwap = false;
        }

        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    // This method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 cantidadBruta,
        bool takeFee
    ) private {
        TransactionFees memory feesReales;
        TransactionFees memory feesRefracionarios;
        (feesReales, feesRefracionarios) = CalcularTasasRealesYRefracionarias(
            cantidadBruta,
            takeFee
        );

        uint256 cantidadNeta = cantidadBruta - feesReales.TotalFee;
        uint256 cantidadBrutaRefracionaria = cantidadBruta *
        GetConversionRate();
        uint256 cantidadNetaRefracionaria = cantidadBrutaRefracionaria -
        feesRefracionarios.TotalFee;

        // Comprobando que el receptor de la transferencia no supere el hard cap de tokens
        require(
            WalletsExcludedFromHardCap[recipient] ||
            (balanceOf(recipient) + cantidadNeta) <= HardCap,
            "Recipient cannot hold more than maxWalletAmount"
        );

        BalancesRefraccionarios[sender] -= cantidadBrutaRefracionaria;
        BalancesRefraccionarios[recipient] += cantidadNetaRefracionaria;

        if (takeFee) {
            ReflactionaryTotal -= feesRefracionarios.TransactionFee;
            TotalFee += feesReales.TransactionFee;

            AccumulateFee(feesReales, feesRefracionarios);

            if (AppliedRatesPercentage.BurnTax > 0) {
                TotalTokenBurn += feesReales.BurnFee;
                BalancesRefraccionarios[address(0)] += feesRefracionarios
                .BurnFee;
                emit Transfer(address(this), address(0), feesReales.BurnFee);
            }

            emit Transfer(sender, address(this), feesReales.TransferrableFee);
        }

        emit Transfer(sender, recipient, cantidadNeta);
    }

    function CalcularTasasRealesYRefracionarias(
        uint256 grossAmount,
        bool takeFee
    )
    private
    view
    returns (
        TransactionFees memory realFees,
        TransactionFees memory refFees
    )
    {
        if (takeFee) {
            uint256 currentRate = GetConversionRate();

            realFees.TransactionFee =
            (grossAmount * AppliedRatesPercentage.RewardTax) /
            100;
            realFees.BurnFee =
            (grossAmount * AppliedRatesPercentage.BurnTax) /
            100;
            realFees.DevFee =
            (grossAmount * AppliedRatesPercentage.DevelopmentTax) /
            100;
            realFees.MarketingFee =
            (grossAmount * AppliedRatesPercentage.MarketingTax) /
            100;
            realFees.LiquidityFee =
            (grossAmount * AppliedRatesPercentage.LiquidityTax) /
            100;

            realFees.TransferrableFee =
            realFees.DevFee +
            realFees.MarketingFee +
            realFees.LiquidityFee;
            realFees.TotalFee =
            realFees.TransactionFee +
            realFees.BurnFee +
            realFees.TransferrableFee;

            refFees.TransactionFee = realFees.TransactionFee * currentRate;
            refFees.BurnFee = realFees.BurnFee * currentRate;
            refFees.DevFee = realFees.DevFee * currentRate;
            refFees.MarketingFee = realFees.MarketingFee * currentRate;
            refFees.LiquidityFee = realFees.LiquidityFee * currentRate;

            refFees.TotalFee = realFees.TotalFee * currentRate;
            refFees.TransferrableFee = realFees.TransferrableFee * currentRate;
        }
    }

    function AccumulateFee(
        TransactionFees memory realFees,
        TransactionFees memory refractionaryFees
    ) private {
        BalancesRefraccionarios[address(this)] += refractionaryFees
        .TransferrableFee;
        AccumulatedFeeForDistribution.LiquidityFee += realFees.LiquidityFee;
        AccumulatedFeeForDistribution.DevFee += realFees.DevFee;
        AccumulatedFeeForDistribution.MarketingFee += realFees.MarketingFee;
    }

    function SwapPct(uint256 pct) public {
        uint256 balance = (balanceOf(address(this)) * pct) / 100;
        if (balance > 0) {
            SwapTokens(balance);
        }
    }

    function SwapTokens(uint256 tokensToSwap) internal {
        uint256 totalTokensToSwap = AccumulatedFeeForDistribution.DevFee +
        AccumulatedFeeForDistribution.MarketingFee +
        AccumulatedFeeForDistribution.LiquidityFee;

        bool success;

        uint256 liquidityTokens = (tokensToSwap *
            AccumulatedFeeForDistribution.LiquidityFee) /
        totalTokensToSwap /
        2;
        uint256 amountToSwapForETH = tokensToSwap - (liquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - (initialETHBalance);

        uint256 ethForMarketing = (ethBalance *
            (AccumulatedFeeForDistribution.MarketingFee)) / (totalTokensToSwap);
        uint256 ethForDev = (ethBalance *
            (AccumulatedFeeForDistribution.DevFee)) / (totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;

        TotalSwapped += AccumulatedFeeForDistribution.LiquidityFee;
        AccumulatedFeeForDistribution.LiquidityFee = 0;
        AccumulatedFeeForDistribution.DevFee = 0;
        AccumulatedFeeForDistribution.MarketingFee = 0;

        (success, ) = address(DevAddress).call{value: ethForDev}("");

        if (
            liquidityTokens > 0 && ethForLiquidity > 0 && AutoLiquidity == true
        ) {
            UniswapV2Router.addLiquidityETH{value: ethForLiquidity}(
                address(this),
                liquidityTokens,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                DevAddress,
                block.timestamp
            );
            emit LiquidityAdded(liquidityTokens, ethForLiquidity);
        }

        (success, ) = address(MarketingAddress).call{value: ethForMarketing}(
            ""
        );
    }

    function SwapAccumulatedFees() private {
        uint256 tokensToSwap = balanceOf(address(this));
        if (tokensToSwap > LiquidityThreshold) {
            if (tokensToSwap > LiquidityThreshold * 20) {
                tokensToSwap = LiquidityThreshold * 20;
            }
            SwapTokens(balanceOf(address(this)));
        }
    }

    function tokenFromReflection(uint256 reflactionaryAmount)
    public
    view
    returns (uint256)
    {
        require(
            reflactionaryAmount <= ReflactionaryTotal,
            "Amount must be less than total reflections"
        );
        return reflactionaryAmount / GetConversionRate();
    }

    function GetConversionRate() private view returns (uint256) {
        return ReflactionaryTotal / totalSupply();
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        SwapEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    receive() external payable {}
}