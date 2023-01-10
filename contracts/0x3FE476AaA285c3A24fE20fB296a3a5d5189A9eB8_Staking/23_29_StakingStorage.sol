// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./Controller.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is IStaking, ReentrancyGuard, PermissionControl, Util, Pausable {
    bool private _initialized = false;

    // Incrementing stake Id used to record history
    mapping(address => uint256) public stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) public stakeHistory;

    StakingStorage public oldContract;

    constructor(address controller, address _oldContract) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
        if (_isContract(_oldContract)) oldContract = StakingStorage(_oldContract);
        _grantRole(CONTROLLER_ROLE, controller);
    }

    /** ----------------------------------
     * ! Business logic
     * ----------------------------------- */

    /**
     * @notice Saving stakes into storage.
     * @notice Function can be called only manager
     *
     * @param addr - user address
     * @param amount - amount of tokens to stake
     * @return stakeID
     */
    function updateHistory(address addr, uint256 amount) external onlyRole(CONSUMER_ROLE) returns (uint256) {
        if (address(addr) == address(0)) revert InvalidInput(WRONG_ADDRESS);

        uint128 time = uint128(currentTime());
        Stake memory newStake = Stake(time, amount);
        uint256 userStakeId = ++stakeIds[addr]; // ++i cheaper than i++, so, stakeHistory[addr] starts from 1
        stakeHistory[addr][userStakeId] = newStake;
        return userStakeId;
    }

    /**
     * @notice Migrate LBA LP staking history for `addr`
     * @dev This function can only to called from contracts or wallets with CONSUMER_ROLE
     * @param addr The user wallet address for the migration.
     * @param amount The LP token amount to be migrated. It should be verified in caller contract with CONSUMER_ROLE.
     * @param stakeTime The stake time for LBA LP tokens.
     */
    function migrateLBAHistory(
        address addr,
        uint256 amount,
        uint256 stakeTime
    ) external onlyRole(CONSUMER_ROLE) {
        uint256 lastStakeId = stakeIds[addr];

        for (uint256 i = lastStakeId; i > 0; --i) {
            Stake memory existingStake = stakeHistory[addr][i];
            Stake memory newStake = Stake(existingStake.time, existingStake.amount + amount);
            stakeHistory[addr][i + 1] = newStake;
        }

        // LBA LP staking should be the first one in staking history
        stakeHistory[addr][1] = Stake(stakeTime, amount);
        ++stakeIds[addr];
    }

    /**
     * @notice Migrate user's stake history from old contract after upgrading Staking contract to a new version
     * @dev This function can only to called from contracts or wallets with CONSUMER_ROLE
     * @param addresses The list of user wallet address to be migrated.
     */
    function migrateStakeHistory(address[] calldata addresses) external nonReentrant onlyRole(CONSUMER_ROLE) {
        for (uint256 i = 0; i < addresses.length; ++i) {
            address addr = addresses[i];
            if (stakeIds[addr] > 0) {
                continue; // already migrated
            }

            uint256 lastStakeId = oldContract.getUserLastStakeId(addr);
            if (lastStakeId == 0) {
                continue;
            }

            for (uint256 j = 1; j < lastStakeId + 1; ++j) {
                stakeHistory[addr][j] = oldContract.getStake(addr, j);
            }
            stakeIds[addr] = lastStakeId;
        }
    }

    /** ----------------------------------
     * ! Getters
     * ----------------------------------- */

    function getHistory(address addr, uint256 endTime) external view returns (Stake[] memory) {
        uint256 totalStakes = stakeIds[addr];

        Stake[] memory stakes = new Stake[](totalStakes); // suboptimal - it could be larger than needed, when endTime is lesser than current time

        // stakeHistory[addr] starts from 1, see `updateHistory`
        for (uint256 i = 1; i < totalStakes + 1; i++) {
            Stake memory stake = stakeHistory[addr][i];
            if (stake.time <= endTime) stakes[i - 1] = stake;
            else {
                // shortening array before returning
                Stake[] memory res = new Stake[](i - 1);
                for (uint256 j = 0; j < res.length; j++) res[j] = stakes[j];
                return res;
            }
        }
        return stakes;
    }

    function getStake(address addr, uint256 id) external view returns (Stake memory) {
        return stakeHistory[addr][id];
    }

    function getUserLastStakeId(address addr) external view returns (uint256) {
        return stakeIds[addr];
    }

    /**
     * @notice Get the current periodId based on current timestamp
     * @dev Can be overridden by child contracts
     *
     * @return current timestamp
     */
    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /** ----------------------------------
     * ! Administration       | CONTROLLER
     * ----------------------------------- */

    /**
     * @dev Setting up persmissions for this contract:
     * @dev only Consumer is allowed to save into this storage
     * @dev only Controller is allowed to update permissions - to reduce amount of DAO votings
     * @dev
     *
     * @param controller Controller contract address
     * @param stakingLogic Staking contract address
     */
    function init(address stakingLogic) external onlyRole(CONTROLLER_ROLE) {
        if (!_initialized) {
            _grantRole(CONSUMER_ROLE, stakingLogic);
            _initialized = true;
        }
    }

    /**
     * @dev Update the Controller contract address
     * @dev only controller is allowed to call this function
     */
    function setController(address newController) external onlyRole(CONTROLLER_ROLE) {
        _clearRole(CONTROLLER_ROLE);
        _grantRole(CONTROLLER_ROLE, newController);
    }

    function setOldContract(address _oldContract) external onlyRole(CONTROLLER_ROLE) {
        oldContract = StakingStorage(_oldContract);
    }
}