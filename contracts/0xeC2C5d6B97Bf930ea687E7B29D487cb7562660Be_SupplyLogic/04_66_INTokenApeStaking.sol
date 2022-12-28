// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import "../dependencies/yoga-labs/ApeCoinStaking.sol";
import "./INToken.sol";

interface INTokenApeStaking {
    function getBAKC() external view returns (IERC721);

    function getApeStaking() external view returns (ApeCoinStaking);

    function depositApeCoin(ApeCoinStaking.SingleNft[] calldata _nfts) external;

    function claimApeCoin(uint256[] calldata _nfts, address _recipient)
        external;

    function withdrawApeCoin(
        ApeCoinStaking.SingleNft[] calldata _nfts,
        address _recipient
    ) external;

    function depositBAKC(
        ApeCoinStaking.PairNftDepositWithAmount[] calldata _nftPairs
    ) external;

    function claimBAKC(
        ApeCoinStaking.PairNft[] calldata _nftPairs,
        address _recipient
    ) external;

    function withdrawBAKC(
        ApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs,
        address _apeRecipient
    ) external;

    function unstakePositionAndRepay(uint256 tokenId, address unstaker)
        external;

    function getUserApeStakingAmount(address user)
        external
        view
        returns (uint256);
}