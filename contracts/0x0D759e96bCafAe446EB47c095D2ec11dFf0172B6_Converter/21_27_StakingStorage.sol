// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "./helpers/IStaking.sol";
import "./helpers/TimeConstants.sol";
import "./Controller.sol";
import "./Staking.sol";
import "./helpers/Util.sol";
import "./helpers/PermissionControl.sol";

/**
 * @dev ASM Genome Mining - Staking Storage contract
 */
contract StakingStorage is IStaking, PermissionControl, Util, Pausable {
    bool private _initialized = false;

    // Incrementing stake Id used to record history
    mapping(address => uint256) public stakeIds;
    // Store stake history per each address keyed by stake Id
    mapping(address => mapping(uint256 => Stake)) public stakeHistory;

    constructor(address controller) {
        if (!_isContract(controller)) revert InvalidInput(INVALID_CONTROLLER);
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
}