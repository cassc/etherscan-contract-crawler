// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../dependencies/yoga-labs/ApeCoinStaking.sol";

/**
 * @title IPoolApeStaking
 *
 * @notice Defines the basic interface for an ParaSpace Ape Staking Pool.
 **/
interface IPoolApeStaking {
    struct StakingInfo {
        // Contract address of BAYC/MAYC
        address nftAsset;
        // address of borrowing asset, can be Ape or cApe
        address borrowAsset;
        // Borrow amount of Ape from lending pool
        uint256 borrowAmount;
        // Cash amount of Ape from user wallet
        uint256 cashAmount;
    }

    /**
     * @notice Deposit ape coin to BAYC/MAYC pool or BAKC pool
     * @param stakingInfo Detail info of the staking
     * @param _nfts Array of BAYC/MAYC NFT's with staked amounts
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's with staked amounts
     * @dev Need check User health factor > 1.
     */
    function borrowApeAndStake(
        StakingInfo calldata stakingInfo,
        ApeCoinStaking.SingleNft[] calldata _nfts,
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external;

    /**
     * @notice Withdraw staked ApeCoin from the BAYC/MAYC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nfts Array of BAYC/MAYC NFT's with staked amounts
     * @dev Need check User health factor > 1.
     */
    function withdrawApeCoin(
        address nftAsset,
        ApeCoinStaking.SingleNft[] calldata _nfts
    ) external;

    /**
     * @notice Claim rewards for array of tokenIds from the BAYC/MAYC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @dev Need check User health factor > 1.
     */
    function claimApeCoin(address nftAsset, uint256[] calldata _nfts) external;

    /**
     * @notice Withdraw staked ApeCoin from the BAKC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's with staked amounts
     * @dev Need check User health factor > 1.
     */
    function withdrawBAKC(
        address nftAsset,
        ApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs
    ) external;

    /**
     * @notice Claim rewards for array of tokenIds from the BAYC/MAYC pool
     * @param nftAsset Contract address of BAYC/MAYC
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's
     * @dev Need check User health factor > 1.
     */
    function claimBAKC(
        address nftAsset,
        ApeCoinStaking.PairNft[] calldata _nftPairs
    ) external;

    /**
     * @notice Unstake user Ape coin staking position and repay user debt
     * @param nftAsset Contract address of BAYC/MAYC
     * @param tokenId Token id of the ape staking position on
     * @dev Need check User health factor > 1.
     */
    function unstakeApePositionAndRepay(address nftAsset, uint256 tokenId)
        external;

    /**
     * @notice repay asset and supply asset for user
     * @param underlyingAsset Contract address of BAYC/MAYC
     * @param onBehalfOf The beneficiary of the repay and supply
     * @dev Convenient callback function for unstakeApePositionAndRepay. Only NToken of BAYC/MAYC can call this.
     */
    function repayAndSupply(
        address underlyingAsset,
        address onBehalfOf,
        uint256 totalAmount
    ) external;

    /**
     * @notice Claim user Ape coin reward and deposit to ape compound to get cApe, then deposit cApe to Lending pool for user
     * @param nftAsset Contract address of BAYC/MAYC
     * @param users array of user address
     * @param tokenIds array of user tokenId array
     */
    function claimApeAndCompound(
        address nftAsset,
        address[] calldata users,
        uint256[][] calldata tokenIds
    ) external;

    /**
     * @notice Claim user BAKC paired Ape coin reward and deposit to ape compound to get cApe, then deposit cApe to Lending pool for user
     * @param nftAsset Contract address of BAYC/MAYC
     * @param users array of user address
     * @param _nftPairs Array of Paired BAYC/MAYC NFT's
     */
    function claimPairedApeAndCompound(
        address nftAsset,
        address[] calldata users,
        ApeCoinStaking.PairNft[][] calldata _nftPairs
    ) external;

    /**
     * @notice get current incentive fee rate for claiming ape position reward to compound
     */
    function getApeCompoundFeeRate() external returns (uint256);
}