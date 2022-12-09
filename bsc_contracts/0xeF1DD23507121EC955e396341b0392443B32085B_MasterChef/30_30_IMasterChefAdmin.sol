// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

import {IMasterChef} from "./IMasterChef.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChefAdmin {
    struct AddNewPoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 startBlockNumber;
        bool isRegular;
    }

    struct SetPoolAllocationInfo {
        uint256 pid;
        uint256 allocPoint;
    }

    event AddPool(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken,
        bool isRegular
    );
    event SetPool(uint256 indexed pid, uint256 allocPoint);
    event UpdatePool(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 lpSupply,
        uint256 accKswapPerShare
    );

    event UpdateCakeRate(
        uint256 burnRate,
        uint256 regularFarmRate,
        uint256 specialFarmRate
    );
    event UpdateBurnAdmin(address indexed oldAdmin, address indexed newAdmin);
    event UpdateWhiteList(address indexed user, bool isValid);
    event UpdateBoostContract(address indexed boostContract);
    event UpdateBoostMultiplier(
        address indexed user,
        uint256 pid,
        uint256 oldMultiplier,
        uint256 newMultiplier
    );
    event SetTreasuryAddress(address indexed user, address treasury);

    /**
     * @notice Add a new pool. Can only be called by the owner.
     * DO NOT add the same LP token more than once. Rewards will be messed up if you do.
     * @param _allocPoint Number of allocation points for the new pool.
     * @param _lpToken Address of the LP BEP-20 token.
     * @param _isRegular Whether the pool is regular or special. LP farms are always "regular". "Special" pools are
     * @param _withUpdate Whether call "massUpdatePools" operation.
     * only for KSWAP distributions within Kyoto Swap products.
     */
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _isRegular,
        uint256 _startBlockNumber,
        bool _withUpdate
    ) external;

    /**
     * @notice Update the given pool's KSWAP allocation point. Can only be called by the owner.
     *
     * @param poolAlocations List of SetPoolAllocationInfo to update
     * @param _withUpdate Whether call "massUpdatePools" operation.
     */
    function set(
        SetPoolAllocationInfo[] calldata poolAlocations,
        bool _withUpdate
    ) external;

    /**
     * @notice Update the given pool's KSWAP allocation point. Can only be called by the owner.
     *
     * @param _pid The id of the pool. See `poolInfo`.
     * @param _allocPoint New number of allocation points for the pool.
     * @param _withUpdate Whether call "massUpdatePools" operation.
     */
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external;

    /**
     * @notice Updates the given pool's allocations and the pool rates.
     *
     * @param poolAlocations List of SetPoolAllocationInfo to update
     * @param _burnRate The % of KSWAP to burn each block.
     * @param _regularFarmRate The % of KSWAP to regular pools each block.
     * @param _specialFarmRate The % of KSWAP to special pools each block.
     */
    function updateRatesAndPools(
        SetPoolAllocationInfo[] calldata poolAlocations,
        uint256 _burnRate,
        uint256 _regularFarmRate,
        uint256 _specialFarmRate,
        bool _withUpdate
    ) external;

    /**
     * @notice Send KSWAP pending for burn to `burnAdmin`.
     *
     * @param _withUpdate Whether call "massUpdatePools" operation.
     */
    function burnKswap(bool _withUpdate) external;

    /**
     * @notice Update the % of KSWAP distributions for burn, regular pools and special pools.
     *
     * @param _burnRate The % of KSWAP to burn each block.
     * @param _regularFarmRate The % of KSWAP to regular pools each block.
     * @param _specialFarmRate The % of KSWAP to special pools each block.
     * @param _withUpdate Whether call "massUpdatePools" operation.
     */
    function updateKswapRate(
        uint256 _burnRate,
        uint256 _regularFarmRate,
        uint256 _specialFarmRate,
        bool _withUpdate
    ) external;

    /**
     * @notice Update burn admin address.
     *
     * @param _newAdmin The new burn admin address.
     */
    function updateBurnAdmin(address _newAdmin) external;

    /**
     * @notice Update whitelisted addresses for special pools.
     *
     * @param _user The address to be updated.
     * @param _isValid The flag for valid or invalid.
     */
    function updateWhiteList(address _user, bool _isValid) external;

    /**
     * @notice Update boost contract address and max boost factor.
     *
     * @param _newBoostContract The new address for handling all the share boosts.
     */
    function updateBoostContract(address _newBoostContract) external;

    /**
     * @notice Update user boost factor.
     *
     * @param _user The user address for boost factor updates.
     * @param _pid The pool id for the boost factor updates.
     * @param _newMultiplier New boost multiplier.
     */
    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external;

    /**
     * @notice Update the treasury address.
     */
    function setTreasuryAddress(address _treasury) external;

    /**
     * @notice Updates the lastRewardBlock for a pool.
     *         Both the new and old values must be future blocks!
     *         If the new value is 0, it will be set to `block.number + 200`.
     *
     * @param _pid The pool id to update.
     * @param newLastRewardBlock The new value.
     */
    function setPoolLastRewardBlock(
        uint256 _pid,
        uint256 newLastRewardBlock
    ) external;

    /**
     * @notice Updates the lastRewardBlock for a list of pools.
     *         Both the new and old values must be future blocks!
     *         If the new value is 0, it will be set to `block.number + 200`.
     *
     * @param _pids The list of pool ids to update.
     * @param newLastRewardBlock The new value.
     */
    function setPoolLastRewardBlock(
        uint256[] memory _pids,
        uint256 newLastRewardBlock
    ) external;
}