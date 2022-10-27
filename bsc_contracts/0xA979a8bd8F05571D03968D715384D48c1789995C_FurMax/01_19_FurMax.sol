// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces
import "./interfaces/IFurBotMax.sol";
import "./interfaces/ISwapV2.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurMax
 * @notice This is the contract that distributes FurMax earnings.
 */

/// @custom:security-contact [email protected]
contract FurMax is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * External contracts.
     */
    IFurBotMax private _furBotMax;
    IERC20 private _fur;
    IERC20 private _usdc;
    ISwapV2 private _swap;
    IVault private _vault;

    /**
     * Mappings.
     */
    mapping(address => bool) public isFurMax;
    mapping(address => uint256) public furMaxClaimed;
    mapping(address => uint256) public furBetPercent;
    mapping(address => uint256) public furBotPercent;
    mapping(address => uint256) public furPoolPercent;

    /**
     * Setup.
     */
    function setup() external
    {
        _fur = IERC20(addressBook.get("token"));
        _usdc = IERC20(addressBook.get("payment"));
        _swap = ISwapV2(addressBook.get("swap"));
        _vault = IVault(addressBook.get("vault"));
    }

    /**
     * Join.
     * @param furBet_ The new FurBet distribution.
     * @param furBot_ The new FurBot distribution.
     * @param furPool_ The new FurPool distribution.
     */
    function join(uint256 furBet_, uint256 furBot_, uint256 furPool_) external
    {
        require(!isFurMax[msg.sender], "FurMax: Already joined");
        isFurMax[msg.sender] = true;
        updateDistribution(furBet_, furBot_, furPool_);
    }

    /**
     * Update distribution.
     * @param furBet_ The new FurBet distribution.
     * @param furBot_ The new FurBot distribution.
     * @param furPool_ The new FurPool distribution.
     */
    function updateDistribution(uint256 furBet_, uint256 furBot_, uint256 furPool_) public
    {
        require(isFurMax[msg.sender], "FurMax: Not in the FurMax program.");
        require(furBet_ + furBot_ + furPool_ == 100, "FurMax: Invalid distribution");
        furBetPercent[msg.sender] = furBet_;
        furBotPercent[msg.sender] = furBot_;
        furPoolPercent[msg.sender] = furPool_;
    }

    /**
     * Distribute.
     * @param participant_ Participant address.
     * @param amount_ Amount to distribute.
     */
    function distribute(address participant_, uint256 amount_) external canDistribute
    {
        require(isFurMax[participant_], "FurMax: Not in the FurMax program.");
        require(amount_ > 0, "FurMax: Invalid amount");
        require(_fur.transferFrom(msg.sender, address(this), amount_), "FurMax: Transfer failed");
        // Transfer half the FUR to the participant.
        uint256 _furDistributedToParticipant_ = amount_ / 2;
        if(_furDistributedToParticipant_ > 0) {
            require(_fur.transfer(participant_, _furDistributedToParticipant_), "FurMax: Transfer failed");
        }
        // Convert the rest to USDC.
        uint256 _balance_ = _usdc.balanceOf(address(this));
        _swap.sell(amount_ - _furDistributedToParticipant_);
        uint256 _remaining_ = _usdc.balanceOf(address(this)) - _balance_;
        // Send some to FurBet.
        uint256 _furBetAmount_ = _remaining_ * furBetPercent[participant_] / 100;
        if(_furBetAmount_ > 0) {

        }
    }

    /**
     * Modifiers.
     */
    modifier canDistribute()
    {
        require(msg.sender == address(_vault), "Unauthorized");
        _;
    }
}