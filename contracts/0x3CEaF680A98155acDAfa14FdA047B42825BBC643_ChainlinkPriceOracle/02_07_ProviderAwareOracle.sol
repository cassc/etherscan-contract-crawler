// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IPriceOracle.sol";
import "../../interfaces/IPriceProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ProviderAwareOracle is IPriceOracle, Ownable {

    uint internal constant PRECISION = 1 ether;

    IPriceProvider public provider;

    event ProviderTransfer(address _newProvider, address _oldProvider);

    constructor(address _provider) {
        provider = IPriceProvider(_provider);
    }

    function setPriceProvider(address _newProvider) external onlyOwner {
        address oldProvider = address(provider);
        provider = IPriceProvider(_newProvider);
        emit ProviderTransfer(_newProvider, oldProvider);
    }


}