// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./openzeppelin/TokensRecoverable.sol";

contract FloorCalculator2 is TokensRecoverable {
    uint256 public subFloorPBNB;

    function setSubFloorForPBNB(uint256 _subFloorPBNB) public ownerOnly {
        subFloorPBNB = _subFloorPBNB;
    }

    function calculateSubFloorPBNB(IERC20, IERC20)
        public
        view
        returns (uint256)
    {
        return subFloorPBNB;
    }
}