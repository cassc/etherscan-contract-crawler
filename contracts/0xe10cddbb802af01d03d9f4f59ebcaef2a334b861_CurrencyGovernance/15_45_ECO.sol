/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./InflationCheckpoints.sol";
import "../governance/monetary/CurrencyGovernance.sol";
import "../governance/IGeneration.sol";

/** @title An ERC20 token interface to the Eco currency system.
 */
contract ECO is InflationCheckpoints {
    /** Fired when a proposal with a new inflation multiplier is selected and passed.
     * Used to calculate new values for the rebased token.
     */
    event NewInflationMultiplier(uint256 inflationMultiplier);

    /* Current generation of the balance store. */
    uint256 public currentGeneration;

    // the address of the contract for initial distribution
    address public immutable distributor;

    uint256 public immutable initialSupply;

    constructor(
        Policy _policy,
        address _distributor,
        uint256 _initialSupply,
        address _initialPauser
    ) InflationCheckpoints(_policy, "ECO", "ECO", _initialPauser) {
        distributor = _distributor;
        initialSupply = _initialSupply;
    }

    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        pauser = ERC20Pausable(_self).pauser();
        _mint(distributor, initialSupply);
    }

    function mint(address _to, uint256 _value) external {
        require(
            msg.sender == policyFor(ID_CURRENCY_TIMER) ||
                msg.sender == policyFor(ID_ECOX) ||
                msg.sender == policyFor(ID_FAUCET),
            "Caller not authorized to mint tokens"
        );

        _mint(_to, _value);
    }

    function burn(address _from, uint256 _value) external {
        require(
            msg.sender == _from || msg.sender == policyFor(ID_CURRENCY_TIMER),
            "Caller not authorized to burn tokens"
        );

        _burn(_from, _value);
    }

    function notifyGenerationIncrease() public virtual override {
        uint256 _old = currentGeneration;
        uint256 _new = IGeneration(policyFor(ID_TIMED_POLICIES)).generation();
        require(_new != _old, "Generation has not increased");

        // update currentGeneration
        currentGeneration = _new;

        CurrencyGovernance bg = CurrencyGovernance(
            policyFor(ID_CURRENCY_GOVERNANCE)
        );

        if (address(bg) != address(0)) {
            if (
                uint8(bg.currentStage()) <
                uint8(CurrencyGovernance.Stage.Compute)
            ) {
                bg.updateStage();
            }
            if (
                uint8(bg.currentStage()) ==
                uint8(CurrencyGovernance.Stage.Compute)
            ) {
                bg.compute();
            }
            address winner = bg.winner();
            if (winner != address(0)) {
                uint256 _inflationMultiplier;
                (, , , , _inflationMultiplier, ) = bg.proposals(winner);
                emit NewInflationMultiplier(_inflationMultiplier);

                // updates the inflation value
                uint256 _newInflationMultiplier = (_linearInflationCheckpoints[
                    _linearInflationCheckpoints.length - 1
                ].value * _inflationMultiplier) / INITIAL_INFLATION_MULTIPLIER;
                _writeCheckpoint(
                    _linearInflationCheckpoints,
                    _replace,
                    _newInflationMultiplier
                );
            }
        }
    }
}