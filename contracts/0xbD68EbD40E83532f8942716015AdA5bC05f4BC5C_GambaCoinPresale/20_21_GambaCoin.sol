// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

uint256 constant INITIAL_SUPPLY = 777_777_777 ether;
address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant BURN_ADDRESS = address(0xdead);
uint256 constant BPS_DIVISOR = 10_000;

IUniswapV2Factory constant UNISWAP_V2_FACTORY = IUniswapV2Factory(
    0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
);

/**
 * @title Gamba Coin
 * @author @gambacoin: https://twitter.com/gambacoin
 * @notice Total Supply: 777,777,777
 */
contract GambaCoin is ERC20Permit, Ownable {
    address public immutable UNISWAP_V2_PAIR;

    uint256 public maxWalletAmount = (INITIAL_SUPPLY * 10) / BPS_DIVISOR;
    uint256 public deadblockExpiration;

    bool public limitsEnabled;
    bool public tradingActive;

    uint256 private _initialBuyFeesBPS;
    uint256 private _initialSellFeesBPS;

    address public feeRecipient;

    uint256 public taxDuration;

    mapping(address => bool) private _exclusionList;
    mapping(address => bool) private _blacklist;

    event UpdatedTradingStatus(bool tradingActive, uint256 deadBlockExpiration);
    event UpdatedMaxWalletAmount(uint256 maxWalletAmount);
    event UpdatedExclusionList(address account, bool excluded);
    event UpdatedBlacklist(address account, bool blacklisted);
    event UpdatedLimitsEnabled(bool limitsInEffect);
    event UpdatedFeeRecipient(address recipient);

    constructor(
        address feeRecipient_
    ) ERC20Permit("Gamba Coin") ERC20("Gamba Coin", "GAMBA") {
        _updateExclusionList(BURN_ADDRESS, true);
        _updateExclusionList(feeRecipient_, true);
        _updateExclusionList(msg.sender, true);
        updateFeeRecipient(feeRecipient_);
        _mint(msg.sender, INITIAL_SUPPLY);
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

        if (limitsEnabled) {
            //when buy
            if (from == UNISWAP_V2_PAIR && !isExcluded(to)) {
                if (block.number < deadblockExpiration) {
                    _updateBlacklist(to, true);
                }
            } else if (to == UNISWAP_V2_PAIR && !isExcluded(from)) {
                //when sell
                if (block.number < deadblockExpiration) {
                    _updateBlacklist(from, true);
                }
            }

            if (to != UNISWAP_V2_PAIR && !isExcluded(to) && !isExcluded(from)) {
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "amount exceeds wallet limit"
                );
            }
        }

        // if any account does not belong to exclusionList, apply fees to:
        // - bots/snipers
        // - buys
        // - sells
        if (!isExcluded(from) && !isExcluded(to)) {
            uint256 fees;
            // take fees bot/sniper
            if (isBlacklisted(to) || isBlacklisted(from)) {
                fees = (amount * 9_800) / BPS_DIVISOR;
            }
            // take fees on sell swaps
            else if (to == UNISWAP_V2_PAIR) {
                fees = (amount * getFeesBPS(_initialSellFeesBPS)) / BPS_DIVISOR;
            }
            // take fees on buy swaps
            else if (from == UNISWAP_V2_PAIR) {
                fees = (amount * getFeesBPS(_initialBuyFeesBPS)) / BPS_DIVISOR;
            }

            if (fees > 0) {
                super._transfer(from, feeRecipient, fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function getFeesBPS(
        uint256 initialBPS
    ) public view returns (uint256 feesBPS) {
        if (block.number < deadblockExpiration) {
            return initialBPS;
        }

        uint256 elapsedBlocks = block.number - deadblockExpiration;

        if (elapsedBlocks < taxDuration) {
            feesBPS = initialBPS * (taxDuration - elapsedBlocks);
            feesBPS = feesBPS / taxDuration;
        }
    }

    function updateTradingStatus(uint256 deadBlocks) external onlyOwner {
        updateLimitsEnabled(true);

        tradingActive = true;

        if (deadblockExpiration == 0) {
            deadblockExpiration = block.number + deadBlocks;
        }

        emit UpdatedTradingStatus(true, deadblockExpiration);
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
        newAmount = newAmount;
        emit UpdatedMaxWalletAmount(newAmount);
    }

    function updateLimitsEnabled(bool enabled) public onlyOwner {
        limitsEnabled = enabled;
        emit UpdatedLimitsEnabled(enabled);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}