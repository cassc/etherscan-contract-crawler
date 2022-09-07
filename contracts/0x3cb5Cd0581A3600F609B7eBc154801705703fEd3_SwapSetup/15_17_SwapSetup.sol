// contracts/BridgeSetup.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";
import "./SwapSetters.sol";
contract SwapSetup is SwapSetters, ERC1967Upgrade {
    function setup(
        address implementation,
        address nativeWrappedAddress, 
        address _feeCollector,
        address _1inchRouter,
        address _0xRouter
    ) public {

        FEE_PERCENT = 15;
        FEE_PERCENT_DENOMINATOR = 10000; // 
        MAX_INT = 2**256 - 1;
        NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        setFeeCollector(_feeCollector);
        setNativeWrappedAddress(nativeWrappedAddress);
        set1InchRouter(_1inchRouter);
        set0xRouter(_0xRouter);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _upgradeTo(implementation);
    }
}