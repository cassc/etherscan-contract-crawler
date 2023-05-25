// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IIntegralStaking {
    event StopIssuance(uint32 stopBlock);
    event Deposit(address user, uint256 stakeId, uint96 amount);
    event WithdrawAll(address user, uint96 amount, address to);
    event Withdraw(address user, uint256 stakeId, uint96 amount, address to);
    event ClaimAll(address user, uint96 amount, address to);
    event Claim(address user, uint256 stakeId, uint96 amount, address to);

    struct UserStake {
        uint32 startBlock;
        uint32 claimedBlock;
        uint96 lockedAmount;
        bool withdrawn;
    }

    function getUserStakes(address _user) external view returns (UserStake[] memory);

    function owner() external view returns (address);

    function integralToken() external view returns (address);

    function durationInBlocks() external view returns (uint32);

    function stopBlock() external view returns (uint32);

    function ratePerBlockNumerator() external view returns (uint32);

    function ratePerBlockDenominator() external view returns (uint32);

    function setOwner(address _owner) external;

    function stopIssuance(uint32 _stopBlock) external;

    function deposit(uint96 _amount) external returns (uint256 stakeId);

    function withdrawAll(address _to) external;

    function withdraw(uint256 _stakeId, address _to) external;

    function claimAll(address _to) external;

    function claim(uint256 _stakeId, address _to) external;

    function getAllClaimable(address _user) external view returns (uint96 claimableAmount);

    function getClaimable(address _user, uint256 _stakeId) external view returns (uint96 claimableAmount);
}