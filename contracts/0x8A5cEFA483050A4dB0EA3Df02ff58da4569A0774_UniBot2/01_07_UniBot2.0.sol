// SPDX-License-Identifier: MIT                        

pragma solidity 0.8.19;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "./IUniswapV2Router02.sol";

contract UniBot2 is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    uint256 public tradingStartTimeStamp;
    uint256 public maxHoldingAmount;
    uint256 public maxTransactionAmount;
    uint256 private swapTokensAt;

    address public deployerWallet;
    address public marketingWallet;
    address public uniswapV2Pair;

    bool public limited;
    bool public swapEnabled;
    bool private swapping;
    

    mapping (address => bool) private _ExcludedFromFees;
    mapping (address => bool) private _ExcludedFromTransactionAmount;

    error CanOnlySetPairOnce(address);
    error InvalidPresalePrice(uint256);
    error ExceedsHoldingAmount(uint256);
    error ExceedsMaxTransactionAmount(uint256);
    error TradingHasNotStarted();
    error WithdrawFailed();

    constructor(
        uint256 _totalSupply, 
        address _marketingWallet
    ) ERC20("UniBot2.0", "UniBot2.0") {

        _mint(msg.sender, _totalSupply);

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

    function withdrawTokens(address payable _address, address _tokenContract) external onlyOwner {
        uint256 balanceInContract = IERC20(_tokenContract).balanceOf(address(this));
        _transfer(address(this), _address, balanceInContract);
    }


    function _getTaxes(
        uint256 _currentTimestamp
    ) internal view returns (uint256 _buyTax, uint256 _sellTax, bool _eligibleForTax) {
        uint256 elapsedTime = _currentTimestamp - tradingStartTimeStamp;
        uint256 buyTax = 1;
        uint256 sellTax = 1;
        bool eligibleForTax = true;
        if (elapsedTime < 1 minutes) {
            buyTax = 3;
            sellTax = 3;
            eligibleForTax = true;
        } else if (elapsedTime >= 1 minutes && elapsedTime < 3 minutes) {
            buyTax = 2;
            sellTax = 2;
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

        // Swap tokens for ETH
        _swapTokensForEth(_contractBalance); 

        uint256 totalEth = address(this).balance;

        // Send ETH to marketing wallet
        (bool success,) = address(marketingWallet).call{value: totalEth}("");
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
}