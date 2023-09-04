// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./registry/ICompaniesRegistry.sol";

import "./governor/IGovernor.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(
        ICompaniesRegistry.CompanyInfo memory companyInfo_
    ) external;

    function setNewOwnerWithSettings(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_
    ) external;

    function propose(
        address proposer,
        uint256 proposalType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId);

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function setProposalIdToTGE(address tge) external;

    function cancelProposal(uint256 proposalId) external;

    function setSettings(
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_,
        address[] memory secretary,
        address[] memory executor
    ) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function getGovernanceToken() external view returns (IToken);

    function tokenExists(IToken token_) external view returns (bool);

    function tokenTypeByAddress(
        address token_
    ) external view returns (IToken.TokenType);

    function isValidProposer(address account) external view returns (bool);

    function isPoolSecretary(address account) external view returns (bool);

    function isLastProposalIdByTypeActive(
        uint256 type_
    ) external view returns (bool);

    function validateGovernanceSettings(
        IGovernanceSettings.NewGovernanceSettings memory settings
    ) external pure;

    function getPoolSecretary() external view returns (address[] memory);

    function getPoolExecutor() external view returns (address[] memory);

    function setCompanyInfo(
        uint256 _fee,
        uint256 _jurisdiction,
        uint256 _entityType,
        string memory _ein,
        string memory _dateOfIncorporation,
        string memory _OAuri
    ) external;

    function castVote(uint256 proposalId, bool support) external;

    function executeProposal(uint256 proposalId) external;

    function getCompanyFee() external returns (uint256);
}