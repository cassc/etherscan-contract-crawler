import "./libraries/SafeMath.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/Address.sol";
import "./libraries/SafeERC20.sol";
import "./interface/IHATETreasury.sol";
import "./interface/IERC721.sol";

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;

/// @title   ERC721 Bonding Contract
/// @notice  ERC721 BONDING
contract BondERC721 {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// EVENTS ///

    /// @notice Emitted when A bond is created
    /// @param deposit Address of where bond is deposited to
    /// @param payout Amount of HATE to be paid out
    /// @param expires Timestamp bond will be fully redeemable
    event BondCreated(uint deposit, uint payout, uint expires);

    /// @notice Emitted when a bond is redeemed
    /// @param recipient Address receiving HATE
    /// @param payout Amount of HATE redeemed
    /// @param remaining Amount of HATE left to be paid out
    event BondRedeemed(address recipient, uint payout, uint remaining);

    /// STATE VARIABLES ///

    address public owner;

    /// @notice HATE token
    IERC20 public immutable HATE;

    IERC721 public immutable ERC721;

    /// @notice HATE Treasury
    IHATETreasury public immutable treasury;

    address public feeTo;
    // in thousandths of a %. i.e. 500 = 0.5%
    uint public feePercent;

    /// @notice Total ERC721 tokens that have been bonded
    uint public totalPrincipalBonded;
    /// @notice Total HATE tokens given as payout
    uint public totalPayoutGiven;
    /// @notice Vesting term in seconds
    uint public vestingTerm;

    uint public lastBondPrice;

    uint public secondsToDouble;

    uint public lastInteraction;

    /// @notice 1000 = 10%
    uint public decayPercent;

    /// @notice Array of IDs that have been bondable
    uint[] public bondedIds;

    /// @notice Bool if bond contract has been initialized
    bool public initialized;

    /// @notice Stores bond information for depositors
    mapping(address => Bond) public bondInfo;

    /// STRUCTS ///

    /// @notice           Details of an addresses current bond
    /// @param payout     HATE tokens remaining to be paid
    /// @param vesting    Seconds left to vest
    /// @param lastTimestamp  Last interaction
    struct Bond {
        uint payout;
        uint vesting;
        uint lastTimestamp;
    }

    /// CONSTRUCTOR ///

    /// @param _treasury   Address of treasury
    /// @param _ERC721  Address of MILDAY ERC721
    constructor(address _treasury, address _ERC721) {
        require(_treasury != address(0));
        treasury = IHATETreasury(_treasury);
        HATE = IERC20(IHATETreasury(_treasury).HATE());

        require(_ERC721 != address(0));
        ERC721 = IERC721(_ERC721);

        //lastInteraction = block.timestamp;

        owner = msg.sender;
    }

    /// POLICY FUNCTIONS ///

    function setFeeAndFeeTo(address feeTo_, uint256 feePercent_) external onlyOwner {
        feeTo = feeTo_;
        feePercent = feePercent_;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    /// @notice              Initializes bond and sets vesting rate
    /// @param _vestingTerm  Vesting term in seconds
    function initializeBond(uint _vestingTerm, uint _startingPrice, uint _secondsToDouble, uint _decayPercent) external onlyOwner {
        require(!initialized, "Already initialized");
        vestingTerm = _vestingTerm;
        lastBondPrice = _startingPrice;
        secondsToDouble = _secondsToDouble;
        lastInteraction = block.timestamp;
        require (_decayPercent < 10000, "Decay percent can not be over 10000bps");
        decayPercent = _decayPercent;
        initialized = true;
    }

    /// @notice          Updates current vesting term
    /// @param _vesting  New vesting in seconds
    function setVesting(uint _vesting) external onlyOwner {
        require(initialized, "Not initalized");
        vestingTerm = _vesting;
    }

    function setDecayPercent(uint _decayPercent) external onlyOwner {
        require (_decayPercent < 10000, "Decay percent can not be over 10000bps");
        decayPercent = _decayPercent;
    }

    /// USER FUNCTIONS ///

    /// @notice            Bond ERC721 to get HATE tokens
    /// @param _id         ID number that is being bonded
    /// @param _depositor  Address that HATE tokens will be redeemable for
    function deposit(uint _id, address _depositor) external returns (uint) {
        require(initialized, "Not initalized");
        require(bondPrice() > 0, "Not bondable");
        require(_depositor != address(0), "Invalid address");

        uint payout;

        payout = bondPrice();
        lastBondPrice = payout.mul((10000 - decayPercent)).div(10000);
        lastInteraction = block.timestamp;

        // depositor info is stored
        bondInfo[_depositor] = Bond({
            payout: bondInfo[_depositor].payout.add(payout),
            vesting: vestingTerm,
            lastTimestamp: block.timestamp
        });

        ++totalPrincipalBonded;
        totalPayoutGiven = totalPayoutGiven + payout;

        treasury.mintHATE(address(this), payout);

        if (feeTo != address(0) && feePercent > 0) {
            uint256 _fee = payout.mul(feePercent).div(100000);
            treasury.mintHATE(feeTo, _fee);
        }

        ERC721.safeTransferFrom(msg.sender, address(treasury), _id);

        // indexed events are emitted
        emit BondCreated(_id, payout, block.timestamp.add(vestingTerm));

        return payout;
    }

    /// @notice            Redeem bond for `depositor`
    /// @param _depositor  Address of depositor being redeemed
    /// @return            Amount of HATE redeemed
    function redeem(address _depositor) external returns (uint) {
        Bond memory info = bondInfo[_depositor];
        uint percentVested = percentVestedFor(_depositor); // (Seconds since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[_depositor]; // delete user info
            emit BondRedeemed(_depositor, info.payout, 0); // emit bond data
            HATE.safeTransfer(_depositor, info.payout);
            return info.payout;
        } else {
            // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul(percentVested).div(10000);

            // store updated deposit info
            bondInfo[_depositor] = Bond({
                payout: info.payout.sub(payout),
                vesting: info.vesting.sub(block.timestamp.sub(info.lastTimestamp)),
                lastTimestamp: block.timestamp
            });

            emit BondRedeemed(_depositor, payout, bondInfo[_depositor].payout);
            HATE.safeTransfer(_depositor, payout);
            return payout;
        }
    }

    /// VIEW FUNCTIONS ///

    /// @notice          Payout and fee for a specific bond ID
    /// @return payout_  Amount of HATE user will recieve for bonding a 721
    function bondPrice() public view returns (uint payout_) {
        uint256 secondsSinceLastInteraction = block.timestamp.sub(lastInteraction);
        if (secondsSinceLastInteraction == 0) return lastBondPrice;
        payout_ = lastBondPrice.add((lastBondPrice.mul(secondsSinceLastInteraction).div(secondsToDouble)));
    }

    /// @notice                 Calculate how far into vesting `_depositor` is
    /// @param _depositor       Address of depositor
    /// @return percentVested_  Percent `_depositor` is into vesting
    function percentVestedFor(address _depositor) public view returns (uint percentVested_) {
        Bond memory bond = bondInfo[_depositor];
        uint secondsSinceLast = block.timestamp.sub(bond.lastTimestamp);
        uint vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = secondsSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /// @notice                 Calculate amount of payout token available for claim by `_depositor`
    /// @param _depositor       Address of depositor
    /// @return pendingPayout_  Pending payout for `_depositor`
    function pendingPayoutFor(address _depositor) external view returns (uint pendingPayout_) {
        uint percentVested = percentVestedFor(_depositor);
        uint payout = bondInfo[_depositor].payout;

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }
}