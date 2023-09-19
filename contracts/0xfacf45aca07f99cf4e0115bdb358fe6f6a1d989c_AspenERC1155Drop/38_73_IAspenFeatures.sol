// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IAspenFeaturesV1 is IERC165Upgradeable {
    // Marker interface to make an ERC165 clash less likely
    function isIAspenFeaturesV1() external pure returns (bool);

    // List of codes for features this contract supports
    function supportedFeatureCodes() external pure returns (uint256[] memory codes);
}