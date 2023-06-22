// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ERC721 Pool Immutables
 */
interface IERC721PoolImmutables{

    /**
     *  @notice Returns the type of `NFT` pool.
     *  @return `True` if `NTF` pool is a subset pool.
     */
    function isSubset() external view returns (bool);

}