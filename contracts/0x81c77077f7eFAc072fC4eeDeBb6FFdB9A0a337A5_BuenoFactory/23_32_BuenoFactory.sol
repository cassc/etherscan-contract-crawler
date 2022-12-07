// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Bueno721Drop.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract BuenoFactory is AccessControl {
    address private implementation;
    address private DEFAULT_OPERATOR_FILTER =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    event ContractCreated(address creator, address contractAddress);

    constructor() {
        implementation = address(new Bueno721Drop());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateDefaultOperatorFilter(
        address newFilter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        DEFAULT_OPERATOR_FILTER = newFilter;
    }

    function updateImplementation(
        address newImplementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        implementation = newImplementation;
    }

    function getOperatorFilter() external view returns (address) {
        return DEFAULT_OPERATOR_FILTER;
    }

    function getImplementationAddress() external view returns (address) {
        return implementation;
    }

    function deployBuenoContract(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        RoyaltySettings calldata _royaltySettings,
        PhaseSettings[] calldata _phases,
        BaseSettings calldata _baseSettings,
        PaymentSplitterSettings calldata _paymentSplitterSettings,
        uint256 _maxIntendedSupply,
        bool _registerOperatorFilter,
        bool _allowBurning
    ) external {
        address payable clone = payable(Clones.clone(implementation));
        address operatorFilter = _registerOperatorFilter
            ? DEFAULT_OPERATOR_FILTER
            : address(0);

        Bueno721Drop(clone).initialize(
            _name,
            _symbol,
            _baseUri,
            _royaltySettings,
            _phases,
            _baseSettings,
            _paymentSplitterSettings,
            _maxIntendedSupply,
            _allowBurning,
            msg.sender,
            operatorFilter
        );

        emit ContractCreated(msg.sender, clone);
    }
}