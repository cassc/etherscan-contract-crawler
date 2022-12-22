// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
    @title Interface to be used with handlers that support ERC20s and ERC721s.
    @author Router Protocol.
 */
interface IVoterUpgradeable {

    enum ProposalStatus { Inactive, Active, Passed, Executed, Cancelled }

    struct issueStruct {
        ProposalStatus status;
        uint256 startBlock;
        uint256 endBlock;
        uint64 quorum;
        uint256 maxVotes;
        uint8 resultOption;
    }

    function Voted(uint256, address) external view returns (bool);

    function mint(address) external;

    function burn(address account) external;
    
    function balanceOf(address) external view returns (uint256);

    function fetchIssueMap(uint256 _issue) external view returns (issueStruct memory issue);

    function fetchIsExpired(uint256 _issue) external view returns (bool status);

    function createProposal(uint256 endBlock, uint64 quorum)
        external
        returns (uint256 id);

    function setStatus(uint256 issueId) external  returns (bool success);
    function getStatus(uint256 issueId) external view returns (ProposalStatus status);
     function vote(
        uint256 issueId,
        uint8 option,
        address relayer
    )
        external
        returns (bool success);
    
    function executeProposal(uint256 issueId) external returns (bool success);
}