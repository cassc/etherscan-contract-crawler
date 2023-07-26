// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBaseCollection {
    event OperatorAllowed(bytes32 indexed operator, bool allowed);
    event OperatorBlocked(bytes32 indexed operator, bool blocked);

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