pragma solidity ^0.5.16;

// Inheritance
import "../FuturesMarket.sol";
import "./MixinFuturesOCOOrders.sol";

contract ExtendedFuturesMarket is FuturesMarket, MixinFuturesOCOOrders {
    constructor(
        address _resolver,
        bytes32 _baseAsset,
        bytes32 _marketKey
    ) public FuturesMarket(_resolver, _baseAsset, _marketKey) {}
}