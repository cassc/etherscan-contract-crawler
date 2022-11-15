// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TEST is ERC20, Ownable, Pausable {
    // CONFIG START

    uint256 denominator = 100;
    
    // TOKEN
    string tokenName = "Test";
    string tokenSymbol = "TEST";
    uint256 tokenTotalSupply = 1_000_000_000 * (10**18);
    
    // ADRESSES
    address marketingWallet = 0x39c15a761FFa69ba1204232996d9007CD8Dd26D5;
    address communityWallet = 0x521f2115Eb20c8Cd2297AFAFC6627808E8Ba83Bf;
    address router02 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    // BUY TAX
    uint256 public marketingTaxBuy = 3;
    uint256 public communityTaxBuy = 6;

    // SELL TAX
    uint256 public marketingTaxSell = 5;
    uint256 public communityTaxSell = 10;

    uint256 public maxTxAmount = 2_500_000 * 10**18 + 1;
    uint256 public maxWalletAmount = 2_500_000 * 10**18 + 1;

    
    // CONFIG END
    
    IUniswapV2Router02 private _UniswapV2Router02;
    IUniswapV2Factory private _UniswapV2Factory;
    IUniswapV2Pair private _UniswapV2Pair;
    
    mapping (address => uint256) private nextBuyBlock;
    
    mapping (address => bool) public isExcluded;
    bool public botProtectionStatus;
    mapping (address => bool) public isExcludedFromBotProtection;

    // Whitelist
    bool public whitelistStatus;
    mapping (address => bool) public isWhitelisted;

    // Blacklist
    bool public blacklistStatus;
    mapping (address => bool) public isBlacklisted;
    
    uint256 private feeTokens;
    uint256 private marketingTokens;
    uint256 private communityTokens;

    bool public taxStatus;
    
    using Address for address;

    uint256 totalHolded;

    event LogNum(string, uint256);
    event LogBool(string, bool);
    event LogAddress(string, address);
    event LogString(string, string);
    event LogBytes(string, bytes);
    
    constructor() ERC20(tokenName, tokenSymbol) {
        _UniswapV2Router02 = IUniswapV2Router02(router02);
        _UniswapV2Factory = IUniswapV2Factory(_UniswapV2Router02.factory());
        _UniswapV2Pair = IUniswapV2Pair(_UniswapV2Factory.createPair(address(this), _UniswapV2Router02.WETH()));
        
        isExcluded[msg.sender] = true;
        isExcluded[marketingWallet] = true;
        isExcluded[address(this)] = true;

        isExcludedFromBotProtection[address(_UniswapV2Pair)] = true;

        taxStatus = true;
        
        _mint(msg.sender, tokenTotalSupply);
    }

    bool inTax;
    
    function handleFees(address sender, address recipient, uint256 amount) internal returns (uint256 fee) {
        bool isBuy = sender == address(_UniswapV2Pair);
        bool isSell = recipient == address(_UniswapV2Pair);

        uint256 fees;
        uint256 taxSum;

        uint256 marketingAmount;
        uint256 communityAmount;

        if(isBuy) {
            fees = amount * 10**18 / denominator * (marketingTaxBuy + communityTaxBuy) / 10**18;

            taxSum = marketingTaxBuy + communityTaxBuy;

            if(taxSum > 0) {
                marketingAmount = fees * 10**18 / taxSum * marketingTaxBuy / 10**18;
                communityAmount = fees * 10**18 / taxSum * communityTaxBuy / 10**18;
            }

            feeTokens += fees;

            marketingTokens += marketingAmount;
            communityTokens += communityAmount;

            super._transfer(sender, address(this), fees);
        } else if(isSell) {
            fees = amount * 10**18 / denominator * (marketingTaxSell + communityTaxSell) / 10**18;

            taxSum = marketingTaxSell + communityTaxSell;
            
            if(taxSum > 0) {
                marketingAmount = fees * 10**18 / taxSum * marketingTaxSell / 10**18;
                communityAmount = fees * 10**18 / taxSum * communityTaxSell / 10**18;
            }

            feeTokens += fees;

            marketingTokens += marketingAmount;
            communityTokens += communityAmount;

            super._transfer(sender, address(this), fees);

            if(feeTokens > 0) {
                address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = _UniswapV2Router02.WETH();
                
                uint256 startBalance = address(this).balance;
                
                _approve(address(this), address(_UniswapV2Router02), feeTokens);

                inTax = true;
                
                _UniswapV2Router02.swapExactTokensForETH(
                    feeTokens,
                    0,
                    path,
                    address(this),
                    block.timestamp
                );
                
                uint256 ethGained = address(this).balance - startBalance;
                
                Address.sendValue(payable(marketingWallet), marketingTokens * 10**18 / feeTokens * ethGained / 10**18);
                Address.sendValue(payable(communityWallet), communityTokens * 10**18 / feeTokens * ethGained / 10**18);

                inTax = false;

                feeTokens = 0;
                marketingTokens = 0;
                communityTokens = 0;
            }
        }

        return fees;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override virtual {
        if(isExcluded[msg.sender] || isExcluded[tx.origin] || inTax) {
            super._transfer(sender, recipient, amount);
        } else {
            if(!isExcluded[sender] && !isExcluded[recipient]) {
                require(!paused(), "TEST: Transfers paused");
                require(!blacklistStatus || (!isBlacklisted[sender] && !isBlacklisted[recipient]), "TEST: Blacklisted");
                require(!whitelistStatus || (isWhitelisted[sender] && isWhitelisted[recipient]), "TEST: Not Whitelisted");

                if(sender == address(_UniswapV2Pair) || recipient == address(_UniswapV2Pair)) {
                    if(sender == address(_UniswapV2Pair)) {
                        require(amount <= maxTxAmount, "TEST: Max tx amount");
                        require(sender != address(_UniswapV2Pair) || (sender == address(_UniswapV2Pair) && block.number >= nextBuyBlock[recipient]), "TEST: Cooldown");

                        nextBuyBlock[recipient] = block.number + 1;
                    }

                    if(taxStatus) {
                        uint256 fees = handleFees(sender, recipient, amount);
                        amount -= fees;   
                    }

                    require(isExcludedFromBotProtection[recipient] || balanceOf(recipient) + amount <= maxWalletAmount, "TEST: Max wallet amount");                
                }
            }

            if(botProtectionStatus) {
                if(sender == address(_UniswapV2Pair) && !isExcludedFromBotProtection[recipient]) {
                    require(!recipient.isContract(), "TEST: Bot Protection");
                } else if(recipient == address(_UniswapV2Pair) && !isExcludedFromBotProtection[sender]) {
                    require(!sender.isContract(), "TEST: Bot Protection");
                }
            }

            super._transfer(sender, recipient, amount);
        }
    }

    /**
     * General settings
     */

    function setDenominator(uint256 newValue) external onlyOwner {
        require(newValue != denominator, "TEST: Value already set to that option");

        denominator = newValue;
    }

    function setMaxTxAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxTxAmount, "TEST: Value already set to that option");

        maxTxAmount = newValue;
    }

    function setMaxWalletAmount(uint256 newValue) external onlyOwner {
        require(newValue != maxWalletAmount, "TEST: Value already set to that option");

        maxWalletAmount = newValue;
    }



    /**
     * Exclude
     */

    function setExcluded(address account, bool newValue) external onlyOwner {
        require(newValue != isExcluded[account], "TEST: Value already set to that option");

        isExcluded[account] = newValue;
    }

    function setBotProtectionStatus(bool newValue) external onlyOwner {
        require(newValue != botProtectionStatus, "TEST: Value already set to that option");

        botProtectionStatus = newValue;
    }

    function setExcludedFromBotProtection(address account, bool newValue) external onlyOwner {
        require(newValue != isExcludedFromBotProtection[account], "TEST: Value already set to that option");

        isExcludedFromBotProtection[account] = newValue;
    }

    function massSetExcluded(address[] memory accounts, bool newValue) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcluded[accounts[i]], "TEST: Value already set to that option");

            isExcluded[accounts[i]] = newValue;
        }
    }

    function massSetExcludedFromBotProtection(address[] memory accounts, bool newValue) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isExcludedFromBotProtection[accounts[i]], "TEST: Value already set to that option");

            isExcludedFromBotProtection[accounts[i]] = newValue;
        }
    }



    /**
     * Blacklist & whitelist
     */

    function setBlacklistStatus(bool newValue) external onlyOwner {
        require(blacklistStatus != newValue, "TEST: Value already set to that option");

        blacklistStatus = newValue;
    }

    function setWhitelistStatus(bool newValue) external onlyOwner {
        require(whitelistStatus != newValue, "TEST: Value already set to that option");

        whitelistStatus = newValue;
    }

    function setBlacklisted(address account, bool newValue) external onlyOwner {
        require(newValue != isBlacklisted[account], "TEST: Value already set to that option");

        isBlacklisted[account] = newValue;
    }

    function setWhitelisted(address account, bool newValue) external onlyOwner {
        require(newValue != isWhitelisted[account], "TEST: Value already set to that option");

        isWhitelisted[account] = newValue;
    }

    function massSetBlacklisted(address[] memory accounts, bool newValue) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isBlacklisted[accounts[i]], "TEST: Value already set to that option");

            isBlacklisted[accounts[i]] = newValue;
        }
    }

    function massSetWhitelisted(address[] memory accounts, bool newValue) external onlyOwner {
        for(uint256 i; i < accounts.length; i++) {
            require(newValue != isWhitelisted[accounts[i]], "TEST: Value already set to that option");

            isWhitelisted[accounts[i]] = newValue;
        }
    }



    /**
     * Taxes
     */

    function setTaxesBuy(uint256 marketing, uint256 community) external onlyOwner {
        marketingTaxBuy = marketing;
        communityTaxBuy = community;
    }

    function setTaxesSell(uint256 marketing, uint256 community) external onlyOwner {
        marketingTaxSell = marketing;
        communityTaxSell = community;
    }

    function setTaxStatus(bool newValue) external onlyOwner {
        require(taxStatus != newValue, "TEST: Value already set to that option");

        taxStatus = newValue;
    }

    function withdrawETH(address to, uint256 value) external onlyOwner {
        require(address(this).balance >= value, "TEST: Insufficient ETH balance");

        (bool success,) = to.call{value: value}("");
        require(success, "TEST: Transfer failed");
    }
    
    receive() external payable {}
}