// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingDescriptor.sol";

contract StakingDescriptorMock {
    function constructTokenURI(
        StakingDescriptor.ConstructTokenURIParams memory params
    ) public pure returns (string memory) {
        return StakingDescriptor.constructTokenURI(params);
    }
}