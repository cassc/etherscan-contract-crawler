// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

IUniswapV2Factory constant UNISWAP_V2_FACTORY = IUniswapV2Factory(
    0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
);

address constant DISPERSE_APP = 0xD152f549545093347A162Dce210e7293f1452150;

uint256 constant TOTAL_SUPPLY = 420_000_000 ether;
uint256 constant BPS_DIVISOR = 100;

contract GyatCoin is ERC20("GyatCoin", "GYAT"), Ownable {
    address public immutable UNISWAP_V2_PAIR;

    uint256 public maxWalletAmount = (TOTAL_SUPPLY * 1) / BPS_DIVISOR;

    bool public limitsEnabled;
    bool public tradingActive;

    uint256 public buyFeesBPS;
    uint256 public sellFeesBPS;

    address public feeRecipient;

    mapping(address => bool) private _exclusionList;
    mapping(address => bool) private _blacklist;

    event UpdatedTradingStatus(bool tradingActive);
    event UpdatedMaxWalletAmount(uint256 maxWalletAmount);
    event UpdatedExclusionList(address account, bool excluded);
    event UpdatedBlacklist(address account, bool blacklisted);
    event UpdatedLimitsEnabled(bool limitsInEffect);
    event UpdatedFeeRecipient(address recipient);

    constructor() {
        buyFeesBPS = 5;
        sellFeesBPS = 25;

        _updateExclusionList(DISPERSE_APP, true);
        _updateExclusionList(msg.sender, true);
        _updateExclusionList(msg.sender, true);
        updateFeeRecipient(msg.sender);
        _mint(msg.sender, TOTAL_SUPPLY);
        UNISWAP_V2_PAIR = UNISWAP_V2_FACTORY.createPair(address(this), WETH);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "amount must be greater than 0");

        if (!tradingActive) {
            require(
                isExcluded(from) || isExcluded(to),
                "transfers are not yet active"
            );
        }

        if (from != owner() && to != owner()) {
            require(!isBlacklisted(from) && !isBlacklisted(to), "blacklisted");
        }

        if (limitsEnabled) {
            if (to != UNISWAP_V2_PAIR && !isExcluded(to) && !isExcluded(from)) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "amount exceeds wallet limit"
                );
            }
        }

        if (!isExcluded(from) && !isExcluded(to)) {
            uint256 fees;

            // take fees on sell swaps
            if (to == UNISWAP_V2_PAIR) {
                fees = getFeesAmount(amount, sellFeesBPS);
            }
            // take fees on buy swaps
            else if (from == UNISWAP_V2_PAIR) {
                fees = getFeesAmount(amount, buyFeesBPS);
            }

            if (fees > 0) {
                super._transfer(from, feeRecipient, fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function getFeesAmount(
        uint256 amount,
        uint256 initialBPS
    ) public pure returns (uint256 fees) {
        fees = (amount * initialBPS) / BPS_DIVISOR;
    }

    function updateTradingStatus() external onlyOwner {
        updateLimitsEnabled(true);
        tradingActive = true;
        emit UpdatedTradingStatus(true);
    }

    function updateFeeRecipient(address recipient) public onlyOwner {
        feeRecipient = recipient;
        emit UpdatedFeeRecipient(recipient);
    }

    function updateExclusionList(
        address[] calldata addresses,
        bool value
    ) public onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            _updateExclusionList(addresses[i], value);
            unchecked {
                i++;
            }
        }
    }

    function _updateExclusionList(address account, bool value) private {
        _exclusionList[account] = value;
        emit UpdatedExclusionList(account, value);
    }

    function isExcluded(address account) public view returns (bool) {
        return _exclusionList[account];
    }

    function updateBlacklist(
        address[] calldata addresses,
        bool status
    ) external onlyOwner {
        for (uint256 i; i < addresses.length; ) {
            _updateBlacklist(addresses[i], status);
            unchecked {
                i++;
            }
        }
    }

    function _updateBlacklist(address account, bool status) private {
        _blacklist[account] = status;
        emit UpdatedBlacklist(account, status);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return !isExcluded(account) && _blacklist[account];
    }

    function updateMaxWalletAmount(uint256 newAmount) external onlyOwner {
        maxWalletAmount = newAmount;
        emit UpdatedMaxWalletAmount(newAmount);
    }

    function updateLimitsEnabled(bool enabled) public onlyOwner {
        limitsEnabled = enabled;
        emit UpdatedLimitsEnabled(enabled);
    }

    function updateFeesBPS(
        uint256 buyFeesBPS_,
        uint256 sellFeesBPS_
    ) external onlyOwner {
        buyFeesBPS = buyFeesBPS_;
        sellFeesBPS = sellFeesBPS_;
    }

    receive() external payable {}
}