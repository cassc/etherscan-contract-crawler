// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract FFS is ERC20, Ownable, ERC20Burnable {
    // ADDRESSESS -------------------------------------------------------------------------------------------
    address public lpPair; // Liquidity token address
    address public w1;

    // NUMBERS ----------------------------------------------------------------------------------------------
    uint256 divisor; // divisor | 0.0001 max presition fee
    uint256 maxTransactionAmount;
    uint256 maxWalletAmount;

    // BOOLEANS ---------------------------------------------------------------------------------------------
    bool tradingEnabled;

    // MAPPINGS
    mapping(address => bool) public _isExcludedFromFee; // list of users excluded from fee
    mapping(address => bool) public _isExcludedFromMaxLimit; //
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public _list;

    // STRUCTS ----------------------------------------------------------------------------------------------
    struct Fees {
        uint16 buyFee; // fee when people BUY tokens
        uint16 sellFee; // fee when people SELL tokens
        uint16 transferFee; // fee when people TRANSFER tokens
    }

    // OBJECTS ----------------------------------------------------------------------------------------------
    Fees public _feesRates; // fees rates

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    constructor() ERC20("FFS", "FFS") {
        // mint tokens to deployer
        _mint(msg.sender, 1000000 ether);

        divisor = 10000;

        // marketing address
        w1 = 0xB7212D62eaD620bc16fa2141926C3Da2E8728c8e;

        // default fees
        // 2% on BUY
        // 2% on SELL
        // 0% on Transfer
        _feesRates = Fees({buyFee: 200, sellFee: 200, transferFee: 0});

        // exclude from fees
        // owner, token and marketing address
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[w1] = true;

        _isExcludedFromMaxLimit[owner()] = true;
        _isExcludedFromMaxLimit[address(this)] = true;

        maxTransactionAmount = calculatePercent(totalSupply(), 200); // 2% of total supply
        maxWalletAmount = calculatePercent(totalSupply(), 200); // 2% of total supply
    }

    // function for calculate percent
    function calculatePercent(uint256 value, uint256 percent)
        public
        view
        returns (uint256)
    {
        return (value * percent) / divisor;
    }

    receive() external payable virtual {}

    // Set fees
    function setTaxes(
        uint16 buyFee,
        uint16 sellFee,
        uint16 transferFee
    ) external virtual onlyOwner {
        require(buyFee + sellFee + transferFee <= 200, "Fees too high");
        _feesRates.buyFee = buyFee;
        _feesRates.sellFee = sellFee;
        _feesRates.transferFee = transferFee;
    }

    // this function will be called every buy, sell or transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check before each tx
        _beforeTransferCheck(from, to, amount);
        _finalizeTransfer(from, to, amount);
    }

    function setPair(address pair) external onlyOwner {
        require(lpPair == address(0), "Pair already set");
        lpPair = pair;
        automatedMarketMakerPairs[lpPair] = true;
        _isExcludedFromMaxLimit[lpPair] = true;
    }

    function _finalizeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        // by default receiver receive 100% of sended amount
        uint256 amountReceived = amount;
        uint256 feeAmount = 0; // received fee amount is zero

        // If takeFee is false there is 0% fee
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        // check if we need take fee or not
        if (takeFee) {
            // if we need take fee
            // calc how much we need take
            feeAmount = calcBuySellTransferFee(from, to, amount);

            // we substract fee amount from recipient amount
            amountReceived = amount - feeAmount;

            if (feeAmount > 0) {
                // if fee amount is more than zero
                // we send fee to contract
                super._transfer(from, w1, feeAmount);
            }
        }

        // finally send remaining tokens to recipient
        super._transfer(from, to, amountReceived);
    }

    function calcBuySellTransferFee(
        address from,
        address to,
        uint256 amount
    ) internal view virtual returns (uint256) {
        // by default we take zero fee
        uint256 totalFeePercent = 0;
        uint256 feeAmount = 0;

        // BUY -> FROM == LP ADDRESS
        if (automatedMarketMakerPairs[from]) {
            totalFeePercent += _feesRates.buyFee;
        }
        // SELL -> TO == LP ADDRESS
        else if (automatedMarketMakerPairs[to]) {
            totalFeePercent += _feesRates.sellFee;
        }
        // TRANSFER
        else {
            totalFeePercent += _feesRates.transferFee;
        }

        // CALC FEES AMOUT
        if (totalFeePercent > 0) {
            feeAmount = (amount * totalFeePercent) / divisor;
        }

        return feeAmount;
    }

    function _beforeTransferCheck(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(
            from != address(0),
            "ERC20: transfer from the ZERO_ADDRESS address"
        );
        require(
            to != address(0),
            "ERC20: transfer to the ZERO_ADDRESS address"
        );
        require(amount > 0, "Transfer amount must be greater than ZERO");

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            require(tradingEnabled, "Trading not active");
            require(!_list[from] && !_list[to], "list");

            // BUY -> FROM == LP ADDRESS
            if (automatedMarketMakerPairs[from]) {
                if (!_isExcludedFromMaxLimit[from]) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Max wallet exceeded"
                    );
                }
            }
            // SELL -> TO == LP ADDRESS
            else if (automatedMarketMakerPairs[to]) {
                if (!_isExcludedFromMaxLimit[to]) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                }
            }
            // TRANSFER
            else {
                if (!_isExcludedFromMaxLimit[to]) {
                    require(
                        amount + balanceOf(to) <= maxWalletAmount,
                        "Max wallet exceeded"
                    );
                }
            }
        }
    }
    
    function excludeFromMaxLimit(address account, bool val)
        public
        virtual
        onlyOwner
    {
        _isExcludedFromMaxLimit[account] = val;
    }

    function excludeFromFee(address account, bool val)
        public
        virtual
        onlyOwner
    {
        _isExcludedFromFee[account] = val;
    }

    function addToList(address account, bool val) public virtual onlyOwner {
        _list[account] = val;
    }

    function setMaxWalletAmount(uint256 value) public virtual onlyOwner {
        maxWalletAmount = value;
    }

    function setMaxTransactionAmount(uint256 value) public virtual onlyOwner {
        maxTransactionAmount = value;
    }

    function enableTrading() public virtual onlyOwner {
        require(!tradingEnabled, "TradingEnabled already actived");
        tradingEnabled = true;
    }
}