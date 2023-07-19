// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/PausableUpgradeable.sol";

import "./interfaces/IeETH.sol";
import "./interfaces/IMembershipManager.sol";
import "./interfaces/IMembershipNFT.sol";
import "./interfaces/ILiquidityPool.sol";


contract MembershipManager is Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable, IMembershipManager {

    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------

    IeETH public eETH;
    ILiquidityPool public liquidityPool;
    IMembershipNFT public membershipNFT;
    address public treasury;
    address public protocolRevenueManager;

    mapping (uint256 => uint256) public allTimeHighDepositAmount;
    mapping (uint256 => TokenDeposit) public tokenDeposits;
    mapping (uint256 => TokenData) public tokenData;
    TierDeposit[] public tierDeposits;
    TierData[] public tierData;

    // [BEGIN] SLOT 261

    uint16 public pointsBoostFactor; // + (X / 10000) more points, if staking rewards are sacrificed
    uint16 public pointsGrowthRate; // + (X / 10000) kwei points are earned per ETH per day
    uint56 public minDepositGwei;
    uint8  public maxDepositTopUpPercent;

    uint16 private mintFee; // fee = 0.001 ETH * 'mintFee'
    uint16 private burnFee; // fee = 0.001 ETH * 'burnFee'
    uint16 private upgradeFee; // fee = 0.001 ETH * 'upgradeFee'
    uint8 public treasuryFeeSplitPercent;
    uint8 public protocolRevenueFeeSplitPercent;

    uint32 public topUpCooltimePeriod;
    uint32 public withdrawalLockBlocks;

    uint32 private __gap0;

    // [END] SLOT 261 END

    uint128 public sharesReservedForRewards;

    address public admin;

 
    //--------------------------------------------------------------------------------------
    //-------------------------------------  EVENTS  ---------------------------------------
    //--------------------------------------------------------------------------------------

    event FundsMigrated(address indexed user, uint256 _tokenId, uint256 _amount, uint256 _eapPoints, uint40 _loyaltyPoints, uint40 _tierPoints);
    event NftUpdated(uint256 _tokenId, uint128 _amount, uint128 _amountSacrificedForBoostingPoints, uint40 _loyaltyPoints, uint40 _tierPoints, uint8 _tier, uint32 _prevTopUpTimestamp, uint96 _rewardsLocalIndex);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------

    error Deprecated();
    error DisallowZeroAddress();

    function initialize(address _eEthAddress, address _liquidityPoolAddress, address _membershipNft, address _treasury, address _protocolRevenueManager) external initializer {
        if (_eEthAddress == address(0) || _liquidityPoolAddress == address(0) || _treasury == address(0) || _protocolRevenueManager == address(0) || _membershipNft == address(0)) revert DisallowZeroAddress();

        __Ownable_init();
        __UUPSUpgradeable_init();

        eETH = IeETH(_eEthAddress);
        liquidityPool = ILiquidityPool(_liquidityPoolAddress);
        membershipNFT = IMembershipNFT(_membershipNft);
        treasury = _treasury;
        protocolRevenueManager = _protocolRevenueManager;

        pointsBoostFactor = 10000;
        pointsGrowthRate = 10000;
        minDepositGwei = (0.1 ether / 1 gwei);
        maxDepositTopUpPercent = 20;
        withdrawalLockBlocks = 3600;

        treasuryFeeSplitPercent = 0;
        protocolRevenueFeeSplitPercent = 100;
    }

    error InvalidEAPRollover();

    /// @notice EarlyAdopterPool users can re-deposit and mint a membership NFT claiming their points & tiers
    /// @dev The deposit amount must be greater than or equal to what they deposited into the EAP
    /// @param _amount amount of ETH to earn staking rewards.
    /// @param _amountForPoints amount of ETH to boost earnings of {loyalty, tier} points
    /// @param _snapshotEthAmount exact balance that the user has in the merkle snapshot
    /// @param _points EAP points that the user has in the merkle snapshot
    /// @param _merkleProof array of hashes forming the merkle proof for the user
    function wrapEthForEap(
        uint256 _amount,
        uint256 _amountForPoints,
        uint256 _snapshotEthAmount,
        uint256 _points,
        bytes32[] calldata _merkleProof
    ) external payable whenNotPaused returns (uint256) {
        if (_points == 0 || msg.value < _snapshotEthAmount || msg.value > _snapshotEthAmount * 2 || msg.value != _amount + _amountForPoints) revert InvalidEAPRollover();

        membershipNFT.processDepositFromEapUser(msg.sender, _snapshotEthAmount, _points, _merkleProof);
        (uint40 loyaltyPoints, uint40 tierPoints) = membershipNFT.convertEapPoints(_points, _snapshotEthAmount);

        bytes32[] memory zeroProof;
        liquidityPool.deposit{value: msg.value}(msg.sender, address(this), zeroProof);

        uint256 tokenId = _mintMembershipNFT(msg.sender, msg.value - _amountForPoints, _amountForPoints, loyaltyPoints, tierPoints);

        _emitNftUpdateEvent(tokenId);
        emit FundsMigrated(msg.sender, tokenId, msg.value, _points, loyaltyPoints, tierPoints);
        return tokenId;
    }

    error InvalidDeposit();
    error InvalidAllocation();
    error InvalidAmount();
    error InsufficientBalance();

    /// @notice Wraps ETH into a membership NFT.
    /// @dev This function allows users to wrap their ETH into membership NFT.
    /// @param _amount amount of ETH to earn staking rewards.
    /// @param _amountForPoints amount of ETH to boost earnings of {loyalty, tier} points
    /// @param _merkleProof Array of hashes forming the merkle proof for the user.
    /// @return tokenId The ID of the minted membership NFT.
    function wrapEth(uint256 _amount, uint256 _amountForPoints, bytes32[] calldata _merkleProof) public payable whenNotPaused returns (uint256) {
        uint256 feeAmount = mintFee * 0.001 ether;
        uint256 depositPerNFT = _amount + _amountForPoints;
        uint256 ethNeededPerNFT = depositPerNFT + feeAmount;

        if (depositPerNFT / 1 gwei < minDepositGwei || msg.value != ethNeededPerNFT) revert InvalidDeposit();

        return _wrapEth(_amount, _amountForPoints, _merkleProof);
    }

    function wrapEthBatch(uint256 _numNFTs, uint256 _amount, uint256 _amountForPoints, bytes32[] calldata _merkleProof) public payable whenNotPaused returns (uint256[] memory) {
        _requireAdmin();

        uint256 feeAmount = mintFee * 0.001 ether;
        uint256 depositPerNFT = _amount + _amountForPoints;
        uint256 ethNeededPerNFT = depositPerNFT + feeAmount;

        if (depositPerNFT / 1 gwei < minDepositGwei || msg.value != _numNFTs * ethNeededPerNFT) revert InvalidDeposit();

        uint256[] memory tokenIds = new uint256[](_numNFTs);
        for (uint256 i = 0; i < _numNFTs; i++) {
            tokenIds[i] = _wrapEth(_amount, _amountForPoints, _merkleProof);
        }
        return tokenIds;
    }

    /// @notice Increase your deposit tied to this NFT within the configured percentage limit.
    /// @dev Can only be done once per month
    /// @param _tokenId ID of NFT token
    /// @param _amount amount of ETH to earn staking rewards.
    /// @param _amountForPoints amount of ETH to boost earnings of {loyalty, tier} points
    /// @param _merkleProof array of hashes forming the merkle proof for the user
    function topUpDepositWithEth(uint256 _tokenId, uint128 _amount, uint128 _amountForPoints, bytes32[] calldata _merkleProof) public payable whenNotPaused {
        _requireTokenOwner(_tokenId);

        _claimPoints(_tokenId);
        _claimStakingRewards(_tokenId);

        uint256 additionalDeposit = _topUpDeposit(_tokenId, _amount, _amountForPoints);
        liquidityPool.deposit{value: additionalDeposit}(msg.sender, address(this), _merkleProof);
        _emitNftUpdateEvent(_tokenId);
    }

    error ExceededMaxWithdrawal();
    error InsufficientLiquidity();
    error RequireTokenUnlocked();

    /// @notice Unwraps membership points tokens for ETH.
    /// @dev This function allows users to unwrap their membership tokens and receive ETH in return.
    /// @param _tokenId The ID of the membership NFT to unwrap.
    /// @param _amount The amount of membership tokens to unwrap.
    function unwrapForEth(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        _requireTokenOwner(_tokenId);
        if (liquidityPool.totalValueInLp() < _amount) revert InsufficientLiquidity();

        // prevent transfers for several blocks after a withdrawal to prevent frontrunning
        membershipNFT.incrementLock(_tokenId, withdrawalLockBlocks);

        _claimPoints(_tokenId);
        _claimStakingRewards(_tokenId);

        if (!membershipNFT.isWithdrawable(_tokenId, _amount)) revert ExceededMaxWithdrawal();

        uint256 prevAmount = tokenDeposits[_tokenId].amounts;
        _updateAllTimeHighDepositOf(_tokenId);
        _withdraw(_tokenId, _amount);
        _applyUnwrapPenalty(_tokenId, prevAmount, _amount);

        liquidityPool.withdraw(address(msg.sender), _amount);

        _emitNftUpdateEvent(_tokenId);
    }

    /// @notice withdraw the entire balance of this NFT and burn it
    /// @param _tokenId The ID of the membership NFT to unwrap
    function withdrawAndBurnForEth(uint256 _tokenId) public whenNotPaused {
        _requireTokenOwner(_tokenId);

        // Claim all staking rewards before burn
        _claimStakingRewards(_tokenId);

        uint256 feeAmount = burnFee * 0.001 ether;
        uint256 totalBalance = _withdrawAndBurn(_tokenId);
        if (totalBalance < feeAmount) revert InsufficientBalance();

        liquidityPool.withdraw(address(this), totalBalance);
        (bool sent, ) = address(msg.sender).call{value: totalBalance - feeAmount}("");
        if (!sent) revert InvalidWithdraw();
        _emitNftUpdateEvent(_tokenId);
    }

    /// @notice Sacrifice the staking rewards and earn more points
    /// @dev This function allows users to stake their ETH to earn membership points faster.
    /// @param _tokenId The ID of the membership NFT.
    /// @param _amount The amount of ETH which sacrifices its staking rewards to earn points faster
    function stakeForPoints(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        revert Deprecated();
    }

    /// @notice Unstakes ETH.
    /// @dev This function allows users to un-do 'stakeForPoints'
    /// @param _tokenId The ID of the membership NFT.
    /// @param _amount The amount of ETH to unstake for staking rewards.
    function unstakeForPoints(uint256 _tokenId, uint256 _amount) external whenNotPaused {
        revert Deprecated();
    }

    /// @notice Claims {points, staking rewards} and update the tier, if needed.
    /// @param _tokenId The ID of the membership NFT.
    /// @dev This function allows users to claim the rewards + a new tier, if eligible.
    function claim(uint256 _tokenId) public whenNotPaused {
        uint8 oldTier = tokenData[_tokenId].tier;
        uint8 newTier = membershipNFT.claimableTier(_tokenId);
        if (oldTier == newTier) {
            return;
        }

        _claimPoints(_tokenId);
        _claimStakingRewards(_tokenId);
        _claimTier(_tokenId, oldTier, newTier);
        _emitNftUpdateEvent(_tokenId);
    }

    /// @notice Distributes staking rewards to eligible stakers.
    /// @dev This function distributes staking rewards to eligible NFTs based on their staked tokens and membership tiers.
    function distributeStakingRewards() external {
        _requireAdmin();
        (uint96[] memory globalIndex, uint128[] memory adjustedShares) = calculateGlobalIndex();
        uint128 totalShares = 0;
        for (uint256 i = 0; i < tierDeposits.length; i++) {
            uint256 amounts = liquidityPool.amountForShare(adjustedShares[i]);
            tierDeposits[i].shares = adjustedShares[i];
            tierData[i].rewardsGlobalIndex = globalIndex[i];
            totalShares += tierDeposits[i].shares;
        }

        // Restricts the total amount of the withdrawable staking rewards
        sharesReservedForRewards = uint128(eETH.shares(address(this))) - totalShares;
    }

    error TierLimitExceeded();
    function addNewTier(uint40 _requiredTierPoints, uint24 _weight) external returns (uint256) {
        _requireAdmin();
        if (tierDeposits.length >= type(uint8).max) revert TierLimitExceeded();
        tierDeposits.push(TierDeposit(0, 0));
        tierData.push(TierData(0, _requiredTierPoints, _weight, 0));
        return tierDeposits.length - 1;
    }

    error OutOfBound();
    function updateTier(uint8 _tier, uint40 _requiredTierPoints, uint24 _weight) external {
        _requireAdmin();
        if (_tier >= tierData.length) revert OutOfBound();
        tierData[_tier].requiredTierPoints = _requiredTierPoints;
        tierData[_tier].weight = _weight;
    }

    /// @notice Sets the points for a given Ethereum address.
    /// @dev This function allows the contract owner to set the points for a specific Ethereum address.
    /// @param _tokenIds The ID of the membership NFT.
    /// @param _loyaltyPoints The number of loyalty points to set for the specified NFT.
    /// @param _tierPoints The number of tier points to set for the specified NFT.
    function setPointsBatch(uint256[] calldata _tokenIds, uint40[] calldata _loyaltyPoints, uint40[] calldata _tierPoints) external {
        _requireAdmin();
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            _setPoints(tokenId, _loyaltyPoints[i], _tierPoints[i]);
            _claimTier(tokenId);
            _emitNftUpdateEvent(tokenId);
        }
    }

    /// @notice Sets the points for a given Ethereum address.
    /// @dev This function allows the contract owner to set the points for a specific Ethereum address.
    /// @param _tokenId The ID of the membership NFT.
    /// @param _loyaltyPoints The number of loyalty points to set for the specified NFT.
    /// @param _tierPoints The number of tier points to set for the specified NFT.
    function setPoints(uint256 _tokenId, uint40 _loyaltyPoints, uint40 _tierPoints) external {
        _requireAdmin();
        _setPoints(_tokenId, _loyaltyPoints, _tierPoints);
        _claimTier(_tokenId);
        _emitNftUpdateEvent(_tokenId);
    }

    error InvalidWithdraw();
    function withdrawFees(uint256 _amount) external {
        _requireAdmin();
        if (address(this).balance < _amount) revert InvalidWithdraw();
        uint256 treasuryFees = _amount * treasuryFeeSplitPercent / 100;
        uint256 protocolRevenueFees = _amount * protocolRevenueFeeSplitPercent / 100;

        bool sent;
        if (treasuryFees > 0) {
            (sent, ) = address(treasury).call{value: treasuryFees}("");
            if (!sent) revert InvalidWithdraw();
        }
        if (protocolRevenueFees > 0) {
            (sent, ) = address(protocolRevenueManager).call{value: protocolRevenueFees}("");
            if (!sent) revert InvalidWithdraw();
        }
    }

    function updatePointsParams(uint16 _newPointsBoostFactor, uint16 _newPointsGrowthRate) external {
        _requireAdmin();
        pointsBoostFactor = _newPointsBoostFactor;
        pointsGrowthRate = _newPointsGrowthRate;
    }

    /// @dev set how many blocks a token is locked from trading for after withdrawing
    function setWithdrawalLockBlocks(uint32 _blocks) external {
        _requireAdmin();
        withdrawalLockBlocks = _blocks;
    }

    /// @notice Updates minimum valid deposit
    /// @param _value minimum deposit in wei
    function setMinDepositWei(uint56 _value) external {
        _requireAdmin();
        minDepositGwei = _value;
    }

    /// @notice Updates minimum valid deposit
    /// @param _percent integer percentage value
    function setMaxDepositTopUpPercent(uint8 _percent) external {
        _requireAdmin();
        maxDepositTopUpPercent = _percent;
    }

    /// @notice Updates the time a user must wait between top ups
    /// @param _newWaitTime the new time to wait between top ups
    function setTopUpCooltimePeriod(uint32 _newWaitTime) external {
        _requireAdmin();
        topUpCooltimePeriod = _newWaitTime;
    }

    function setFeeAmounts(uint256 _mintFeeAmount, uint256 _burnFeeAmount, uint256 _upgradeFeeAmount) external {
        _requireAdmin();
        _feeAmountSanityCheck(_mintFeeAmount);
        _feeAmountSanityCheck(_burnFeeAmount);
        _feeAmountSanityCheck(_upgradeFeeAmount);
        mintFee = uint16(_mintFeeAmount / 0.001 ether);
        burnFee = uint16(_burnFeeAmount / 0.001 ether);
        upgradeFee = uint16(_upgradeFeeAmount / 0.001 ether);
    }

    function setFeeSplits(uint8 _treasurySplitPercent, uint8 _protocolRevenueManagerSplitPercent) external {
        _requireAdmin();
        if (_treasurySplitPercent + _protocolRevenueManagerSplitPercent != 100) revert InvalidAmount();
        treasuryFeeSplitPercent = _treasurySplitPercent;
        protocolRevenueFeeSplitPercent = _protocolRevenueManagerSplitPercent;
    }

    /// @notice Updates the address of the admin
    /// @param _newAdmin the new address to set as admin
    function updateAdmin(address _newAdmin) external onlyOwner {
        admin = _newAdmin;
    }

    //Pauses the contract
    function pauseContract() external {
        _requireAdmin();
        _pause();
    }

    //Unpauses the contract
    function unPauseContract() external {
        _requireAdmin();
        _unpause();
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    error WrongTokenMinted();

    /**
    * @dev Internal function to mint a new membership NFT.
    * @param _to The address of the recipient of the NFT.
    * @param _amount The amount of ETH to earn the staking rewards.
    * @param _amountForPoints The amount of ETH to boost the points earnings.
    * @param _loyaltyPoints The initial loyalty points for the NFT.
    * @param _tierPoints The initial tier points for the NFT.
    * @return tokenId The unique ID of the newly minted NFT.
    */
    function _mintMembershipNFT(address _to, uint256 _amount, uint256 _amountForPoints, uint40 _loyaltyPoints, uint40 _tierPoints) internal returns (uint256) {
        uint256 tokenId = membershipNFT.nextMintTokenId();
        uint8 tier = tierForPoints(_tierPoints);

        tokenData[tokenId] = TokenData(tierData[tier].rewardsGlobalIndex, _loyaltyPoints, _tierPoints, uint32(block.timestamp), 0, tier, 0);

        _deposit(tokenId, _amount, _amountForPoints);

        // Finally, we mint the token!
        if (tokenId != membershipNFT.mint(_to, 1)) revert WrongTokenMinted();

        return tokenId;
    }

    function _deposit(uint256 _tokenId, uint256 _amount, uint256 _amountForPoints) internal {
        if (_amountForPoints != 0) revert Deprecated();
        uint256 tier = tokenData[_tokenId].tier;
        _incrementTokenDeposit(_tokenId, _amount + _amountForPoints);
        _incrementTierDeposit(tier, _amount + _amountForPoints);
    }

    function _topUpDeposit(uint256 _tokenId, uint128 _amount, uint128 _amountForPoints) internal returns (uint256) {
        // subtract fee from provided ether. Will revert if not enough eth provided
        uint256 upgradeFeeAmount = uint256(upgradeFee) * 0.001 ether;
        uint256 additionalDeposit = msg.value - upgradeFeeAmount;
        if (!canTopUp(_tokenId, additionalDeposit, _amount, _amountForPoints)) revert InvalidDeposit();

        TokenDeposit memory deposit = tokenDeposits[_tokenId];
        TokenData storage token = tokenData[_tokenId];
        uint256 totalDeposit = deposit.amounts;
        uint256 maxDepositWithoutPenalty = (totalDeposit * maxDepositTopUpPercent) / 100;

        _deposit(_tokenId, _amount, _amountForPoints);
        token.prevTopUpTimestamp = uint32(block.timestamp);

        // proportionally dilute tier points if over deposit threshold & update the tier
        if (additionalDeposit > maxDepositWithoutPenalty) {
            uint256 dilutedPoints = (totalDeposit * token.baseTierPoints) / (additionalDeposit + totalDeposit);
            token.baseTierPoints = uint40(dilutedPoints);
            _claimTier(_tokenId);
        }

        return additionalDeposit;
    }

    function _wrapEth(uint256 _amount, uint256 _amountForPoints, bytes32[] calldata _merkleProof) internal returns (uint256) {
        liquidityPool.deposit{value: _amount + _amountForPoints}(msg.sender, address(this), _merkleProof);
        uint256 tokenId = _mintMembershipNFT(msg.sender, _amount, _amountForPoints, 0, 0);
        _emitNftUpdateEvent(tokenId);
        return tokenId;
    }

    function _withdrawAndBurn(uint256 _tokenId) internal returns (uint256) {
        TokenDeposit memory deposit = tokenDeposits[_tokenId];
        uint256 totalBalance = deposit.amounts;
        _withdraw(_tokenId, totalBalance);
        membershipNFT.burn(msg.sender, _tokenId, 1);

        // Rounding down in favor of the protocol
        // + Guard against the inflation attack
        return _min(totalBalance, liquidityPool.amountForShare(deposit.shares));
    }

    function _withdraw(uint256 _tokenId, uint256 _amount) internal {
        if (tokenDeposits[_tokenId].amounts < _amount) revert InsufficientBalance();
        uint256 tier = tokenData[_tokenId].tier;
        _decrementTokenDeposit(_tokenId, _amount);
        _decrementTierDeposit(tier, _amount);
    }

    function _incrementTokenDeposit(uint256 _tokenId, uint256 _amount) internal {
        TokenDeposit memory deposit = tokenDeposits[_tokenId];
        uint128 newAmount = deposit.amounts + uint128(_amount);
        uint128 newShare = uint128(liquidityPool.sharesForAmount(newAmount));
        tokenDeposits[_tokenId] = TokenDeposit(
            newAmount,
            newShare
        );
    }

    function _decrementTokenDeposit(uint256 _tokenId, uint256 _amount) internal {
        TokenDeposit memory deposit = tokenDeposits[_tokenId];
        uint128 newAmount = deposit.amounts - uint128(_amount);
        uint128 newShare = uint128(liquidityPool.sharesForAmount(newAmount));
        tokenDeposits[_tokenId] = TokenDeposit(
            newAmount,
            newShare
        );
    }

    function _incrementTierDeposit(uint256 _tier, uint256 _amount) internal {
        TierDeposit memory deposit = tierDeposits[_tier];
        uint128 newAmount = deposit.amounts + uint128(_amount);
        uint128 newShare = uint128(liquidityPool.sharesForAmount(newAmount));
        tierDeposits[_tier] = TierDeposit(
            newAmount,
            newShare
        );
    }

    function _decrementTierDeposit(uint256 _tier, uint256 _amount) internal {
        TierDeposit memory deposit = tierDeposits[_tier];
        uint128 newAmount = deposit.amounts - uint128(_amount);
        uint128 newShare = uint128(liquidityPool.sharesForAmount(newAmount));
        tierDeposits[_tier] = TierDeposit(
            newAmount,
            newShare
        );
    }

    function _claimTier(uint256 _tokenId) internal {
        uint8 oldTier = tokenData[_tokenId].tier;
        uint8 newTier = membershipNFT.claimableTier(_tokenId);
        _claimTier(_tokenId, oldTier, newTier);
    }

    error UnexpectedTier();

    function _claimTier(uint256 _tokenId, uint8 _curTier, uint8 _newTier) internal {
        if (tokenData[_tokenId].tier != _curTier) revert UnexpectedTier();
        if (_curTier == _newTier) {
            return;
        }
        uint256 amount = tokenDeposits[_tokenId].amounts;
        _decrementTierDeposit(_curTier, amount);
        _incrementTierDeposit(_newTier, amount);
        tokenData[_tokenId].rewardsLocalIndex = tierData[_newTier].rewardsGlobalIndex;
        tokenData[_tokenId].tier = _newTier;
    }

    /// @notice Claims the accrued membership {loyalty, tier} points.
    /// @param _tokenId The ID of the membership NFT.
    function _claimPoints(uint256 _tokenId) internal {
        TokenData storage token = tokenData[_tokenId];
        token.baseLoyaltyPoints = membershipNFT.loyaltyPointsOf(_tokenId);
        token.baseTierPoints = membershipNFT.tierPointsOf(_tokenId);
        token.prevPointsAccrualTimestamp = uint32(block.timestamp);
    }

    error NotEnoughReservedRewards();

    /// @notice Claims the staking rewards for a specific membership NFT.
    /// @dev This function allows users to claim the staking rewards earned by a specific membership NFT.
    /// @param _tokenId The ID of the membership NFT.
    function _claimStakingRewards(uint256 _tokenId) internal {
        TokenData storage token = tokenData[_tokenId];
        uint256 tier = token.tier;
        uint256 amount = membershipNFT.accruedStakingRewardsOf(_tokenId);
        // Round-up in favor of safety of the protocol
        uint256 share = liquidityPool.sharesForWithdrawalAmount(amount);
        if (share > sharesReservedForRewards) {
            // This guard is against any malicious BIG withdrawal of staking rewards beyond limit
            // It may have some false alerts in theory because the rounding-up in calculating the share.
            // But it is rare in practice.
            revert NotEnoughReservedRewards();
        }
        _incrementTokenDeposit(_tokenId, amount);
        _incrementTierDeposit(tier, amount);
        sharesReservedForRewards -= uint128(share);
        token.rewardsLocalIndex = tierData[tier].rewardsGlobalIndex;
    }

    function _updateAllTimeHighDepositOf(uint256 _tokenId) internal {
        allTimeHighDepositAmount[_tokenId] = membershipNFT.allTimeHighDepositOf(_tokenId);
    }

    error OnlyTokenOwner();
    function _requireTokenOwner(uint256 _tokenId) internal {
        if (membershipNFT.balanceOfUser(msg.sender, _tokenId) != 1) revert OnlyTokenOwner();
    }

    error OnlyAdmin();
    function _requireAdmin() internal {
        if (msg.sender != admin) revert OnlyAdmin();
    }

    function _feeAmountSanityCheck(uint256 _feeAmount) internal {
        if (_feeAmount % 0.001 ether != 0 || _feeAmount / 0.001 ether > type(uint16).max) revert InvalidAmount();
    }

    error IntegerOverflow();

    /**
    * @dev This function calculates the global index and adjusted shares for each tier used for reward distribution.
    *
    * The function performs the following steps:
    * 1. Iterates over each tier, computing rebased amounts, tier rewards, weighted tier rewards.
    * 2. Sums all the tier rewards and the weighted tier rewards.
    * 3. If there are any weighted tier rewards, it iterates over each tier to perform the following actions:
    *    a. Computes the amounts eligible for rewards.
    *    b. If there are amounts eligible for rewards, 
    *       it calculates rescaled tier rewards and updates the global index and adjusted shares for the tier.
    *
    * The rescaling of tier rewards is done based on the weight of each tier. 
    *
    * @notice This function essentially pools all the staking rewards across tiers and redistributes them proportional to the tier weights
    * @return globalIndex A uint96 array containing the updated global index for each tier.
    * @return adjustedShares A uint128 array containing the updated shares for each tier reflecting the amount of staked ETH in the liquidity pool.
    */
    function calculateGlobalIndex() public view returns (uint96[] memory, uint128[] memory) {
        uint96[] memory globalIndex = new uint96[](tierDeposits.length);
        uint128[] memory adjustedShares = new uint128[](tierDeposits.length);
        uint256[] memory weightedTierRewards = new uint256[](tierDeposits.length);
        uint256[] memory tierRewards = new uint256[](tierDeposits.length);
        uint256 sumTierRewards = 0;
        uint256 sumWeightedTierRewards = 0;
        for (uint256 i = 0; i < weightedTierRewards.length; i++) {
            TierDeposit memory deposit = tierDeposits[i];
            uint256 rebasedAmounts = liquidityPool.amountForShare(deposit.shares);
            if (rebasedAmounts >= deposit.amounts) {
                tierRewards[i] = rebasedAmounts - deposit.amounts;
                weightedTierRewards[i] = tierData[i].weight * tierRewards[i];
            }
            globalIndex[i] = tierData[i].rewardsGlobalIndex;
            adjustedShares[i] = tierDeposits[i].shares;

            sumTierRewards += tierRewards[i];
            sumWeightedTierRewards += weightedTierRewards[i];
        }

        if (sumWeightedTierRewards > 0) {
            for (uint256 i = 0; i < weightedTierRewards.length; i++) {
                uint256 shares = tierDeposits[i].shares;
                if (shares > 0) {
                    uint256 rescaledTierRewards = weightedTierRewards[i] * sumTierRewards / sumWeightedTierRewards;
                    uint256 delta = 1 ether * rescaledTierRewards / shares;

                    if (uint256(globalIndex[i]) + uint256(delta) > type(uint96).max) revert IntegerOverflow();

                    globalIndex[i] += uint96(delta);
                    adjustedShares[i] = uint128(liquidityPool.sharesForAmount(tierDeposits[i].amounts));
                }
            }
        }

        return (globalIndex, adjustedShares);
    }

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a > _b) ? _b : _a;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a > _b) ? _a : _b;
    }

    /// @notice Applies the unwrap penalty.
    /// @dev Always lose at least a tier, possibly more depending on percentage of deposit withdrawn
    /// @param _tokenId The ID of the membership NFT.
    /// @param _prevAmount The amount of ETH that the NFT was holding
    /// @param _withdrawalAmount The amount of ETH that is being withdrawn
    function _applyUnwrapPenalty(uint256 _tokenId, uint256 _prevAmount, uint256 _withdrawalAmount) internal {
        TokenData storage token = tokenData[_tokenId];
        uint8 prevTier = token.tier > 0 ? token.tier - 1 : 0;
        uint40 curTierPoints = token.baseTierPoints;

        // point deduction if we kick back to start of previous tier
        uint40 degradeTierPenalty = curTierPoints - tierData[prevTier].requiredTierPoints;

        // point deduction if scaled proportional to withdrawal amount
        uint256 ratio = (10000 * _withdrawalAmount) / _prevAmount;
        uint40 scaledTierPointsPenalty = uint40((ratio * curTierPoints) / 10000);

        uint40 penalty = uint40(_max(degradeTierPenalty, scaledTierPointsPenalty));

        token.baseTierPoints -= penalty;
        _claimTier(_tokenId);
    }

    function _setPoints(uint256 _tokenId, uint40 _loyaltyPoints, uint40 _tierPoints) internal {
        TokenData storage token = tokenData[_tokenId];
        token.baseLoyaltyPoints = _loyaltyPoints;
        token.baseTierPoints = _tierPoints;
        token.prevPointsAccrualTimestamp = uint32(block.timestamp);
    }

    function _emitNftUpdateEvent(uint256 _tokenId) internal {
        TokenDeposit memory deposit = tokenDeposits[_tokenId];
        TokenData memory token = tokenData[_tokenId];
        emit NftUpdated(_tokenId, deposit.amounts, 0,
                        token.baseLoyaltyPoints, token.baseTierPoints, token.tier,
                        token.prevTopUpTimestamp, token.rewardsLocalIndex);
    }

    // Finds the corresponding for the tier points
    function tierForPoints(uint40 _tierPoints) public view returns (uint8) {
        uint8 tierId = 0;

        while (tierId < tierData.length && _tierPoints >= tierData[tierId].requiredTierPoints) {
            tierId++;
        }

        return tierId - 1;
    }

    function canTopUp(uint256 _tokenId, uint256 _totalAmount, uint128 _amount, uint128 _amountForPoints) public view returns (bool) {
        uint32 prevTopUpTimestamp = tokenData[_tokenId].prevTopUpTimestamp;
        if (block.timestamp - uint256(prevTopUpTimestamp) < topUpCooltimePeriod) return false;
        if (_totalAmount != _amount + _amountForPoints) return false;
        return true;
    }

    function numberOfTiers() external view returns (uint8) {
        return uint8(tierData.length);
    }

    function minimumAmountForMint() external view returns (uint256) {
        return uint256(1 gwei) * minDepositGwei;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //--------------------------------------  GETTER  --------------------------------------
    //--------------------------------------------------------------------------------------

    // returns (mintFeeAmount, burnFeeAmount, upgradeFeeAmount)
    function getFees() external view returns (uint256 mintFeeAmount, uint256 burnFeeAmount, uint256 upgradeFeeAmount) {
        return (uint256(mintFee) * 0.001 ether, uint256(burnFee) * 0.001 ether, uint256(upgradeFee) * 0.001 ether);
    }

    function rewardsGlobalIndex(uint8 _tier) external view returns (uint256) {
        return tierData[_tier].rewardsGlobalIndex;
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    //--------------------------------------------------------------------------------------
    //------------------------------------  MODIFIER  --------------------------------------
    //--------------------------------------------------------------------------------------

}