// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface to react on staking and unstaking on the ZiggyverseStakerPotERC721.
 */
interface IZiggyverseStakerPotERC721Listener {

    /**
     * @dev Hook to act on staking tokens.
     * @param from the address the staked token was transfered from
     * @param to the address the staking-receipt token was minted to
     * @param tokenIds the tokenIds of the tokens beeing staked
     */
    function afterTokenStake(address from, address to, uint256[] memory tokenIds) external;

    /**
     * @dev Hook to act on unstaking tokens.
     * @param from the address the staking-receipt token was burned from
     * @param to the address the staking token was transfered back to
     * @param tokenIds the tokenIds of the tokens beeing unstaked
     */
    function afterTokenUnstake(address from, address to, uint256[] memory tokenIds) external;
}