// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IService.sol";
import "./IToken.sol";
import "./IDispatcher.sol";

interface IPool {
    function initialize(
        uint256 jurisdiction_,
        string memory EIN_,
        string memory dateOfIncorporation,
        uint256 entityType,
        uint256 metadataIndex
    ) external;

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay
    ) external;

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash
    ) external returns (uint256 proposalId);

    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) external returns (uint256 proposalId);

    function setLastProposalIdForAccount(address creator, uint256 proposalId) external;

    function serviceCancelBallot(uint256 proposalId) external;

    function getTVL() external returns (uint256);

    function owner() external view returns (address);

    function service() external view returns (IService);

    function maxProposalId() external view returns (uint256);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function ballotExecDelay(uint256 _index) external view returns (uint256);

    function paused() external view returns (bool);

    function launch(
        address owner_,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        string memory trademark
    ) external;

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function tokens(IToken.TokenType tokenType_) external view returns (IToken);
}