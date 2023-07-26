// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;
import {IApeCoinStaking} from "../interfaces/IApeCoinStaking.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library ApeStakingLib {
    uint256 internal constant APE_COIN_PRECISION = 1e18;
    uint256 internal constant SECONDS_PER_HOUR = 3600;
    uint256 internal constant SECONDS_PER_MINUTE = 60;

    uint256 internal constant APE_COIN_POOL_ID = 0;
    uint256 internal constant BAYC_POOL_ID = 1;
    uint256 internal constant MAYC_POOL_ID = 2;
    uint256 internal constant BAKC_POOL_ID = 3;

    function getCurrentTimeRange(
        IApeCoinStaking apeCoinStaking_,
        uint256 poolId
    ) internal view returns (IApeCoinStaking.TimeRange memory) {
        (
            IApeCoinStaking.PoolUI memory apeCoinPoolUI,
            IApeCoinStaking.PoolUI memory baycPoolUI,
            IApeCoinStaking.PoolUI memory maycPoolUI,
            IApeCoinStaking.PoolUI memory bakcPoolUI
        ) = apeCoinStaking_.getPoolsUI();

        if (poolId == apeCoinPoolUI.poolId) {
            return apeCoinPoolUI.currentTimeRange;
        }

        if (poolId == baycPoolUI.poolId) {
            return baycPoolUI.currentTimeRange;
        }

        if (poolId == maycPoolUI.poolId) {
            return maycPoolUI.currentTimeRange;
        }
        if (poolId == bakcPoolUI.poolId) {
            return bakcPoolUI.currentTimeRange;
        }

        revert("invalid pool id");
    }

    function getNftPoolId(IApeCoinStaking apeCoinStaking_, address nft_) internal view returns (uint256) {
        if (nft_ == apeCoinStaking_.nftContracts(BAYC_POOL_ID)) {
            return BAYC_POOL_ID;
        }

        if (nft_ == apeCoinStaking_.nftContracts(MAYC_POOL_ID)) {
            return MAYC_POOL_ID;
        }
        if (nft_ == apeCoinStaking_.nftContracts(BAKC_POOL_ID)) {
            return BAKC_POOL_ID;
        }
        revert("invalid nft");
    }

    function getNftPosition(
        IApeCoinStaking apeCoinStaking_,
        address nft_,
        uint256 tokenId_
    ) internal view returns (IApeCoinStaking.Position memory) {
        return apeCoinStaking_.nftPosition(getNftPoolId(apeCoinStaking_, nft_), tokenId_);
    }

    function getNftPool(
        IApeCoinStaking apeCoinStaking_,
        address nft_
    ) internal view returns (IApeCoinStaking.PoolWithoutTimeRange memory) {
        return apeCoinStaking_.pools(getNftPoolId(apeCoinStaking_, nft_));
    }

    function getNftRewardsBy(
        IApeCoinStaking apeCoinStaking_,
        address nft_,
        uint256 from_,
        uint256 to_
    ) internal view returns (uint256, uint256) {
        return apeCoinStaking_.rewardsBy(getNftPoolId(apeCoinStaking_, nft_), from_, to_);
    }

    function bayc(IApeCoinStaking apeCoinStaking_) internal view returns (IERC721) {
        return IERC721(apeCoinStaking_.nftContracts(BAYC_POOL_ID));
    }

    function mayc(IApeCoinStaking apeCoinStaking_) internal view returns (IERC721) {
        return IERC721(apeCoinStaking_.nftContracts(MAYC_POOL_ID));
    }

    function bakc(IApeCoinStaking apeCoinStaking_) internal view returns (IERC721) {
        return IERC721(apeCoinStaking_.nftContracts(BAKC_POOL_ID));
    }

    function getPreviousTimestampHour() internal view returns (uint256) {
        return block.timestamp - (getMinute(block.timestamp) * 60 + getSecond(block.timestamp));
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    /// @notice the seconds (0 to 59) of a timestamp
    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }
}