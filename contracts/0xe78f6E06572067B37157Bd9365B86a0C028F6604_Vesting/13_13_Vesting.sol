//solhint-disable not-rely-on-time
//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Hinata.sol";

contract Vesting is OwnableUpgradeable {
    event VestingInitialized(
        address indexed beneficiary,
        uint64 unlockTime,
        uint256 amount,
        uint256 vestingId
    );
    event Claimed(address indexed beneficiary, uint256 amount);

    struct VestingInfo {
        address beneficiary;
        uint64 unlockTime;
        uint256 amount;
        bool claimed;
    }

    address public hinata;

    uint256 public vestingId;
    mapping(uint256 => VestingInfo) public vestings;
    mapping(address => uint256[]) public vestingIds;

    function initialize(address hinata_) public initializer {
        require(hinata_ != address(0), "Vesting: INVALID_HINATA");
        hinata = hinata_;

        __Ownable_init();
    }

    function initVesting(VestingInfo calldata vesting_) public {
        _initVesting(vesting_);
    }

    function initVestings(VestingInfo[] calldata vestings_) external {
        uint256 len = vestings_.length;
        for (uint256 i; i < len; ++i) _initVesting(vestings_[i]);
    }

    function claim() public returns (uint256 claimed) {
        uint256[] memory ids = vestingIds[msg.sender];
        uint256 len = ids.length;
        for (uint256 i; i < len; ++i) {
            VestingInfo memory vesting = vestings[ids[i]];
            if (vestings[ids[i]].claimed || block.timestamp < vesting.unlockTime) continue;
            claimed += vesting.amount;
            vestings[ids[i]].claimed = true;
        }
        require(claimed > 0, "Vesting: NOTHING_TO_CLAIM");
        Hinata(hinata).mint(msg.sender, claimed);
        emit Claimed(msg.sender, claimed);
    }

    function getVestingsByAccount(
        address account
    ) external view returns (VestingInfo[] memory vestings_) {
        uint256 len = vestingIds[account].length;
        vestings_ = new VestingInfo[](len);
        for (uint256 i; i < len; ++i) vestings_[i] = vestings[vestingIds[account][i]];
    }

    function getPendingAmount(address account) external view returns (uint256 amount) {
        uint256[] memory ids = vestingIds[account];
        uint256 len = ids.length;
        for (uint256 i; i < len; ++i) {
            VestingInfo memory vesting = vestings[ids[i]];
            if (vestings[ids[i]].claimed) continue;
            amount += vesting.amount;
        }
    }

    function _initVesting(VestingInfo calldata vesting_) private onlyOwner {
        require(vesting_.beneficiary != address(0), "Vesting: INVALID_BENEFICIARY");
        require(vesting_.unlockTime > block.timestamp, "Vesting: INVALID_UNLOCK_TIME");
        require(vesting_.amount > 0, "Vesting: EMPTY_AMOUNT");

        vestings[vestingId] = vesting_;
        vestings[vestingId].claimed = false;
        vestingIds[vesting_.beneficiary].push(vestingId);

        emit VestingInitialized(
            vesting_.beneficiary,
            vesting_.unlockTime,
            vesting_.amount,
            vestingId++
        );
    }
}