//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Libraries.sol";
import "./Interfaces.sol";
import "./BaseErc20.sol";

interface IPinkAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}

abstract contract AntiSniper is BaseErc20 {
    IPinkAntiBot public pinkAntiBot;

    bool public enableSniperBlocking;
    bool public enableBlockLogProtection;
    bool public enableHighTaxCountdown;
    bool public enablePinkAntiBot;

    uint256 public msPercentage;
    uint256 public mhPercentage;

    uint256 public launchTime;
    uint256 public launchBlock;
    uint256 public snipersCaught;

    mapping(address => bool) public isSniper;
    mapping(address => bool) public isNeverSniper;
    mapping(address => uint256) public transactionBlockLog;

    // Overrides

    function configure(address _owner) internal virtual override {
        isNeverSniper[_owner] = true;
        // BSC address from https://github.com/pinkmoonfinance/pink-antibot-guide
        pinkAntiBot = IPinkAntiBot(0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002);
        super.configure(_owner);
    }

    function launch() public virtual override onlyOwner {
        super.launch();
        launchTime = block.timestamp;
        launchBlock = block.number;
    }

    function preTransfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        require(
            enableSniperBlocking == false || isSniper[msg.sender] == false,
            "sniper rejected"
        );

        if (
            launched &&
            from != owner &&
            isNeverSniper[from] == false &&
            isNeverSniper[to] == false
        ) {
            if (mhPercentage > 0 && exchanges[to] == false) {
                require(
                    _balances[to] + value <= mhAmount(),
                    "this is over the max hold amount"
                );
            }

            if (msPercentage > 0 && exchanges[to]) {
                require(
                    value <= msAmount(),
                    "this is over the max sell amount"
                );
            }

            if (enableBlockLogProtection) {
                require(
                    !(transactionBlockLog[from] >= block.number - 2 &&
                        exchanges[to]),
                    "potential frontrun attack"
                );
                require(
                    !(transactionBlockLog[to] >= block.number - 2 &&
                        exchanges[from]),
                    "potential frontrun attack"
                );

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

    function calculateTransferAmount(
        address from,
        address to,
        uint256 value
    ) internal virtual override returns (uint256) {
        uint256 amountAfterTax = value;
        if (launched && enableHighTaxCountdown) {
            if (
                from != owner &&
                sniperTax() > 0 &&
                isNeverSniper[from] == false &&
                isNeverSniper[to] == false
            ) {
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

    function sniperTax() public view virtual returns (uint256) {
        if (launched) {
            if (block.number - launchBlock < 3) {
                return 9900;
            }
        }
        return 0;
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
        enablePinkAntiBot = enabled;
        if (enabled) {
            pinkAntiBot.setTokenOwner(owner);
        }
    }

    function setMsPercentage(uint256 amount) external onlyOwner {
        require(amount >= 300, "Max hold cannot be less than 3%");
        msPercentage = amount;
    }

    function setMhPercentage(uint256 amount) external onlyOwner {
        require(amount >= 300, "Max hold cannot be less than 3%");
        mhPercentage = amount;
    }
}