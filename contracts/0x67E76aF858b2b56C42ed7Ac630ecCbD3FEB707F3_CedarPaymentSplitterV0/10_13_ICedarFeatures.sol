// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface ICedarFeaturesV0 is IERC165Upgradeable {
    // Marker interface to make an ERC165 clash less likely
    function isICedarFeaturesV0() external pure returns (bool);

    // List of features that contract supports and may be passed to featureVersion
    function supportedFeatures() external pure returns (string[] memory features);
}