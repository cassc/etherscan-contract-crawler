//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Libraries.sol";
import "./Interfaces.sol";
import "./BaseErc20.sol";

interface IPinkAntiBot {
  function setTokenOwner(address owner) external;
  function onPreTransferCheck(address from, address to, uint256 amount) external;
}

abstract contract AntiSniper is BaseErc20 {
    
    IPinkAntiBot public pinkAntiBot;
    bool private pinkAntiBotConfigured;

    bool public enableSniperBlocking;
    bool public enableBlockLogProtection;
    bool public enableHighTaxCountdown;
    bool public enablePinkAntiBot;
    
    uint256 public msPercentage;
    uint256 public mhPercentage;
    uint256 public maxGasLimit;

    uint256 public launchTime;
    uint256 public launchBlock;
    uint256 public snipersCaught;
    
    mapping (address => bool) public isSniper;
    mapping (address => bool) public isNeverSniper;
    mapping (address => uint256) public transactionBlockLog;
    
    // Overrides
    
    function configure(address _owner) internal virtual override {
        isNeverSniper[_owner] = true;
        super.configure(_owner);
    }
    
    function launch() override virtual public onlyOwner {
        super.launch();
        launchTime = block.timestamp;
        launchBlock = block.number;
    }
    
    function preTransfer(address from, address to, uint256 value) override virtual internal {
        require(enableSniperBlocking == false || isSniper[msg.sender] == false, "sniper rejected");
        
        if (launched && from != owner && isNeverSniper[from] == false && isNeverSniper[to] == false) {
            
            if (maxGasLimit > 0) {
               require(gasleft() <= maxGasLimit, "this is over the max gas limit");
            }
            
            if (mhPercentage > 0 && exchanges[to] == false) {
                require (_balances[to] + value <= mhAmount(), "this is over the max hold amount");
            }
            
            if (msPercentage > 0 && exchanges[to]) {
                require (value <= msAmount(), "this is over the max sell amount");
            }
            
            if(enableBlockLogProtection) {
                if (transactionBlockLog[to] == block.number) {
                    isSniper[to] = true;
                    snipersCaught ++;
                }
                if (transactionBlockLog[from] == block.number) {
                    isSniper[from] = true;
                    snipersCaught ++;
                }
                if (exchanges[to] == false) {
                    transactionBlockLog[to] = block.number;
                }
                if (exchanges[from] == false) {
                    transactionBlockLog[from] = block.number;
                }
            }
            
            if (enablePinkAntiBot) {
                pinkAntiBot.onPreTransferCheck(from, to, value);
            }
        }
        
        super.preTransfer(from, to, value);
    }
    
    function calculateTransferAmount(address from, address to, uint256 value) internal virtual override returns (uint256) {
        uint256 amountAfterTax = value;
        if (launched && enableHighTaxCountdown) {
            if (from != owner && sniperTax() > 0 && isNeverSniper[from] == false && isNeverSniper[to] == false) {
                uint256 taxAmount = (value * sniperTax()) / 10000;
                amountAfterTax = amountAfterTax - taxAmount;
            }
        }
        return super.calculateTransferAmount(from, to, amountAfterTax);
    }
    
    // Public methods
    
    function mhAmount() public view returns (uint256) {
        return (_totalSupply * mhPercentage) / 10000;
    }
    
    function msAmount() public view returns (uint256) {
         return (_totalSupply * msPercentage) / 10000;
    }
    
   function sniperTax() public virtual view returns (uint256) {
        if(launched) {
            if (block.number - launchBlock < 3) {
                return 9900;
            }
        }
        return 0;
    }
    
    // Admin methods
    
    function configurePinkAntiBot(address antiBot) external onlyOwner {
        pinkAntiBot = IPinkAntiBot(antiBot);
        pinkAntiBot.setTokenOwner(owner);
        pinkAntiBotConfigured = true;
        enablePinkAntiBot = true;
    }
    
    function setSniperBlocking(bool enabled) external onlyOwner {
        enableSniperBlocking = enabled;
    }
    
    function setBlockLogProtection(bool enabled) external onlyOwner {
        enableBlockLogProtection = enabled;
    }
    
    function setHighTaxCountdown(bool enabled) external onlyOwner {
        enableHighTaxCountdown = enabled;
    }
    
    function setPinkAntiBot(bool enabled) external onlyOwner {
        require(pinkAntiBotConfigured, "pink anti bot is not configured");
        enablePinkAntiBot = enabled;
    }
    
    function setMsPercentage(uint256 amount) external onlyOwner {
        msPercentage = amount;
    }
    
    function setMhPercentage(uint256 amount) external onlyOwner {
        mhPercentage = amount;
    }
    
    function setMaxGasLimit(uint256 amount) external onlyOwner {
        maxGasLimit = amount;
    }
    
    function setIsSniper(address who, bool enabled) external onlyOwner {
        isSniper[who] = enabled;
    }

    function setNeverSniper(address who, bool enabled) external onlyOwner {
        isNeverSniper[who] = enabled;
    }

    // private methods
}