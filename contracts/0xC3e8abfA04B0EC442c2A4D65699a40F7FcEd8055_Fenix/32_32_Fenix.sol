// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/***********************************************************************************************************************
        ..:^~!?YPB&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
7                   .:~JP#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
&            !:            :[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@G           [email protected]@#GY7~^..       ^[email protected]@@@@@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@&!&@@@@@@@@[email protected]@@@@@@@7#@@@@@@@G7&@@@@@@@G!&@
@@J           [email protected]@@@@@@@@@&GJ^     [email protected]@@@@@@@@@@^[email protected]@@@@@@@@@@@@[email protected]@@@@@@@@@@@@& ~?&@@@@@@[email protected]@@@@@@@[email protected]@@@@@@@#[email protected]@@@#!?&@@
@@@J        ~P#@@@@@@@@@@@@@@&!     [email protected]@@@@@@@@[email protected]@@@@@@@@@@@@:[email protected]@@@@@@@@@@@@&[email protected][email protected]@@@@[email protected]@@@@@@@:[email protected]@@@@@@@@@G~P&?!&@@@@
@@@@G    [email protected]@@@@@@@@@@@@@@@@@@@Y     [email protected]@@@@@@@~^[email protected]@@@@@@@@:[email protected]@@@@@@@@&[email protected]@@[email protected]@@[email protected]@@@@@@@:[email protected]@@@@@@@@@@&. [email protected]@@@@@
@@@@@&^^&@@@@@@@@@@@@@@@@@@@@@@@:     @@@@@@@@[email protected]@@@@@@@@@@@@:[email protected]@@@@@@@@@@@@&[email protected]@@@@[email protected][email protected]@@@@@@@:[email protected]@@@@@@@@@[email protected][email protected]@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&5!^^!P~     [email protected]@@@@@@[email protected]@@@@@@@@@@@@:[email protected]@@@@@@@@@@@@&[email protected]@@@@@&[email protected]@@@@@@@[email protected]@@@@@@@[email protected]@@@&7!&@@
@@@@@@@@@@@@@@@@@@@@@@@@Y             [email protected]@@@@@@[email protected]@@@@@@@@@@@@^!5555Y#@@@@@@@&:@@@@@@@@&^[email protected]@@@@@@@^[email protected]@@@@@&[email protected]@@@@@@@#[email protected]
@@@@@@@@@@@@@@@@@@@@@@@&             [email protected]@@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@
@@@@@@@@@@@@@@@@@@@@@@@@7           [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@#7.    .^Y&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
***********************************************************************************************************************/

import { UD60x18, convert, wrap, unwrap, ud, E, ZERO } from "@prb/math/UD60x18.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IBurnableToken } from "xen-crypto/interfaces/IBurnableToken.sol";
import { IBurnRedeemable } from "xen-crypto/interfaces/IBurnRedeemable.sol";

enum Status {
    ACTIVE,
    DEFER,
    END
}

struct Stake {
    Status status;
    uint40 startTs;
    uint40 deferralTs;
    uint40 endTs;
    uint16 term;
    uint256 fenix;
    uint256 shares;
    uint256 payout;
}

struct Reward {
    uint40 id;
    uint40 rewardTs;
    uint256 fenix;
    address caller;
}

///----------------------------------------------------------------------------------------------------------------
/// Events
///----------------------------------------------------------------------------------------------------------------
library FenixError {
    error WrongCaller(address caller);
    error AddressZero();
    error BalanceZero();
    error TermZero();
    error TermGreaterThanMax();
    error StakeNotActive();
    error StakeNotEnded();
    error StakeLate();
    error CooldownActive();
    error StakeStatusAlreadySet(Status status);
    error SizeGreaterThanMax();
}

/// @title FENIX pays you to hold your own crypto
/// @author Joe Blau <[email protected]>
/// @notice FENIX pays you to hold your own crypto
/// @dev Fenix is an ERC20 token that pays you to hold your own crypto.
contract Fenix is IBurnRedeemable, IERC165, ERC20("FENIX", "FENIX") {
    ///----------------------------------------------------------------------------------------------------------------
    /// Constants
    ///----------------------------------------------------------------------------------------------------------------

    address public constant XEN_ADDRESS = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;

    uint256 public constant XEN_BURN_RATIO = 10_000;

    uint256 public constant MAX_STAKE_LENGTH_DAYS = 7_777;

    uint256 internal constant UINT256_MAX = type(uint256).max;
    uint256 internal constant ONE_DAY_TS = 86_400; // (1 day)
    uint256 internal constant ONE_EIGHTY_DAYS_TS = 15_552_000; // 86_400 * 180 (180 days)
    uint256 internal constant REWARD_COOLDOWN_TS = 7_862_400; // 86_400 * 7 * 13  (13 weeks)
    uint256 internal constant REWARD_LAUNCH_COOLDOWN_TS = 1_814_400; // 86_400 * 7 * 3 (3 weeks)

    UD60x18 public constant ANNUAL_INFLATION_RATE = UD60x18.wrap(0.016180339887498948e18);
    UD60x18 internal constant ONE = UD60x18.wrap(1e18);
    UD60x18 internal constant ONE_YEAR_DAYS = UD60x18.wrap(365);

    ///----------------------------------------------------------------------------------------------------------------
    /// Variables
    ///----------------------------------------------------------------------------------------------------------------

    uint40 public immutable genesisTs;
    uint256 public cooldownUnlockTs;
    uint256 public rewardPoolSupply = 0;

    uint256 public shareRate = 1e18;

    uint256 public equityPoolSupply = 0;
    uint256 public equityPoolTotalShares = 0;

    mapping(address => Stake[]) internal stakes;
    Reward[] internal rewards;

    ///----------------------------------------------------------------------------------------------------------------
    /// Events
    ///----------------------------------------------------------------------------------------------------------------

    /// @notice Stake has been started
    /// @dev Size and Time bonus have been calculated to burn FENIX in exchnge for equity to start stake
    /// @param _stake the stake object
    event StartStake(Stake indexed _stake);

    /// @notice Stake has been deferred
    /// @dev Remove the stake and it's equity from the pool
    /// @param _stake the stake object
    event DeferStake(Stake indexed _stake);

    /// @notice Stake has been ended
    /// @dev Remove the stake from the users stakes and mint the payout into the stakers wallet
    /// @param _stake the stake object
    event EndStake(Stake indexed _stake);

    /// @notice Reward Pool has been flushed
    /// @dev Flushed reward pool into staker pool
    event FlushRewardPool(Reward indexed reward);

    /// @notice Share rate has been updated
    /// @dev Share rate has been updated
    /// @param _shareRate the new share rate
    event UpdateShareRate(uint256 indexed _shareRate);

    ///----------------------------------------------------------------------------------------------------------------
    /// Contract
    ///----------------------------------------------------------------------------------------------------------------

    constructor() {
        genesisTs = uint40(block.timestamp);
        cooldownUnlockTs = block.timestamp + REWARD_LAUNCH_COOLDOWN_TS;
    }

    /// @notice Evaluate if the contract supports the interface
    /// @dev Evaluate if the contract supports burning tokens
    /// @param interfaceId the interface to evaluate
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBurnRedeemable).interfaceId || interfaceId == this.supportsInterface.selector;
    }

    /// @notice Mint FENIX tokens
    /// @dev Mint FENIX tokens to the user address
    /// @param user the address of the user to mint FENIX tokens for
    /// @param amount the amount of FENIX tokens to mint
    function onTokenBurned(address user, uint256 amount) external {
        if (_msgSender() != XEN_ADDRESS) revert FenixError.WrongCaller(_msgSender());
        if (user == address(0)) revert FenixError.AddressZero();
        if (amount == 0) revert FenixError.BalanceZero();

        uint256 fenix = amount / XEN_BURN_RATIO;
        rewardPoolSupply += fenix;
        _mint(user, fenix);
        emit Redeemed(user, XEN_ADDRESS, address(this), amount, fenix);
    }

    /// @notice Burn XEN tokens
    /// @dev Execute proof of burn on remote contract to burn XEN tokens
    /// @param xen the amount of XEN to burn from the current wallet address
    function burnXEN(uint256 xen) public {
        IBurnableToken(XEN_ADDRESS).burn(_msgSender(), xen);
    }

    /// @notice Starts a stake
    /// @dev Initialize a stake for the current wallet address
    /// @param fenix the amount of fenix to stake
    /// @param term the number of days to stake
    function startStake(uint256 fenix, uint256 term) public {
        if (fenix == 0) revert FenixError.BalanceZero();
        if (term == 0) revert FenixError.TermZero();

        uint40 startTs = uint40(block.timestamp);
        uint40 endTs = uint40(block.timestamp + (term * ONE_DAY_TS));

        uint256 bonus = calculateBonus(fenix, term);
        uint256 shares = calculateShares(bonus);

        UD60x18 time = ud(term).div(ONE_YEAR_DAYS);
        uint256 inflatedSupply = unwrap(ud(fenix).mul((ONE.add(ANNUAL_INFLATION_RATE)).pow(time)));

        uint256 newShares = unwrap(ud(shares).mul(ud(inflatedSupply)));

        equityPoolSupply += inflatedSupply;
        equityPoolTotalShares += newShares;

        Stake memory _stake = Stake(Status.ACTIVE, startTs, 0, endTs, uint16(term), fenix, newShares, 0);
        stakes[_msgSender()].push(_stake);

        _burn(_msgSender(), fenix);
        emit StartStake(_stake);
    }

    /// @notice Defer stake until future date
    /// @dev Defer a stake by removing the supply allocated to the stake from the pool
    /// @param stakeIndex the index of the stake to defer
    /// @param stakerAddress the address of the stake owner that will be deferred
    function deferStake(uint256 stakeIndex, address stakerAddress) public {
        if (stakes[stakerAddress].length <= stakeIndex) revert FenixError.StakeNotActive();
        Stake memory _stake = stakes[stakerAddress][stakeIndex];

        if (_stake.status != Status.ACTIVE) return;

        if (block.timestamp < _stake.endTs && _msgSender() != stakerAddress)
            revert FenixError.WrongCaller(_msgSender());

        UD60x18 rewardPercent = ZERO;
        if (block.timestamp > _stake.endTs) {
            rewardPercent = ud(calculateLatePayout(_stake));
        } else {
            rewardPercent = ud(calculateEarlyPayout(_stake));
        }

        UD60x18 poolSharePercent = ud(_stake.shares).div(ud(equityPoolTotalShares));
        UD60x18 stakerPoolSupplyPercent = poolSharePercent.mul(rewardPercent);

        uint256 equitySupply = unwrap(ud(equityPoolSupply).mul(stakerPoolSupplyPercent));

        Stake memory deferredStake = Stake(
            Status.DEFER,
            _stake.startTs,
            uint40(block.timestamp),
            _stake.endTs,
            _stake.term,
            _stake.fenix,
            _stake.shares,
            equitySupply
        );

        stakes[stakerAddress][stakeIndex] = deferredStake;

        equityPoolTotalShares -= _stake.shares;
        equityPoolSupply -= equitySupply;

        emit DeferStake(deferredStake);
    }

    /// @notice End a stake
    /// @dev End a stake by allocating the stake supply to the stakers wallet
    /// @param stakeIndex the index of the stake to end
    function endStake(uint256 stakeIndex) public {
        deferStake(stakeIndex, _msgSender());

        Stake memory _stake = stakes[_msgSender()][stakeIndex];
        if (_stake.status == Status.END) revert FenixError.StakeStatusAlreadySet(Status.END);

        _mint(_msgSender(), _stake.payout);

        uint256 returnOnStake = unwrap(ud(_stake.payout).div(ud(_stake.fenix)));

        if (returnOnStake > shareRate) {
            shareRate = returnOnStake;
            emit UpdateShareRate(shareRate);
        }

        Stake memory endedStake = Stake(
            Status.END,
            _stake.startTs,
            _stake.deferralTs,
            _stake.endTs,
            _stake.term,
            _stake.fenix,
            _stake.shares,
            _stake.payout
        );

        stakes[_msgSender()][stakeIndex] = endedStake;
        emit EndStake(endedStake);
    }

    /// @notice Calculate bonus
    /// @dev Use fenix amount and term to calculate size and time bonus used for pool equity stake
    /// @param fenix the amount of fenix used to calculate the equity stake
    /// @param term the term of the stake in days used to calculate the pool equity stake
    /// @return bonus the bonus for pool equity stake
    function calculateBonus(uint256 fenix, uint256 term) public pure returns (uint256) {
        UD60x18 sizeBonus = ud(calculateSizeBonus(fenix));
        UD60x18 timeBonus = ud(calculateTimeBonus(term));
        UD60x18 bonus = sizeBonus.mul(E.pow(timeBonus));
        return unwrap(bonus);
    }

    /// @notice Calculate size bonus
    /// @dev Use fenix amount to calculate the size bonus used for pool equity stake
    /// @param fenix the amount of fenix used to calculate the equity stake
    /// @return bonus the size bonus for pool equity stake
    function calculateSizeBonus(uint256 fenix) public pure returns (uint256) {
        if (fenix >= (UINT256_MAX - 3)) revert FenixError.SizeGreaterThanMax();
        return unwrap(ONE.sub((ud(fenix).add(ONE)).inv()));
    }

    /// @notice Calculate time bonus
    /// @dev Use term to calculate the time bonus used for pool equity stake
    /// @param term the term of the stake in days used to calculate the pool equity stake
    /// @return bonus the time bonus for pool equity stake
    function calculateTimeBonus(uint256 term) public pure returns (uint256) {
        if (term > MAX_STAKE_LENGTH_DAYS) revert FenixError.TermGreaterThanMax();
        UD60x18 timeBonus = ONE.add(ud(term).div(ud(MAX_STAKE_LENGTH_DAYS)));
        return unwrap(timeBonus);
    }

    /// @notice Calculate shares
    /// @dev Use bonus to calculate the number of shares to be issued to the staker
    /// @param bonus the bonus to calculate the shares from
    /// @return shares the number of shares to be issued to the staker
    function calculateShares(uint256 bonus) public view returns (uint256) {
        UD60x18 shares = ud(bonus).div(ud(shareRate));
        return unwrap(shares);
    }

    /// @notice Calculate the early end stake penalty
    /// @dev Calculates the early end stake penality to be split between the pool and the staker
    /// @param stake the stake to calculate the penalty for
    /// @return reward the reward percentage for the stake
    function calculateEarlyPayout(Stake memory stake) public view returns (uint256) {
        if (block.timestamp < stake.startTs || stake.status != Status.ACTIVE) revert FenixError.StakeNotActive();
        if (block.timestamp > stake.endTs) revert FenixError.StakeLate();
        uint256 termDelta = block.timestamp - stake.startTs;
        uint256 scaleTerm = stake.term * ONE_DAY_TS;
        UD60x18 reward = (convert(termDelta).div(convert(scaleTerm))).powu(2);
        return unwrap(reward);
    }

    /// @notice Calculate the late end stake penalty
    /// @dev Calculates the late end stake penality to be split between the pool and the staker
    /// @param stake a parameter just like in doxygen (must be followed by parameter name)
    /// @return reward the reward percentage for the stake
    function calculateLatePayout(Stake memory stake) public view returns (uint256) {
        if (block.timestamp < stake.startTs || stake.status != Status.ACTIVE) revert FenixError.StakeNotActive();
        if (block.timestamp < stake.endTs) revert FenixError.StakeNotEnded();

        uint256 lateTs = block.timestamp - stake.endTs;
        if (lateTs > ONE_EIGHTY_DAYS_TS) return 0;

        UD60x18 penalty = ud(lateTs).div(ud(ONE_EIGHTY_DAYS_TS)).powu(3);
        UD60x18 reward = ONE.sub(penalty);
        return unwrap(reward);
    }

    /// @notice Flush reward pool
    /// @dev Flush reward pool to stake pool
    function flushRewardPool() public {
        if (block.timestamp < cooldownUnlockTs) revert FenixError.CooldownActive();
        uint256 cooldownPeriods = (block.timestamp - cooldownUnlockTs) / REWARD_COOLDOWN_TS;
        equityPoolSupply += rewardPoolSupply;
        cooldownUnlockTs += REWARD_COOLDOWN_TS + (cooldownPeriods * REWARD_COOLDOWN_TS);

        Reward memory reward = Reward(uint40(rewards.length), uint40(block.timestamp), rewardPoolSupply, _msgSender());

        rewardPoolSupply = 0;
        rewards.push(reward);
        emit FlushRewardPool(reward);
    }

    /// @notice Get stake for address at index
    /// @dev Read stake from stakes mapping stake array
    /// @param stakerAddress address of stake owner
    /// @param stakeIndex index of stake to read
    /// @return stake
    function stakeFor(address stakerAddress, uint256 stakeIndex) public view returns (Stake memory) {
        return stakes[stakerAddress][stakeIndex];
    }

    /// @notice Get stake count for address
    /// @dev Read stake count from stakes mapping
    /// @param stakerAddress address of stake owner
    /// @return stake count
    function stakeCount(address stakerAddress) public view returns (uint256) {
        return stakes[stakerAddress].length;
    }

    /// @notice Get reward for index
    /// @dev Read reward from rewards array
    /// @param index index of reward to read
    /// @return reward
    function rewardFor(uint256 index) public view returns (Reward memory) {
        return rewards[index];
    }

    /// @notice Get reward count
    /// @dev Read reward count from rewards array
    /// @return reward count
    function rewardCount() public view returns (uint256) {
        return rewards.length;
    }
}