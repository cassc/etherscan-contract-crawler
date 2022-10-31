// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces
import "./interfaces/IFurBetToken.sol";
import "./interfaces/ILPStakingV1.sol";
import "./interfaces/ISwapV2.sol";
import "./interfaces/ISwapFurbet.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @title FurMax
 * @notice This is the contract that handles FurMax earnings.
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
    IToken private _fur;
    IFurBetToken private _furbet;
    ILPStakingV1 private _furpool;
    ISwapV2 private _swap;
    ISwapFurbet private _swapFurbet;
    IERC20 private _usdc;
    IVault private _vault;

    /**
     * Stats.
     */
    uint256 public totalParticipants;
    uint256 public totalFurbotPendingInvestment;
    uint256 public totalFurbotInvestment;
    uint256 public totalFurbotDividends;
    uint256 public totalFurpoolPendingInvestment;
    uint256 public totalFurpoolInvestment;
    uint256 public totalFurpoolDividends;

    /**
     * Mappings.
     */
    mapping(address => bool) public isAdmin;
    mapping(address => bool) public isDistributor;
    mapping(address => bool) public isFurmax;
    mapping(address => bool) public acceptedLoanTerms;
    mapping(address => uint256) public furbetPercent;
    mapping(address => uint256) public furbotPercent;
    mapping(address => uint256) public furpoolPercent;
    mapping(address => uint256) public furbotInvestment;
    mapping(address => uint256) public furbotDividendsClaimed;
    mapping(address => uint256) public furpoolInvestment;
    mapping(address => uint256) public furpoolDividendsClaimed;

    /**
     * Events.
     */
    event ParticipantJoined(address indexed participant);
    event DistributionUpdated(address indexed participant, uint256 furbetPercent, uint256 furbotPercent, uint256 furpoolPercent);
    event AdminAdded(address indexed participant);
    event AdminRemoved(address indexed participant);
    event VaultRewardsDistributed(address indexed participant, uint256 amount);
    event DividendsClaimed(address indexed participant, uint256 amount);
    event FurpoolDividendsAdded(uint256 amount);
    event FurbotDividendsAdded(uint256 amount);

    /**
     * Setup.
     */
    function setup() external
    {
        _fur = IToken(addressBook.get("token"));
        _furbet = IFurBetToken(addressBook.get("furbettoken"));
        _furpool = ILPStakingV1(addressBook.get("lpStaking"));
        _swap = ISwapV2(addressBook.get("swap"));
        _usdc = IERC20(addressBook.get("payment"));
        _vault = IVault(addressBook.get("vault"));
        isAdmin[msg.sender] = true;
        isDistributor[address(_vault)] = true;
    }

    /**
     * Available dividends.
     * @param participant_ Address of participant.
     * @return uint256 Amount of available dividends.
     */
    function availableDividends(address participant_) public view returns (uint256)
    {
        return _availableFurbotDividends(participant_) + _availableFurpoolDividends(participant_);
    }

    /**
     * Available furbot dividends.
     * @param participant_ Address of participant.
     * @return uint256 Amount of available furbot dividends.
     */
    function _availableFurbotDividends(address participant_) internal view returns (uint256)
    {
        uint256 _available_;
        if(totalFurbotInvestment > 0) _available_ = totalFurbotDividends / totalFurbotInvestment * furbotInvestment[participant_] - furbotDividendsClaimed[participant_];
    }

    /**
     * Available furpool dividends.
     * @param participant_ Address of participant.
     * @return uint256 Amount of available furpool dividends.
     */
    function _availableFurpoolDividends(address participant_) internal view returns (uint256)
    {
        uint256 _available_;
        if(totalFurpoolInvestment > 0) _available_ = totalFurpoolDividends / totalFurpoolInvestment * furpoolInvestment[participant_] - furpoolDividendsClaimed[participant_];
    }

    /**
     * Claim.
     */
    function claim() external
    {
        furbotDividendsClaimed[msg.sender] += _availableFurbotDividends(msg.sender);
        furpoolDividendsClaimed[msg.sender] += _availableFurpoolDividends(msg.sender);
        uint256 _amount_ = _availableFurbotDividends(msg.sender) + _availableFurpoolDividends(msg.sender);
        _usdc.transfer(msg.sender, _amount_);
        emit DividendsClaimed(msg.sender, _amount_);
    }

    /**
     * Join.
     * @param acceptTerms_ Accept the terms of the contract.
     * @param furbet_ Percent of earnings to be sent to Furbet.
     * @param furbot_ Percent of earnings to be sent to Furbot.
     * @param furpool_ Percent of earnings to be sent to Furpool.
     */
    function join(bool acceptTerms_, uint256 furbet_, uint256 furbot_, uint256 furpool_) external
    {
        require(acceptTerms_, "Furmax: You must accept the terms of service.");
        require(_vault.participantMaxed(msg.sender), "Furmax: You must be maxed in Furvault");
        require(!isFurmax[msg.sender], "Furmax: You are already a FurMax participant.");
        isFurmax[msg.sender] = true;
        acceptedLoanTerms[msg.sender] = true;
        totalParticipants++;
        _updateDistribution(msg.sender, furbet_, furbot_, furpool_);
        emit ParticipantJoined(msg.sender);
    }

    /**
     * Update distribution.
     * @param furbet_ Percent of earnings to be sent to Furbet.
     * @param furbot_ Percent of earnings to be sent to Furbot.
     * @param furpool_ Percent of earnings to be sent to Furpool.
     */
    function updateDistribution(uint256 furbet_, uint256 furbot_, uint256 furpool_) external
    {
        require(isFurmax[msg.sender], "Furmax: You are not a FurMax participant.");
        require(furbet_ + furbot_ + furpool_ == 100, "Furmax: The percentages must add up to 100.");
        _updateDistribution(msg.sender, furbet_, furbot_, furpool_);
    }

    /**
     * Internal update distribution.
     * @param participant_ Participant address.
     * @param furbet_ Percent of earnings to be sent to Furbet.
     * @param furbot_ Percent of earnings to be sent to Furbot.
     * @param furpool_ Percent of earnings to be sent to Furpool.
     */
    function _updateDistribution(address participant_, uint256 furbet_, uint256 furbot_, uint256 furpool_) internal
    {
        furbetPercent[participant_] = furbet_;
        furbotPercent[participant_] = furbot_;
        furpoolPercent[participant_] = furpool_;
        emit DistributionUpdated(participant_, furbet_, furbot_, furpool_);
    }

    /**
     * Distribute.
     * @param participant_ Participant address.
     * @param amount_ Amount to distribute.
     */
    function distribute(address participant_, uint256 amount_) external onlyDistributors
    {
        require(isFurmax[participant_], "Furmax: You are not a FurMax participant.");
        require(amount_ > 0, "Furmax: Amount must be greater than 0.");
        require(_fur.transferFrom(msg.sender, address(this), amount_), "Furmax: Fur transfer to contract failed.");
        // Send 50% to participant.
        _sendFurToParticipant(participant_, amount_ * 50 / 100);
        // Swap remaining for USDC.
        uint256 _distribution_ = _swapFurForUsdc(amount_ * 50 / 100);
        // Distribute FurBet.
        _distributeFurbet(participant_, _distribution_ * furbetPercent[participant_] / 100);
        // Distribute Furbot.
        _distributeFurbot(participant_, _distribution_ * furbotPercent[participant_] / 100);
        // Distribute Furpool.
        _distributeFurpool(participant_, _distribution_ * furpoolPercent[participant_] / 100);
        emit VaultRewardsDistributed(participant_, amount_);
    }

    /**
     * Send fur to participant.
     * @param participant_ Participant address.
     * @param amount_ Amount to send.
     */
    function _sendFurToParticipant(address participant_, uint256 amount_) internal
    {
        require(_fur.transfer(participant_, amount_), "Furmax: Fur transfer to participant failed.");
    }

    /**
     * Swap FUR for USDC.
     * @param amount_ Amount to swap.
     * @return uint256 Amount of USDC received.
     */
    function _swapFurForUsdc(uint256 amount_) internal returns (uint256)
    {
        _fur.approve(address(_swap), amount_);
        uint256 _startingBalance_ = _usdc.balanceOf(address(this));
        _swap.sell(amount_);
        return _usdc.balanceOf(address(this)) - _startingBalance_;
    }

    /**
     * Distribute Furbet.
     * @param participant_ Participant address.
     * @param amount_ Amount to distribute.
     */
    function _distributeFurbet(address participant_, uint256 amount_) internal
    {
        if(amount_ == 0) return;
        // Minting for now until LP is in place
        _furbet.mint(participant_, amount_ * 110 / 100);
    }

    /**
     * Distribute Furbot.
     * @param participant_ Participant address.
     * @param amount_ Amount to distribute.
     */
    function _distributeFurbot(address participant_, uint256 amount_) internal
    {
        if(amount_ == 0) return;
        totalFurbotPendingInvestment += amount_;
        furbotInvestment[participant_] += amount_;
    }

    /**
     * Distribute Furpool.
     * @param participant_ Participant address.
     * @param amount_ Amount to distribute.
     */
    function _distributeFurpool(address participant_, uint256 amount_) internal
    {
        if(amount_ == 0) return;
        totalFurpoolPendingInvestment += amount_;
        furpoolInvestment[participant_] += amount_;
    }

    /**
     * Run furpool.
     */
    function runFurpool() external
    {
        if(totalFurpoolPendingInvestment > 0) {
            _usdc.approve(address(_furpool), totalFurpoolPendingInvestment);
            _furpool.stake(address(_usdc), totalFurpoolPendingInvestment, 0);
            totalFurpoolPendingInvestment = 0;
        }
        uint256 _startingBalance_ = _usdc.balanceOf(address(this));
        _furpool.claimRewards();
        uint256 _amountClaimed_ = _usdc.balanceOf(address(this)) - _startingBalance_;
        if(_amountClaimed_ > 0) {
            totalFurpoolDividends += _amountClaimed_;
            emit FurpoolDividendsAdded(_amountClaimed_);
        }
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Set admin.
     * @param participant_ Participant address.
     * @param isAdmin_ Is admin.
     */
    function setAdmin(address participant_, bool isAdmin_) external onlyAdmins
    {
        isAdmin[participant_] = isAdmin_;
        if(isAdmin_) emit AdminAdded(participant_);
        else emit AdminRemoved(participant_);
    }

    /**
     * Withdraw furbot pending investment.
     */
    function withdrawFurbotPendingInvestment() external onlyAdmins
    {
        if(totalFurbotPendingInvestment == 0) return;
        uint256 _amount_ = totalFurbotPendingInvestment;
        totalFurbotInvestment += _amount_;
        totalFurbotPendingInvestment = 0;
        _usdc.transfer(msg.sender, _amount_);
    }

    /**
     * Deposit furbot dividends.
     * @param amount_ Amount to deposit.
     */
    function depositFurbotDividends(uint256 amount_) external onlyAdmins
    {
        require(amount_ > 0, "Furmax: Amount must be greater than 0.");
        require(_usdc.transferFrom(msg.sender, address(this), amount_), "Furmax: USDC transfer to contract failed.");
        totalFurbotDividends += amount_;
        emit FurbotDividendsAdded(amount_);
    }

    /**
     * Modifiers.
     */
    modifier onlyDistributors()
    {
        require(isDistributor[msg.sender], "FurMax: Unauthorized");
        _;
    }

    modifier onlyAdmins()
    {
        require(isAdmin[msg.sender], "FurMax: Unauthorized");
        _;
    }
}