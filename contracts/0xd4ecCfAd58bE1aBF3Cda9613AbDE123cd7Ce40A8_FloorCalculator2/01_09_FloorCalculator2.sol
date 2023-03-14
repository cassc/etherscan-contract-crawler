// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./openzeppelin/TokensRecoverable.sol";

contract FloorCalculator2 is TokensRecoverable {
    uint256 public subFloorPETH;

    function setSubFloorForPETH(uint256 _subFloorPETH) public ownerOnly {
        subFloorPETH = _subFloorPETH;
    }

    function calculateSubFloorPETH(IERC20, IERC20)
        public
        view
        returns (uint256)
    {
        return subFloorPETH;
    }
}