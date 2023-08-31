// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Non Escrow Staking
contract NES {
    // This is an optional reference to an external contract allows
    // you to abstract away your staking interface to another contract.
    // if this variable is set, stake / unstake can only be called from
    // the stakingController if it is not set stake / unstake can be called
    // directly on the implementing contract.
    address public stakingController;

    // Event published when a token is staked.
    event Locked(uint256 tokenId);
    // Event published when a token is unstaked.
    event Unlocked(uint256 tokenId);

    // Mapping of tokenId storing its staked status
    mapping(uint256 => bool) public tokenToIsStaked;

    /**
     *  @dev sets stakingController, scope of this method is internal, so this defaults
     *  to requiring setting the staking controller contact upon deployment or requires
     *  a public OnlyOwner helper method to be exposed in the implementing contract.
     */
    function _setStakingController(address _stakingController) internal {
        stakingController = _stakingController;
    }

    /**
     *  @dev returns whether a token is currently staked
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        return tokenToIsStaked[tokenId];
    }

    /**
     *  @dev marks a token as staked, calling this function
     *  you disable the ability to transfer the token.
     */
    function _stake(uint256 tokenId) internal {
        require(!isStaked(tokenId), "token is already staked");

        tokenToIsStaked[tokenId] = true;
        emit Locked(tokenId);
    }

    /**
     *  @dev marks a token as unstaked. By calling this function
     *  you re-enable the ability to transfer the token.
     */
    function _unstake(uint256 tokenId) internal {
        require(isStaked(tokenId), "token isn't staked");

        tokenToIsStaked[tokenId] = false;
        emit Unlocked(tokenId);
    }
}