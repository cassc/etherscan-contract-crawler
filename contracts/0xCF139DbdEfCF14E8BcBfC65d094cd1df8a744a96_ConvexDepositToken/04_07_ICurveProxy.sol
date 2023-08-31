// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICurveProxy {
    struct GaugeWeightVote {
        address gauge;
        uint256 weight;
    }

    struct TokenBalance {
        address token;
        uint256 amount;
    }

    event CrvFeePctSet(uint256 feePct);

    function approveGaugeDeposit(address gauge, address depositor) external returns (bool);

    function claimFees() external returns (uint256);

    function execute(address target, bytes calldata data) external returns (bytes memory);

    function lockCRV() external returns (bool);

    function mintCRV(address gauge, address receiver) external returns (uint256);

    function setCrvFeePct(uint64 _feePct) external returns (bool);

    function setDepositManager(address _depositManager) external returns (bool);

    function setExecutePermissions(
        address caller,
        address target,
        bytes4[] calldata selectors,
        bool permitted
    ) external returns (bool);

    function setGaugeRewardsReceiver(address gauge, address receiver) external returns (bool);

    function setPerGaugeApproval(address caller, address gauge) external returns (bool);

    function setVoteManager(address _voteManager) external returns (bool);

    function transferTokens(address receiver, TokenBalance[] calldata balances) external returns (bool);

    function voteForGaugeWeights(GaugeWeightVote[] calldata votes) external returns (bool);

    function voteInCurveDao(address aragon, uint256 id, bool support) external returns (bool);

    function withdrawFromGauge(
        address gauge,
        address lpToken,
        uint256 amount,
        address receiver
    ) external returns (bool);

    function CRV() external view returns (address);

    function PRISMA_CORE() external view returns (address);

    function crvFeePct() external view returns (uint64);

    function depositManager() external view returns (address);

    function feeDistributor() external view returns (address);

    function feeToken() external view returns (address);

    function gaugeController() external view returns (address);

    function guardian() external view returns (address);

    function minter() external view returns (address);

    function owner() external view returns (address);

    function perGaugeApproval(address caller) external view returns (address gauge);

    function unlockTime() external view returns (uint64);

    function voteManager() external view returns (address);

    function votingEscrow() external view returns (address);
}