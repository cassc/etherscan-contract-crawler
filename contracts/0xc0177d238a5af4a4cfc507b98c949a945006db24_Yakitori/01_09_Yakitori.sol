/*
██╗   ██╗ █████╗ ██╗  ██╗██╗████████╗ ██████╗ ██████╗ ██╗
╚██╗ ██╔╝██╔══██╗██║ ██╔╝██║╚══██╔══╝██╔═══██╗██╔══██╗██║
 ╚████╔╝ ███████║█████╔╝ ██║   ██║   ██║   ██║██████╔╝██║
  ╚██╔╝  ██╔══██║██╔═██╗ ██║   ██║   ██║   ██║██╔══██╗██║
   ██║   ██║  ██║██║  ██╗██║   ██║   ╚██████╔╝██║  ██║██║
   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝
                                                         
🌐 Website: https://www.yakitorierc.xyz/
🐦 Twitter: https://twitter.com/YakitoriERC20
🇹 Telegram: http://t.me/YakitoriERC
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Yakitori is ERC20("Yakitori", "YAKI"), Ownable {

    // Uniswap variables
    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_V2_PAIR;

    // Contract variables
    uint256 constant TOTAL_SUPPLY = 420_000_000_000 ether;
    address constant BURN_ADDRESS = address(0xdead);
    uint256 public launchedOnBlock;

    // Max buy | sell | wallet amount
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    // Swap back variables
    bool private swapping;
    uint256 public swapTokensAtAmount;

    // Tax fee recipients
    address public treasuryWallet;
    address public devWallet;

    // Trading state variables
    bool public limitsActive = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    // Tax fees
    uint256 public totalBuyFees = 20;
    uint256 public treasuryBuyFee = 20;
    uint256 public devBuyFee = 0;

    uint256 public totalSaleFees = 35;
    uint256 public treasurySellFee = 35;
    uint256 public devSellFee = 0;

    uint256 public treasuryTokens;
    uint256 public devTokens;

    // Mappings
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public isBot;


    event EnabledTrading(bool tradingActive);
    event RemovedLimits();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event UpdatedTreasuryWallet(address indexed newWallet);
    event UpdatedDevWallet(address indexed newWallet);
    event UpdatedRewardsAddress(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    

    constructor() {
        _mint(msg.sender, TOTAL_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTransaction(address(UNISWAP_ROUTER), true);

        UNISWAP_V2_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyAmount = (totalSupply() * 20) / 1_000; // 2% max buy
        maxSellAmount = (totalSupply() * 20) / 1_000; // 2% max sell
        maxWalletAmount = (totalSupply() * 30) / 1_000; // 3% max holdings
        swapTokensAtAmount = (totalSupply() * 100) / 10_000; // 1% swapToEth threshold 

        treasuryWallet = msg.sender;
        devWallet = msg.sender;

        _excludeFromMaxTransaction(msg.sender, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }


    receive() external payable {}


    function launchToken() public onlyOwner {
        require(launchedOnBlock == 0, "ERROR: Token state is already live !");
        launchedOnBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading(tradingActive);
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        maxBuyAmount = newNum;
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        maxSellAmount = newNum;
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    // To remove tax limits on buys/sales
    function removeLimits() external onlyOwner {
        limitsActive = false;
        emit RemovedLimits();
    }

    // Update wallet recipients
    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        require(_treasuryWallet != address(0), "ERROR: _treasuryWallet address cannot be 0 !");
        treasuryWallet = payable(_treasuryWallet);
        emit UpdatedTreasuryWallet(_treasuryWallet);
    }

    function setDevWallet(address _devWallet) external onlyOwner {
        require(_devWallet != address(0), "ERROR: _devWallet address cannot be 0 !");
        devWallet = payable(_devWallet);
        emit UpdatedDevWallet(_devWallet);
    }

    // Update tax amounts
    function updateTaxFees(
        uint256 _newTreasurySellFee,
        uint256 _newTreasuryBuyFee,
        uint256 _newDevSellFee,
        uint256 _newDevBuyFee
    ) external onlyOwner {
        treasurySellFee = _newTreasurySellFee;
        treasuryBuyFee = _newTreasuryBuyFee;
        devSellFee = _newDevSellFee;
        devBuyFee = _newDevBuyFee;
        totalBuyFees = treasuryBuyFee + devBuyFee;
        totalSaleFees = treasurySellFee + devSellFee;
    }

    // Exclude from restrictions & fees
    function _excludeFromMaxTransaction(
        address updAds,
        bool isExcluded
    ) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // Blacklist functions (remove | add)
    function addBotterToList(address _account) external onlyOwner {
        require(
            _account != address(UNISWAP_ROUTER),
            "ERROR: Cannot blacklist Uniswap Router !"
        );
        require(!isBot[_account], "ERROR: Botter already exist !");
        isBot[_account] = true;
    }

    function removeBotterFromList(address _account) external onlyOwner {
        require(isBot[_account], "ERROR: Address not found in Bots !");
        isBot[_account] = false;
    }


    // TRADING GOVERNANCE
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERROR ERC20: transfer from the zero address !");
        require(to != address(0), "ERROR ERC20: transfer to the zero address !");
        require(amount > 0, "ERROR: Amount must be greater than 0 !");
        require(!isBot[to], "ERROR: Bot detected !");
        require(!isBot[from], "ERROR: Bot detected !");

        if (limitsActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] || _isExcludedMaxTransactionAmount[to],
                        "ERROR: Trading is not active !"
                    );
                    require(from == owner(), "ERROR: Trading is active !");
                }
                //when buy
                if (
                    from == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyAmount,
                        "ERROR: Buy amount limit exceeded !"
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: Max wallet amount exceeded !"
                    );
                }
                //when sell
                else if (
                    to == UNISWAP_V2_PAIR && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxSellAmount,
                        "ERROR: Sale amount limit exceeded !"
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "ERROR: Max wallet amount exceeded !"
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
            !(from == UNISWAP_V2_PAIR) &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (to == UNISWAP_V2_PAIR && totalSaleFees > 0) {
                fees = (amount * totalSaleFees) / 100;
                treasuryTokens += (fees * treasurySellFee) / totalSaleFees;
                devTokens += (fees * devSellFee) / totalSaleFees;
            }
            // on buy
            else if (from == UNISWAP_V2_PAIR && totalBuyFees > 0) {
                fees = (amount * totalBuyFees) / 100;
                treasuryTokens += (fees * treasuryBuyFee) / totalBuyFees;
                devTokens += (fees * devBuyFee) / totalBuyFees;
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
        path[1] = UNISWAP_ROUTER.WETH();

        _approve(address(this), address(UNISWAP_ROUTER), tokenAmount);

        // make the swap
        UNISWAP_ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }


    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = treasuryTokens + devTokens;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount) {
            contractBalance = swapTokensAtAmount;
        }

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance;

        uint256 ethForTreasury = (ethBalance * treasuryTokens) / totalTokensToSwap;

        treasuryTokens = 0;
        devTokens = 0;

        (success, ) = address(treasuryWallet).call{value: ethForTreasury}("");
        (success, ) = address(devWallet).call{value: address(this).balance}("");
    }

    
    // NOTE: ARGUMENT IN ETHER (1e18)
    function airdropTokens(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            addresses.length == amounts.length,
            "ERROR: Array sizes must be equal !"
        );
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i] * 1e18;
            _transfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }



    // to withdarw ETH from contract 
    // NOTE: ARGUMENT IN WEI
    function withdrawETH(uint256 _amount) external onlyOwner {

        require(
            address(this).balance >= _amount,
            "ERROR: Insufficient balance to complete txn !"
        );

        payable(msg.sender).transfer(_amount);
    }

    // to withdraw ERC20 tokens from contract 
    // NOTE: ARGUMENT IN WEI
    function withdrawToken(IERC20 _token, uint256 _amount) external onlyOwner {

        require(
            _token.balanceOf(address(this)) >= _amount,
            "ERROR: Insufficient balance to complete txn !"
        );

        _token.transfer(msg.sender, _amount);
    }

    // DISABLE TRADING | EMERGENCY USE ONLY
    function updateTradingStatus(bool enabled) external onlyOwner {
        tradingActive = enabled;
    }
    
}