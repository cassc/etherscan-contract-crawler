// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./IAffiliateRegistry.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Affiliate
 * @dev   Contract that can be inherited to make any contract interact with AffiliateRegistry.
 * @author Chain Labs Team
 */
contract Affiliate {
    IAffiliateRegistry private _affiliateRegistry;
    bytes32 private _projectId;

    event AffiliateShareTransferred(
        address indexed affiliate,
        bytes32 indexed project,
        uint256 value
    );

    function getAffiliateRegistry() public view returns (IAffiliateRegistry) {
        return _affiliateRegistry;
    }

    function getProjectId() public view returns (bytes32) {
        return _projectId;
    }

    function _setAffiliateModule(
        IAffiliateRegistry newRegistry,
        bytes32 projectId
    ) internal {
        require(
            address(newRegistry) != address(0),
            "Affiliate: Registry cannot be null address"
        );
        require(projectId != bytes32(0), "Affiliate: zero project id");
        _affiliateRegistry = newRegistry;
        _projectId = projectId;
    }

    function _setProjectId(bytes32 projectId) internal {
        require(projectId != bytes32(0), "Affiliate: zero project id");
        _projectId = projectId;
    }

    function _transferAffiliateShare(
        bytes memory signature,
        address affiliate,
        uint256 value
    ) internal {
        require(_isAffiliateModuleInitialised(), "Affiliate: not initialised");
        bool isAffiliate;
        uint256 shareValue;
        (isAffiliate, shareValue) = _affiliateRegistry.getAffiliateShareValue(
            signature,
            affiliate,
            _projectId,
            value
        );
        if (isAffiliate) {
            Address.sendValue(payable(affiliate), shareValue);
            emit AffiliateShareTransferred(affiliate, _projectId, shareValue);
        }
    }

    function _isAffiliateModuleInitialised() internal view returns (bool) {
        return
            _projectId != bytes32(0) &&
            address(_affiliateRegistry) != address(0);
    }
}