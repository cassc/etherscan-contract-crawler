// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PRTCLBaseGovernor.sol";
import "./IPRTCLVotes.sol";

/**
 * @dev Extension of {PRTCLBaseGovernor} for voting weight extraction from an {IPRTCLCoreERC721Votes} token.
 *
 * @author Particle Collection - valdi.eth
 */
abstract contract PRTCLGovernorVotes is PRTCLBaseGovernor {
    IPRTCLVotes public immutable votesToken;

    constructor(IPRTCLVotes tokenAddress) {
        votesToken = tokenAddress;
    }

    /**
     * Read the voting weight for collection passed in `params` from the token's built in snapshot 
     * mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        uint256 collectionId
    ) internal view virtual override returns (uint256) {
        return votesToken.getPastVotes(account, blockNumber, collectionId);
    }
}