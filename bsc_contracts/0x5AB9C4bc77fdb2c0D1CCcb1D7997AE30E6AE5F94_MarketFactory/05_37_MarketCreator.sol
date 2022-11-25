//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/ITeamNFT.sol";
import "../interfaces/IMarketCreator.sol";

error MarketCreator_CannotRevokeOwner();

contract MarketCreator is
    IMarketCreator,
    Initializable,
    AccessControlUpgradeable
{
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    address public creatorOnwer;

    mapping(uint256 => address) public partners;

    function initialize(address creatorOnwer_) public initializer {
        __AccessControl_init();
        _setupRole(CONTROLLER_ROLE, msg.sender);

        creatorOnwer = creatorOnwer_;
        _setupRole(DEFAULT_ADMIN_ROLE, creatorOnwer_);
        _setupRole(CONTROLLER_ROLE, creatorOnwer_);

        // default partner is creator
        partners[0] = creatorOnwer_;
    }

    function setDefaultBeneficiary(address beneficiary_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        partners[0] = beneficiary_;
    }

    function addPartner(uint256 partnerId, address partnerAddress)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        partners[partnerId] = partnerAddress;
    }

    function removePartner(uint256 partnerId)
        external
        onlyRole(CONTROLLER_ROLE)
    {
        partners[partnerId] = address(0);
    }

    function isPartner(uint256 partnerId)
        public
        view
        returns (bool isCreator_)
    {
        isCreator_ = partners[partnerId] != address(0);
    }

    function getBeneficiary(uint256 partnerId) external view returns (address) {
        return isPartner(partnerId) ? partners[partnerId] : partners[0];
    }

    function hasControllerRole(address user) external view returns (bool) {
        return hasRole(CONTROLLER_ROLE, user);
    }

    function grantController(address user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(CONTROLLER_ROLE, user);
    }

    function revokeController(address user)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (user == creatorOnwer) revert MarketCreator_CannotRevokeOwner();
        _revokeRole(CONTROLLER_ROLE, user);
    }
}