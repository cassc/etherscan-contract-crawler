//SPDX-License-Identifier: Unlicense

pragma solidity = 0.8.9;

import "contracts/integrations/curve/common/Stablz3CRVMetaPoolIntegration.sol";

/// @title Stablz FRAX-3CRV pool integration
contract StablzFRAX3CRVIntegration is Stablz3CRVMetaPoolIntegration {

    /// @dev Meta pool specific addresses
    address private constant FRAX_3CRV_POOL = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address private constant FRAX_3CRV_GAUGE = 0x72E158d38dbd50A483501c24f792bDAAA3e7D55C;

    /// @param _oracle Oracle address
    /// @param _feeHandler Fee handler address
    constructor(address _oracle, address _feeHandler) Stablz3CRVMetaPoolIntegration(
        FRAX_3CRV_POOL,
        FRAX_3CRV_GAUGE,
        _oracle,
        _feeHandler
    ) {

    }

}