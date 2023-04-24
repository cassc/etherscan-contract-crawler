// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "./interfaces/IPrizeDistributionFactory.sol";
import "./interfaces/IDrawCalculatorTimelock.sol";
import "./interfaces/IBeaconTimelockTrigger.sol";

import "../core/interfaces/IDrawBeacon.sol";
import "../core/interfaces/IDrawBuffer.sol";

import "../owner-manager/Manageable.sol";

/**
 * @title  Asymetrix Protocol V1 BeaconTimelockTrigger
 * @author Asymetrix Protocol Inc Team
 * @notice The BeaconTimelockTrigger smart contract passes the information about
 *         the current draw to the prizeDistributionFactory for the creation of
 *         a prizeDistribution.
 */
contract BeaconTimelockTrigger is IBeaconTimelockTrigger, Manageable {
    /* ============ Global Variables ============ */

    /// @notice PrizeDistributionFactory reference.
    IPrizeDistributionFactory public prizeDistributionFactory;

    /// @notice DrawCalculatorTimelock reference.
    IDrawCalculatorTimelock public timelock;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /* ============ Modifiers ============= */

    modifier onlyNonZeroAddress(address _addressToCheck) {
        require(
            _addressToCheck != address(0),
            "BeaconTimelockTrigger/can-not-be-zero-address"
        );
        _;
    }

    /* ============ Initialize ============ */

    /**
     * @notice Initialize BeaconTimelockTrigger smart contract.
     * @param _owner The smart contract owner
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    function initialize(
        address _owner,
        IPrizeDistributionFactory _prizeDistributionFactory,
        IDrawCalculatorTimelock _timelock
    )
        external
        initializer
        onlyNonZeroAddress(address(_prizeDistributionFactory))
        onlyNonZeroAddress(address(_timelock))
    {
        __BeaconTimelockTrigger_init_unchained(
            _owner,
            _prizeDistributionFactory,
            _timelock
        );
    }

    /**
     * @notice Unchained initialization of BeaconTimelockTrigger smart contract.
     * @param _owner The smart contract owner
     * @param _prizeDistributionFactory PrizeDistributionFactory address
     * @param _timelock DrawCalculatorTimelock address
     */
    function __BeaconTimelockTrigger_init_unchained(
        address _owner,
        IPrizeDistributionFactory _prizeDistributionFactory,
        IDrawCalculatorTimelock _timelock
    ) internal onlyInitializing {
        __Manageable_init_unchained(_owner);

        prizeDistributionFactory = _prizeDistributionFactory;
        timelock = _timelock;

        emit Deployed(_prizeDistributionFactory, _timelock);
    }

    /* ============ External Methods ============ */

    /// @inheritdoc IBeaconTimelockTrigger
    function push(
        IDrawBeacon.Draw memory _draw,
        uint256 _totalNetworkTicketSupply
    ) external override onlyManagerOrOwner {
        bool _locked = timelock.lock(
            _draw.drawId,
            _draw.timestamp + _draw.beaconPeriodSeconds
        );

        require(_locked, "BeaconTimelockTrigger/draw-is-not-locked");

        prizeDistributionFactory.pushPrizeDistribution(
            _draw.drawId,
            _totalNetworkTicketSupply
        );

        emit DrawLockedAndTotalNetworkTicketSupplyPushed(
            _draw.drawId,
            _draw,
            _totalNetworkTicketSupply
        );
    }
}