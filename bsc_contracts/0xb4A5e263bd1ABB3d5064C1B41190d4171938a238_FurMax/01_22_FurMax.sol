// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces
import "./interfaces/IFurBetStake.sol";
import "./interfaces/IFurBetToken.sol";
import "./interfaces/IFurBotMax.sol";
import "./interfaces/ILPStakingV1.sol";
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
    IFurBetStake private _furBetStake;
    IFurBetToken private _furBetToken;
    IFurBotMax private _furBotMax;
    ILPStakingV1 private _furPool;
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
    mapping(address => bool) public acceptedTerms;

    /**
     * Setup.
     */
    function setup() external
    {
        _furBetStake = IFurBetStake(addressBook.get("furbetstake"));
        _furBetToken = IFurBetToken(addressBook.get("furbettoken"));
        _furBotMax = IFurBotMax(addressBook.get("furbotmax"));
        _furPool = ILPStakingV1(addressBook.get("lpStaking"));
        _fur = IERC20(addressBook.get("token"));
        _usdc = IERC20(addressBook.get("payment"));
        _swap = ISwapV2(addressBook.get("swap"));
        _vault = IVault(addressBook.get("vault"));
    }

    /**
     * Join.
     * @param acceptTerms_ Whether the user accepts the terms.
     * @param furBet_ The new FurBet distribution.
     * @param furBot_ The new FurBot distribution.
     * @param furPool_ The new FurPool distribution.
     */
    function join(bool acceptTerms_, uint256 furBet_, uint256 furBot_, uint256 furPool_) external
    {
        require(!isFurMax[msg.sender], "FurMax: Already joined");
        require(acceptTerms_, "FurMax: Terms not accepted");
        require(_vault.participantMaxed(msg.sender), "FurMax: Not maxed");
        require(furBet_ + furBot_ + furPool_ == 100, "FurMax: Invalid distribution");
        isFurMax[msg.sender] = true;
        furBetPercent[msg.sender] = furBet_;
        furBotPercent[msg.sender] = furBot_;
        furPoolPercent[msg.sender] = furPool_;
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
        _sendFurToParticipant(participant_, amount_ / 2);
        // Convert the other half to USDC.
        uint256 _usdcAmount_ = _convertFurToUsdc(amount_ / 2);
        // Send some to FurBet.
        uint256 _furBetAmount_ = _usdcAmount_ * furBetPercent[participant_] / 100;
        if(_furBetAmount_ > 0) {
            _convertUsdcToFurBet(participant_, _furBetAmount_);
        }
        // Send some to FurBot.
        uint256 _furBotAmount_ = _usdcAmount_ * furBotPercent[participant_] / 100;
        if(_furBotAmount_ > 0) {
            _convertUsdcToFurBot(participant_, _furBotAmount_);
        }
    }

    /**
     * Internal.
     */

    /**
     * @param participant_ Participant address.
     * @param amount_ Amount to send.
     */
    function _sendFurToParticipant(address participant_, uint256 amount_) internal
    {
        require(_fur.transfer(participant_, amount_), "FurMax: Transfer failed");
    }

    /**
     * @param amount_ Amount of FUR to convert.
     * @return uint256 Amount of USDC received.
     */
    function _convertFurToUsdc(uint256 amount_) internal returns (uint256)
    {
        uint256 _balance_ = _usdc.balanceOf(address(this));
        _swap.sell(amount_);
        return _usdc.balanceOf(address(this)) - _balance_;
    }

    /**
     * Convert USDC to FurBet.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC to convert.
     */
    function _convertUsdcToFurBet(address participant_, uint256 amount_) internal
    {
        // Current price hardcoded to .90 cents. Will update with swap when that is launched.
        uint256 _furbAmount_ = amount_ / 90 * 100;
        _furBetToken.mint(address(this), _furbAmount_);
        _furBetToken.approve(address(_furBetStake), _furbAmount_);
        _furBetStake.stakeMax(participant_, _furbAmount_);
    }

    /**
     * Convert USDC to FurBot.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC to convert.
     */
    function _convertUsdcToFurBot(address participant_, uint256 amount_) internal
    {
        _usdc.approve(address(_furBotMax), amount_);
        _furBotMax.deposit(participant_, amount_);
    }

    /**
     * Convert USDC to FurPool.
     * @param participant_ Participant address.
     * @param amount_ Amount of USDC to convert.
     */
    function _convertUsdcToFurPool(address participant_, uint256 amount_) internal
    {
        _usdc.approve(address(_furPool), amount_);
        _furPool.stakeFor(address(_usdc), amount_, 3, participant_);
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