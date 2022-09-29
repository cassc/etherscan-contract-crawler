pragma solidity ^0.8.17;
import '../swapper/Swapper.sol';
import '../fee/FeeSettingsDecorator.sol';

contract GigaSwap is Swapper, FeeSettingsDecorator {
    constructor(address feeSettingsAddress)
        FeeSettingsDecorator(feeSettingsAddress)
    {}
}