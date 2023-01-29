/**
 * ShibUtility | SHIBU
 *
 * Total Supply: 40,000,000
 * Max Wallet: 1%
 * Max Tx: 1%
 * Tax: 1% Liquidity, 4% Treasury
 *
 * ---
 *
 * In the jungle of DeFi,
 * Where apes roam free,
 * A new token rises,
 * With a unique strategy.
 *
 * Shibu, oh Shibu,
 * A community-driven crew,
 * With a direct liquidity injection,
 * That's sure to make the market move.
 *
 * The K Score rises,
 * As ETH is injected,
 * A fresh way to moonshot,
 * The token's price projected.
 *
 * The team is passionate,
 * About the future of DeFi,
 * With Ethereum for the launch,
 * But expansion is key.
 *
 * So join the Shibu family,
 * As we strive for glory,
 * To make our mark,
 * In the DeFi story.
 *
 * ---
 *
 * 🦴 https://Shibu.app
 * 🦴 https://shibutility.medium.com
 * 🦴 https://t.me/ShibUtilityPortal
 *
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ShibUtility is ERC20, Pausable, Ownable {
    IUniswapV2Router02 public marketMakerRouter;
    address public marketMakerPair;

    address public treasury;

    uint256 public liquidityFee = 1;
    uint256 public treasuryFee = 4;
    uint256 public totalFees = liquidityFee + treasuryFee;

    uint256 private _maxWalletAmount;
    uint256 private _maxTxAmount;
    uint256 private _buyMultiplier = 100;
    uint256 private _sellMultiplier = 100;
    uint256 private _transferMultiplier = 0;
    uint256 private _swapAndLiqInjectThreshold;
    bool private _inSwap;

    mapping(address => bool) private _isFeeExempt;
    mapping(address => bool) private _isPauseExempt;
    mapping(address => bool) private _isMaxTxExempt;
    mapping(address => bool) private _isMaxWalletExempt;

    modifier swapping() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    event SetMaxWallet(uint256 amount);
    event SetMaxTx(uint256 amount);
    event SetSwapAndLiqInjectThreshold(uint256 threshold);
    event SetFees(uint256 buy, uint256 sell, uint256 transfer);
    event SetTreasury(address indexed treasury);
    event SwapAndLiqInject(uint256 amountTreasury, uint256 amountLiquidity);

    constructor() ERC20("ShibUtility", "SHIBU") {
        marketMakerRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        marketMakerPair = IUniswapV2Factory(marketMakerRouter.factory()).createPair(
            address(this), marketMakerRouter.WETH()
        );

        _isFeeExempt[msg.sender] = true;
        _isPauseExempt[msg.sender] = true;
        _isMaxTxExempt[msg.sender] = true;
        _isMaxTxExempt[address(marketMakerRouter)] = true;
        _isMaxTxExempt[marketMakerPair] = true;
        _isMaxTxExempt[address(0)] = true;
        _isMaxWalletExempt[msg.sender] = true;
        _isMaxWalletExempt[marketMakerPair] = true;
        _isMaxWalletExempt[address(0)] = true;
        _isMaxWalletExempt[address(this)] = true;

        uint256 initialSupply = 40_000_000 * 10 ** 18; // 40 million
        _maxTxAmount = initialSupply / 100; // 1% of total supply
        _maxWalletAmount = initialSupply / 100; // 1% of total supply
        _swapAndLiqInjectThreshold = initialSupply * 8 / 1000; // 0.8% of total supply

        _mint(owner(), initialSupply);
        _pause();
    }

    receive() external payable {}

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() - balanceOf(address(0));
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (_inSwap) {
            return super._transfer(from, to, amount);
        }

        if (!_isPauseExempt[from] && !_isPauseExempt[to]) {
            _requireNotPaused();
        }

        if (!_isMaxWalletExempt[to]) {
            require((balanceOf(to) + amount) <= _maxWalletAmount, "MAX_WALLET_EXCEEDED");
        }

        if (!_isMaxTxExempt[from]) {
            require((amount <= _maxTxAmount), "MAX_TX_EXCEEDED");
        }

        if (!_isFeeExempt[from] && !_isFeeExempt[to]) {
            amount = _takeFee(from, to, amount);

            if (_shouldSwapAndLiqInject()) {
                _swapAndLiqInject();
            }
        }

        return super._transfer(from, to, amount);
    }

    function _shouldSwapAndLiqInject() internal view returns (bool) {
        return msg.sender != marketMakerPair && !paused()
            && balanceOf(address(this)) >= _swapAndLiqInjectThreshold;
    }

    function _takeFee(address from, address to, uint256 amount) internal returns (uint256) {
        if (amount == 0 || totalFees == 0) {
            return amount;
        }

        uint256 multiplier;

        if (marketMakerPair == to) {
            multiplier = _sellMultiplier;
        } else if (marketMakerPair == from) {
            multiplier = _buyMultiplier;
        } else {
            multiplier = _transferMultiplier;
        }

        uint256 fee = (amount * totalFees * multiplier) / 10_000; // allow for 2 decimal places of precision

        if (fee > 0) {
            super._transfer(from, address(this), fee);
        }

        return amount - fee;
    }

    function _swapAndLiqInject() internal swapping {
        uint256 balanceToken = balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = marketMakerRouter.WETH();
        _approve(address(this), address(marketMakerRouter), balanceToken);
        marketMakerRouter.swapExactTokensForETH(
            balanceToken - 1 ether, 0, path, address(this), block.timestamp
        );

        uint256 balanceETH = address(this).balance;

        uint256 amountTreasury = balanceETH * treasuryFee / totalFees;
        uint256 amountLiquidity = balanceETH - amountTreasury;
        (bool success,) = payable(treasury).call{value: amountTreasury, gas: 30_000}("");
        require(success, "TRANSFER_FAILED");

        if (amountLiquidity > 0) {
            IWETH weth = IWETH(marketMakerRouter.WETH());

            weth.deposit{value: amountLiquidity}();
            weth.transfer(address(marketMakerRouter), amountLiquidity);

            IUniswapV2Pair(marketMakerPair).sync();
        }
        emit SwapAndLiqInject(amountTreasury, amountLiquidity);
    }

    function burn(uint256 amount) external onlyOwner {
        uint256 supply = totalSupply();
        uint256 maxWalletPercent = _maxWalletAmount * 10_000 / supply; // base 10000
        uint256 maxTxPercent = _maxTxAmount * 10_000 / supply; // base 10000
        uint256 swapAndLiqInjectThresholdPercent = _swapAndLiqInjectThreshold * 100 / supply;

        _burn(msg.sender, amount);

        // Update values where totalSupply() is used
        setMaxWallet(maxWalletPercent);
        setMaxTx(maxTxPercent);
        setSwapAndLiqInjectThreshold(swapAndLiqInjectThresholdPercent * totalSupply() / 10 ** 18);
    }

    function setFeeExempt(address wallet, bool status) external onlyOwner {
        _isFeeExempt[wallet] = status;
    }

    function setMaxTxExempt(address wallet, bool status) external onlyOwner {
        _isMaxTxExempt[wallet] = status;
    }

    function setMaxWalletExempt(address wallet, bool status) external onlyOwner {
        _isMaxWalletExempt[wallet] = status;
    }

    function setPauseExempt(address wallet, bool status) external onlyOwner {
        _isPauseExempt[wallet] = status;
    }

    /// @param percent - Max percent of total supply a wallet may hold. Uses a
    /// base of 10000 e.g., 10000 = 100%, 125 = 1.25%.
    function setMaxWallet(uint256 percent) public onlyOwner {
        require(percent >= 50, "MAX_WALLET_UNDER_0.5%");

        _maxWalletAmount = totalSupply() * percent / 10_000;
        emit SetMaxWallet(_maxWalletAmount);
    }

    /// @param percent - Max percent of total supply a transaction may transfer.
    /// Uses a base of 10000 e.g., 10000 = 100%, 125 = 1.25%.
    function setMaxTx(uint256 percent) public onlyOwner {
        require(percent >= 10, "MAX_TX_UNDER_0.1%");

        _maxTxAmount = totalSupply() * percent / 10_000;
        emit SetMaxTx(_maxTxAmount);
    }

    /// @param amount - Threshold amount in ERC20 token (no decimals). When the
    /// contract's balance reaches this amount, it may distribute held funds.
    function setSwapAndLiqInjectThreshold(uint256 amount) public onlyOwner {
        uint256 newThreshold = amount * 10 ** 18;
        require(newThreshold <= totalSupply() / 20, "THRESHOLD_OVER_5%_SUPPLY");

        _swapAndLiqInjectThreshold = newThreshold;
        emit SetSwapAndLiqInjectThreshold(newThreshold);
    }

    function _validateFees() internal {
        uint256 buyFee = totalFees * _buyMultiplier / 100;
        uint256 sellFee = totalFees * _sellMultiplier / 100;
        uint256 transferFee = totalFees * _transferMultiplier / 100;

        require(buyFee <= 20, "BUY_FEE_OVER_20%");
        require(sellFee <= 20, "SELL_FEE_OVER_20%");
        require(buyFee + sellFee <= 30, "BUY+SELL_FEE_OVER_30%");
        require(transferFee <= 10, "TRANSFER_FEE_OVER_10%");

        emit SetFees(buyFee, sellFee, transferFee);
    }

    function setMultipliers(
        uint256 buyMultiplier,
        uint256 sellMultiplier,
        uint256 transferMultiplier
    ) external onlyOwner {
        _buyMultiplier = buyMultiplier;
        _sellMultiplier = sellMultiplier;
        _transferMultiplier = transferMultiplier;

        _validateFees();
    }

    function setFees(uint256 newLiquidityFee, uint256 newTreasuryFee) external onlyOwner {
        liquidityFee = newLiquidityFee;
        treasuryFee = newTreasuryFee;
        totalFees = newLiquidityFee + newTreasuryFee;

        _validateFees();
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
        emit SetTreasury(newTreasury);
    }

    // Pausable so that we can launch V2 and pause V1 when utility is released.
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // In case of stuck ETH or tokens during pause.
    function clearStuckBalance(uint256 percent) external onlyOwner {
        require(percent <= 100, "OVER_100%");

        uint256 amount = (address(this).balance * percent) / 100;
        payable(msg.sender).transfer(amount);
    }

    function clearStuckToken(address token, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = ERC20(token).balanceOf(address(this));
        }

        require(ERC20(token).transfer(msg.sender, amount), "TRANSFER_FAILED");
    }
}

/// @dev 🐕