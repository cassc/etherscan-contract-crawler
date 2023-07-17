// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILockingPositionService {
    struct LockingPosition {
        uint96 startCycle; /// @dev Cycle of the start of the locking
        uint96 lastEndCycle; /// @dev  Cycle of the end of the locking
        uint64 ysPercentage; /// @dev  Percentage of the NFT dedicated to ysCvg
        uint256 totalCvgLocked; /// @dev  Number of CVG Locked
        uint256 mgCvgAmount; /// @dev  Meta Governance CVG amount Max
    }

    struct LockingInfo {
        uint256 tokenId;
        uint256 cvgLocked;
        uint256 lockEnd;
        uint256 ysPercentage;
        uint256 mgCvg;
    }

    function TDE_DURATION() external view returns (uint256);

    function updateYsTotalSupply() external;

    function ysTotalSupply() external view returns (uint256);

    function ysTotalSupplyHistory(uint256) external view returns (uint256);

    function ysShareOnTokenAtTde(uint256, uint256) external view returns (uint256);

    function votingPowerPerAddress(address _user) external view returns (uint256);

    function mintPosition(
        uint96 lockDuration,
        uint256 amount,
        uint64 ysPercentage,
        address receiver,
        bool isAddToManagedTokens
    ) external;

    function increaseLockAmount(uint256 tokenId, uint256 amount, address operator) external;

    function increaseLockTime(uint256 tokenId, uint256 durationAdd) external;

    function increaseLockTimeAndAmount(uint256 tokenId, uint256 durationAdd, uint256 amount, address operator) external;

    function totalSupplyYsCvgHistories(uint256 cycleClaimed) external view returns (uint256);

    function balanceOfYsCvgAt(uint256 tokenId, uint256 cycle) external view returns (uint256);

    function lockingPositions(uint256 tokenId) external view returns (LockingPosition memory);

    function unlockingTimestampPerToken(uint256 tokenId) external view returns (uint256);

    function lockingInfo(uint256 tokenId) external view returns (LockingInfo memory);

    function isContractLocker(address contractAddress) external view returns (bool);
}