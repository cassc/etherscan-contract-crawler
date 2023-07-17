// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "./IMintConstraintV1.sol";

interface IMintConstraintFactoryV1 is IERC165Upgradeable {
    event ConstraintCreated(
        address indexed constraint
    );
    function createConstraint(
        bytes memory _data
    ) external returns (IMintConstraintV1);
}