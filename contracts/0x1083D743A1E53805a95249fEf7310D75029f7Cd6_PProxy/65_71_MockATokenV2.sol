// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.7.1;

import "../interfaces/IAaveLendingPool.sol";
import "./MockToken.sol";

contract MockATokenV2 is MockToken {
    IERC20 public token;

    address public UNDERLYING_ASSET_ADDRESS;

    constructor(address _token) public MockToken("MockATokenV2", "MATKNV2") {
        token = IERC20(_token);
        UNDERLYING_ASSET_ADDRESS = _token;
    }

}