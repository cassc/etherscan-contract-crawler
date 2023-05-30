// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMoneyMakingOpportunity {
    function unlock(address _uriContract) external;
    function claim() external;
    function castVote(uint256 tokenId, uint256 week, bool vote) external;
    function proposeSettlementAddress(uint256 week, address settlementAddress) external;
    function settlePayment() external;
    function calculateVotes(uint256 week) external view returns (uint256, uint256);
    function tokenIdToWeek(uint256 tokenId) external view returns (uint256);
    function weekToTokenId(uint256 week) external view returns (uint256);
    function currentWeek() external view returns (uint256);
    function isEliminated(uint256 tokenId) external view returns (bool);
    function setTokenURIContract(address _uriContract) external;
    function updateTokenURI(uint256 tokenId) external;
    function batchUpdateTokenURI(uint256 from, uint256 to) external;
    function lockURI() external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}