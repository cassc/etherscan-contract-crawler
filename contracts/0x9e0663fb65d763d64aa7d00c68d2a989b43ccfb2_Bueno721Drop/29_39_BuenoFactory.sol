// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Bueno721Drop.sol";
import "./Bueno1155Drop.sol";

contract BuenoFactory is AccessControl {
    address private DEFAULT_OPERATOR_FILTER =
        address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    address private drop721Implementation;
    address private drop1155Implementation;

    event ContractCreated(address creator, address contractAddress);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function updateDefaultOperatorFilter(
        address newFilter
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        DEFAULT_OPERATOR_FILTER = newFilter;
    }

    function update721Implementation(
        address newImplementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        drop721Implementation = newImplementation;
    }

    function update1155Implementation(
        address newImplementation
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        drop1155Implementation = newImplementation;
    }

    function getOperatorFilter() external view returns (address) {
        return DEFAULT_OPERATOR_FILTER;
    }

    function get721ImplementationAddress() external view returns (address) {
        return drop721Implementation;
    }

    function get1155ImplementationAddress() external view returns (address) {
        return drop1155Implementation;
    }

    function deploy721Drop(
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
        require(drop721Implementation != address(0), "Implementation not set");

        address payable clone = payable(Clones.clone(drop721Implementation));
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

    function deploy1155Drop(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        TokenSettings[] calldata _tokenSettings,
        RoyaltySettings calldata _royaltySettings,
        PaymentSplitterSettings calldata _paymentSplitterSettings,
        bool _registerOperatorFilter,
        bool _allowBurning
    ) external {
        require(drop1155Implementation != address(0), "Implementation not set");

        address clone = Clones.clone(drop1155Implementation);

        address operatorFilter = _registerOperatorFilter
            ? DEFAULT_OPERATOR_FILTER
            : address(0);

        Bueno1155Drop(clone).initialize(
            _name,
            _symbol,
            _baseUri,
            _tokenSettings,
            _royaltySettings,
            _paymentSplitterSettings,
            _allowBurning,
            msg.sender,
            operatorFilter
        );

        emit ContractCreated(msg.sender, clone);
    }
}