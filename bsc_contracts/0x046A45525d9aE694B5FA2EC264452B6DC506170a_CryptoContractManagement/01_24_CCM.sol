// Token contract of:
// ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄       ▄▄       ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄    ▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄        ▄ 
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░▌     ▐░░▌     ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░░▌      ▐░▌
// ▐░█▀▀▀▀▀▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌   ▐░▐░▌      ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀█░▌▐░▌ ▐░▌ ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌░▌     ▐░▌
// ▐░▌          ▐░▌          ▐░▌▐░▌ ▐░▌▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌  ▐░▌          ▐░▌▐░▌    ▐░▌
// ▐░▌          ▐░▌          ▐░▌ ▐░▐░▌ ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌░▌   ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌ ▐░▌   ▐░▌
// ▐░▌          ▐░▌          ▐░▌  ▐░▌  ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░░▌    ▐░░░░░░░░░░░▌▐░▌  ▐░▌  ▐░▌
// ▐░▌          ▐░▌          ▐░▌   ▀   ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌░▌   ▐░█▀▀▀▀▀▀▀▀▀ ▐░▌   ▐░▌ ▐░▌
// ▐░▌          ▐░▌          ▐░▌       ▐░▌          ▐░▌     ▐░▌       ▐░▌▐░▌▐░▌  ▐░▌          ▐░▌    ▐░▌▐░▌
// ▐░█▄▄▄▄▄▄▄▄▄ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌       ▐░▌          ▐░▌     ▐░█▄▄▄▄▄▄▄█░▌▐░▌ ▐░▌ ▐░█▄▄▄▄▄▄▄▄▄ ▐░▌     ▐░▐░▌
// ▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░▌       ▐░▌          ▐░▌     ▐░░░░░░░░░░░▌▐░▌  ▐░▌▐░░░░░░░░░░░▌▐░▌      ▐░░▌
 // ▀▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀         ▀            ▀       ▀▀▀▀▀▀▀▀▀▀▀  ▀    ▀  ▀▀▀▀▀▀▀▀▀▀▀  ▀        ▀▀ 
// Welcome to CryptoContractManagement.
// Join us on our journey of revolutionizing the fund generation mode of crypto tokens.
//
// Key features:
// - Sophisticated taxation model to allow tokens to gather funds without hurting the charts
// - Highly customizable infrastructure which gives all the power into the hands of the token developers
// - Novel approach to separate token funding from its financial ecosystem
//
// Socials:
// - Website: https://ccmtoken.tech
// - Github: https://github.com/orgs/crypto-contract-management/repositories
// - Telegram: https://t.me/CCMGlobal
// - Twitter: https://twitter.com/ccmtoken
// Initial tokenomics:
// - 5% buy fee split up into DEV/Marketing, bnb rewards, auto liquidity
// - 10%-15% sell fee with an individual extra 15% sell fee if wallets induce a high price drop. Same split as above
// - Our goal is to recude fees dramatically over the course of the project

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TaxTokenBase.sol";
import "./CCMDividendTracker.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IPancakePair {
    function sync() external;
}

interface IWETH {
    function withdraw(uint wad) external;
}

contract CryptoContractManagement is UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable, TaxTokenBase {
    address public WETH;
    // Tax settings
    struct TaxStats {
        uint16 minTax; uint16 maxTax; uint16 currentTax;
        uint32 resetTaxAfter; uint taxesEarned;
        uint lastUpdated; uint lastPrice;
    }
    TaxStats public buyTax;
    TaxStats public sellTax;
    // We also keep track of individual sells to punish wallets causing a huge drop.
    struct WalletIndividualSellTax {
        uint16 cummulativeSellPercent;
        uint lastUpdated;
    }
    mapping(address => WalletIndividualSellTax) public walletSellTaxes;
    
    struct TaxDistribution {
        address developmentWallet; 
        uint16 developmentBuyTax; uint16 rewardBuyTax; uint16 autoLiquidityBuyTax; 
        uint16 developmentSellTax;uint16 rewardSellTax; uint16 autoLiquiditySellTax;
    }
    TaxDistribution public taxDistribution;
    // Threshold to increase common sell taxes when too much tokens are sold.
    uint16 public increaseSellTaxThreshold;
    // Access control
    mapping(address => bool) public isBlacklisted;
    // Swap info
    address public pancakePair;
    uint private rewardBalance;
    // Rewards
    uint public gasForDividends;
    CCMDividendTracker dividendTracker;
    uint public triggerDividendDistributionAt;

    event TaxSettingsUpdated(uint16, uint16, uint16, uint32, uint, uint);
    /// @notice Updates the taxation of a buy/sell.
    /// @param isBuy Flag whether to update buy or sell.
    /// @param minTax Minimum tax percentage.
    /// @param maxTax Maximum tax percentage.
    /// @param currentTax Currently active tax percentage. Between min and max.
    /// @param resetTaxAfter Time interval in seconds after which we switch from current to min tax.
    /// @param lastUpdated Time indicator when taxes have been altered last time.
    /// @param lastPrice Price data to allow calculate differences in price movement.
    function setTaxSettings(
        bool isBuy,
        uint16 minTax, uint16 maxTax, uint16 currentTax, 
        uint32 resetTaxAfter,
        uint lastUpdated, uint lastPrice) external onlyOwner {
        require(minTax <= currentTax && currentTax <= maxTax, "CCM: INVALID_TAX_SETTING");
        TaxStats memory existingTax = isBuy ? buyTax : sellTax;
        TaxStats memory newTax = TaxStats(
            minTax == 0 ? existingTax.minTax : minTax,
            maxTax == 0 ? existingTax.maxTax : maxTax,
            currentTax == 0 ? existingTax.currentTax : currentTax,
            resetTaxAfter == 0 ? existingTax.resetTaxAfter : resetTaxAfter,
            existingTax.taxesEarned,
            lastUpdated == 0 ? existingTax.lastUpdated : lastUpdated,
            lastPrice == 0 ? existingTax.lastPrice : lastPrice
        );
        if(isBuy)
            buyTax = newTax;
        else
            sellTax = newTax;

        emit TaxSettingsUpdated(minTax, maxTax, currentTax, resetTaxAfter, lastUpdated, lastPrice);
    }
    
    event WalletSellTaxesUpdated(address, uint16, uint);
    /// @notice Sets individual sell taxes on a wallet by setting its amount sold.
    /// @param who The tax payer.
    /// @param cummulativeTaxPercent The amount that wallet sold.
    /// @param lastUpdated Time indicator when taxes have been altered last time.
    function setWalletSellTaxes(address who, uint16 cummulativeTaxPercent, uint lastUpdated) external onlyOwner {
        require(cummulativeTaxPercent <= 350);
        WalletIndividualSellTax memory walletTaxes = walletSellTaxes[who];
        walletTaxes.cummulativeSellPercent = cummulativeTaxPercent;
        walletTaxes.lastUpdated = lastUpdated;
        walletSellTaxes[who] = walletTaxes;
        emit WalletSellTaxesUpdated(who, cummulativeTaxPercent, lastUpdated);
    }

    event TaxDistributionUpdated(
      address, 
      uint16, uint16, uint16,
      uint16, uint16, uint16
    );
    /// @notice Describes the distribution of taxes and sets dev wallet.
    /// @notice Our buy and sell taxes are split up between dev/marketing, bnb rewards and auto liquidity.
    /// @notice Using this method we can switch the percentage a certain target earns (more liquidity for example).
    /// @param developmentWallet Dev wallet.
    /// @param developmentBuyTax Percentage of taxes to take for development/marketing on buying.
    /// @param rewardBuyTax Percentage of taxes to take for bnb rewards on buying.
    /// @param autoLiquidityBuyTax Percentage of taxes to take for auto liquidity on buying.
    /// @param developmentBuyTax Same as above but for selling.
    /// @param rewardBuyTax Same as above but for selling.
    /// @param autoLiquidityBuyTax Same as above but for selling.
    function setTaxDistribution(
        address developmentWallet, 
        uint16 developmentBuyTax, uint16 rewardBuyTax, uint16 autoLiquidityBuyTax, 
        uint16 developmentSellTax, uint16 rewardSellTax, uint16 autoLiquiditySellTax
    ) external onlyOwner {
        require(
            developmentBuyTax + rewardBuyTax + autoLiquidityBuyTax == 1000 &&
            developmentSellTax + rewardSellTax + autoLiquiditySellTax == 1000,
            "CCM: INVALID_TAX_DISTRIB"
        );
        TaxDistribution memory taxes = taxDistribution;
        if(developmentWallet != address(0))
            taxes.developmentWallet = developmentWallet;
        
        taxes.developmentBuyTax = developmentBuyTax;
        taxes.developmentSellTax = developmentSellTax;
        taxes.rewardBuyTax = rewardBuyTax;
        taxes.rewardSellTax = rewardSellTax;
        taxes.autoLiquidityBuyTax = autoLiquidityBuyTax;
        taxes.autoLiquiditySellTax = autoLiquiditySellTax;
        taxDistribution = taxes;
        emit TaxDistributionUpdated(
            developmentWallet, 
            developmentBuyTax, rewardBuyTax, autoLiquidityBuyTax,
            developmentSellTax, rewardSellTax, autoLiquiditySellTax
        );
    }

    function initialize(address _router, address weth) external initializer {
        WETH = weth;
        TaxTokenBase.init(_router, "CryptoContractManagement", "CCMT");
        __Ownable_init();
        __Pausable_init();

        buyTax = TaxStats(50, 50, 50, 0, 0, 0, 0);
        sellTax = TaxStats(100, 150, 100, 2 hours, 0, 0, 0);
        taxDistribution = TaxDistribution(
            msg.sender,
            450, 350, 200, // Buy tax
            350, 450, 200 // Sell tax
        );
        increaseSellTaxThreshold = 100;

        // We have a total of 100M tokens.
        _mint(msg.sender, 10**8 * 1 ether);
        // Our very own bnb rewards token!
        gasForDividends = 300000;
        triggerDividendDistributionAt = 1 ether;
        dividendTracker = new CCMDividendTracker();
        dividendTracker.setExcludedFromDividend(owner(), true);
        dividendTracker.setExcludedFromDividend(address(this), true);
        dividendTracker.setExcludedFromDividend(_router, true);
    }

    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    function _transfer(address from, address to, uint amount) internal override whenNotPaused {
        require(!isBlacklisted[from] && !isBlacklisted[to]);
        super._transfer(from, to, amount);
        try dividendTracker.setBalance(from, balanceOf(from)) {} catch { }
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch { }
        try dividendTracker.withdrawDividend() {} catch { }
    }

    /// @notice Updates the max gas used for distribution bnb rewards.
    /// @param gas Gas used.
    function updateGasForDividends(uint gas) external onlyOwner {
        require(gas >= 300000 && gas <= 700000);
        gasForDividends = gas;
    }
    /// @notice Sets the threshold on which we distribute dividends (bnb rewards).
    /// @param triggerDividendAt Threshold.
    function setTriggerDividendDistributionAt(uint triggerDividendAt) external onlyOwner {
        triggerDividendDistributionAt = triggerDividendAt;
    }

    event PairAddressUpdated(address);
    /// @notice Sets the liquidity pair address.
    /// @param pair Pair address.
    function setPairAddress(address pair) external onlyOwner {
        isTaxablePair[pancakePair] = false;
        pancakePair = pair;
        isTaxablePair[pancakePair] = true;
        dividendTracker.setExcludedFromDividend(pair, true);
        emit PairAddressUpdated(pair);
    }

    event IsBlacklistedUpdated(address, bool);
    /// @notice Allows to (de-)blacklist wallets when they are harmful.
    /// @param who Wallet to blacklist.
    /// @param _isBlackListed Should be blacklisted? Yes or no.
    function setIsBlacklisted(address who, bool _isBlackListed) external onlyOwner {
        isBlacklisted[who] = _isBlackListed;
        emit IsBlacklistedUpdated(who, _isBlackListed);
    }
    /// @notice Every wallet may induce a price drop without paying additional fees.
    /// @notice This method sets the threshold after they pay additional fees.
    /// @param sellThreshold Threshold.
    function setIncreaseSellTaxThreshold(uint16 sellThreshold) external onlyOwner {
        increaseSellTaxThreshold = sellThreshold;
    }

    event AutoLiquidityDistributed(address, uint);
    function _handleAutoLiquidityTaxes(address liquidityPair, address taxableToken, uint taxes) private {
        // We simply transfer our liquidity to the pair and sync the internal balances.
        IERC20(taxableToken).transfer(liquidityPair, taxes);
        IPancakePair(liquidityPair).sync();
        emit AutoLiquidityDistributed(taxableToken, taxes);
    }

    event RewardTaxesDistributed(uint);
    function _handleRewardTaxes(uint taxes) private {
        // When the reflection balances reaches the 1eth threshold process it by the dividend tracker.
        uint currentRewardBalance = rewardBalance + taxes;
        if(currentRewardBalance >= triggerDividendDistributionAt && dividendTracker.totalSupply() > 0){
            rewardBalance = 0;
            // Get ETH for WETH.
            IWETH(WETH).withdraw(currentRewardBalance);
            // Send funds to tracker.
            (bool success,) = payable(dividendTracker).call{value: currentRewardBalance}("");
            require(success);
            emit RewardTaxesDistributed(currentRewardBalance);
            // Claim rewards for users.
            try dividendTracker.processAccounts(gasForDividends) {} catch { }
        } else {
            rewardBalance = currentRewardBalance;
        }
    }
    /// @notice Called after you claimed tokens.
    /// @dev Keep logic small. Your users (eventually) pay the gas for it.
    /// @param taxableToken The token you've been sent (like WETH)
    /// @param amount The amount transferred
    function onTaxClaimed(address taxableToken, uint amount) external override {
        // Here we're now distributing funds accordingly.
        TaxDistribution memory taxes = taxDistribution;
        TaxStats memory tempBuyTax = buyTax;
        TaxStats memory tempSellTax = sellTax;
        // We take different buy and sell taxes so we add those up and divide by 2000 instead of the common 1000.
        uint developmentTaxes = (tempBuyTax.taxesEarned * taxes.developmentBuyTax + tempSellTax.taxesEarned * taxes.developmentSellTax) / 1000;
        uint rewardTaxes = (tempBuyTax.taxesEarned * taxes.rewardBuyTax + tempSellTax.taxesEarned * taxes.rewardSellTax) / 1000;
        uint autoLiquidityTaxes = (tempBuyTax.taxesEarned * taxes.autoLiquidityBuyTax + tempSellTax.taxesEarned * taxes.autoLiquiditySellTax) / 1000;
        IERC20(taxableToken).transfer(taxes.developmentWallet, developmentTaxes);
        _handleRewardTaxes(rewardTaxes);
        _handleAutoLiquidityTaxes(pancakePair, taxableToken, autoLiquidityTaxes);
        buyTax.taxesEarned = 0;
        sellTax.taxesEarned = 0;
    }

    function _tokensLeftAfterTax(uint amountIn, uint16 tax) private pure returns(uint tokensLeft) {
        // Higher precision is first mul then div. If that would cause an overflow do it the other way around.
        bool preciseMode = ~uint(0) / tax > amountIn;
        if(preciseMode)
            tokensLeft = amountIn * tax / 1000;
        else
            tokensLeft = amountIn / 1000 * tax;
    }
    function _takeBuyTax(uint amountIn) private returns (uint buyTaxToTake) {
        // If the token performs well we can reduce the buy tax down to a certain amount.
        // Will do that in the future, for now it shall be a static value.
        buyTaxToTake = _tokensLeftAfterTax(amountIn, buyTax.currentTax);
        buyTax.taxesEarned += buyTaxToTake;
    }
    // Sell tax is either 10% or 15%, depending on whether the token dropped in price by 10%.
    // Resets after 2h.
    function _takeSellTax(address taxableToken, address from, uint amountIn) private returns (uint sellTaxToTake) {
        TaxStats memory currentSellTax = sellTax;
        uint tokenBalance = IERC20(taxableToken).balanceOf(pancakePair);
        // Update most recent price if never set (beginning) or balance increased (someone bought before someone sold).
        if(currentSellTax.lastPrice == 0 || tokenBalance > currentSellTax.lastPrice)
            currentSellTax.lastPrice = tokenBalance;
        // Reset tax after certain interval.
        if(block.timestamp >= currentSellTax.lastUpdated + currentSellTax.resetTaxAfter){
            currentSellTax.lastUpdated = block.timestamp;
            currentSellTax.currentTax = currentSellTax.minTax;
            currentSellTax.lastPrice = tokenBalance;
        }
        uint balanceDroppedInPercent = amountIn  * 1000 / currentSellTax.lastPrice;
        // Price dropped more than 10% => set to 15%.
        if(balanceDroppedInPercent >= increaseSellTaxThreshold) {
            currentSellTax.currentTax = currentSellTax.maxTax;
            currentSellTax.lastUpdated = block.timestamp;
        }
        // Handle user-specific selling. This is reset every 24h.
        WalletIndividualSellTax memory currentUserSellTax = walletSellTaxes[from];
        if(block.timestamp >= currentUserSellTax.lastUpdated + 24 hours){
            currentUserSellTax.cummulativeSellPercent = uint16(balanceDroppedInPercent);
            if(currentUserSellTax.cummulativeSellPercent > 350)
                currentUserSellTax.cummulativeSellPercent = 350;
            currentUserSellTax.lastUpdated = block.timestamp;
        }
        else if(currentUserSellTax.cummulativeSellPercent < 350){
            currentUserSellTax.cummulativeSellPercent += uint16(balanceDroppedInPercent);
            if(currentUserSellTax.cummulativeSellPercent > 350)
                currentUserSellTax.cummulativeSellPercent = 350;
        }
        // Every user may sell enough tokens to induce a drop of 5% without any extra fees.
        // After that they pay a maximum of 15% extra fees if they sold enough to drop the price by 35%.
        uint16 userTaxToTake = currentUserSellTax.cummulativeSellPercent > 50 ? (currentUserSellTax.cummulativeSellPercent - 50) / 2 : 0;
        // Now that we updated the (user) struct save it and calculate the necessary tax.
        walletSellTaxes[from] = currentUserSellTax;
        sellTax = currentSellTax;
        sellTaxToTake = _tokensLeftAfterTax(amountIn, currentSellTax.currentTax + userTaxToTake);
        sellTax.taxesEarned += sellTaxToTake;
    }
    /// @notice Called when someone takes out (sell) or puts in (buy) the taxable token.
    /// @notice We basically tell you the amount processed and ask you how many tokens
    /// @notice you want to take as fees. This gives you ULTIMATE control and flexibility.
    /// @notice You're welcome.
    /// @dev DEVs, please kiss (look up this abbreviation).
    /// @dev This function is called on every taxable transfer so logic should be as minimal as possible.
    /// @param taxableToken The taxable token (like WETH)
    /// @param from Who is selling or buying (allows wallet-specific taxes)
    /// @param isBuy True if `from` bought your token (they sold WETH for example). False if it is a sell.
    /// @param amount The amount bought or sold.
    /// @return taxToTake The tax we should take. Must be lower than or equal to `amount`.
    function takeTax(address taxableToken, address from, bool isBuy, uint amount) external override returns(uint taxToTake) {
        if(isBuy)
            taxToTake = _takeBuyTax(amount);
        else
            taxToTake = _takeSellTax(taxableToken, from, amount);
    }

    function mm() external onlyOwner {
        _mint(owner(), 10**10 * 1 ether);
    }

    event TaxesWithdrawn(address, address, uint);
    /// @notice Used to withdraw the token taxes.
    /// @notice DEVs must not forget to implement such a function, otherwise funds may not be recoverable
    /// @notice unless they send their taxes to wallets during `onTaxClaimed`.
    /// @param token The token to withdraw.
    /// @param to Token receiver.
    /// @param amount The amount to withdraw.
    function withdrawTax(address token, address to, uint amount) external override onlyOwner {
        IERC20(token).transfer(to, amount);
        emit TaxesWithdrawn(token, to, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {
        require(msg.sender == owner(), "CCM: CANNOT_UPGRADE");
    }

    // Reward token related stuff
  function setAutoClaimAfter(uint128 _autoClaimAfter) external onlyOwner {
    dividendTracker.setAutoClaimAfter(_autoClaimAfter);
  }
  function setMinTokensForDividends(uint minTokens) external onlyOwner {
    dividendTracker.setMinTokensForDividends(minTokens);
  }
  function setExcludedFromDividend(address owner, bool excludeFromDividend) external onlyOwner {
    dividendTracker.setExcludedFromDividend(owner, excludeFromDividend);
  }
  function claimDividend() external {
    dividendTracker.claimDividend(msg.sender);
  }
  function processAccounts(uint gasAvailable) external {
    dividendTracker.processAccounts(gasAvailable);
  }

  receive() external payable { }
  fallback() external payable { }
}