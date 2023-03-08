// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import {ApeCoinStaking} from "../../dependencies/yoga-labs/ApeCoinStaking.sol";
import {NTokenApeStaking} from "./NTokenApeStaking.sol";
import {IPool} from "../../interfaces/IPool.sol";
import {XTokenType} from "../../interfaces/IXTokenType.sol";
import {ApeStakingLogic} from "./libraries/ApeStakingLogic.sol";

/**
 * @title MAYC NToken
 *
 * @notice Implementation of the NToken for the ParaSpace protocol
 */
contract NTokenMAYC is NTokenApeStaking {
    constructor(IPool pool, address apeCoinStaking)
        NTokenApeStaking(pool, apeCoinStaking)
    {}

    /**
     * @notice Deposit ApeCoin to the MAYC Pool
     * @param _nfts Array of SingleNft structs
     * @dev Commits 1 or more MAYC NFTs, each with an ApeCoin amount to the MAYC pool.\
     * Each MAYC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the MAYC pool cap amount.
     */
    function depositApeCoin(ApeCoinStaking.SingleNft[] calldata _nfts)
        external
        onlyPool
        nonReentrant
    {
        _apeCoinStaking.depositMAYC(_nfts);
    }

    /**
     * @notice Claim rewards for array of MAYC NFTs and send to recipient
     * @param _nfts Array of NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimApeCoin(uint256[] calldata _nfts, address _recipient)
        external
        onlyPool
        nonReentrant
    {
        _apeCoinStaking.claimMAYC(_nfts, _recipient);
    }

    /**
     * @notice Withdraw staked ApeCoin from the MAYC pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nfts Array of MAYC NFT's with staked amounts
     * @param _recipient Address to send withdraw amount and claim to
     */
    function withdrawApeCoin(
        ApeCoinStaking.SingleNft[] calldata _nfts,
        address _recipient
    ) external onlyPool nonReentrant {
        _apeCoinStaking.withdrawMAYC(_nfts, _recipient);
    }

    /**
     * @notice Deposit ApeCoin to the Pair Pool, where Pair = (MAYC + BAKC)
     * @param _nftPairs Array of PairNftWithAmount structs
     * @dev Commits 1 or more Pairs, each with an ApeCoin amount to the Pair pool.\
     * Each BAKC committed must attach an ApeCoin amount >= 1 ApeCoin and <= the Pair pool cap amount.\
     * Example: MAYC + BAKC + 1 ApeCoin:  [[0, 0, "1000000000000000000"]]\
     */
    function depositBAKC(
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external onlyPool nonReentrant {
        _apeCoinStaking.depositBAKC(
            new ApeCoinStaking.PairNftDepositWithAmount[](0),
            _nftPairs
        );
    }

    /**
     * @notice Claim rewards for array of Paired NFTs and send to recipient
     * @param _nftPairs Array of Paired MAYC NFTs owned and committed by the msg.sender
     * @param _recipient Address to send claim reward to
     */
    function claimBAKC(
        ApeCoinStaking.PairNft[] calldata _nftPairs,
        address _recipient
    ) external onlyPool nonReentrant {
        _apeCoinStaking.claimBAKC(
            new ApeCoinStaking.PairNft[](0),
            _nftPairs,
            _recipient
        );
    }

    /**
     * @notice Withdraw staked ApeCoin from the Pair pool.  If withdraw is total staked amount, performs an automatic claim.
     * @param _nftPairs Array of Paired MAYC NFT's with staked amounts
     * @dev if pairs have split ownership and BAKC is attempting a withdraw, the withdraw must be for the total staked amount
     */
    function withdrawBAKC(
        ApeCoinStaking.PairNftWithdrawWithAmount[] calldata _nftPairs,
        address _apeRecipient
    ) external onlyPool nonReentrant {
        ApeStakingLogic.withdrawBAKC(
            _apeCoinStaking,
            POOL_ID(),
            _nftPairs,
            _apeRecipient
        );
    }

    function POOL_ID() internal pure virtual override returns (uint256) {
        return ApeStakingLogic.MAYC_POOL_ID;
    }

    function getXTokenType() external pure override returns (XTokenType) {
        return XTokenType.NTokenMAYC;
    }
}