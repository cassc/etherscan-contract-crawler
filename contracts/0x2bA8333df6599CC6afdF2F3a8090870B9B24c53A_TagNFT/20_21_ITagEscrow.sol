//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface ITagEscrow {

    struct DepositAsset {
        IERC20 currency;
        uint256 amount;
    }

    function createEscrow(
        address partyA,
        address partyB,
        address partyArbitrator,
        string memory description,
        uint256 determineTime
    ) external returns (uint256);

    function depositFunds(
        uint256 escrowId,
        ERC20 currency,
        uint256 amount
    ) external payable;

    function determineOutcome(
        uint256 escrowId,
        bool partyAWon
    ) external payable;

    function transferRightToCollect(
        uint256 escrowId,
        uint256 nftTokenId,
        address newOwner
    ) external;

    function escrows(uint256 id)
    external
    view
    returns (
        uint256 escrowId,
        address partyA,
        address partyB,
        uint256 nftA,
        uint256 nftB,
        address partyArbitrator,
        uint256 arbitratorFeeBps,
        string memory description,
        uint256 createTime,
        uint256 determineTime,
        bool started,
        bool closed,
        DepositAsset memory pendingAssetB,
        address winner
    );
}