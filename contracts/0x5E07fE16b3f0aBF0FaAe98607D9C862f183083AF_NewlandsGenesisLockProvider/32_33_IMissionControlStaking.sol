// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMissionControlStaking {
    struct Lockup {
        uint256 amount;
        uint256 lockedAt;
    }

    event TokenStaked(address tokenAddress, uint256 tokenId, uint256 amount, address user);

    event TokenUnstaked(address tokenAddress, uint256 tokenId, uint256 amount, address user);

    event TokensWhitelisted(address tokenAddress, uint256[] tokenIds);

    event UnstakeProviderSet(address tokenAddress, uint256[] tokenIds, address provider);

    /**
     * @notice This allows the user to stake a token Id from a particular contract
     * @param tokenAddress Address for the token
     * @param tokenId Id of token
     */
    function stakeNonFungible(
        address tokenAddress,
        uint256 tokenId,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to stake a token Id from a particular contract
     * @param tokenAddress Address for the token
     * @param tokenId Id of token
     * @param amount amount of the token th user would like to stake.
     */
    function stakeSemiFungible(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to stake multiple token Ids from a particular contract
     * @param tokenAddresses Address for the token
     * @param tokenIds Id of token
     */
    function stakeManyNonFungible(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to stake multiple token Ids from a particular contract
     * @param tokenAddresses Address for the token
     * @param tokenIds Id of token
     * @param amounts amount of the token th user would like to stake. 1 if ERC721
     */
    function stakeManySemiFungible(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to unstake a tokenId from a particular contract
     * @param tokenAddress Address for the token
     * @param tokenId Id of the staked token
     * @param amount amount of the token th user would like to unstake. 1 if ERC721
     */
    function unstake(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice This allows the user to unstake multiple token Ids from a particular contract
     * @param tokenAddresses Address for the token
     * @param tokenIds Id of token
     * @param amounts amount of the token th user would like to stake. 1 if ERC721
     */
    function unstakeMany(
        address[] memory tokenAddresses,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 relayerFee
    ) external payable;

    /**
     * @notice Allows admin to whitelist a set of tokenIds for staking
     * @param tokenAddress Address for the token
     * @param tokenIds List of ids to be whitelisted
     */
    function whitelistTokens(
        address tokenAddress,
        uint256[] memory tokenIds,
        bool isWhitelisted
    ) external;

    /**
     * @notice Allows admin to add logic for what happens when a user unstakes a set of tokenIds
     * @param tokenAddress Address for the token
     * @param tokenIds Id of the staked token
     * @param provider logic contract to handle all unstake events involving the tokenIds in the array. should implement IUnlockProvider
     */
    function setUnstakeProvider(
        address tokenAddress,
        uint256[] memory tokenIds,
        address provider
    ) external;

    /**
     * @notice View function for checking how much of a particular token a user has staked.
     * @param tokenAddress Address for the token
     * @param tokenId Id of the staked token
     */
    function getUserStakedBalance(
        address user,
        address tokenAddress,
        uint256 tokenId
    ) external view returns (uint256);
}