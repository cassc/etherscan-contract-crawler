// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./IPriceFeed.sol";
import "./Ownable.sol";

contract ChainLinkPriceFeed is IPriceFeed, Context, Ownable {

    mapping(address => IChainLinkPriceProvider) _priceProxy;

    function setProvider(address[] calldata assets, IChainLinkPriceProvider[] calldata providers) external onlyOwner {
        require(assets.length == providers.length, 'Assets and providers are mismatched');
        for (uint i = 0; i < assets.length; i++) 
            _priceProxy[assets[i]] = providers[i];
    }

    function proxyOf(address asset) external view returns(IChainLinkPriceProvider) {
        return _priceProxy[asset];
    }

    function getAssetPrice(address asset) external override view returns(uint) {
        IChainLinkPriceProvider provider = _priceProxy[asset];
        if (address(provider) != address(0))
            return provider.latestAnswer();
        return 0;
    }

}