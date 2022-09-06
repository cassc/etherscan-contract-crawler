// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev ERC173 standard
 */
interface IERC173 {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner(
    ) view external returns (address);

    function transferOwnership(
        address _newOwner
    ) external;
}