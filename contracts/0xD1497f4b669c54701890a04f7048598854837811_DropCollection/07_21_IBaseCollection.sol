// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBaseCollection {
    event OperatorAllowed(address indexed operator, bool allowed);
    event OperatorBlocked(address indexed operator, bool blocked);

    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(
        address owner,
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) external;
}