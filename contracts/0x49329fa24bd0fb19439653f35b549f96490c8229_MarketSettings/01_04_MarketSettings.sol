// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMarketSettings.sol";

contract MarketSettings is IMarketSettings, Ownable {
    constructor(
        address royaltyRegsitry_,
        address paymentTokenRegistry_,
        address wrappedEther_
    ) {
        _royaltyRegsitry = royaltyRegsitry_;
        _paymentTokenRegistry = paymentTokenRegistry_;
        _wrappedEther = wrappedEther_;
        _serviceFeeReceiver = msg.sender;
    }

    address private _royaltyRegsitry;
    address private _paymentTokenRegistry;

    address private immutable _wrappedEther;

    bool private _isTradingEnabled = true;
    uint256 public constant FEE_DENOMINATOR = 10000;
    address private _serviceFeeReceiver;
    uint256 private _serviceFeeFraction = 200;
    uint64 private _actionTimeOutRangeMin = 300; // 5 mins
    uint64 private _actionTimeOutRangeMax = 15552000; // 180 days

    mapping(address => bool) private _marketDisabled;

    /**
     * @dev See {IMarketSettings-wrappedEther}.
     */
    function wrappedEther() external view returns (address) {
        return _wrappedEther;
    }

    /**
     * @dev See {IMarketSettings-royaltyRegsitry}.
     */
    function royaltyRegsitry() external view returns (address) {
        return _royaltyRegsitry;
    }

    /**
     * @dev See {IMarketSettings-paymentTokenRegistry}.
     */
    function paymentTokenRegistry() external view returns (address) {
        return _paymentTokenRegistry;
    }

    /**
     * @dev See {IMarketSettings-updateRoyaltyRegistry}.
     */
    function updateRoyaltyRegistry(
        address newRoyaltyRegistry
    ) external onlyOwner {
        address oldRoyaltyRegistry = _royaltyRegsitry;
        _royaltyRegsitry = newRoyaltyRegistry;

        emit RoyaltyRegistryChanged(oldRoyaltyRegistry, newRoyaltyRegistry);
    }

    /**
     * @dev See {IMarketSettings-updatePaymentTokenRegistry}.
     */
    function updatePaymentTokenRegistry(
        address newPaymentTokenRegistry
    ) external onlyOwner {
        address oldPaymentTokenRegistry = _paymentTokenRegistry;
        _paymentTokenRegistry = newPaymentTokenRegistry;

        emit PaymentTokenRegistryChanged(
            oldPaymentTokenRegistry,
            newPaymentTokenRegistry
        );
    }

    /**
     * @dev See {IMarketSettings-isTradingEnabled}.
     */
    function isTradingEnabled() external view returns (bool) {
        return _isTradingEnabled;
    }

    /**
     * @dev See {IMarketSettings-isCollectionTradingEnabled}.
     */
    function isCollectionTradingEnabled(
        address collectionAddress
    ) external view returns (bool) {
        return _isTradingEnabled && !_marketDisabled[collectionAddress];
    }

    /**
     * @dev enable or disable trading of the whole marketplace
     */
    function changeMarketplaceStatus(bool enabled) external onlyOwner {
        _isTradingEnabled = enabled;
    }

    /**
     * @dev enable or disable trading of collection
     */
    function changeCollectionStatus(
        address collectionAddress,
        bool enabled
    ) external onlyOwner {
        if (enabled) {
            delete _marketDisabled[collectionAddress];
        } else {
            _marketDisabled[collectionAddress] = true;
        }
    }

    /**
     * @dev See {IMarketSettings-actionTimeOutRangeMin}.
     */
    function actionTimeOutRangeMin() external view returns (uint64) {
        return _actionTimeOutRangeMin;
    }

    /**
     * @dev See {IMarketSettings-actionTimeOutRangeMax}.
     */
    function actionTimeOutRangeMax() external view returns (uint64) {
        return _actionTimeOutRangeMax;
    }

    /**
     * @dev Change minimum expire time range
     */
    function changeMinActionTimeLimit(uint64 timeInSec) external onlyOwner {
        _actionTimeOutRangeMin = timeInSec;
    }

    /**
     * @dev Change maximum expire time range
     */
    function changeMaxActionTimeLimit(uint64 timeInSec) external onlyOwner {
        _actionTimeOutRangeMax = timeInSec;
    }

    /**
     * @dev See {IMarketSettings-serviceFeeReceiver}.
     */
    function serviceFeeReceiver() external view returns (address) {
        return _serviceFeeReceiver;
    }

    /**
     * @dev See {MarketSettings-serviceFeeFraction}.
     */
    function serviceFeeFraction() external view returns (uint256) {
        return _serviceFeeFraction;
    }

    /**
     * @dev See {IMarketSettings-serviceFeeInfo}.
     */
    function serviceFeeInfo(
        uint256 salePrice
    ) external view returns (address receiver, uint256 amount) {
        receiver = _serviceFeeReceiver;
        amount = (salePrice * _serviceFeeFraction) / FEE_DENOMINATOR;
    }

    /**
     * @dev Change service fee receiver
     */
    function changeSeriveFeeReceiver(address newReceiver) external onlyOwner {
        _serviceFeeReceiver = newReceiver;
    }

    /**
     * @dev Change service fee percentage.
     */
    function changeSeriveFee(uint256 newServiceFeeFraction) external onlyOwner {
        require(
            newServiceFeeFraction <= 10000 / 20,
            "MarketSettings: attempt to set percentage above 5%"
        );

        _serviceFeeFraction = newServiceFeeFraction;
    }
}