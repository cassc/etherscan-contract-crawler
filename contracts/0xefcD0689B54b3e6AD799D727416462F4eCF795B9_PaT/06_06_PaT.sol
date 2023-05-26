// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaT is Ownable, ERC20 {
    uint256 public constant TOTAL_SUPPLY = 100 * (10 ** 12) * (10 ** 18); // Total 100 trillion PAT

    // Sniper bots and MEV protection
    mapping(address => bool) public bots;

    // AMM
    mapping(address => bool) public ammPairs;

    // Exclude from max transaction amount
    mapping(address => bool) public excludedFromMaxTransferAmount;

    // Max transaction amount, only applied in limited mode
    uint256 public maxTransferAmount;

    // Flags
    bool public activateTrading; // Set to true when trading is enabled
    bool public limitedMode = true; // Set to false when it gets stable

    // Events
    event BlockBots(address bot, bool isSet);
    event SetAmmPair(address pair, bool isPair);
    event TradingEnabled();
    event LimitedDisable();
    event SetMaxTransferAmount(uint256 amount);

    constructor() ERC20("PaT", "PAT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function blockBots(address _bot, bool _isSet) external onlyOwner {
        bots[_bot] = _isSet;

        emit BlockBots(_bot, _isSet);
    }

    function enableSwap() external onlyOwner {
        activateTrading = true;

        emit TradingEnabled();
    }

    function disableLimitation() external onlyOwner {
        limitedMode = false;

        emit LimitedDisable();
    }

    function setAmmPair(address _pair, bool _isPair) external onlyOwner {
        ammPairs[_pair] = _isPair;

        emit SetAmmPair(_pair, _isPair);
    }

    function setMaxTransferAmount(
        uint256 _maxTransferAmount
    ) external onlyOwner {
        maxTransferAmount = _maxTransferAmount;

        emit SetMaxTransferAmount(_maxTransferAmount);
    }

    function excludeFromMaxTransferAmount(
        address _account,
        bool _excluded
    ) external onlyOwner {
        excludedFromMaxTransferAmount[_account] = _excluded;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!bots[from] && !bots[to], "Blacklisted bot");

        if (from != owner() && to != owner()) {
            require(activateTrading, "Swap not enabled");
        }

        if (limitedMode) {
            if (ammPairs[from] && !excludedFromMaxTransferAmount[to]) {
                // On buy
                require(amount <= maxTransferAmount, "Buy amount exceeded");
            } else if (ammPairs[to] && !excludedFromMaxTransferAmount[from]) {
                // On sell
                require(amount <= maxTransferAmount, "Sell amount exceeded");
            }
        }

        super._transfer(from, to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}