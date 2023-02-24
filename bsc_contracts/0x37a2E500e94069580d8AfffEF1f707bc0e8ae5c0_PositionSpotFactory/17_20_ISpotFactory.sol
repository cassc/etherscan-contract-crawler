// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface ISpotFactory {
    event PairManagerInitialized(
        address quoteAsset,
        address baseAsset,
        uint256 basisPoint,
        uint128 maxFindingWordsIndex,
        uint128 initialPip,
        address owner,
        address pairManager,
        uint256 pipRange,
        uint256 tickSpace
    );

    event StakingForPairAdded(
        address pairManager,
        address stakingAddress,
        address ownerOfPair
    );

    struct Pair {
        address BaseAsset;
        address QuoteAsset;
    }

    /// @notice create new pair for dex
    /// @param quoteAsset address of quote asset
    /// @param baseAsset address of base asset
    /// @param basisPoint the basis point for pip and price
    /// @param maxFindingWordsIndex the max word can finding
    /// @param initialPip the pip start of the pair
    /// @param pipRange the range of liquidity index
    /// @param tickSpace tick space for generate orderbook
    function createPairManager(
        address quoteAsset,
        address baseAsset,
        uint256 basisPoint,
        uint128 maxFindingWordsIndex,
        uint128 initialPip,
        uint128 pipRange,
        uint32 tickSpace
    ) external;

    /// @notice get pair manager address
    /// @param quoteAsset the address of quote asset
    /// @param baseAsset the address of base asset
    /// @return pairManager the address of pair manager
    function getPairManager(address quoteAsset, address baseAsset)
        external
        view
        returns (address pairManager);

    /// @notice get the quote asset and base asset
    /// @param pairManager the address of pair
    /// @return struct of quote and base
    function getQuoteAndBase(address pairManager)
        external
        view
        returns (Pair memory);

    /// @notice check pair manager is exist
    /// @param pairManager the address of pair
    /// @return true if exist, false if not exist
    function isPairManagerExist(address pairManager)
        external
        view
        returns (bool);

    /// @notice check pair and assets is supported with random two token
    /// @param tokenA the first token
    /// @param tokenB the second token
    /// @return baseToken the address of base token
    /// @return quoteToken the address of quote token
    /// @return pairManager the address of pair
    function getPairManagerSupported(address tokenA, address tokenB)
        external
        view
        returns (
            address baseToken,
            address quoteToken,
            address pairManager
        );

    /// @notice get staking manager of pair
    /// @param owner the owner of pair
    /// @param pair the address of pair
    /// @return the address of contract staking manager
    function stakingManagerOfPair(address owner, address pair)
        external
        view
        returns (address);

    /// @notice get owner of pair
    /// @param pair the address of pair
    /// @return address owner of pair
    function ownerPairManager(address pair) external view returns (address);

    /// @notice fee share for liquidity provider
    /// @return the rate share
    function feeShareAmm() external view returns(uint32);
}