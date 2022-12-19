//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

import "contracts/integrations/curve/common/Stablz3CRVMetaPoolIntegration.sol";

/// @title Stablz PWRD-3CRV pool integration
contract StablzPWRD3CRVIntegration is Stablz3CRVMetaPoolIntegration {

    /// @dev Meta pool specific addresses
    address private constant PWRD_3CRV_POOL = 0xbcb91E689114B9Cc865AD7871845C95241Df4105;
    address private constant PWRD_3CRV_GAUGE = 0xb07d00e0eE9b1b2eb9f1B483924155Af7AF0c8Fa;

    /// @param _oracle Oracle address
    /// @param _feeHandler Fee handler address
    constructor(address _oracle, address _feeHandler) Stablz3CRVMetaPoolIntegration(
        PWRD_3CRV_POOL,
        PWRD_3CRV_GAUGE,
        _oracle,
        _feeHandler
    ) {

    }

}