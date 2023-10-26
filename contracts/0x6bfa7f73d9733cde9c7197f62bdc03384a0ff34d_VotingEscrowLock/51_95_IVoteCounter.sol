//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IVoteCounter {
    function getVotes(uint256 votingRightId, uint256 timestamp)
        external
        view
        returns (uint256);

    function voterOf(uint256 votingRightId) external view returns (address);

    function votingRights(address voter)
        external
        view
        returns (uint256[] memory rights);

    function getTotalVotes() external view returns (uint256);
}