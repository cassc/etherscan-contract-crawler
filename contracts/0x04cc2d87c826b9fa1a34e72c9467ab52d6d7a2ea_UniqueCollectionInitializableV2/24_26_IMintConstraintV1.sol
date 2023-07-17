// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IMintConstraintV1 is IERC165Upgradeable {
    function canMint(
        address mintTo,
        uint256 ammount,
        bytes memory _data
    ) external returns(bool);

    /*
     * @dev you should implement a function that decodes _data
     * to the actual values. other systems can use the function
     * and debug if encoding is implemented properly.
     * Solidity does not have a `any` or generic type so we can
     * not define a function with undefined return type.
     *
     * function decodeInitializerData(
     *     bytes memory _data
     * ) external pure returns (any);
     */
}