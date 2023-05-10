// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingSVG.sol";

contract StakingSVGMock {
    function generateSVG(
        StakingSVG.StakingSVGParams memory svgParams
    ) public pure returns (string memory svg) {
        return StakingSVG.generateSVG(svgParams);
    }
}