// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5 <=0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

import "../Types/TheopetraAccessControlled.sol";

import "../Libraries/SafeERC20.sol";
import "../Libraries/ABDKMathQuad.sol";

import "../Interfaces/ITreasury.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IDistributor.sol";

import "../Interfaces/IStaking.sol";
import "../Interfaces/IStakedTHEOToken.sol";

contract StakingDistributor is IDistributor, TheopetraAccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;

    /* ====== VARIABLES ====== */

    IERC20 private immutable THEO;
    ITreasury private immutable treasury;
    mapping(address => bool) private staking;

    uint48 public immutable epochLength;

    mapping(uint256 => Adjust) public adjustments;
    uint256 public override bounty;

    uint256 private constant rateDenominator = 1_000_000_000;

    /**
        @dev    byte representation of 1095. See also `deriveRate`.
     */
    bytes16 private constant n = 0x400911c0000000000000000000000000;
    /**
        @dev    byte representation of 1;
     */
    bytes16 private constant one = 0x3fff0000000000000000000000000000;

    event Distribute(uint256 indexed amount, uint256 indexed rate, address recipient);
    event BountyRetrieved(uint256 indexed amount, address indexed beneficiary);
    event SetBounty(uint256 indexed amount);
    event AddRecipient(address recipient, uint256 startRate, bool locked);
    event RemoveRecipient(address recipient);
    event SetStakingContract(address stakingContract);
    event UpdateDRS(address recipient, int256 drs);
    event UpdateDYS(address recipient, int256 dry);
    /* ====== STRUCTS ====== */

    /**
        @notice information for rewards to recipients
        @dev    Info::start is the starting rate for rewards in ten-thousandsths (2000 = 0.2%);
                Info::drs is the Discount Rate Return Staking. The discount rate applied to the fluctuation of the token price, as a proportion (that is, a percentage in its decimal form), with 9 decimals
                Info::dys is the discount rate applied to the fluctuation of the treasury yield, as a proportion (that is, a percentage in its decimal form), with 9 decimals
                Info::recipient is the recipient staking contract for rewards
                Info::locked is whether the staking tranche is locked (true) or unlocked (false)
                Info::nextEpochTime is the timestamp for the next epoch, when wind-down will next be applied to the starting reward rate and the maximum reward rate
     */
    struct Info {
        uint256 start;
        int256 drs;
        int256 dys;
        address recipient;
        bool locked;
        uint48 nextEpochTime;
    }
    Info[] public info;

    struct Adjust {
        bool add;
        uint256 rate;
        uint256 target;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(
        address _treasury,
        address _theo,
        uint48 _epochLength,
        ITheopetraAuthority _authority,
        address _staking
    ) TheopetraAccessControlled(ITheopetraAuthority(_authority)) {
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_theo != address(0), "Zero address: THEO");
        THEO = IERC20(_theo);
        require(_staking != address(0), "Zero address: Staking");
        staking[_staking] = true;
        epochLength = _epochLength;
    }

    /* ====== Modifiers ====== */
    modifier onlyStaking() {
        require(staking[msg.sender], "Only staking");
        _;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice send epoch reward to staking contract
        @dev    distribute can only be called by a Staking contract (and the Staking contract will only call if its epoch is over)
                This method distributes rewards to each recipient (minting and sending from the treasury)
                If the current time is greater than `nextEpochTime`, the starting rate is wound-down, and the `nextEpochTime` is updated.
                Wind-down occurs according to the schedules for unlocked and locked tranches where:
                Locked tranches wind-down by 1.5% per epoch (that is, per year) to a minimum of 6% (60_000_000 -- see also `rateDenominator`)
                Unlocked tranches wind-down by 0.5% per epoch (that is, per year) to a minimum of 2% (20_000_000)
     */
    function distribute() external override onlyStaking {
        for (uint256 i = 0; i < info.length; i++) {
            uint256 _rate = nextRewardRate(i);
            if (_rate > 0) {
                uint256 reward = nextRewardAt(_rate, info[i].recipient);
                ITreasury(treasury).mint(info[i].recipient, reward);
                emit Distribute(reward, _rate, info[i].recipient);
            }
            if (info[i].nextEpochTime <= block.timestamp) {
                if (info[i].locked == false && info[i].start > 20_000_000) {
                    info[i].start = info[i].start.sub(5_000_000);
                } else if (info[i].locked == true && info[i].start > 60_000_000) {
                    info[i].start = info[i].start.sub(15_000_000);
                }
                info[i].nextEpochTime = uint48(uint256(info[i].nextEpochTime).add(uint256(epochLength)));
            }
        }
    }

    /**
        @dev If the distributor bounty is > 0, mint it for the staking contract.
     */
    function retrieveBounty() external override onlyStaking returns (uint256) {
        // onlyStaking compares msg.sender to the `staking` mapping, so this is safe
        // msg.sender at this point can only be a staking contract
        if (bounty > 0) {
            treasury.mint(address(msg.sender), bounty);
            emit BountyRetrieved(bounty, address(msg.sender));
        }

        return bounty;
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt(uint256 _rate, address _recipient) public view override returns (uint256) {
        return IStakedTHEOToken(IStaking(_recipient).basis()).circulatingSupply().mul(_rate).div(rateDenominator);
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint256
     */
    function nextRewardFor(address _recipient) external view override returns (uint256) {
        uint256 reward;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].recipient == _recipient) {
                reward = nextRewardAt(nextRewardRate(i), _recipient);
                break;
            }
        }
        return reward;
    }

    /**
     * @notice calculate the next reward rate
       @dev `apyVariable`, is calculated as: APYfixed + SCrs + SCys
            Where APYfixed is the fixed starting rate, with 9 decimals
            SCrs is the Control Return for Staking (with 9 decimals): SCrs = Drs * deltaTokenPrice
            SCys is Control Treasury for Staking (with 9 decimals): SCys = Dys * deltaTreasuryYield
            The returned rate is limited to a minimum of zero and a maximum of 1.5 times the fixed starting rate (in locked and unlocked tranches).
     * @param _index uint256
     * @return uint256 The reward rate. 9 decimals
     */
    function nextRewardRate(uint256 _index) public view override returns (uint256) {
        int256 apyVariable = (info[_index].start.toInt256())
            .add((ITreasury(treasury).deltaTokenPrice().mul(info[_index].drs)).div(10**9))
            .add((ITreasury(treasury).deltaTreasuryYield().mul(info[_index].dys)).div(10**9));

        if (apyVariable > 0) {
            uint256 _rate = deriveRate(uint256(apyVariable));
            uint256 maxRate = (info[_index].start * 15) / 10;
            return _rate < maxRate ? _rate : maxRate;
        } else {
            return 0;
        }
    }

    /* ====== POLICY FUNCTIONS ====== */

    /**
     * @notice set bounty to incentivize keepers
     * @param _bounty uint256
     */
    function setBounty(uint256 _bounty) external override onlyGovernor {
        require(_bounty <= 2e9, "Too much");
        bounty = _bounty;
        emit SetBounty(_bounty);
    }

    /**
        @notice adds recipient for distributions
        @dev    When a recipient is added, the epochLength and current block timestamp is used to calculate when the next epoch should occur
        @param _recipient address
        @param _startRate uint256 9 decimal starting rate
        @param _drs       uint256 9 decimal Discount Rate Return Staking. The discount rate applied to the fluctuation of the token price, as a proportion (that is, a percentage in its decimal form), with 9 decimals
        @param _dys       uint256 9 decimial discount rate applied to the fluctuation of the treasury yield, as a proportion (that is, a percentage in its decimal form), with 9 decimals
        @param _locked    bool is the staking tranche locked or unlocked
     */
    function addRecipient(
        address _recipient,
        uint256 _startRate,
        int256 _drs,
        int256 _dys,
        bool _locked
    ) external override onlyGovernor {
        require(_recipient != address(0), "Recipient cannot be the zero address");
        require(_startRate <= rateDenominator, "Rate cannot exceed denominator");

        info.push(
            Info({
                recipient: _recipient,
                start: _startRate,
                drs: _drs,
                dys: _dys,
                locked: _locked,
                nextEpochTime: uint48((block.timestamp).add(uint256(epochLength)))
            })
        );

        emit AddRecipient(
            _recipient,
            _startRate,
            _locked
        );
    }

    /**
        @notice set the address as a staking contract
        @dev setting the address as a staking contract will allow the staking contract to call the `distribute` function
             the contract must also be set up as a recipient to receive the rewards
        @param _addr address
     */
    function setStaking(address _addr) external override onlyGovernor {
        staking[_addr] = true;
        emit SetStakingContract(_addr);
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
     */
    function removeRecipient(uint256 _index) external override {
        require(
            msg.sender == authority.governor() || msg.sender == authority.guardian(),
            "Caller is not governor or guardian"
        );
        require(info[_index].recipient != address(0), "Recipient does not exist");
        info[_index].recipient = address(0);
        info[_index].start = 0;
        info[_index].drs = 0;
        info[_index].dys = 0;
        emit RemoveRecipient(info[_index].recipient);
    }

    function setDiscountRateStaking(uint256 _index, int256 _drs) external override onlyPolicy {
        info[_index].drs = _drs;
        emit UpdateDRS(info[_index].recipient, _drs);
    }

    function setDiscountRateYield(uint256 _index, int256 _dys) external override onlyPolicy {
        info[_index].dys = _dys;
        emit UpdateDYS(info[_index].recipient, _dys);
    }

    /**
     * @notice derives the rate for a given apy for the next Epoch.
     * @dev    the rate is calculated as:
     *         1095 * e^z - 1095
     *         z = ln(apyProportion + 1) / 1095
     *         1095 is: 365(days) * 24(hours) / 8(hours per performance update)
     *         apyProportion is a proportion (that is, a percentage in its decimal form), calculated using the param _apy
     *         0x401cdcd6500000000000000000000000 is the byte representation of 10**9
     * @param _apy The APY to calculate the rate for. 9 decimals
     * @return uint256 The rate for the given APY. 9 decimals
     */
    function deriveRate(uint256 _apy) public view returns (uint256) {
        bytes16 apyProportion = ABDKMathQuad.div(ABDKMathQuad.fromUInt(_apy), 0x401cdcd6500000000000000000000000);
        bytes16 z = ABDKMathQuad.div(ABDKMathQuad.ln(ABDKMathQuad.add(apyProportion, one)), n);
        bytes16 eToTheZ = ABDKMathQuad.exp(z);

        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.mul(ABDKMathQuad.sub(ABDKMathQuad.mul(n, eToTheZ), n), 0x401cdcd6500000000000000000000000)
            );
    }
}