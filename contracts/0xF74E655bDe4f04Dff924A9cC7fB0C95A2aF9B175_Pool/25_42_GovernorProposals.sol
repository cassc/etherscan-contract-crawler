// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./Governor.sol";
import "./GovernanceSettings.sol";
import "../interfaces/IPool.sol";
import "../interfaces/governor/IGovernorProposals.sol";
import "../interfaces/IService.sol";
import "../interfaces/registry/IRecordsRegistry.sol";
import "../interfaces/ITGE.sol";
import "../interfaces/IToken.sol";
import "../interfaces/ICustomProposal.sol";
import "../libraries/ExceptionsLibrary.sol";

abstract contract GovernorProposals is
    Initializable,
    Governor,
    GovernanceSettings,
    IGovernorProposals
{
    // STORAGE

    /// @dev Service address
    IService public service;

    /// @dev last Proposal Id By Type for state checking
    mapping(uint256 => uint256) public lastProposalIdByType;

    /// @notice Proposal Type
    enum ProposalType {
        Transfer,
        TGE,
        GovernanceSettings
        // 3 - PoolSecretary
        // 4 - CustomTx
        // 5 - PoolExecutor
    }

    /// @notice Storage gap (for future upgrades)
    uint256[49] private __gap;
}