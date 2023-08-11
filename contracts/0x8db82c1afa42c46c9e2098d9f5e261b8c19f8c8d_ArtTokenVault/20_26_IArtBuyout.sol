//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum BuyoutStatus {
    IN_PROGRESS,
    SUCCESSFUL,
    UNSUCCESSFUL
}

interface IArtBuyout {
    function initialize(
        address buyer,
        IERC20Upgradeable _tokenAT,
        uint256 _endTimestamp,
        uint256 _successVoteThreshold,
        IERC20 _tokenBT,
        uint256 _amountBT
    ) external;

    function voteFor() external;

    function claimBuyoutShare() external;

    function refundVote() external;

    function buyer() external view returns(address);

    function status() external view returns(BuyoutStatus);
}