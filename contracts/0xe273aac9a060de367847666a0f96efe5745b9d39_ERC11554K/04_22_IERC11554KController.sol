// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev {IERC11554KController} interface:
 */
interface IERC11554KController {
    function owner() external returns (address);

    function originators(address collection, uint256 tokenId)
        external
        returns (address);

    function isActiveCollection(address collection) external returns (bool);

    function isLinkedCollection(address collection) external returns (bool);

    function paymentToken() external returns (IERC20Upgradeable);

    function maxMintPeriod() external returns (uint256);
}