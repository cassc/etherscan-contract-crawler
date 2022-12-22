// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";

interface IDispatcher {
    // Directory
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        PreferenceToken,
        TGE
    }

    enum EventType {
        None,
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings
    }

    function addContractRecord(address addr, ContractType contractType, string memory description)
        external
        returns (uint256 index);

    function addProposalRecord(address pool, uint256 proposalId)
        external
        returns (uint256 index);

    function addEventRecord(address pool, EventType eventType, uint256 proposalId, string calldata metaHash)
        external
        returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);

    // Metadata
    enum Status {
        NotUsed,
        Used
    }

    struct QueueInfo {
        uint256 jurisdiction;
        string EIN;
        string dateOfIncorporation;
        uint256 entityType;
        Status status;
        address pool;
        uint256 fee;
    }

    function initialize() external;

    function service() external view returns (address);

    function lockRecord(uint256 jurisdiction, uint256 entityType) external returns (address, uint256);

    // WhitelistedTokens
    function tokenWhitelist() external view returns (address[] memory);

    function isTokenWhitelisted(address token) external view returns (bool);

    function tokenSwapPath(address) external view returns (bytes memory);

    function tokenSwapReversePath(address) external view returns (bytes memory);

    // ProposalGateway
    enum ProposalType {
        None,
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings
    }

    function validateTGEInfo(
        ITGE.TGEInfo calldata info, 
        IToken.TokenType tokenType, 
        uint256 cap, 
        uint256 totalSupply
    ) external view returns (bool);

    function validateBallotParams(
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        uint256 ballotLifespan,
        uint256[10] calldata ballotExecDelay
    ) external pure returns (bool);
}