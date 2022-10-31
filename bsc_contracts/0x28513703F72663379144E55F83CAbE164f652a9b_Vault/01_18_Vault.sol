// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
// Interfaces.
import "./interfaces/IClaim.sol";
import "./interfaces/IDownline.sol";
import "./interfaces/IFurMax.sol";
import "./interfaces/IToken.sol";


/**
 * @title Vault
 * @author Steve Harmeyer
 * @notice This is the Furio vault contract.
 * @dev All percentages are * 100 (e.g. .5% = 50, .25% = 25)
 */

/// @custom:security-contact [email protected]
contract Vault is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        _properties.period = 86400; // PRODUCTION period is 24 hours.
        _properties.lookbackPeriods = 28; // 28 periods.
        _properties.penaltyLookbackPeriods = 7; // 7 periods.
        _properties.maxPayout = 100000 * (10 ** 18);
        _properties.maxReturn = 36000;
        _properties.neutralClaims = 13;
        _properties.negativeClaims = 15;
        _properties.penaltyClaims = 7;
        _properties.depositTax = 1000;
        _properties.depositReferralBonus = 1000;
        _properties.compoundTax = 500;
        _properties.compoundReferralBonus = 500;
        _properties.airdropTax = 1000;
        _properties.claimTax = 1000;
        _properties.maxReferralDepth = 15;
        _properties.teamWalletRequirement = 5;
        _properties.teamWalletChildBonus = 2500;
        _properties.devWalletReceivesBonuses = true;
        // Rewards percentages based on 28 day claims.
        _rates[0] = 250;
        _rates[1] = 225;
        _rates[2] = 225;
        _rates[3] = 225;
        _rates[4] = 225;
        _rates[5] = 225;
        _rates[6] = 225;
        _rates[7] = 225;
        _rates[8] = 225;
        _rates[9] = 200;
        _rates[10] = 200;
        _rates[11] = 200;
        _rates[12] = 200;
        _rates[13] = 200;
        _rates[14] = 200;
        _rates[15] = 100;
        _rates[16] = 100;
        _rates[17] = 100;
        _rates[18] = 100;
        _rates[19] = 100;
        _rates[20] = 100;
        _rates[21] = 50;
        _rates[22] = 50;
        _rates[23] = 50;
        _rates[24] = 50;
        _rates[25] = 50;
        _rates[26] = 50;
        _rates[27] = 50;
        _rates[28] = 50;
    }

    /**
     * Participant struct.
     */
    struct Participant {
        uint256 startTime;
        uint256 balance;
        address referrer;
        uint256 deposited;
        uint256 compounded;
        uint256 claimed;
        uint256 taxed;
        uint256 awarded;
        bool negative;
        bool penalized;
        bool maxed;
        bool banned;
        bool teamWallet;
        bool complete;
        uint256 maxedRate;
        uint256 availableRewards;
        uint256 lastRewardUpdate;
        uint256 directReferrals;
        uint256 airdropSent;
        uint256 airdropReceived;
    }
    mapping(address => Participant) private _participants;
    mapping(address => address[]) private _referrals;
    mapping(address => uint256[]) private _claims;

    /**
     * Stats.
     */
    struct Stats {
        uint256 totalParticipants;
        uint256 totalDeposits;
        uint256 totalDeposited;
        uint256 totalCompounds;
        uint256 totalCompounded;
        uint256 totalClaims;
        uint256 totalClaimed;
        uint256 totalTaxed;
        uint256 totalTaxes;
        uint256 totalAirdropped;
        uint256 totalAirdrops;
        uint256 totalBonused;
        uint256 totalBonuses;
    }
    Stats private _stats;

    /**
     * Properties.
     */
    struct Properties {
        uint256 period;
        uint256 lookbackPeriods;
        uint256 penaltyLookbackPeriods;
        uint256 maxPayout;
        uint256 maxReturn;
        uint256 neutralClaims;
        uint256 negativeClaims;
        uint256 penaltyClaims;
        uint256 depositTax;
        uint256 depositReferralBonus;
        uint256 compoundTax;
        uint256 compoundReferralBonus;
        uint256 airdropTax;
        uint256 claimTax;
        uint256 maxReferralDepth;
        uint256 teamWalletRequirement;
        uint256 teamWalletChildBonus;
        bool devWalletReceivesBonuses;
    }
    Properties private _properties;
    mapping(uint256 => uint256) private _rates; // Mapping of claims to rates.
    mapping(address => address) private _lastRewarded; // Mapping of last addresses rewarded in an upline.

    /**
     * Events.
     */
    event Deposit(address participant_, uint256 amount_);
    event Compound(address participant_, uint256 amount_);
    event Claim(address participant_, uint256 amount_);
    event Tax(address participant_, uint256 amount_);
    event Bonus(address particpant_, uint256 amount_);
    event Maxed(address participant_);
    event Complete(address participant_);
    event TokensSent(address recipient_, uint256 amount_);
    event AirdropSent(address from_, address to_, uint256 amount_);

    /**
     * -------------------------------------------------------------------------
     * PARTICIPANTS.
     * -------------------------------------------------------------------------
     */

    /**
     * Get participant.
     * @param participant_ Address of participant.
     * @return Participant The participant struct.
     */
    function getParticipant(address participant_) public view returns (Participant memory)
    {
        return _participants[participant_];
    }

    /**
     * -------------------------------------------------------------------------
     * STATS.
     * -------------------------------------------------------------------------
     */

    /**
     * Get stats.
     * @return Stats The contract stats.
     */
    function getStats() external view returns (Stats memory)
    {
        return _stats;
    }

    /**
     * -------------------------------------------------------------------------
     * PROPERTIES.
     * -------------------------------------------------------------------------
     */

    /**
     * Get properties.
     * @return Properties The contract properties.
     */
    function getProperties() external view returns (Properties memory)
    {
        return _properties;
    }

    /**
     * -------------------------------------------------------------------------
     * DEPOSITS.
     * -------------------------------------------------------------------------
     */

    /**
     * Deposit.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function deposit(uint256 quantity_) external returns (bool)
    {
        return depositFor(msg.sender, quantity_);
    }

    /**
     * Deposit with referrer.
     * @param quantity_ Token quantity.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function deposit(uint256 quantity_, address referrer_) external returns (bool)
    {
        return depositFor(msg.sender, quantity_, referrer_);
    }

    /**
     * Deposit for.
     * @param participant_ Participant address.
     * @param quantity_ Token quantity.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function depositFor(address participant_, uint256 quantity_) public returns (bool)
    {
        _addReferrer(participant_, address(0));
        if(msg.sender != addressBook.get("claim") && msg.sender != addressBook.get("swap")) {
            // The claim contract can deposit on behalf of a user straight from a presale NFT.
            require(_token().transferFrom(participant_, address(this), quantity_), "Unable to transfer tokens");
        }
        return _deposit(participant_, quantity_, _properties.depositTax);
    }

    /**
     * Deposit for with referrer.
     * @param participant_ Participant address.
     * @param quantity_ Token quantity.
     * @param referrer_ Referrer address.
     * @return bool True if successful.
     * @dev Uses function overloading to allow with or without a referrer.
     */
    function depositFor(address participant_, uint256 quantity_, address referrer_) public returns (bool)
    {
        _addReferrer(participant_, referrer_);
        if(msg.sender != addressBook.get("claim") && msg.sender != addressBook.get("swap")) {
            // The claim contract can deposit on behalf of a user straight from a presale NFT.
            require(_token().transferFrom(participant_, address(this), quantity_), "Unable to transfer tokens");
        }
        return _deposit(participant_, quantity_, _properties.depositTax);
    }

    /**
     * Internal deposit.
     * @param participant_ Participant address.
     * @param amount_ Deposit amount.
     * @param taxRate_ Tax rate.
     * @return bool True if successful.
     */
    function _deposit(address participant_, uint256 amount_, uint256 taxRate_) internal returns (bool)
    {
        require(_participants[participant_].deposited + _participants[participant_].airdropReceived + amount_ <= 5000e18, "Maximum deposit reached");
        // Get some data that will be used a bunch.
        uint256 _maxThreshold_ = _maxThreshold();
        // Checks.
        require(amount_ > 0, "Invalid deposit amount");
        require(!_participants[participant_].banned, "Participant is banned");
        require(_participants[participant_].balance < _maxThreshold_ , "Participant has reached the max payout threshold");
        // Check if participant is new.
        _addParticipant(participant_);
        // Calculate tax amount.
        uint256 _taxAmount_ = amount_ * taxRate_ / 10000;
        if(_taxAmount_ > 0) {
            amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[participant_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Calculate refund amount if this deposit pushes them over the max threshold.
        uint256 _refundAmount_ = 0;
        if(_participants[participant_].balance + amount_ > _maxThreshold_) {
            _refundAmount_ = _participants[participant_].balance + amount_ - _maxThreshold_;
            amount_ -= _refundAmount_;
        }
        // Update contract deposit stats.
        _stats.totalDeposits ++;
        _stats.totalDeposited += amount_;
        // Update participant deposit stats.
        _participants[participant_].deposited += amount_;
        // Emit Deposit event.
        emit Deposit(participant_, amount_);
        // Credit the particpant.
        _participants[participant_].balance += amount_;
        // Check if participant is maxed.
        if(_participants[participant_].balance >= _maxThreshold_) {
            _participants[participant_].maxedRate = _rewardPercent(participant_);
            _participants[participant_].maxed = true;
            // Emit Maxed event
            emit Maxed(participant_);
        }
        // Calculate the referral bonus.
        uint256 _referralBonus_ = amount_ * _properties.depositReferralBonus / 10000;
        _payUpline(participant_, _referralBonus_);
        _sendTokens(participant_, _refundAmount_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * COMPOUNDS.
     * -------------------------------------------------------------------------
     */

    /**
     * Compound.
     * @return bool True if successful.
     */
    function compound() external returns (bool)
    {
        return _compound(msg.sender, _properties.compoundTax);
    }

    /**
     * Auto compound.
     * @param participant_ Address of participant to compound.
     * @return bool True if successful.
     */
    function autoCompound(address participant_) external returns (bool)
    {
        require(msg.sender == addressBook.get("autocompound"));
        return _compound(participant_, _properties.compoundTax);
    }

    /**
     * Compound.
     * @param participant_ Address of participant.
     * @param taxRate_ Tax rate.
     * @return bool True if successful.
     */
    function _compound(address participant_, uint256 taxRate_) internal returns (bool)
    {
        _addReferrer(participant_, address(0));
        // Get some data that will be used a bunch.
        uint256 _timestamp_ = block.timestamp;
        uint256 _maxThreshold_ = _maxThreshold();
        uint256 _amount_ = _availableRewards(participant_);
        // Checks.
        require(_amount_ > 0, "Invalid compound amount");
        require(!_participants[participant_].banned, "Participant is banned");
        require(_participants[participant_].balance < _maxThreshold_ , "Participant has reached the max payout threshold");
        // Check if participant is new.
        _addParticipant(participant_);
        // Update participant available rewards
        _participants[participant_].availableRewards = 0;
        _participants[participant_].lastRewardUpdate = _timestamp_;
        // Calculate tax amount.
        uint256 _taxAmount_ = _amount_ * taxRate_ / 10000;
        if(_taxAmount_ > 0) {
            _amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[participant_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Calculate if this compound pushes them over the max threshold.
        if(_participants[participant_].balance + _amount_ > _maxThreshold_) {
            uint256 _over_ = _participants[participant_].balance + _amount_ - _maxThreshold_;
            _amount_ -= _over_;
            _participants[participant_].availableRewards = _over_;
            _participants[participant_].lastRewardUpdate = _timestamp_;
        }
        // Update contract compound stats.
        _stats.totalCompounds ++;
        _stats.totalCompounded += _amount_;
        // Update participant compound stats.
        _participants[participant_].compounded += _amount_;
        // Emit Compound event.
        emit Compound(participant_, _amount_);
        // Credit the particpant.
        _participants[participant_].balance += _amount_;
        // Check if participant is maxed.
        if(_participants[participant_].balance >= _maxThreshold_) {
            _participants[participant_].maxedRate = _rewardPercent(participant_);
            _participants[participant_].maxed = true;
            // Emit Maxed event
            emit Maxed(participant_);
        }
        // Calculate the referral bonus.
        uint256 _referralBonus_ = _amount_ * _properties.compoundReferralBonus / 10000;
        _payUpline(participant_, _referralBonus_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * CLAIMS.
     * -------------------------------------------------------------------------
     */

    /**
     * Claim.
     * @return bool True if successful.
     */
    function claim() external returns (bool)
    {
        require(!_participants[msg.sender].banned, "Participant is banned");
        uint256 _amount_ = _claim(msg.sender, _properties.claimTax);
        // If participant is not maxed, send them tokens and return.
        if(!_participants[msg.sender].maxed) {
            _sendTokens(msg.sender, _amount_);
            return true;
        }
        // If participant is not part of FurMax, send them tokens and return.
        IFurMax _furMax_ = IFurMax(addressBook.get("furmax"));
        if(!_furMax_.isFurmax(msg.sender)) {
            _sendTokens(msg.sender, _amount_);
            return true;
        }
        // Participant is FurMax so send tokens over there.
        // Take 10% management fee
        _amount_ = _amount_ * 90 / 100;
        IToken _token_ = _token();
        uint256 _balance_ = _token_.balanceOf(address(this));
        if(_balance_ < _amount_) {
            _token_.mint(address(this), _amount_ - _balance_);
        }
        _token_.approve(address(_furMax_), _amount_);
        _furMax_.distribute(msg.sender, _amount_);
        return true;
    }

    /**
     * Claim.
     * @param participant_ Address of participant.
     * @param taxRate_ Tax rate.
     * @return uint256 Amount of tokens claimed.
     */
    function _claim(address participant_, uint256 taxRate_) internal returns (uint256)
    {
        // Get some data that will be used a bunch.
        uint256 _timestamp_ = block.timestamp;
        uint256 _amount_ = _availableRewards(participant_);
        uint256 _maxPayout_ = _maxPayout(participant_);
        _addReferrer(participant_, address(0));
        // Checks.
        require(_amount_ > 0, "Invalid claim amount");
        require(!_participants[participant_].banned, "Participant is banned");
        require(!_participants[participant_].complete, "Participant is complete");
        require(_participants[participant_].claimed < _maxPayout_, "Maximum payout has been reached");
        // Keep total under max payout.
        if(_participants[participant_].claimed + _amount_ > _maxPayout_) {
            _amount_ = _maxPayout_ - _participants[participant_].claimed;
        }
        // Check penalty claims
        if(_penaltyClaims(participant_) + 1 >= _properties.penaltyClaims) {
            // User is penalized
            _participants[participant_].penalized = true;
        }
        // Check effective claims
        if(_effectiveClaims(participant_, 1) >= _properties.negativeClaims) {
            // User is negative
            _participants[participant_].negative = true;
        }
        // Update the claims mapping.
        _claims[participant_].push(_timestamp_);
        // Update participant available rewards.
        _participants[participant_].availableRewards = 0;
        _participants[participant_].lastRewardUpdate = _timestamp_;
        // Update contract claim stats.
        _stats.totalClaims ++;
        _stats.totalClaimed += _amount_;
        // Update participant claim stats.
        _participants[participant_].claimed += _amount_;
        // Emit Claim event.
        emit Claim(participant_, _amount_);
        // Check if participant is finished.
        if(_participants[participant_].claimed >= _properties.maxPayout) {
            _participants[participant_].complete = true;
            emit Complete(participant_);
        }
        // Calculate tax amount.
        uint256 _taxAmount_ = _amount_ * taxRate_ / 10000;
        if(_taxAmount_ > 0) {
            _amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[participant_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Calculate whale tax.
        uint256 _whaleTax_ = _amount_ * whaleTax(participant_) / 10000;
        if(_whaleTax_ > 0) {
            _amount_ -= _whaleTax_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _whaleTax_;
            // Update participant tax stats
            _participants[participant_].taxed += _whaleTax_;
            // Emit Tax event.
            emit Tax(participant_, _taxAmount_);
        }
        // Return amount of tokens claimed.
        return _amount_;
    }

    /**
     * 28 Day Claims.
     * @param participant_ Address of participant.
     * @return uint256 Amount of claims.
     */
    function twentyEightDayClaims(address participant_) external view returns (uint256)
    {
        return _effectiveClaims(participant_, 0);
    }

    /**
     * Effective claims.
     * @param participant_ Participant address.
     * @param additional_ Additional claims to add.
     * @return uint256 Effective claims.
     */
    function _effectiveClaims(address participant_, uint256 additional_) internal view returns (uint256)
    {
        if(_participants[participant_].penalized) {
            return _properties.lookbackPeriods; // Max amount of claims.
        }
        uint256 _penaltyClaims_ = _penaltyClaims(participant_) + additional_;
        if(_penaltyClaims_ >= _properties.penaltyClaims) {
            return _properties.lookbackPeriods; // Max amount of claims.
        }
        uint256 _claims_ = _periodClaims(participant_) + additional_;
        if(_participants[participant_].negative && _claims_ < _properties.negativeClaims) {
            _claims_ = _properties.negativeClaims; // Once you go negative, you never go back!
        }
        if(_claims_ > _properties.lookbackPeriods) {
            _claims_ = _properties.lookbackPeriods; // Limit claims to make rate calculation easier.
        }
        if(_participants[participant_].startTime >= block.timestamp - (_properties.period * _properties.lookbackPeriods) && _claims_ < 1) {
            _claims_ = 1; // Before the lookback periods are up, a user can only go up to neutral.
        }
        if(_participants[participant_].startTime == 0) {
            _claims_ = _properties.neutralClaims; // User hasn't started yet.
        }
        return _claims_;
    }

    /**
     * Claims.
     * @param participant_ Participant address.
     * @return uint256 Effective claims.
     */
    function _periodClaims(address participant_) internal view returns (uint256)
    {
        return _claimsSinceTimestamp(participant_, block.timestamp - (_properties.period * _properties.lookbackPeriods));
    }

    /**
     * Penalty claims.
     * @param participant_ Participant address.
     * @return uint256 Effective claims.
     */
    function _penaltyClaims(address participant_) internal view returns (uint256)
    {
        return _claimsSinceTimestamp(participant_, block.timestamp - (_properties.period * _properties.penaltyLookbackPeriods));
    }

    /**
     * Claims since timestamp.
     * @param participant_ Participant address.
     * @param timestamp_ Unix timestamp for start of period.
     * @return uint256 Number of claims during period.
     */
    function _claimsSinceTimestamp(address participant_, uint256 timestamp_) internal view returns (uint256)
    {
        uint256 _claims_ = 0;
        for(uint i = 0; i < _claims[participant_].length; i++) {
            if(_claims[participant_][i] >= timestamp_) {
                _claims_ ++;
            }
        }
        return _claims_;
    }

    /**
     * -------------------------------------------------------------------------
     * AIRDROPS.
     * -------------------------------------------------------------------------
     */

    /**
     * Send an airdrop.
     * @param to_ Airdrop recipient.
     * @param amount_ Amount to send.
     * @return bool True if successful.
     */
    function airdrop(address to_, uint256 amount_) external returns (bool)
    {
        require(!_participants[msg.sender].banned, "Sender is banned");
        IToken _token_ = _token();
        require(_token_.transferFrom(msg.sender, address(this), amount_), "Token transfer failed");
        return _airdrop(msg.sender, to_, amount_);
    }

    /**
     * Send an airdrop to your team.
     * @param amount_ Amount to send.
     * @param minBalance_ Minimum balance to qualify.
     * @param maxBalance_ Maximum balance to qualify.
     * @return bool True if successful.
     */
    function airdropTeam(uint256 amount_, uint256 minBalance_, uint256 maxBalance_) external returns (bool)
    {
        require(!_participants[msg.sender].banned, "Sender is banned");
        IToken _token_ = _token();
        require(_token_.transferFrom(msg.sender, address(this), amount_), "Token transfer failed");
        address[] memory _team_ = _referrals[msg.sender];
        uint256 _count_;
        // Loop through first to get number of qualified accounts.
        for(uint256 i = 0; i < _team_.length; i ++) {
            if(_team_[i] == msg.sender) {
                continue;
            }
            if( _participants[_team_[i]].balance >= minBalance_ &&
                _participants[_team_[i]].balance <= maxBalance_ &&
                !_participants[_team_[i]].maxed &&
                _participants[_team_[i]].deposited + _participants[_team_[i]].airdropReceived + amount_ <= 5000e18
            ) {
                _count_ ++;
            }
        }
        require(_count_ > 0, "No qualified accounts exist");
        uint256 _airdropAmount_ = amount_ / _count_;
        // Send an airdrop to each qualified account.
        for(uint256 i = 0; i < _team_.length; i ++) {
            if(_team_[i] == msg.sender) {
                continue;
            }
            if( _participants[_team_[i]].balance >= minBalance_ &&
                _participants[_team_[i]].balance <= maxBalance_ &&
                !_participants[_team_[i]].maxed &&
                _participants[_team_[i]].deposited + _participants[_team_[i]].airdropReceived + amount_ <= 5000e18
            ) {
                _airdrop(msg.sender, _team_[i], _airdropAmount_);
            }
        }
        return true;
    }

    /**
     * Send an airdrop.
     * @param from_ Airdrop sender.
     * @param to_ Airdrop recipient.
     * @param amount_ Amount to send.
     * @return bool True if successful.
     */
    function _airdrop(address from_, address to_, uint256 amount_) internal returns (bool)
    {
        require(!_participants[to_].banned, "Receiver is banned");
        // Check if participant is new.
        _addParticipant(to_);
        _addReferrer(to_, address(0));
        // Check that airdrop can happen.
        require(from_ != to_, "Cannot airdrop to self");
        require(!_participants[to_].maxed, "Recipient is maxed");
        // Update sender airdrop stats.
        _participants[from_].airdropSent += amount_;
        // Update contract airdrop stats.
        _stats.totalAirdropped += amount_;
        _stats.totalAirdrops ++;
        // Remove tax
        uint256 _taxAmount_ = amount_ * _properties.airdropTax / 10000;
        if(_taxAmount_ > 0) {
            amount_ -= _taxAmount_;
            // Update contract tax stats.
            _stats.totalTaxed ++;
            _stats.totalTaxes += _taxAmount_;
            // Update participant tax stats
            _participants[to_].taxed += _taxAmount_;
            // Emit Tax event.
            emit Tax(to_, _taxAmount_);
        }
        // Add amount to receiver.
        require(_participants[to_].balance + amount_ <= _maxThreshold(), "Recipient is maxed");
        require(_participants[to_].deposited + _participants[to_].airdropReceived + amount_ <= 5000e18, "Maximum deposits received");
        _participants[to_].airdropReceived += amount_;
        _participants[to_].balance += amount_;
        // Emit airdrop event.
        emit AirdropSent(from_, to_, amount_);
        return true;
    }

    /**
     * -------------------------------------------------------------------------
     * REFERRALS.
     * -------------------------------------------------------------------------
     */

    /**
     * Add referrer.
     * @param referred_ Address of the referred participant.
     * @param referrer_ Address of the referrer.
     */
    function _addReferrer(address referred_, address referrer_) internal
    {
        if(_participants[referred_].referrer != address(0) && _participants[referred_].referrer != addressBook.get("safe")) {
            // Only update referrer if none is set yet
            return;
        }
        if(referrer_ == address(0)) {
            // Use the safe address if referrer is zero.
            referrer_ = addressBook.get("safe");
        }
        if(referred_ == referrer_) {
            // Use the safe address if referrer is self.
            referrer_ = addressBook.get("safe");
        }
        _participants[referred_].referrer = referrer_;
        _referrals[referrer_].push(referred_);
        _participants[referrer_].directReferrals ++;
        // Check if the referrer is a team wallet.
        if(_referrals[referrer_].length >= _properties.teamWalletRequirement) {
            _participants[referrer_].teamWallet = true;
        }
        // Check if referrer is new.
        if(_participants[referrer_].referrer != address(0)) {
            return;
        }
        // Referrer is new so add them to the safe's referrals.
        _addReferrer(referrer_, addressBook.get("safe"));
    }

    /**
     * Pay upline.
     * @param participant_ Address of participant.
     * @param bonus_ Bonus amount.
     */
    function _payUpline(address participant_, uint256 bonus_) internal
    {
        if(bonus_ == 0) {
            return;
        }
        // Get some data that will be used later.
        address _safe_ = addressBook.get("safe");
        uint256 _maxThreshold_ = _maxThreshold();
        address _lastRewarded_ = _lastRewarded[participant_];
        IDownline _downline_ = _downline();
        // If nobody has been rewarded yet start with the participant.
        if(_lastRewarded_ == address(0)) {
            _lastRewarded_ = participant_;
        }
        // Set previous rewarded so we can pay out team bonuses if applicable.
        address _previousRewarded_ = address(0);
        // Set depth to 1.
        for(uint _depth_ = 1; _depth_ <= _properties.maxReferralDepth; _depth_ ++) {
            if(_lastRewarded_ == _safe_) {
                // We're at the top so let's start over.
                _lastRewarded_ = participant_;
            }
            // Move up the chain.
            _previousRewarded_ = _lastRewarded_;
            _lastRewarded_ = _participants[_lastRewarded_].referrer;
            // Check for downline NFTs
            if(_downline_.balanceOf(_lastRewarded_) < _depth_) {
                // Downline NFT balance is not high enough so skip to the next referrer.
                continue;
            }
            if(_participants[_lastRewarded_].balance + bonus_ > _maxThreshold_) {
                // Bonus is too high, so skip to the next referrer.
                continue;
            }
            if(_participants[_lastRewarded_].balance < _participants[_lastRewarded_].claimed) {
                // Participant has claimed more than deposited/compounded.
                continue;
            }
            if(_lastRewarded_ == participant_) {
                // Can't receive your own bonuses.
                continue;
            }
            // We found our winner!
            _lastRewarded[participant_] = _lastRewarded_;
            if(_participants[_lastRewarded_].teamWallet) {
                uint256 _childBonus_ = bonus_ * _properties.teamWalletChildBonus / 10000;
                bonus_ -= _childBonus_;
                if(_participants[_previousRewarded_].balance + _childBonus_ > _maxThreshold_) {
                    _childBonus_ = _maxThreshold_ - _participants[_previousRewarded_].balance;
                }
                _participants[_previousRewarded_].balance += _childBonus_;
                _participants[_previousRewarded_].awarded += _childBonus_;
            }
            if(_lastRewarded_ == _safe_) {
                _sendTokens(_lastRewarded_, bonus_);
            }
            else {
                _participants[_lastRewarded_].balance += bonus_;
                _participants[_lastRewarded_].awarded += bonus_;
            }
            // Update contract bonus stats.
            _stats.totalBonused += bonus_;
            _stats.totalBonuses ++;
            // Fire bonus event.
            emit Bonus(_lastRewarded_, bonus_);
            break;
        }
    }

    /**
     * Get referrals.
     * @param participant_ Participant address.
     * @return address[] Participant's referrals.
     */
    function getReferrals(address participant_) external view returns (address[] memory)
    {
        return _referrals[participant_];
    }

    /**
     * Admin update referrer.
     * @param participant_ Participant address.
     * @param referrer_ Referrer address.
     * @dev Owner can update someone's referrer.
     */
    function adminUpdateReferrer(address participant_, address referrer_) external onlyOwner
    {
        for(uint i = 0; i < _referrals[_participants[participant_].referrer].length; i ++) {
            if(_referrals[_participants[participant_].referrer][i] == participant_) {
                delete _referrals[_participants[participant_].referrer][i];
                _participants[_participants[participant_].referrer].directReferrals --;
                break;
            }
        }
        _participants[participant_].referrer = referrer_;
        _participants[referrer_].directReferrals ++;
        _referrals[referrer_].push(participant_);
    }

    /**
     * -------------------------------------------------------------------------
     * REWARDS.
     * -------------------------------------------------------------------------
     */

    /**
     * Available rewards.
     * @param participant_ Participant address.
     * @return uint256 Amount of rewards available.
     */
    function _availableRewards(address participant_) internal view returns (uint256)
    {
        uint256 _period_ = ((block.timestamp - _participants[participant_].lastRewardUpdate) * 10000) / _properties.period;
        if(_period_ > 10000) {
            // Only let rewards accumulate for 1 period.
            _period_ = 10000;
        }
        uint256 _available_ = ((_period_ * _rewardPercent(participant_) * _participants[participant_].balance) / 100000000);
        // Make sure participant doesn't go above max payout.
        uint256 _maxPayout_ = _maxPayout(participant_);
        if(_available_ + _participants[participant_].claimed > _maxPayout_) {
            _available_ = _maxPayout_ - _participants[participant_].claimed;
        }
        return _available_;
    }

    /**
     * Reward percent.
     * @param participant_ Participant address.
     * @return uint256 Reward percent.
     */
    function _rewardPercent(address participant_) internal view returns (uint256)
    {
        if(_participants[participant_].startTime == 0) {
            return _rates[_properties.neutralClaims];
        }
        //if(_participants[participant_].maxed) {
            //return _participants[participant_].maxedRate;
        //}
        if(_participants[participant_].penalized) {
            return _rates[_properties.lookbackPeriods];
        }
        return _rates[_effectiveClaims(participant_, 0)];
    }

    /**
     * -------------------------------------------------------------------------
     * GETTERS.
     * -------------------------------------------------------------------------
     */

    /**
     * Available rewards.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's available rewards.
     */
    function availableRewards(address participant_) external view returns (uint256)
    {
        return _availableRewards(participant_);
    }

    /**
     * Max payout.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's max payout.
     */
    function maxPayout(address participant_) external view returns (uint256)
    {
        return _maxPayout(participant_);
    }

    /**
     * Remaining payout.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's remaining payout.
     */
    function remainingPayout(address participant_) external view returns (uint256)
    {
        return _maxPayout(participant_) - _participants[participant_].claimed;
    }

    /**
     * Participant status.
     * @param participant_ Address of participant.
     * @return uint256 Returns a participant's status (1 = negative, 2 = neutral, 3 = positive).
     */
    function participantStatus(address participant_) external view returns (uint256)
    {
        uint256 _status_ = 3;
        uint256 _effectiveClaims_ = _effectiveClaims(participant_, 0);
        if(_effectiveClaims_ >= _properties.neutralClaims) _status_ = 2;
        if(_effectiveClaims_ >= _properties.negativeClaims) _status_ = 1;
        if(_participants[participant_].startTime == 0) {
            _status_ = 2;
        }
        return _status_;
    }

    /**
     * Participant balance.
     * @param participant_ Address of participant.
     * @return uint256 Participant's balance.
     */
    function participantBalance(address participant_) external view returns (uint256)
    {
        return _participants[participant_].balance;
    }

    /**
     * Participant maxed.
     * @param participant_ Address of participant.
     * @return bool Whether the participant is maxed or not.
     */
    function participantMaxed(address participant_) external view returns (bool)
    {
        return _participants[participant_].maxed;
    }


    /**
     * Claim precheck.
     * @param participant_ Address of participant.
     * @return uint256 Reward rate after another claim.
     */
    function claimPrecheck(address participant_) external view returns (uint256)
    {
        //if(_participants[participant_].maxed) {
            //return _participants[participant_].maxedRate;
        //}
        return _rates[_effectiveClaims(participant_, 1)];
    }

    /**
     * Reward rate.
     * @param participant_ Address of participant.
     * @return uint256 Current reward rate.
     */
    function rewardRate(address participant_) external view returns (uint256)
    {
        return _rates[_effectiveClaims(participant_, 0)];
    }

    /**
     * Max threshold.
     * @return uint256 Maximum balance threshold.
     */
    function maxThreshold() external view returns (uint256)
    {
        return _maxThreshold();
    }

    /**
     * -------------------------------------------------------------------------
     * HELPER FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Get token contract.
     * @return IToken Token contract.
     */
    function _token() internal view returns (IToken)
    {
        return IToken(addressBook.get("token"));
    }

    /**
     * Get downline contract.
     * @return IDownline Downline contract.
     */
    function _downline() internal view returns (IDownline)
    {
        return IDownline(addressBook.get("downline"));
    }

    /**
     * Max threshold.
     * @return uint256 Number of tokens needed to be considered at max.
     */
    function _maxThreshold() internal view returns (uint256)
    {
        return _properties.maxPayout * 10000 / _properties.maxReturn;
    }

    /**
     * Max payout.
     * @param participant_ Address of participant.
     * @return uint256 Maximum payout based on balance of participant and max payout.
     */
    function _maxPayout(address participant_) internal view returns (uint256)
    {
        uint256 _maxPayout_ = _participants[participant_].balance * _properties.maxReturn / 1000;
        if(_maxPayout_ > _properties.maxPayout) {
            _maxPayout_ = _properties.maxPayout;
        }
        return _maxPayout_;
    }

    /**
     * Add participant.
     * @param participant_ Address of participant.
     */
    function _addParticipant(address participant_) internal
    {
        // Check if participant is new.
        if(_participants[participant_].startTime == 0) {
            _participants[participant_].startTime = block.timestamp;
            _participants[participant_].lastRewardUpdate = block.timestamp;
            _stats.totalParticipants ++;
        }
    }

    /**
     * Send tokens.
     * @param recipient_ Token recipient.
     * @param amount_ Tokens to send.
     */
    function _sendTokens(address recipient_, uint256 amount_) internal
    {
        if(amount_ == 0) {
            return;
        }
        IToken _token_ = _token();
        uint256 _balance_ = _token_.balanceOf(address(this));
        if(_balance_ < amount_) {
            _token_.mint(address(this), amount_ - _balance_);
        }
        emit TokensSent(recipient_, amount_);
        _token_.transfer(recipient_, amount_);
    }

    /**
     * Whale tax.
     * @param participant_ Participant address.
     * @return uint256 Whale tax amount.
     */
    function whaleTax(address participant_) public view returns (uint256)
    {
        uint256 _claimed_ = _participants[participant_].claimed + _participants[participant_].compounded;
        uint256 _tax_ = 0;
        if(_claimed_ > 10000 * (10 ** 18)) _tax_ = 500;
        if(_claimed_ > 20000 * (10 ** 18)) _tax_ = 1000;
        if(_claimed_ > 30000 * (10 ** 18)) _tax_ = 1500;
        if(_claimed_ > 40000 * (10 ** 18)) _tax_ = 2000;
        if(_claimed_ > 50000 * (10 ** 18)) _tax_ = 2500;
        if(_claimed_ > 60000 * (10 ** 18)) _tax_ = 3000;
        if(_claimed_ > 70000 * (10 ** 18)) _tax_ = 3500;
        if(_claimed_ > 80000 * (10 ** 18)) _tax_ = 4000;
        if(_claimed_ > 90000 * (10 ** 18)) _tax_ = 4500;
        if(_claimed_ > 100000 * (10 ** 18)) _tax_ = 5000;
        return _tax_;
    }

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS
     * -------------------------------------------------------------------------
     */

    /**
     * Ban participant.
     * @param participant_ Address of participant.
     */
    function banParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].banned = true;
    }

    /**
     * Unban participant.
     * @param participant_ Address of participant.
     */
    function unbanParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].banned = false;
    }

    /**
     * Negative participant.
     * @param participant_ Address of participant.
     */
    function negativeParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].negative = true;
    }

    /**
     * Un-negative participant.
     * @param participant_ Address of participant.
     */
    function unnegativeParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].negative = false;
    }

    /**
     * Penalize participant.
     * @param participant_ Address of participant.
     */
    function penalizeParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].penalized = true;
    }

    /**
     * Un-penalize participant.
     * @param participant_ Address of participant.
     */
    function unpenalizeParticipant(address participant_) external onlyOwner
    {
        _participants[participant_].penalized = false;
    }

    /**
     * Add to compounded.
     * @param participant_ Address of participant.
     * @param amount_ Amount to add.
     */
    function addToCompounded(address participant_, uint256 amount_) external onlyOwner
    {
        _participants[participant_].compounded += amount_;
    }

    /**
     * Add to claimed.
     * @param participant_ Address of participant.
     * @param amount_ Amount to add.
     */
    function addToClaimed(address participant_, uint256 amount_) external onlyOwner
    {
        _participants[participant_].claimed += amount_;
    }

    /**
     * Add to taxed.
     * @param participant_ Address of participant.
     * @param amount_ Amount to add.
     */
    function addToTaxed(address participant_, uint256 amount_) external onlyOwner
    {
        _participants[participant_].taxed += amount_;
    }

    /**
     * Set rate.
     * @param claims_ Number of claims.
     * @param rate_ New rate.
     */
    function setRate(uint256 claims_, uint256 rate_) external onlyOwner
    {
        _rates[claims_] = rate_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}