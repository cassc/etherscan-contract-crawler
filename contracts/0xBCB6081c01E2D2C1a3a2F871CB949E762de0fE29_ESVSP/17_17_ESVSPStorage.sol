// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/IESVSP.sol";
import "../interface/IESVSP721.sol";

abstract contract ESVSPStorageV1 is IESVSP {
    struct LockPosition {
        uint256 lockedAmount; // VSP locked
        uint256 boostedAmount; // based on the `lockPeriod`
        uint256 unlockTime; // now + `lockPeriod`
    }

    uint8 public decimals;
    string public name;
    string public symbol;

    /**
     * @notice The treasury contract (will receive exit penalty collected)
     */
    address public treasury;

    /**
     * @notice NFT contract
     */
    IESVSP721 public esVSP721;

    /**
     * @notice Rewards contract
     */
    IRewards public rewards;

    /**
     * @notice Total VSP locked
     */
    uint256 public override totalLocked;

    /**
     * @notice Total boosted amount
     */
    uint256 public override totalBoosted;

    /**
     * @notice Fee paid when withdrawing. Decreases linearly as period finish approaches.
     * @dev Use 18 decimals (e.g. 0.5e18 is 50%)
     */
    uint256 public exitPenalty;

    /**
     * @notice Lock positions
     * @dev tokenId => position
     */
    mapping(uint256 => LockPosition) public positions;

    /**
     * @notice Total VSP locked by user among all his positions
     * @dev user => total locked;
     */
    mapping(address => uint256) public override locked;

    /**
     * @notice Total boosted amount by user among all his positions
     * @dev user => total boosted;
     */
    mapping(address => uint256) public override boosted;
}