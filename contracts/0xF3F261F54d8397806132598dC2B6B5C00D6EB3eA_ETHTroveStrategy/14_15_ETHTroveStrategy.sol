// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VersionedInitializable} from "../../proxy/VersionedInitializable.sol";
import {IBorrowerOperations} from "../../interfaces/IBorrowerOperations.sol";
import {StakingRewardsChild} from "../../staking/StakingRewardsChild.sol";
import {IPriceFeed} from "../../interfaces/IPriceFeed.sol";
import {ILendingPool} from "../../interfaces/ILendingPool.sol";
import {ETHTroveLogic} from "./ETHTroveLogic.sol";

// import "hardhat/console.sol";

/**
 * @title ETHTroveStrategy
 * @author MahaDAO
 *
 * @notice A ETH staking contract that takes in ETH and uses it to mint ARTH and provide liquidity to MahaLend.
 * This strategy is a low risk strategy albeit some risks such as ETH price fluctuation and smart-contract bugs.
 * Most liquidity providers who participate in this strategy will be able to withdraw the
 * same amount of ETH that they provided.
 **/
contract ETHTroveStrategy is VersionedInitializable, StakingRewardsChild {
    event RevenueClaimed(uint256 wad);
    event PauseToggled(bool val);

    uint256 public minCollateralRatio;
    address private me;
    address private _arth;
    mapping(address => ETHTroveLogic.Position) public positions;

    IERC20 public arth;

    /// @dev the MahaLend lending pool
    ILendingPool public pool;

    /// @dev the ARTH price feed
    IPriceFeed public priceFeed;

    /// @dev Borrower operations for minting ARTH
    IBorrowerOperations public borrowerOperations;

    /// @dev the MahaLend aToken for ARTH.
    IERC20 public mArth;

    /// @dev for collection of revenue
    address public treasury;

    /// @dev to track how much interest this pool has earned.
    uint256 public totalmArthSupplied;

    /// @dev is the contract paused?
    bool public paused;

    function initialize(
        address _borrowerOperations,
        address __arth,
        address __maha,
        address _priceFeed,
        address _pool,
        uint256 _rewardsDuration,
        address _owner,
        address _treasury,
        uint256 _minCr
    ) external initializer {
        arth = IERC20(__arth);
        _arth = __arth;
        borrowerOperations = IBorrowerOperations(_borrowerOperations);
        priceFeed = IPriceFeed(_priceFeed);
        pool = ILendingPool(_pool);

        arth.approve(_pool, type(uint256).max);
        arth.approve(_borrowerOperations, type(uint256).max);

        me = address(this);

        mArth = IERC20((pool.getReserveData(__arth)).aTokenAddress);
        minCollateralRatio = _minCr;
        treasury = _treasury;

        totalmArthSupplied = mArth.balanceOf(me);

        _stakingRewardsChildInit(__maha, _rewardsDuration, _owner);
        _transferOwnership(_owner);
        _transferOperator(_owner);
    }

    function deposit(
        uint256 maxFee,
        address upperHint,
        address lowerHint,
        uint256 arthAmount
    ) external payable nonReentrant {
        // Check that we are getting ETH.
        require(msg.value > 0, "no eth");
        require(!paused, "paused");

        _stake(msg.sender, msg.value);
        totalmArthSupplied += arthAmount;

        ETHTroveLogic.deposit(
            positions, // mapping(address => Position) memory positions
            ETHTroveLogic.DepositParams({
                priceFeed: priceFeed, // IPriceFeed priceFeed,
                minCollateralRatio: minCollateralRatio, // uint256 minCollateralRatio,
                borrowerOperations: borrowerOperations, // IBorrowerOperations borrowerOperations,
                me: me, // address me,
                pool: pool, // ILendingPool pool,
                arth: _arth, // address _arth,
                upperHint: upperHint, // address upperHint;
                lowerHint: lowerHint, // address lowerHint;
                arthAmount: arthAmount, // uint256 arthAmount;
                maxFee: maxFee // uint256 maxFee;
            })
        );
    }

    function withdraw(
        uint256 maxFee,
        address upperHint,
        address lowerHint
    ) external nonReentrant {
        require(!paused, "paused");

        _withdraw(msg.sender, positions[msg.sender].ethForLoan);
        totalmArthSupplied -= positions[msg.sender].arthFromLoan;

        ETHTroveLogic.withdraw(
            positions, // mapping(address => Position) memory positions
            ETHTroveLogic.WithdrawParams({
                borrowerOperations: borrowerOperations, // IBorrowerOperations borrowerOperations,
                me: me, // address me,
                pool: pool, // ILendingPool pool,
                arth: _arth, // address _arth,
                upperHint: upperHint, // address upperHint;
                lowerHint: lowerHint, // address lowerHint;
                maxFee: maxFee // uint256 maxFee;
            })
        );
    }

    function increase(
        uint256 maxFee,
        address upperHint,
        address lowerHint,
        uint256 arthAmount
    ) external payable nonReentrant {
        // Check that we are getting ETH.
        require(msg.value > 0, "no eth");
        require(!paused, "paused");
        require(false, "disabled");

        // track how much mARTH was minted
        // record the eth deposited in the staking contract for maha rewards
        _stake(msg.sender, msg.value);
        totalmArthSupplied += arthAmount;

        ETHTroveLogic.increase(
            positions, // mapping(address => Position) memory positions
            ETHTroveLogic.DepositParams({
                priceFeed: priceFeed, // IPriceFeed priceFeed,
                minCollateralRatio: minCollateralRatio, // uint256 minCollateralRatio,
                borrowerOperations: borrowerOperations, // IBorrowerOperations borrowerOperations,
                me: me, // address me,
                pool: pool, // ILendingPool pool,
                arth: _arth, // address _arth,
                upperHint: upperHint, // address upperHint;
                lowerHint: lowerHint, // address lowerHint;
                arthAmount: arthAmount, // uint256 arthAmount;
                maxFee: maxFee // uint256 maxFee;
            })
        );
    }

    /// @notice Send the revenue the strategy has generated to the treasury <3
    function collectRevenue() public nonReentrant {
        uint256 revenue = revenueMArth();
        pool.withdraw(_arth, revenue, me);
        arth.transfer(treasury, revenue);
        emit RevenueClaimed(revenue);
    }

    // /// @notice in case operator needs to rebalance the position for a particular user
    // /// this function can be used.
    // // TODO: make this publicly accessible somehow
    // function rebalance(
    //     address who,
    //     ETHTroveLogic.LoanParams memory loanParams,
    //     uint256 arthToBurn
    // ) external payable onlyOperator {
    //     ETHTroveLogic.rebalance(
    //         positions, // mapping(address => Position) memory positions
    //         who,
    //         arthToBurn,
    //         loanParams, // LoanParams memory loanParams,
    //         ETHTroveLogic.DepositParams({
    //             priceFeed: priceFeed, // IPriceFeed priceFeed,
    //             minCollateralRatio: minCollateralRatio, // uint256 minCollateralRatio,
    //             borrowerOperations: borrowerOperations, // IBorrowerOperations borrowerOperations,
    //             mArth: mArth, // IERC20 mArth,
    //             me: me, // address me,
    //             pool: pool, // ILendingPool pool,
    //             arth: _arth // address _arth,
    //         })
    //     );
    //     // update mARTH tracker variable
    //     totalmArthSupplied = totalmArthSupplied.sub(arthToBurn);
    // }

    /// --- Admin only functions

    /// @notice admin-only function to open a trove; needed to initialize the contract
    function openTrove(
        uint256 _maxFee,
        uint256 _value,
        uint256 _arthAmount,
        address _upperHint,
        address _lowerHint
    ) external onlyOwner {
        require(_value > 0, "no eth");

        // Open the trove.
        borrowerOperations.openTrove{value: _value}(
            _maxFee,
            _arthAmount,
            _upperHint,
            _lowerHint,
            address(0)
        );

        // Send the dust back to owner.
        payable(msg.sender).transfer(me.balance);
    }

    /// @notice admin-only function to close the trove; normally not needed if the campaign keeps on running
    function closeTrove() external payable onlyOwner {
        // Close the trove.
        borrowerOperations.closeTrove();

        // Send the eth back to owner.
        payable(msg.sender).transfer(me.balance);
    }

    /// @notice admin-only function in case admin needs to execute some calls directly
    function emergencyCall(address target, bytes memory signature) external payable onlyOwner {
        (bool success, bytes memory response) = target.call{value: msg.value}(signature);
        require(success, string(response));
    }

    /// @notice Emergency function to modify a position in case it has been corrupted.
    function modifyPosition(address who, ETHTroveLogic.Position memory position) external onlyOwner {
        positions[who] = position;
    }

    /// @notice Toggle pausing the contract in the event of any bugs
    function togglePause() external onlyOwner {
        paused = !paused;
        emit PauseToggled(paused);
    }

    // --- View functions

    /// @notice Version number for upgradability
    function getRevision() public pure virtual override returns (uint256) {
        return 5;
    }

    /// @notice Returns how much mARTH revenue we have generated so far.
    function revenueMArth() public view returns (uint256 revenue) {
        // Since mARTH.balanceOf is always an increasing number,
        // this will always be positive.
        revenue = mArth.balanceOf(me) - totalmArthSupplied;
    }

    /// @notice Returns the CR of the given user
    function getPositionCR(address who) public returns (uint256 cr) {
        uint256 price = priceFeed.fetchPrice();
        return (price * positions[who].ethForLoan) / (positions[who].arthFromLoan);
    }

    receive() external payable {}
}