// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

/**
 * @title Affiliate Registry Interface
 * @dev   Interface with necessary functionalities of Affiliate Registry.
 * @author Chain Labs Team
 */
interface IAffiliateRegistry {
    function setAffiliateShares(uint256 _affiliateShares, bytes32 _projectId)
        external;

    function registerProject(string memory projectName, uint256 affiliateShares)
        external
        returns (bytes32 projectId);

    function getProjectId(string memory _projectName, address _projectOwner)
        external
        view
        returns (bytes32 projectId);

    function getAffiliateShareValue(
        bytes memory signature,
        address affiliate,
        bytes32 projectId,
        uint256 value
    ) external view returns (bool _isAffiliate, uint256 _shareValue);
}