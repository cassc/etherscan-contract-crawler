// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Interfaces/IRouterGater.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@quadrata/contracts/interfaces/IQuadReader.sol";
import "@quadrata/contracts/interfaces/IQuadPassport.sol";
import "@quadrata/contracts/interfaces/IQuadPassportStore.sol";

/// @title A router gater contract for checking users ability for trading actions
/// @author Frigg team
/// @dev Inherits from the OpenZepplin AccessControl & IRouterGater
contract routerGater is AccessControl, IRouterGater {
    address public goldfinchUIDAddress;
    address public quadrataAddress;

    uint8[] goldfinchIds = [0, 1, 2, 3, 4];

    mapping(uint8 => bool) public acceptedGoldfinchIds;
    mapping(bytes32 => bool) public quadrataBlockedCountries;

    /// @dev Set DEFAULT_ADMIN_ROLE to a multisig address controlled by Frigg
    constructor(
        address _multisig,
        address _goldfinchUIDAddress,
        address _quadrataAddress
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, _multisig);

        goldfinchUIDAddress = _goldfinchUIDAddress;
        quadrataAddress = _quadrataAddress;

        acceptedGoldfinchIds[0] = true;
        acceptedGoldfinchIds[1] = false;
        acceptedGoldfinchIds[2] = false;
        acceptedGoldfinchIds[3] = false;
        acceptedGoldfinchIds[4] = true;
        quadrataBlockedCountries[keccak256("US")] = true;
    }

    /// @notice Establishes logic for gating via Goldfinch's UID https://docs.goldfinch.finance/goldfinch/unique-identity-uid

    function updateGoldfinchUIDAddress(address _newGoldfinchUIDAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        goldfinchUIDAddress = _newGoldfinchUIDAddress;
    }

    function updateAcceptedIds(uint8 _id, bool _valid) public onlyRole(DEFAULT_ADMIN_ROLE) {
        acceptedGoldfinchIds[_id] = _valid;
    }

    function goldfinchLogic(address _account) public view override returns (bool _gatedStatus) {
        uint256 goldfinchIdsLength = goldfinchIds.length;

        IERC1155 goldfinchUID = IERC1155(goldfinchUIDAddress);

        for (uint8 i = 0; i < goldfinchIdsLength; ) {
            if (goldfinchUID.balanceOf(_account, i) > 0 && acceptedGoldfinchIds[i]) {
                return true;
            }

            unchecked {
                ++i;
            }
        }
        return false;
    }

    /// @notice Establishes logic for gating via Quadrata's Passports https://docs.quadrata.com/integration/how-to-integrate/query-attributes/query-multiple-attributes

    function updateQuadrataBlockedCountries(bytes32 _country) public onlyRole(DEFAULT_ADMIN_ROLE) {
        quadrataBlockedCountries[_country] = true;
    }

    function updateQuadrataAddress(address _newQuadrataAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        quadrataAddress = _newQuadrataAddress;
    }

    /// @dev not internal function so that composable
    function quadrataLogic(address _account) public payable override returns (bool _gatedStatus) {
        IQuadReader quadrata = IQuadReader(quadrataAddress);
        require(quadrata.balanceOf(_account, keccak256("DID")) > 0, "NO_PASSPORT_IN_WALLET");

        bytes32[] memory attributesToQuery = new bytes32[](2);
        attributesToQuery[0] = keccak256("COUNTRY");
        attributesToQuery[1] = keccak256("AML");

        /// get fee to query both `COUNTRY` & AML
        uint256 queryFeeBulk = quadrata.queryFeeBulk(_account, attributesToQuery);
        require(msg.value == queryFeeBulk, "MISSING_QUERY_FEE");

        IQuadPassportStore.Attribute[] memory attributes = quadrata.getAttributesBulk{value: queryFeeBulk}(
            _account,
            attributesToQuery
        );

        require(!quadrataBlockedCountries[attributes[0].value], "BANNED_COUNTRY");
        require(uint256(attributes[1].value) < 8, "HIGH_RISK_AML");
        return true;
    }

    /// @notice For primaryRouter.sol to access if an address passes the gating conditions
    function checkGatedStatus(address _account) external payable override returns (bool _gatedStatus) {
        require(goldfinchLogic(_account) || quadrataLogic(_account), "You do not pass the gated checks");
        return true;
    }
}