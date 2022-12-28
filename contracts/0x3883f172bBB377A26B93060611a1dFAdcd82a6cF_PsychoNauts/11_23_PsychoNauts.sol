// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PsychoNautUpgradeable.sol";

contract PsychoNauts is PsychoNautUpgradeable {
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _metaUri,
        address[] memory _payees,
        uint256[] memory _shares,
        bytes32 _merkleRoot
    ) public initializer initializerERC721A {
        __PsychoNaut_init(
            _name,
            _symbol,
            _metaUri,
            _payees,
            _shares,
            _merkleRoot
        );
    }
}