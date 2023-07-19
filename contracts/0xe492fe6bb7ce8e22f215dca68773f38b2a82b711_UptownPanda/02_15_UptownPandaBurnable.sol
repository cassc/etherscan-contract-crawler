// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract UptownPandaBurnable {
    event BuyLogAdded(address indexed buyer, uint256 indexed timestamp, uint256 amount);
    event BurnAmountCalculated(
        address indexed sender,
        address indexed recipient,
        uint256 indexed buyTimestamp,
        uint256 buyAmount,
        uint256 burnAmount
    );

    using SafeMath for uint256;

    uint256 private constant BURN_PERCENT_SCALE = 1e9;
    uint256 public constant MAX_BURN_PRICE_MULTIPLIER = 3;
    uint256 public constant MIN_BURN_PRICE_MULTIPLIER = 10;
    uint256 public constant MAX_BURN_PERCENT = 30;
    uint256 public constant MIN_BURN_PERCENT = 5;
    uint256 public constant WALLET_TO_WALLET_BURN_PERCENT = 5;
    uint256 public constant SELL_PENALTY_INTERVAL = 5 minutes;

    struct BuyLog {
        uint256 amount;
        uint256 timestamp;
    }

    uint256 private defaultBuyTimestamp;
    mapping(address => BuyLog[]) private buyLogs;
    mapping(address => uint256) private buyLogTracker;

    function _getAmountsToBurn(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal returns (uint256[] memory) {
        return
            _shouldBurnTokens(_sender, _recipient, _amount)
                ? _calculateAmountsToBurn(_sender, _recipient, _amount)
                : new uint256[](0);
    }

    function _shouldBurnTokens(address _sender, address _recipient, uint256 _amount) private view returns (bool) {
        if (_amount == 0) {
            return false;
        }

        address[] memory nonBurnableSenders = _getNonBurnableSenders();
        for (uint256 i = 0; i < nonBurnableSenders.length; i++) {
            if (_sender == nonBurnableSenders[i]) {
                return false;
            }
        }

        address[] memory nonBurnableRecipients = _getNonBurnableRecipients();
        for (uint256 i = 0; i < nonBurnableRecipients.length; i++) {
            if (_recipient == nonBurnableRecipients[i]) {
                return false;
            }
        }

        return true;
    }

    function _calculateAmountsToBurn(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (uint256[] memory) {
        BuyLog[] memory burnParts = _getBurnParts(_sender, _amount);

        uint256[] memory amountsToBurn = new uint256[](burnParts.length);
        for (uint256 i = 0; i < burnParts.length; i++) {
            amountsToBurn[i] = _calculateSingleAmountToBurn(
                _sender,
                _recipient,
                burnParts[i].amount,
                burnParts[i].timestamp
            );
            emit BurnAmountCalculated(
                _sender,
                _recipient,
                burnParts[i].timestamp,
                burnParts[i].amount,
                amountsToBurn[i]
            );
        }
        return amountsToBurn;
    }

    function _getBurnParts(address _sender, uint256 _amount) private returns (BuyLog[] memory) {
        uint256 burnsCount = _getBurnsCount(_sender, _amount);

        uint256 startBuyLogIndex = buyLogTracker[_sender];
        BuyLog[] storage buyLog = buyLogs[_sender];

        BuyLog[] memory burnParts = new BuyLog[](burnsCount);
        uint256 amountLeft = _amount;

        for (uint256 i = 0; i < burnsCount; i++) {
            uint256 currentBuyLogIndex = startBuyLogIndex + i;
            if (currentBuyLogIndex >= buyLog.length) {
                burnParts[burnsCount - 1] = BuyLog(amountLeft, defaultBuyTimestamp);
                break;
            }
            uint256 subtractAmount = amountLeft >= buyLog[currentBuyLogIndex].amount
                ? buyLog[currentBuyLogIndex].amount
                : amountLeft;

            burnParts[i] = BuyLog(subtractAmount, buyLog[currentBuyLogIndex].timestamp);

            amountLeft = amountLeft.sub(subtractAmount);
            buyLog[currentBuyLogIndex].amount = buyLog[currentBuyLogIndex].amount.sub(subtractAmount);

            if (buyLog[currentBuyLogIndex].amount == 0) {
                buyLogTracker[_sender] = buyLogTracker[_sender].add(1);
            }
        }

        return burnParts;
    }

    function _getBurnsCount(address _sender, uint256 _amount) private view returns (uint256) {
        BuyLog[] storage buyLog = buyLogs[_sender];
        uint256 burnsCount = 0;
        uint256 amountLeft = _amount;

        for (uint256 buyLogIndex = buyLogTracker[_sender]; buyLogIndex < buyLog.length; buyLogIndex++) {
            if (amountLeft == 0) {
                break;
            }
            amountLeft = buyLog[buyLogIndex].amount > amountLeft ? 0 : amountLeft.sub(buyLog[buyLogIndex].amount);
            burnsCount++;
        }

        return amountLeft > 0 ? burnsCount.add(1) : burnsCount;
    }

    function _calculateSingleAmountToBurn(
        address _sender,
        address _recipient,
        uint256 _amount,
        uint256 _timestamp
    ) private returns (uint256) {
        // check for sell under 5 minutes
        bool shouldBurnMaxAmount = block.timestamp.sub(_timestamp) < SELL_PENALTY_INTERVAL;
        if (shouldBurnMaxAmount) {
            return _amount.mul(MAX_BURN_PERCENT).div(100);
        }

        // check if wallet to wallet transfer
        if (_isWalletToWalletTransfer(_sender, _recipient)) {
            return _amount.mul(WALLET_TO_WALLET_BURN_PERCENT).div(100);
        }

        // burn by twap
        uint256 listingPrice = _getListingPriceForBurnCalculation();
        uint256 twapPrice = _getTwapPriceForBurnCalculation();
        uint256 currentPriceMultiplierScaled = listingPrice.mul(BURN_PERCENT_SCALE).div(twapPrice);

        if (currentPriceMultiplierScaled <= MAX_BURN_PRICE_MULTIPLIER.mul(BURN_PERCENT_SCALE)) {
            return _amount.mul(MAX_BURN_PERCENT).div(100);
        }

        if (currentPriceMultiplierScaled >= MIN_BURN_PRICE_MULTIPLIER.mul(BURN_PERCENT_SCALE)) {
            return _amount.mul(MIN_BURN_PERCENT).div(100);
        }

        uint256 maxBurnPercentScaled = MAX_BURN_PERCENT.mul(BURN_PERCENT_SCALE);
        uint256 burnPercentDiff = MAX_BURN_PERCENT.sub(MIN_BURN_PERCENT);
        uint256 burnPercentDiffDividendScaled = currentPriceMultiplierScaled.sub(
            MAX_BURN_PRICE_MULTIPLIER.mul(BURN_PERCENT_SCALE)
        );
        uint256 burnPercentDiffDivisor = MIN_BURN_PRICE_MULTIPLIER.sub(MAX_BURN_PRICE_MULTIPLIER);
        uint256 burnPercentScaled = maxBurnPercentScaled.sub(
            burnPercentDiff.mul(burnPercentDiffDividendScaled.div(burnPercentDiffDivisor))
        );
        return _amount.mul(burnPercentScaled).div(BURN_PERCENT_SCALE.mul(100));
    }

    function _setDefaultBuyTimestamp() internal {
        defaultBuyTimestamp = block.timestamp;
    }

    function _logBuy(address _recipient, uint256 _amount) internal {
        address[] memory nonLoggableRecipients = _getNonLoggableRecipients();
        for (uint256 i = 0; i < nonLoggableRecipients.length; i++) {
            if (_recipient == nonLoggableRecipients[i]) {
                return;
            }
        }
        BuyLog[] storage recipientBuyLog = buyLogs[_recipient];
        recipientBuyLog.push(BuyLog(_amount, block.timestamp));
        emit BuyLogAdded(_recipient, block.timestamp, _amount);
    }

    function _getNonBurnableSenders() internal view virtual returns (address[] memory nonBurnableSenders) {}

    function _getNonBurnableRecipients() internal view virtual returns (address[] memory nonBurnableRecipients) {}

    function _getNonLoggableRecipients() internal view virtual returns (address[] memory nonLoggableRecipients) {}

    function _isWalletToWalletTransfer(address _sender, address _recipient)
        internal
        view
        virtual
        returns (bool isWalletToWalletTransfer)
    {}

    function _getListingPriceForBurnCalculation() internal view virtual returns (uint256 listingPrice) {}

    function _getTwapPriceForBurnCalculation() internal virtual returns (uint256 twapPrice) {}
}