//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract MWX is ERC20, Ownable, Pausable {

    // CONFIG START
    
    uint256 private initialSupply;
   
    uint256 private denominator = 100;

    uint256 private swapThreshold = 0.0000005 ether; // The contract will only swap to ETH, once the fee tokens reach the specified threshold
    
    uint256 private devTaxBuy;
    uint256 private marketingTaxBuy;
    uint256 private liquidityTaxBuy;
    uint256 private charityTaxBuy;
    
    uint256 private devTaxSell;
    uint256 private marketingTaxSell;
    uint256 private liquidityTaxSell;
    uint256 private charityTaxSell;
    
    address private devTaxWallet;
    address private marketingTaxWallet;
    address private liquidityTaxWallet;
    address private charityTaxWallet;
    
    // CONFIG END
    
    mapping (address => bool) private blacklist;
    mapping (address => bool) private excludeList;
    
    mapping (string => uint256) private buyTaxes;
    mapping (string => uint256) private sellTaxes;
    mapping (string => address) private taxWallets;
    
    bool public taxStatus = true;
    
    IUniswapV2Router02 private uniswapV2Router02;
    IUniswapV2Factory private uniswapV2Factory;
    IUniswapV2Pair private uniswapV2Pair;
    
    constructor(string memory _tokenName,string memory _tokenSymbol,uint256 _supply,address[6] memory _addr,uint256[8] memory _value) ERC20(_tokenName, _tokenSymbol) payable
    {
        initialSupply =_supply * (10**18);
        transferOwnership(_addr[5]);
        uniswapV2Router02 = IUniswapV2Router02(_addr[1]);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router02.factory());
        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(this), uniswapV2Router02.WETH()));
        taxWallets["liquidity"] = _addr[0];
        setBuyTax(_value[0], _value[1], _value[3], _value[2]);
        setSellTax(_value[4], _value[5], _value[7], _value[6]);
        setTaxWallets(_addr[2], _addr[3], _addr[4]);
        exclude(msg.sender);
        exclude(address(this));
        payable(_addr[0]).transfer(msg.value);
        _mint(msg.sender, initialSupply);
    }
    
    uint256 private marketingTokens;
    uint256 private devTokens;
    uint256 private liquidityTokens;
    uint256 private charityTokens;
    
    /**
     * @dev Calculates the tax, transfer it to the contract. If the user is selling, and the swap threshold is met, it executes the tax.
     */
    function handleTax(address from, address to, uint256 amount) private returns (uint256) {
        address[] memory sellPath = new address[](2);
        sellPath[0] = address(this);
        sellPath[1] = uniswapV2Router02.WETH();
        
        if(!isExcluded(from) && !isExcluded(to)) {
            uint256 tax;
            uint256 baseUnit = amount / denominator;
            if(from == address(uniswapV2Pair)) {
                tax += baseUnit * buyTaxes["marketing"];
                tax += baseUnit * buyTaxes["dev"];
                tax += baseUnit * buyTaxes["liquidity"];
                tax += baseUnit * buyTaxes["charity"];
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                marketingTokens += baseUnit * buyTaxes["marketing"];
                devTokens += baseUnit * buyTaxes["dev"];
                liquidityTokens += baseUnit * buyTaxes["liquidity"];
                charityTokens += baseUnit * buyTaxes["charity"];
            } else if(to == address(uniswapV2Pair)) {
                tax += baseUnit * sellTaxes["marketing"];
                tax += baseUnit * sellTaxes["dev"];
                tax += baseUnit * sellTaxes["liquidity"];
                tax += baseUnit * sellTaxes["charity"];
                
                if(tax > 0) {
                    _transfer(from, address(this), tax);   
                }
                
                marketingTokens += baseUnit * sellTaxes["marketing"];
                devTokens += baseUnit * sellTaxes["dev"];
                liquidityTokens += baseUnit * sellTaxes["liquidity"];
                charityTokens += baseUnit * sellTaxes["charity"];
                
                uint256 taxSum = marketingTokens + devTokens + liquidityTokens + charityTokens;
                
                if(taxSum == 0) return amount;
                
                uint256 ethValue = uniswapV2Router02.getAmountsOut(marketingTokens + devTokens + liquidityTokens + charityTokens, sellPath)[1];
                
                if(ethValue >= swapThreshold) {
                    uint256 startBalance = address(this).balance;

                    uint256 toSell = marketingTokens + devTokens + liquidityTokens / 2 + charityTokens;
                    
                    _approve(address(this), address(uniswapV2Router02), toSell);
            
                    uniswapV2Router02.swapExactTokensForETH(
                        toSell,
                        0,
                        sellPath,
                        address(this),
                        block.timestamp
                    );
                    
                    uint256 ethGained = address(this).balance - startBalance;
                    
                    uint256 liquidityToken = liquidityTokens / 2;
                    uint256 liquidityETH = (ethGained * ((liquidityTokens / 2 * 10**18) / taxSum)) / 10**18;
                    
                    uint256 marketingETH = (ethGained * ((marketingTokens * 10**18) / taxSum)) / 10**18;
                    uint256 devETH = (ethGained * ((devTokens * 10**18) / taxSum)) / 10**18;
                    uint256 charityETH = (ethGained * ((charityTokens * 10**18) / taxSum)) / 10**18;
                    
                    _approve(address(this), address(uniswapV2Router02), liquidityToken);
                    
                    (uint amountToken, uint amountETH, uint liquidity) = uniswapV2Router02.addLiquidityETH{value: liquidityETH}(
                        address(this),
                        liquidityToken,
                        0,
                        0,
                        taxWallets["liquidity"],
                        block.timestamp
                    );
                    
                    uint256 remainingTokens = (marketingTokens + devTokens + liquidityTokens + charityTokens) - (toSell + amountToken);
                    
                    if(remainingTokens > 0) {
                        _transfer(address(this), taxWallets["dev"], remainingTokens);
                    }
                    
                    (bool successMarketing,) = taxWallets["marketing"].call{value: marketingETH}("");
                    require(successMarketing, "Marketing call failed");
                    (bool successDev,) = taxWallets["dev"].call{value: devETH}("");
                    require(successDev, "dev call failed");
                    (bool successCharity,) = taxWallets["charity"].call{value: charityETH}("");
                    require(successCharity, "charity call failed");
                    if(ethGained - (marketingETH + devETH + liquidityETH + charityETH) > 0) {
                        (bool successMarket,) = taxWallets["marketing"].call{value: ethGained - (marketingETH + devETH + liquidityETH + charityETH)}("");
                        require(successMarket, "Marketing call failed");
                    }
                    
                    marketingTokens = 0;
                    devTokens = 0;
                    liquidityTokens = 0;
                    charityTokens = 0;
                }
                
            }
            
            amount -= tax;
        }
        
        return amount;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override virtual {
        require(!paused(), "MWX: token transfer while paused");
        require(!isBlacklisted(msg.sender), "MWX: sender blacklisted");
        require(!isBlacklisted(recipient), "MWX: recipient blacklisted");
        require(!isBlacklisted(tx.origin), "MWX: sender blacklisted");
        
        if(taxStatus) {
            amount = handleTax(sender, recipient, amount);   
        }
        
        super._transfer(sender, recipient, amount);
    }
    
    /**
     * @dev Triggers the tax handling functionality
     */
    function triggerTax() public onlyOwner {
        handleTax(address(0), address(uniswapV2Pair), 0);
    }
    
    /**
     * @dev Pauses transfers on the token.
     */
    function pause() public onlyOwner {
        require(!paused(), "MWX: Contract is already paused");
        _pause();
    }

    /**
     * @dev Unpauses transfers on the token.
     */
    function unpause() public onlyOwner {
        require(paused(), "MWX: Contract is not paused");
        _unpause();
    }
    
    /**
     * @dev Burns tokens from caller address.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
    
    /**
     * @dev Blacklists the specified account (Disables transfers to and from the account).
     */
    function enableBlacklist(address account) public onlyOwner {
        require(!blacklist[account], "MWX: Account is already blacklisted");
        blacklist[account] = true;
    }
    
    /**
     * @dev Remove the specified account from the blacklist.
     */
    function disableBlacklist(address account) public onlyOwner {
        require(blacklist[account], "MWX: Account is not blacklisted");
        blacklist[account] = false;
    }
    
    /**
     * @dev Excludes the specified account from tax.
     */
    function exclude(address account) public onlyOwner {
        require(!isExcluded(account), "MWX: Account is already excluded");
        excludeList[account] = true;
    }
    
    /**
     * @dev Re-enables tax on the specified account.
     */
    function removeExclude(address account) public onlyOwner {
        require(isExcluded(account), "MWX: Account is not excluded");
        excludeList[account] = false;
    }
    
    /**
     * @dev Sets tax for buys.
     */
    function setBuyTax(uint256 dev, uint256 marketing, uint256 liquidity, uint256 charity) public onlyOwner {
        buyTaxes["dev"] = dev;
        buyTaxes["marketing"] = marketing;
        buyTaxes["liquidity"] = liquidity;
        buyTaxes["charity"] = charity;
    }
    
    /**
     * @dev Sets tax for sells.
     */
    function setSellTax(uint256 dev, uint256 marketing, uint256 liquidity, uint256 charity) public onlyOwner {

        sellTaxes["dev"] = dev;
        sellTaxes["marketing"] = marketing;
        sellTaxes["liquidity"] = liquidity;
        sellTaxes["charity"] = charity;
    }
    
    /**
     * @dev Sets wallets for taxes.
     */
    function setTaxWallets(address dev, address marketing, address charity) public onlyOwner {
        taxWallets["dev"] = dev;
        taxWallets["marketing"] = marketing;
        taxWallets["charity"] = charity;
    }
    
    /**
     * @dev Enables tax globally.
     */
    function enableTax() public onlyOwner {
        require(!taxStatus, "MWX: Tax is already enabled");
        taxStatus = true;
    }
    
    /**
     * @dev Disables tax globally.
     */
    function disableTax() public onlyOwner {
        require(taxStatus, "MWX: Tax is already disabled");
        taxStatus = false;
    }
    
    /**
     * @dev Returns true if the account is blacklisted, and false otherwise.
     */
    function isBlacklisted(address account) public view returns (bool) {
        return blacklist[account];
    }
    
    /**
     * @dev Returns true if the account is excluded, and false otherwise.
     */
    function isExcluded(address account) public view returns (bool) {
        return excludeList[account];
    }
    
    receive() external payable {}
}