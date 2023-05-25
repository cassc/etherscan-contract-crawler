// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBaseCollection {
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address newOwner) external;
}