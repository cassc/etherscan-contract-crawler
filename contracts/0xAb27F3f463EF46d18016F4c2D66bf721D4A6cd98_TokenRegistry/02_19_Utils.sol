// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "../interfaces/IGlobalConfig.sol";

library Utils {
    address public constant ETH_ADDR = 0x000000000000000000000000000000000000000E;
    uint256 public constant INT_UNIT = 10**uint256(18);

    function _isETH(address _token) public pure returns (bool) {
        return ETH_ADDR == _token;
    }

    function getDivisor(IGlobalConfig globalConfig, address _token) public view returns (uint256) {
        if (_isETH(_token)) return INT_UNIT;
        return 10**uint256(globalConfig.tokenRegistry().getTokenDecimals(_token));
    }
}