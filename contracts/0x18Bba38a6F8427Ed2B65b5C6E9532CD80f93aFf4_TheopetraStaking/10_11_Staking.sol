// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
import "../Types/TheopetraAccessControlled.sol";
import "../Libraries/SafeMath.sol";
import "../Libraries/SafeERC20.sol";

import "../Interfaces/IDistributor.sol";
import "../Interfaces/IStakedTHEOToken.sol";
import "../Interfaces/ITHEO.sol";
import "../Interfaces/ITreasury.sol";

contract TheopetraStaking is TheopetraAccessControlled {
    using SafeMath for *;
    using SafeERC20 for IERC20;
    using SafeERC20 for IStakedTHEOToken;
    using SafeERC20 for ITHEO;

    /* ====== VARIABLES ====== */

    Epoch public epoch;

    address public immutable THEO;
    address public immutable sTHEO;
    address public immutable treasury;
    uint256 public immutable stakingTerm;

    address public distributor;

    address public locker;
    uint256 public totalBonus;

    address public warmupContract;
    uint256 public warmupPeriod;

    uint256 private gonsInWarmup;
    uint256 private slashedGons;

    mapping(address => Claim[]) public stakingInfo;
    mapping(address => bool) private isExternalLocked;
    mapping(address => mapping(uint256 => address)) private claimTransfers; // change claim ownership
    mapping(uint256 => uint256) penaltyBands;
    mapping(address => bool) private bondDepos;

    event Stake(address user, uint256 amount, uint256 index);
    event Unstake(address user, uint256 amount, uint256 index);
    event WarmupClaimed(address user, uint256 amount, uint256 index);
    event DefinePenalty(uint256 band, uint256 amount);
    event LockBonusManaged(uint256 amount);
    event SetContract(CONTRACTS contractType, address addr);
    event SetWarmup(uint256 period);
    event SetBondDepo(address depoAddress, bool isDepo);
    event PullClaim(address from, uint256 index);
    event PushClaim(address to, uint256 index);

    /* ====== STRUCTS ====== */

    struct Epoch {
        uint256 length;
        uint256 number;
        uint256 end;
        uint256 distribute;
    }

    struct Claim {
        uint256 deposit;
        uint256 gonsInWarmup;
        uint256 warmupExpiry;
        uint256 stakingExpiry;
        uint256 gonsRemaining;
    }

    struct UnstakeAmounts {
        uint256 _amountSingle;
        uint256 _gonsRemaining;
    }

    constructor(
        address _THEO,
        address _sTHEO,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        uint256 _stakingTerm,
        address _authority,
        address _treasury
    ) TheopetraAccessControlled(ITheopetraAuthority(_authority)) {
        uint256[] memory bands = new uint256[](20);
        uint256[] memory penalties = new uint256[](20);

        for (uint256 i = 1; i < 21; i++) {
            bands[i - 1] = i;
            penalties[i - 1] = 21 - i;
        }

        _definePenalties(bands, penalties);

        require(_THEO != address(0), "Invalid address");
        THEO = _THEO;
        require(_sTHEO != address(0), "Invalid address");
        sTHEO = _sTHEO;
        stakingTerm = _stakingTerm;
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;

        epoch = Epoch({ length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0 });
    }

    /**
        @notice stake THEO to enter warmup
        @dev    if warmupPeriod is 0 and _claim is true, funds are sent immediately, and warmupExpiry is 0:
                this is so that the staker cannot retrieve sTHEO from warmup using the stored
                Claim (see also `claim`). If warmupPeriod is not 0, or if _claim is false, then funds go into warmup (sTheo is not sent)
        @param _amount uint
        @param _claim bool
        @return uint256 _amount staked
        @return _index uint256 the index of the claim added for the recipient in the recipient's stakingInfo
     */
    function stake(
        address _recipient,
        uint256 _amount,
        bool _claim
    ) external returns (uint256, uint256 _index) {
        rebase();
        IERC20(THEO).safeTransferFrom(msg.sender, address(this), _amount);

        if (!isExternalLocked[_recipient]) {
            require(_recipient == msg.sender, "External deposits for account are locked");
        }

        uint256 _index = stakingInfo[_recipient].length;

        if (warmupPeriod == 0 && _claim) {
            stakingInfo[_recipient].push(
                Claim({
                    deposit: _amount,
                    gonsInWarmup: 0,
                    warmupExpiry: 0,
                    stakingExpiry: block.timestamp.add(stakingTerm),
                    gonsRemaining: IStakedTHEOToken(sTHEO).gonsForBalance(_amount)
                })
            );

            _send(_recipient, _amount);
        } else {
            gonsInWarmup = gonsInWarmup.add(IStakedTHEOToken(sTHEO).gonsForBalance(_amount));
            stakingInfo[_recipient].push(
                Claim({
                    deposit: _amount,
                    gonsInWarmup: IStakedTHEOToken(sTHEO).gonsForBalance(_amount),
                    warmupExpiry: block.timestamp.add(warmupPeriod),
                    stakingExpiry: block.timestamp.add(stakingTerm),
                    gonsRemaining: 0
                })
            );
        }

        emit Stake(msg.sender, _amount, _index);
        return (_amount, _index);
    }

    /**
        @notice retrieve sTHEO from warmup
        @dev    After a claim has been retrieved (and a subsequent call to `isUnRetrieved` returns false),
                the claim cannot be re-retrieved; gonsRemaining is therefore only set once by this method for each Claim
        @param _recipient address
        @param _indexes uint256[]      indexes of the sTHEO to retrieve
        @return amount_                The sum total amount of sTHEO sent
     */
    function claim(address _recipient, uint256[] memory _indexes) public returns (uint256 amount_) {
        if (!isExternalLocked[_recipient]) {
            require(_recipient == msg.sender, "External claims for account are locked");
        }

        uint256 amount_ = 0;
        for (uint256 i = 0; i < _indexes.length; i++) {
            if (isUnRetrieved(_recipient, i)) {
                Claim memory info = stakingInfo[_recipient][_indexes[i]];

                if (block.timestamp >= info.warmupExpiry && info.warmupExpiry != 0) {
                    stakingInfo[_recipient][_indexes[i]].gonsInWarmup = 0;

                    gonsInWarmup = gonsInWarmup.sub(info.gonsInWarmup);
                    uint256 balanceForGons = IStakedTHEOToken(sTHEO).balanceForGons(info.gonsInWarmup);
                    stakingInfo[_recipient][_indexes[i]].gonsRemaining = info.gonsInWarmup;
                    amount_ = amount_.add(balanceForGons);

                    emit WarmupClaimed(_recipient, balanceForGons, _indexes[i]);
                }
            }
        }

        return _send(_recipient, amount_);
    }

    /**
     * @notice             claim all retrievable (from warmup) claims for user
     * @dev                if possible, query indexesFor() off-chain and input in claim() to save gas
     * @param _recipient   address. The recipient to retrieve sTHEO from all claims for
     * @return             sum of claim amounts sent, in sTHEO
     */
    function claimAll(address _recipient) external returns (uint256) {
        return claim(_recipient, indexesFor(_recipient, true));
    }

    /**
        @notice forfeit sTHEO in warmup and retrieve THEO
     */
    function forfeit(uint256 _index) external {
        Claim memory info = stakingInfo[msg.sender][_index];
        require(info.gonsInWarmup > 0, "Claim has already been retrieved");
        delete stakingInfo[msg.sender][_index];

        gonsInWarmup = gonsInWarmup.sub(info.gonsInWarmup);

        IERC20(THEO).safeTransfer(msg.sender, info.deposit);
    }

    /**
        @notice prevent new deposits or claims to/from external address (protection from malicious activity)
     */
    function toggleLock() external {
        isExternalLocked[msg.sender] = !isExternalLocked[msg.sender];
    }

    /**
     * @notice redeem sTHEO for THEO from un-redeemed claims
     * @dev    if `stakingExpiry` has not yet passed, Determine the penalty for removing early.
     *         `percentageComplete` is the percentage of time that the stake has completed (versus the `stakingTerm`), expressed with 4 decimals.
     *         note that For unstaking before 100% of staking term, only the principle deposit -- less a penalty -- is returned. In this case, the full claim must be redeemed
     *         and gonsRemaining becomes zero.
     *         note that For unstaking at or beyond 100% of the staking term, a part-redeem can be made: that is, a user may redeem less than 100% of the total amount available to redeem
     *         (as represented by gonsRemaining), during a call to `unstake`
     *         note that The penalty is added (after conversion to gons) to `slasheGons` and subtracted from the amount to return
     *         gonsRemaining keeps track of the amount of sTheo (as gons) that can be redeemed for a Claim
     *         note that When unstaking from the locked tranche (stakingTerm > 0) after the stake reaches maturity,
     *         the Stake becomes eligible to claim against bonus pool rewards (tracked in `slashedGons`; see also `getSlashedRewards`)
     * @param _to address
     * @param _amounts uint
     * @param _trigger bool
     * @param _indexes uint256[]
     * @return amount_ uint
     */
    function unstake(
        address _to,
        uint256[] memory _amounts,
        bool _trigger,
        uint256[] memory _indexes
    ) external returns (uint256 amount_) {
        if (!isExternalLocked[_to]) {
            require(_to == msg.sender, "External unstaking for account is locked");
        }
        require(_amounts.length == _indexes.length, "Amounts and indexes lengths do not match");

        amount_ = 0;
        uint256 bounty;

        uint256[] memory amountsAsGons = new uint256[](_indexes.length);
        for (uint256 i = 0; i < _indexes.length; i++) {
            amountsAsGons[i] = IStakedTHEOToken(sTHEO).gonsForBalance(_amounts[i]);
        }

        if (_trigger) {
            bounty = rebase();
        }

        for (uint256 i = 0; i < _indexes.length; i++) {
            Claim memory info = stakingInfo[_to][_indexes[i]];
            UnstakeAmounts memory unstakeAmounts;
            unstakeAmounts._amountSingle = IStakedTHEOToken(sTHEO).balanceForGons(amountsAsGons[i]);

            if (isUnRedeemed(_to, _indexes[i])) {
                unstakeAmounts._gonsRemaining = IStakedTHEOToken(sTHEO).gonsForBalance(
                    IStakedTHEOToken(sTHEO).balanceForGons(info.gonsRemaining)
                );

                stakingInfo[_to][_indexes[i]].gonsRemaining = (unstakeAmounts._gonsRemaining).sub(
                    IStakedTHEOToken(sTHEO).gonsForBalance(unstakeAmounts._amountSingle)
                );

                IStakedTHEOToken(sTHEO).safeTransferFrom(msg.sender, address(this), unstakeAmounts._amountSingle);

                if (block.timestamp >= info.stakingExpiry) {
                    uint256 slashedRewards = 0;
                    if (stakingTerm > 0) {
                        slashedRewards = getSlashedRewards(unstakeAmounts._amountSingle);
                    }

                    amount_ = amount_.add(bounty).add(unstakeAmounts._amountSingle).add(slashedRewards);
                } else if (block.timestamp < info.stakingExpiry) {
                    require(
                        stakingInfo[_to][_indexes[i]].gonsRemaining == 0,
                        "Amount does not match available remaining to redeem"
                    );

                    uint256 penalty = getPenalty(
                        stakingInfo[_to][_indexes[i]].deposit,
                        (1000000.sub(((info.stakingExpiry.sub(block.timestamp)).mul(1000000)).div(stakingTerm))).div(
                            10000
                        )
                    );

                    slashedGons = slashedGons.add(IStakedTHEOToken(sTHEO).gonsForBalance(penalty));

                    amount_ = amount_.add(stakingInfo[_to][_indexes[i]].deposit).sub(penalty);
                }
            }

            emit Unstake(_to, unstakeAmounts._amountSingle, _indexes[i]);
        }

        require(amount_ <= ITHEO(THEO).balanceOf(address(this)), "Insufficient THEO balance in contract");
        ITHEO(THEO).safeTransfer(_to, amount_);
    }

    /**
        @dev slashedRewards is calculated as: (StakerTokens/totalStakedTokens) * totalSlashedTokens
     */
    function getSlashedRewards(uint256 amount) private view returns (uint256) {
        uint256 circulatingSupply = IStakedTHEOToken(sTHEO).circulatingSupply();
        uint256 baseDecimals = 10**9;

        return
            circulatingSupply > 0
                ? ((amount.add(circulatingSupply)).mul(baseDecimals).div(circulatingSupply).sub(baseDecimals))
                    .mul(IStakedTHEOToken(sTHEO).balanceForGons(slashedGons))
                    .div(baseDecimals)
                : 0;
    }

    function _definePenalties(uint256[] memory bands, uint256[] memory penalties) private {
        require(bands.length == penalties.length, "Arrays must be the same length");
        for (uint256 i = 0; i < bands.length; i++) {
            _definePenalty(bands[i], penalties[i]);
        }
    }

    function definePenalties(uint256[] memory bands, uint256[] memory penalties) public onlyPolicy {
        _definePenalties(bands, penalties);
    }

    function _definePenalty(uint256 _percentBandMax, uint256 _penalty) private {
        penaltyBands[_percentBandMax] = _penalty;
        emit DefinePenalty(_percentBandMax, _penalty);
    }

    function ceil(uint256 a, uint256 m) private view returns (uint256) {
        return a == 0 ? m : ((a.add(m).sub(1)).div(m)).mul(m);
    }

    function getPenalty(uint256 _amount, uint256 stakingTimePercentComplete) public view returns (uint256) {
        if (stakingTimePercentComplete == 100) {
            return 0;
        }

        uint256 penaltyBand = ceil(stakingTimePercentComplete, 5).div(5);
        uint256 penaltyPercent = penaltyBands[penaltyBand];

        return _amount.mul(penaltyPercent).div(100);
    }

    /**
        @notice trigger rebase if epoch over
        @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            ITreasury(treasury).tokenPerformanceUpdate();

            IStakedTHEOToken(sTHEO).rebase(epoch.distribute, epoch.number);

            epoch.end = epoch.end.add(epoch.length);
            epoch.number++;

            if (distributor != address(0)) {
                IDistributor(distributor).distribute();
                bounty = IDistributor(distributor).retrieveBounty(); // Will mint THEO for this contract if there exists a bounty
            }

            uint256 balance = contractBalance();
            uint256 staked = IStakedTHEOToken(sTHEO).circulatingSupply();

            if (balance <= staked.add(bounty)) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance.sub(staked).sub(bounty);
            }
        }
        return bounty;
    }

    /**
        @notice returns contract THEO holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns (uint256) {
        return IERC20(THEO).balanceOf(address(this)).add(totalBonus);
    }

    /**
        @notice provide bonus to locked staking contract
        @param _amount uint
     */
    function giveLockBonus(uint256 _amount) external {
        require(msg.sender == locker, "Only the locker can give bonuses");
        totalBonus = totalBonus.add(_amount);
        IERC20(sTHEO).safeTransfer(locker, _amount);
        emit LockBonusManaged(-_amount);
    }

    /**
        @notice reclaim bonus from locked staking contract
        @param _amount uint
     */
    function returnLockBonus(uint256 _amount) external {
        require(msg.sender == locker, "Only the locker can return bonuses");
        totalBonus = totalBonus.sub(_amount);
        IERC20(sTHEO).safeTransferFrom(locker, address(this), _amount);
        emit LockBonusManaged(_amount);
    }

    enum CONTRACTS {
        DISTRIBUTOR,
        WARMUP,
        LOCKER
    }

    /**
        @notice sets the contract address for LP staking
        @param _contract address
     */

    function setContract(CONTRACTS _contract, address _address) external onlyManager {
        require(_address != address(0), "must supply a valid address");
        if (_contract == CONTRACTS.DISTRIBUTOR) {
            // 0
            distributor = _address;
        } else if (_contract == CONTRACTS.WARMUP) {
            // 1
            require(warmupContract == address(0), "Warmup cannot be set more than once");
            warmupContract = _address;
        } else if (_contract == CONTRACTS.LOCKER) {
            // 2
            require(locker == address(0), "Locker cannot be set more than once");
            locker = _address;
        }

        emit SetContract(_contract, _address);
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup(uint256 _warmupPeriod) external onlyGuardian {
        warmupPeriod = _warmupPeriod;
        emit SetWarmup(_warmupPeriod);
    }

    /**
     * @notice set the address of a bond depo to allow it to push claims to users when redeeming bonds
     * @dev    see also `pushClaimForBond`
     * @param _bondDepo address of the bond depo
     */
    function setBondDepo(address _bondDepo, bool val) external onlyGovernor {
        bondDepos[_bondDepo] = val;
        emit SetBondDepo(_bondDepo, val);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sTHEO (equal unit as THEO)
     * @param _recipient address
     * @param _amount uint
     */
    function _send(address _recipient, uint256 _amount) internal returns (uint256) {
        IStakedTHEOToken(sTHEO).safeTransfer(_recipient, _amount);
        return _amount;
    }

    /* ========== TRANSFER ========== */

    /**
     * @notice             approve an address to transfer a claim
     * @param _to          address to approve claim transfer for
     * @param _index       index of claim to approve transfer for
     */
    function pushClaim(address _to, uint256 _index) external {
        require(stakingInfo[msg.sender][_index].stakingExpiry != 0, "Staking: claim not found");
        claimTransfers[msg.sender][_index] = _to;
    }

    /**
     * @notice             transfer a claim that has been approved by an address
     * @param _from        the address that approved the claim transfer
     * @param _index       the index of the claim to transfer (in the sender's array)
     */
    function pullClaim(address _from, uint256 _index) external returns (uint256 newIndex_) {
        require(claimTransfers[_from][_index] == msg.sender, "Staking: claim not found");
        require(
            stakingInfo[_from][_index].gonsInWarmup > 0 || stakingInfo[_from][_index].gonsRemaining > 0,
            "Staking: claim redeemed"
        );

        newIndex_ = stakingInfo[msg.sender].length;
        stakingInfo[msg.sender].push(stakingInfo[_from][_index]);

        delete stakingInfo[_from][_index];
        emit PullClaim(_from, _index);
    }

    /**
     * @notice             transfer a claim that has been approved by an address
     * @param _to          the address to push the claim to (must be pre-approved for transfer via `pushClaim`)
     * @param _index       the index of the claim to transfer (in the sender's array)
     */
    function pushClaimForBond(address _to, uint256 _index) external returns (uint256 newIndex_) {
        require(bondDepos[msg.sender], "Caller is not a bond depository");
        require(claimTransfers[msg.sender][_index] == _to, "Staking: claim not found");
        require(
            stakingInfo[msg.sender][_index].gonsInWarmup > 0 || stakingInfo[msg.sender][_index].gonsRemaining > 0,
            "Staking: claim redeemed"
        );

        newIndex_ = stakingInfo[_to].length;
        stakingInfo[_to].push(stakingInfo[msg.sender][_index]);

        delete stakingInfo[msg.sender][_index];
        emit PushClaim(_to, _index);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
        @notice returns the sTHEO index, which tracks rebase growth
        @return uint
     */
    function index() public view returns (uint256) {
        return IStakedTHEOToken(sTHEO).index();
    }

    /**
     * @notice total supply in warmup
     */
    function supplyInWarmup() public view returns (uint256) {
        return IStakedTHEOToken(sTHEO).balanceForGons(gonsInWarmup);
    }

    /**
     * @notice                all un-retrieved claims (sTHEO available to retrieve from warmup), or all un-redeemed claims (sTHEO retrieved but yet to be redeemed for THEO) for a user
     * @param _user           the user to query claims for
     * @param unRetrieved   bool. If true, return indexes of all un-claimed claims from warmup, else return indexes of all claims with un-redeemed sTheo
     * @return                indexes of un-retrieved claims, or of un-redeemed claims, for the user
     */
    function indexesFor(address _user, bool unRetrieved) public view returns (uint256[] memory) {
        Claim[] memory claims = stakingInfo[_user];

        uint256 length;
        for (uint256 i = 0; i < claims.length; i++) {
            if (unRetrieved ? isUnRetrieved(_user, i) : isUnRedeemed(_user, i)) length++;
        }

        uint256[] memory indexes = new uint256[](length);
        uint256 position;

        for (uint256 i = 0; i < claims.length; i++) {
            if (unRetrieved ? isUnRetrieved(_user, i) : isUnRedeemed(_user, i)) {
                indexes[position] = i;
                position++;
            }
        }

        return indexes;
    }

    /**
     * @notice             determine whether sTHEO has been retrieved (via `claim`) for a Claim
     * @param _user        the user to query claims for
     * @param _index       the index of the claim
     * @return bool        true if the sTHEO has not yet been retrieved for the claim
     */
    function isUnRetrieved(address _user, uint256 _index) public view returns (bool) {
        Claim memory claim = stakingInfo[_user][_index];
        return claim.gonsInWarmup > 0;
    }

    /**
     * @notice             determine whether a claim has a (non-zero) sTHEO balance remaining that can be redeemed for THEO
     *                     if the claim is still in warmup, this method will return false (as no sTheo can yet be redeemed against the claim)
     * @param _user        the user to query claims for
     * @param _index       the index of the claim
     * @return bool        true if the total sTHEO on the claim has not yet been redeemed for THEO
     */
    function isUnRedeemed(address _user, uint256 _index) public view returns (bool) {
        Claim memory claim = stakingInfo[_user][_index];
        return claim.gonsInWarmup == 0 && claim.gonsRemaining > 0;
    }

    function getClaimsCount(address _user) external view returns (uint256) {
        return stakingInfo[_user].length;
    }

    /**
     * @notice                  return the current expected rewards for a claim
     * @param _user             the user that the claim belongs to
     * @param _index            the index of the claim in the user's array
     * @return currentRewards_  the current total rewards expected for a claim (valid only for claims out of warmup),
     *                          calculated as: (sTHEO remaining + slashedRewards) - deposit amount
     *                          note that currentRewards_ does not include any potential bounty or additional sTheo balance that
     *                          may be applied if rebasing when unstaking. This function may revert or return a wrong value if a user
     *                          has un-staked some of their stake to let the current remaining balance be less than claim.deposit.
     *                          This can only happen if the user has un-staked directly with the contracts, instead of using the UI.
     *                          This also does not affect any rewards that may be applied to the claim if it is redeemed.
     */
    function rewardsFor(address _user, uint256 _index) external view returns (uint256 currentRewards_) {
        Claim memory claim = stakingInfo[_user][_index];
        uint256 _amountRemaining = IStakedTHEOToken(sTHEO).balanceForGons(claim.gonsRemaining);
        currentRewards_ = 0;
        if (isUnRedeemed(_user, _index)) {
            currentRewards_ = (_amountRemaining.add(getSlashedRewards(_amountRemaining))).sub(claim.deposit);
        }
        return currentRewards_;
    }

    /**
     * @notice             return the staking token that the tranche is based on
     *
     * @return address     the address of the staking token
     */
    function basis() public view returns (address) {
        return sTHEO;
    }
}