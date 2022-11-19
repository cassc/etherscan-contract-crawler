// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { IGemGlobalConfig } from "../interfaces/IGemGlobalConfig.sol";

abstract contract Governable {
    IGemGlobalConfig public gemGlobalConfig;

    modifier onlyGov() {
        require(msg.sender == governor(), "Governable: not authorized");
        _;
    }

    function governor() public view returns (address) {
        return gemGlobalConfig.governor();
    }

    function _init(address _gemGlobalConfig) internal {
        gemGlobalConfig = IGemGlobalConfig(_gemGlobalConfig);
    }
}