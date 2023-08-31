// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC20/ERC20.sol";
import "./IUniswapV2Router02.sol";

contract RESET is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public immutable maxAmountToRaiseInPublicSale;
    uint256 public immutable minContribution;
    uint256 public immutable maxContribution;
    uint256 private immutable presaleSupply;

    uint256 public tradingStartTimeStamp;
    uint256 public amountRaisedInPublicSale;
    uint256 public totalContributed;
    uint256 public numOfContributoors;
    uint256 public maxHoldingAmount;
    uint256 public maxTransactionAmount;
    uint256 private swapTokensAt;

    address public deployerWallet;
    address public marketingWallet;
    address public uniswapV2Pair;

    bool public publicSaleStarted;
    bool public limited;
    bool public swapEnabled;
    bool private swapping;
    

    mapping (uint256 => PublicContribution) public contribution;
    mapping (address => uint256) public contributor;
    mapping (address => bool) public purchasedPublic;
    mapping (address => bool) private _ExcludedFromFees;
    mapping (address => bool) private _ExcludedFromTransactionAmount;
    
    struct PublicContribution {
        uint256 amount;
        address userAddr;
    }

    modifier onlyEOA(address _caller) {
        if (tx.origin != _caller) revert NoContracts(tx.origin, _caller);
        _;
    }

    error MistmatchArrayLengths(uint256,uint256);
    error CanOnlySetPairOnce(address);
    error InvalidPresalePrice(uint256);
    error AlreadyPurchased(address);
    error NoContracts(address,address);
    error ExceedsHoldingAmount(uint256);
    error ExceedsMaxTransactionAmount(uint256);
    error SaleHasNotStarted();
    error TradingHasNotStarted();
    error PublicSoldOut();
    error WithdrawFailed();

    constructor(
        uint256 _totalSupply, 
        uint256 _amountRaisedInPrivateSale,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _amountToRaiseInPublic,
        uint256 _preSaleSupply,
        address _marketingWallet
    ) ERC20("RESET", "RESET") {

        _mint(msg.sender, _totalSupply);

        totalContributed = _amountRaisedInPrivateSale;

        minContribution = _minContribution;

        maxContribution = _maxContribution;

        maxAmountToRaiseInPublicSale = _amountToRaiseInPublic;

        presaleSupply = _preSaleSupply;

        swapTokensAt = (_totalSupply * 9) / 10_000;

        swapEnabled = true;

        deployerWallet = msg.sender;

        marketingWallet = _marketingWallet;

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(marketingWallet, true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(msg.sender, true);
        excludeFromMaxTransaction(address(this), true);
    }

    receive() external payable {}

    function sendEthToPresale() external payable onlyEOA(msg.sender) {

        // The sale must have started in order to participate
        if (!publicSaleStarted) revert SaleHasNotStarted();

        // Msg.value must respect the boundries set
        if (msg.value > maxContribution || msg.value < minContribution) revert InvalidPresalePrice(msg.value);

        // Check to see if they have already purchased an allocation of tokens
        if (purchasedPublic[msg.sender]) revert AlreadyPurchased(msg.sender);

        // Ensures that the max amount to raise in a public sale is respected
        if (amountRaisedInPublicSale + msg.value > maxAmountToRaiseInPublicSale) revert PublicSoldOut();

        unchecked {
            uint256 contributionIndex = numOfContributoors + 1;
            contributor[msg.sender] = contributionIndex;
            contribution[contributionIndex].userAddr = msg.sender;
            contribution[contributionIndex].amount += msg.value;
            purchasedPublic[msg.sender] = true;
            numOfContributoors++;
            amountRaisedInPublicSale += msg.value;
            totalContributed += msg.value;
        }
    }

    function airdropPresalers(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {

        // Private presale allocations
        if (_recipients.length != _amounts.length) revert MistmatchArrayLengths(_recipients.length, _amounts.length);

        for (uint256 i; i < _recipients.length;) {
            _transfer(owner(), _recipients[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }

        // Public presale allocations
        uint256 pricePerToken = (totalContributed * 10 ** 18) / presaleSupply;

        for (uint256 i = 1; i <= numOfContributoors;) {
            uint256 contributionAmount = contribution[i].amount * 10 ** 18;

            uint256 numberOfTokens = contributionAmount/pricePerToken;

            _transfer(owner(), contribution[i].userAddr, numberOfTokens);
            unchecked {
                ++i;
            }
        }
 
    }

    function commenceTrading(address _uniswapV2Pair) external onlyOwner {

        if (tradingStartTimeStamp != 0) revert CanOnlySetPairOnce(uniswapV2Pair);

        uniswapV2Pair = _uniswapV2Pair;
        tradingStartTimeStamp = block.timestamp;
    }

    function setLimits(
        bool _limited, 
        uint256 _maxHoldingAmount,
        uint256 _maxTransactionAmount
    ) external onlyOwner {
        limited = _limited;
        maxTransactionAmount = _maxTransactionAmount;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function toggleSwapping(bool _bool) external onlyOwner {
        swapEnabled = _bool;
    }

    function commencePublicSale(bool _bool) external onlyOwner {
        publicSaleStarted = _bool;
    }

    function excludeFromFees(address _account, bool _excluded) public onlyOwner {
        _ExcludedFromFees[_account] = _excluded;
    }

    function excludeFromMaxTransaction(address _account, bool _excluded) public onlyOwner {
        _ExcludedFromTransactionAmount[_account] = _excluded;
    }

    function withdrawFunds(address payable _address) external onlyOwner {
        (bool success, ) = _address.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }


    function _getTaxes(
        uint256 _currentTimestamp
    ) internal view returns (uint256 _buyTax, uint256 _sellTax, bool _eligibleForTax) {
        uint256 elapsedTime = _currentTimestamp - tradingStartTimeStamp;
        uint256 buyTax;
        uint256 sellTax;
        bool eligibleForTax;
        if (elapsedTime < 1 minutes) {
            buyTax = 20;
            sellTax = 20;
            eligibleForTax = true;
        } else if (elapsedTime >= 1 minutes && elapsedTime < 2 minutes) {
            buyTax = 10;
            sellTax = 15;
            eligibleForTax = true;
        } else if (elapsedTime >= 2 minutes && elapsedTime < 3 minutes) {
            buyTax = 5;
            sellTax = 10;
            eligibleForTax = true;
        } else if (elapsedTime >= 3 minutes && elapsedTime < 4 minutes) {
            sellTax = 5;
            eligibleForTax = true;
        } 

        return (buyTax, sellTax, eligibleForTax);
    }

    function _transfer(
        address from, 
        address to, 
        uint256 amount
    ) internal override {
        if (uniswapV2Pair == address(0) && from != address(0) && from != owner()) revert TradingHasNotStarted();

        if(
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping
        )
            {
                if (limited) {
                    if (from == uniswapV2Pair && !_ExcludedFromTransactionAmount[to]) {
                        if (amount > maxTransactionAmount) revert ExceedsMaxTransactionAmount(amount);
                        if (balanceOf(to) + amount > maxHoldingAmount) revert ExceedsHoldingAmount(amount);
                    }
                    else if (to == uniswapV2Pair && !_ExcludedFromTransactionAmount[from]) {
                        if (amount > maxTransactionAmount) revert ExceedsMaxTransactionAmount(amount);
                    }
                    else if (!_ExcludedFromTransactionAmount[to]) {
                        if (balanceOf(to) + amount > maxHoldingAmount) revert ExceedsHoldingAmount(amount);
                    }
                }
            }
        
        uint256 contractBalance = balanceOf(address(this));

        
        bool canSwap = contractBalance >= swapTokensAt;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            from != uniswapV2Pair &&
            !_ExcludedFromFees[from] &&
            !_ExcludedFromFees[to]
        ) {
            swapping = true;
            
            _swapBack(contractBalance);

            swapping = false;
        }

        bool takeFee = !swapping;

        
        if(_ExcludedFromFees[from] || _ExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            (uint256 buyTax, uint256 sellTax, bool eligibleForTax) = _getTaxes(block.timestamp);
            if (from == uniswapV2Pair && eligibleForTax) {
                uint256 tax = (amount * buyTax) / 100;
                super._transfer(from, address(this), tax);
                amount -= tax;
            }

            if (to == uniswapV2Pair && eligibleForTax) {
                uint256 tax = (amount * sellTax) / 100;
                super._transfer(from, address(this), tax);
                amount -= tax;
            }
        }
        super._transfer(from, to, amount);
    }

    function _swapBack(uint256 _contractBalance) private {
        if (_contractBalance == 0) { return; }

        // Calculate the total tokens to swap for ETH (30% marketing + 35% liquidity)
        uint256 tokensToSwap = _contractBalance * 65 / 100;

        // Swap tokens for ETH
        _swapTokensForEth(tokensToSwap); 

        uint256 totalEth = address(this).balance;
        uint256 newBalance = balanceOf(address(this));

        // Calculate ETH distribution
        uint256 ethForMarketing = totalEth * 30 / 100; // 30% ETH for marketing
        uint256 ethForLiquidity = totalEth - ethForMarketing; // 70% ETH for liquidity

        // Send ETH to marketing wallet
        (bool success,) = address(marketingWallet).call{value: ethForMarketing}("");

        // Add ETH to liquidity
        _addLiquidity(newBalance, ethForLiquidity); // We take the proportional part of tokensToSwap for liquidity
    }


    function _swapTokensForEth(uint256 _tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        
        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0, 
            0, 
            deployerWallet,
            block.timestamp
        );

    }
}