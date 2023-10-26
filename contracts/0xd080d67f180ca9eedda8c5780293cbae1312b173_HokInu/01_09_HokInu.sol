// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;


// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((
// ((((((((((((((((((((((((((((@@@@@((((((((((((((((((((((((((((@@@@@((((((((((((((
// ((((((((((((((((((((((((((@@,,,//@@((((((((((((((((((((((((@@,,,@@((((((((((((((
// ((((((((((((((((((((((((((@@,,,///(@(((((((((((((((((((((((@@,,,@@((((((((((((((
// ((((((((((((((((((((((((@@,,,,,///////@@@@@@@@@@@@@@@@@@@@@@@,,,@@((((((((((((((
// ((((((((((((((((((((((((@@,,,,,///////((((((((((((((((((((((((((@@((((((((((((((
// ((((((((((((((((((((((((@@,*////////////////////////////((((((((#(@@((((((((((((
// ((((((((((((((((((((((@@///////////////////////////////////(((((((@@((((((((((((
// ((((((((((((((((((((#&/////////////////////////////////////(((((((@@((((((((((((
// (((((((((((((((((((@@//////////////////////////////////////(((((((@@((((((((((((
// (((((((((((((((((((@@//////////////////////////////////////(((((((((@@((((((((((
// (((((((((((((((@@/////////////////////////     /////////(((((   (((((#@(((((((((
// (((((((((((((((@@///////////          @@@@@//  ///((((((((((((((@@@@(#@(((((((((
// (((((((((((((((@@/////////            @@@@@    ((((((((((((((   @@@@   @@(((((((
// (((((((((((((((@@///////                          @@@@@@@@@              @@(((((
// (((((((((((((((@@///////                          @@@@@@@@@              @@(((((
// (((((((((((((((@@@@@@@@@@@@@@                  @%     @@     @%          @@(((((
// (((((((((((((((@@@@@@@@@%%%%%@@                 ,@@@@@@@@@@@@            @@(((((
// ((((((((((((((@%%%%%%%%%@@%%%%%%%#%@            ,@,,,,//,,,@@            @@(((((
// ((((((((((((@@%%%%%%%%%%@@%%%%%#####@@          ,@,,,,//,,,@@            @@(((((
// (((((((@@@((@@%%%%%%%%##%%%%@###########@@&       @@@@@@@@@         @@&(((((((((
// (((((@&   @@@@%%%%%%%###%%%%@%##########@@%@@                     @@@@@(((((((((
// (((@@     @&@@%%%%%%%#####%%%@@#######@@%%%##@@ .               @@@@#%@(((((((((
// (@@/////////@@%%%%%#########%%%@@###@@%%#######%&@%########@@###@@@@##@(((((((((
// @(//////////@@%%%%%##########%%%%@@@%%#########%&@#%%%%%%%%@@###@@((@@@(((((((((
// @(//////////@@%%%%%@@@@@@@@@@####################%@@#%%%%@@###%@((((((((((((((((
// @(//////////@@%@@@@//////////@@##################%@@%###%@@##@&(((((((((((((((((
// (((@@///////@@/////////////////@@################%@@%#%%%@@##@&(((((((((((((((((
// (((((@@/////@@/////////////////@@##########@@@@@@%@@%#%%@@@@@@&(((((((((((((((((
// (((((((@@@@@@@///////////////////&@%%%%%%%@////@@%%%@@@@(((((@&(((((((((((((((((
// ((((((((((((@@/////////////////////,,,@@%%@,,,,@@%%%%%@@,,*@@(((((((((((((((((((

/*
 
██╗░░██╗░█████╗░██╗░░██╗██╗███╗░░██╗██╗░░░██╗
██║░░██║██╔══██╗██║░██╔╝██║████╗░██║██║░░░██║
███████║██║░░██║█████═╝░██║██╔██╗██║██║░░░██║
██╔══██║██║░░██║██╔═██╗░██║██║╚████║██║░░░██║
██║░░██║╚█████╔╝██║░╚██╗██║██║░╚███║╚██████╔╝
╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░╚══╝░╚═════╝░

Meet Hok, the loyal Shiba Inu sidekick! We're thrilled to introduce HOKINU COIN, a cryptocurrency born from the spirit of the rare Hokkaido Japanese dog. 
Get ready to embark on a captivating journey as Hok and his digital coin venture take the world by storm, spreading the love and uniqueness of the Hokkaido breed to crypto enthusiasts worldwide.

Twitter:  https://twitter.com/hokinucoin
Telegram: https://t.me/hokinucoin
Website:  https://hokinu.vip

*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract HokInu is ERC20("HokInu", "HOKINU"), Ownable {

    // Uniswap variables
    IUniswapV2Factory public constant UNISWAP_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IUniswapV2Router02 public constant UNISWAP_ROUTER = 
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public immutable UNISWAP_PAIR;


    uint256 constant MAX_SUPPLY = 100_000_000 ether;
    uint256 public launchBlock;

    bool private swapping;

    address public hokInuWallet;

    bool public limitsActive = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    bool public fetchRateRequired = true;

    uint256 public buyTotalTaxFees;
    uint256 public sellTotalTaxFees;
    uint256 public taxedTokens;

    uint256 public maxBuyTxAmount;
    uint256 public maxSellTxAmount;
    uint256 public maxWalletHoldings;
    uint256 public swapThreshold;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    event EnabledTrading(bool tradingActive);
    event LimitsDisabled();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyTxAmount(uint256 newAmount);
    event UpdatedMaxSellTxAmount(uint256 newAmount);
    event UpdatedMaxWalletHoldings(uint256 newAmount);
    event UpdatedhokInuWallet(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);


    constructor(){

        _mint(msg.sender, MAX_SUPPLY);

        _approve(address(this), address(UNISWAP_ROUTER), ~uint256(0));

        _excludeFromMaxTx(address(UNISWAP_ROUTER), true);

    
        UNISWAP_PAIR = UNISWAP_FACTORY.createPair(
            address(this),
            UNISWAP_ROUTER.WETH()
        );

        maxBuyTxAmount = (totalSupply() * 15) / 1_000; // 1.5% max buy
        maxSellTxAmount = (totalSupply() * 75) / 10_000; // 0.75% max sell
        maxWalletHoldings = (totalSupply() * 20) / 1_000; // 2% max holdings
        swapThreshold = (totalSupply() * 55) / 10_000; // 0.55% swapToEth threshold 

        hokInuWallet = msg.sender;

        _excludeFromMaxTx(msg.sender, true);
        _excludeFromMaxTx(address(this), true);
        _excludeFromMaxTx(address(0xdead), true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
    }

    receive() external payable {}


    function updateMaxBuyTxAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "max buy txn amount too low"
        );
        maxBuyTxAmount = newNum;
        emit UpdatedMaxBuyTxAmount(maxBuyTxAmount);
    }

    function updateMaxSellTxAmount(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 1) / 1_000),
            "max sell txn amount too low"
        );
        maxSellTxAmount = newNum;
        emit UpdatedMaxSellTxAmount(maxSellTxAmount);
    }

    function updateMaxWalletHoldings(uint256 newNum) external onlyOwner {
        require(
            newNum >= ((totalSupply() * 3) / 1_000),
            "max wallet amount too low"
        );
        maxWalletHoldings = newNum;
        emit UpdatedMaxWalletHoldings(maxWalletHoldings);
    }

    function updateSwapThreshold(uint256 newAmount) external onlyOwner {
        require(
            newAmount >= (totalSupply() * 1) / 100_000,
            "swap threshold too low"
        );
    
        swapThreshold = newAmount;
    }

    function disableLimits() external onlyOwner {
        limitsActive = false;
        emit LimitsDisabled();
    }


    function _excludeFromMaxTx(
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

    function setNewFees(uint256 newBuyFees, uint256 newSellFees) external onlyOwner {
        buyTotalTaxFees = newBuyFees;
        sellTotalTaxFees = newSellFees;
    }

    function launchToken() public onlyOwner {
        require(launchBlock == 0, "Token state is already live !");
        launchBlock = block.number;
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading(tradingActive);
    }


    function sethokInuWallet(address _hokInuWallet) external onlyOwner {
        require(_hokInuWallet != address(0), "Address cannot be 0");
        hokInuWallet = payable(_hokInuWallet);
        emit UpdatedhokInuWallet(_hokInuWallet);
    }

    function getCurrentRate() internal {
        require(
            launchBlock > 0, "Trading not live"
        );
        uint256 currentBlock = block.number;
        uint256 lastTierOneBlock = launchBlock + 6;
        if(currentBlock <= lastTierOneBlock) {
            buyTotalTaxFees = 5;
            sellTotalTaxFees = 15;
        } else {
            buyTotalTaxFees = 2;
            sellTotalTaxFees = 2;
            fetchRateRequired = false;
        } 
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (limitsActive) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead)
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedMaxTransactionAmount[from] ||
                            _isExcludedMaxTransactionAmount[to],
                        "Trading is not active."
                    );
                    require(from == owner(), "Trading is enabled");
                }

                //when buy
                if (
                    from == UNISWAP_PAIR && !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxBuyTxAmount,
                        "Buy transfer amount exceeds the max buy."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletHoldings,
                        "Cannot Exceed max wallet"
                    );
                }
                //when sell
                else if (
                    to == UNISWAP_PAIR && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxSellTxAmount,
                        "Sell transfer amount exceeds the max sell."
                    );
                } else if (
                    !_isExcludedMaxTransactionAmount[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount + balanceOf(to) <= maxWalletHoldings,
                        "Cannot Exceed max wallet"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapThreshold;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !(from == UNISWAP_PAIR) &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;
    
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
    

        if (takeFee) {

            if(fetchRateRequired){
               getCurrentRate(); 
            }

            // Sell
            if (to == UNISWAP_PAIR && sellTotalTaxFees > 0) {
                fees = (amount * sellTotalTaxFees) / 100;
                taxedTokens += fees;
            }
            // Buy
            else if (from == UNISWAP_PAIR && buyTotalTaxFees > 0) {
                fees = (amount * buyTotalTaxFees) / 100;
                taxedTokens += fees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }


    function liquifyTokensForEth(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UNISWAP_ROUTER.WETH();

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

        uint256 totalTokensToSwap =  taxedTokens;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapThreshold) {
            contractBalance = swapThreshold;
        }

        bool success;
    
        liquifyTokensForEth(contractBalance);

        (success, ) = address(hokInuWallet).call{value: address(this).balance}("");
    }



    function rescueToken(address _token) external {
        require(
            msg.sender == owner() || msg.sender == hokInuWallet,
            "Caller not authorized to complete this txn"
        );
        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }


    function withdrawEth() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "failed to withdraw Eth balance");
    }
    
}