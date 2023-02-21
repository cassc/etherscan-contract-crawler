// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../policy/PolicedUtils.sol";
import "../policy/Policy.sol";
import "./community/PolicyProposals.sol";
import "./monetary/CurrencyGovernance.sol";
import "../utils/TimeUtils.sol";
import "./IGenerationIncrease.sol";
import "./IGeneration.sol";
import "./monetary/Lockup.sol";
import "./monetary/RandomInflation.sol";
import "../currency/ECO.sol";

/** @title TimedPolicies
 * Oversees the time-based recurring processes that allow governance of the
 * Eco currency.
 */
contract CurrencyTimer is PolicedUtils, IGenerationIncrease {
    /** The on-chain address for the currency voting contract. This contract is
     * cloned for each new currency vote.
     */
    CurrencyGovernance public bordaImpl;

    RandomInflation public inflationImpl;
    Lockup public lockupImpl;

    // the ECO contract address
    ECO public immutable ecoToken;

    /* Current generation of the balance store. */
    uint256 public currentGeneration;

    mapping(uint256 => Lockup) public lockups;
    mapping(address => bool) public isLockup;

    mapping(uint256 => RandomInflation) public randomInflations;

    event NewInflation(
        RandomInflation indexed addr,
        uint256 indexed generation
    );
    event NewLockup(Lockup indexed addr, uint256 indexed generation);
    event NewCurrencyGovernance(
        CurrencyGovernance indexed addr,
        uint256 indexed generation
    );

    constructor(
        Policy _policy,
        CurrencyGovernance _borda,
        RandomInflation _inflation,
        Lockup _lockup,
        ECO _ecoAddr
    ) PolicedUtils(_policy) {
        require(
            address(_borda) != address(0),
            "Critical: do not set the _borda as the zero address"
        );
        require(
            address(_inflation) != address(0),
            "Critical: do not set the _inflation as the zero address"
        );
        require(
            address(_lockup) != address(0),
            "Critical: do not set the _lockup as the zero address"
        );
        require(
            address(_ecoAddr) != address(0),
            "Critical: do not set the _ecoAddr as the zero address"
        );
        bordaImpl = _borda;
        inflationImpl = _inflation;
        lockupImpl = _lockup;
        ecoToken = _ecoAddr;
    }

    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);

        // all of these values are better left mutable to allow for easier governance
        bordaImpl = CurrencyTimer(_self).bordaImpl();
        inflationImpl = CurrencyTimer(_self).inflationImpl();
        lockupImpl = CurrencyTimer(_self).lockupImpl();
    }

    function notifyGenerationIncrease() external override {
        uint256 _old = currentGeneration;
        uint256 _new = IGeneration(policyFor(ID_TIMED_POLICIES)).generation();
        require(_new != _old, "Generation has not increased");

        currentGeneration = _new;

        CurrencyGovernance bg = CurrencyGovernance(
            policyFor(ID_CURRENCY_GOVERNANCE)
        );

        uint256 _numberOfRecipients = 0;
        uint256 _randomInflationReward = 0;
        uint256 _lockupDuration = 0;
        uint256 _lockupInterest = 0;

        if (address(bg) != address(0)) {
            if (uint8(bg.currentStage()) < 3) {
                bg.updateStage();
            }
            if (uint8(bg.currentStage()) == 3) {
                bg.compute();
            }
            address winner = bg.winner();
            if (winner != address(0)) {
                (
                    _numberOfRecipients,
                    _randomInflationReward,
                    _lockupDuration,
                    _lockupInterest,
                    ,

                ) = bg.proposals(winner);
            }
        }

        {
            CurrencyGovernance _clone = CurrencyGovernance(bordaImpl.clone());
            policy.setPolicy(
                ID_CURRENCY_GOVERNANCE,
                address(_clone),
                ID_CURRENCY_TIMER
            );
            emit NewCurrencyGovernance(_clone, _new);
        }

        if (_numberOfRecipients > 0 && _randomInflationReward > 0) {
            // new inflation contract
            RandomInflation _clone = RandomInflation(inflationImpl.clone());
            ecoToken.mint(
                address(_clone),
                _numberOfRecipients * _randomInflationReward
            );
            _clone.startInflation(_numberOfRecipients, _randomInflationReward);
            emit NewInflation(_clone, _old);
            randomInflations[_old] = _clone;
        }

        if (_lockupDuration > 0 && _lockupInterest > 0) {
            Lockup _clone = Lockup(
                lockupImpl.clone(_lockupDuration, _lockupInterest)
            );
            emit NewLockup(_clone, _old);
            lockups[_old] = _clone;
            isLockup[address(_clone)] = true;
        }
    }

    function lockupWithdrawal(
        address _withdrawer,
        uint256 _amount,
        bool _penalty
    ) external {
        require(isLockup[msg.sender], "Not authorized to call this function");

        if (_penalty) {
            ecoToken.burn(_withdrawer, _amount);
        } else {
            ecoToken.mint(_withdrawer, _amount);
        }
    }
}