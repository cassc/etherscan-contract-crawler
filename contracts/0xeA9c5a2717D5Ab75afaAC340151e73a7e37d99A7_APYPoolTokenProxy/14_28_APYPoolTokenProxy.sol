// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract APYPoolTokenProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _proxyAdmin,
        address _underlyer,
        address _priceAgg
    )
        public
        TransparentUpgradeableProxy(
            _logic,
            _proxyAdmin,
            abi.encodeWithSignature(
                "initialize(address,address,address)",
                _proxyAdmin,
                _underlyer,
                _priceAgg
            )
        )
    {} // solhint-disable no-empty-blocks
}