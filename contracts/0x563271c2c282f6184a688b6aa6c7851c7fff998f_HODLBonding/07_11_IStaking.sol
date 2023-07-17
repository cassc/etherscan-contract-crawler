// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IStaking {
    function add(
        uint8 _isInputNFT,
        uint8 _isVested,
        uint256 _allocPoint,
        address _input,
        uint256 _startIdx,
        uint256 _endIdx
    ) external;

    function canWithdraw(uint8 _lid, address _user) external view returns (bool);

    function claimReward(uint256 _pid) external;

    function deposit(uint256 _pid, uint8 _lid, address _benificiary, uint256[] memory _amounts) external;

    function feeWallet() external view returns (address);

    function getDepositedIdsOfUser(uint256 _pid, address _user) external view returns (uint256[] memory);

    function getRewardPerBlock() external view returns (uint256 rpb);

    function massUpdatePools() external;

    function onERC721Received(address, address, uint256, bytes memory) external returns (bytes4);

    function owner() external view returns (address);

    function pendingTkn(uint256 _pid, address _user) external view returns (uint256);

    function percPerDay() external view returns (uint16);

    function poolInfo(
        uint256
    )
        external
        view
        returns (
            uint8 isInputNFT,
            uint8 isVested,
            uint32 totalInvestors,
            address input,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTknPerShare,
            uint256 startIdx,
            uint256 endIdx,
            uint256 totalDeposit
        );

    function poolLength() external view returns (uint256);

    function poolLockInfo(uint256) external view returns (uint32 multi, uint32 claimFee, uint32 lockPeriodInSeconds);

    function renounceOwnership() external;

    function reward() external view returns (address);

    function rewardWallet() external view returns (address);

    function set(uint256 _pid, uint256 _allocPoint, uint8 _isVested, uint256 _startIdx, uint256 _endIdx) external;

    function setPercentagePerDay(uint16 _perc) external;

    function setPoolLock(uint256 _lid, uint32 _multi, uint32 _claimFee, uint32 _lockPeriod) external;

    function setVesting(address _vesting) external;

    function setWallets(address _reward, address _feeWallet) external;

    function startBlock() external view returns (uint256);

    function totalActualDeposit() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _pid) external;

    function userInfo(
        uint256,
        address
    ) external view returns (uint256 totalDeposit, uint256 rewardDebt, uint256 totalClaimed, uint256 depositTime);

    function userLockInfo(uint8, address) external view returns (uint256 totalActualDeposit, uint256 depositTime);

    function vestingCont() external view returns (address);

    function withdraw(uint256 _pid, uint8 _lid, uint256[] memory _amounts) external;
}