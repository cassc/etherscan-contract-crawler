/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../currency/VoteCheckpoints.sol";
import "../governance/IGenerationIncrease.sol";
import "../policy/PolicedUtils.sol";

/** @title InflationCheckpoints
 * This implements a generational store with snapshotted balances. Balances
 * are lazy-evaluated, but are effectively all atomically snapshotted when
 * the generation changes.
 */
abstract contract InflationCheckpoints is
    VoteCheckpoints,
    PolicedUtils,
    IGenerationIncrease
{
    uint256 public constant INITIAL_INFLATION_MULTIPLIER = 1e18;

    Checkpoint[] internal _linearInflationCheckpoints;

    // to be used to record the transfer amounts after _beforeTokenTransfer
    // these values are the base (unchanging) values the currency is stored in
    event BaseValueTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    /** Construct a new instance.
     *
     * Note that it is always necessary to call reAuthorize on the balance store
     * after it is first constructed to populate the authorized interface
     * contracts cache. These calls are separated to allow the authorized
     * contracts to be configured/deployed after the balance store contract.
     */
    constructor(
        Policy _policy,
        string memory _name,
        string memory _symbol,
        address _initialPauser
    )
        VoteCheckpoints(_name, _symbol, address(_policy), _initialPauser)
        PolicedUtils(_policy)
    {
        _writeCheckpoint(
            _linearInflationCheckpoints,
            _replace,
            INITIAL_INFLATION_MULTIPLIER
        );
    }

    function initialize(address _self)
        public
        virtual
        override
        onlyConstruction
    {
        super.initialize(_self);
        _writeCheckpoint(
            _linearInflationCheckpoints,
            _replace,
            INITIAL_INFLATION_MULTIPLIER
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override returns (uint256) {
        amount = super._beforeTokenTransfer(from, to, amount);
        uint256 gonsAmount = amount *
            _checkpointsLookup(_linearInflationCheckpoints, block.number);

        emit BaseValueTransfer(from, to, gonsAmount);

        return gonsAmount;
    }

    function getPastLinearInflation(uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        require(
            blockNumber <= block.number,
            "InflationCheckpoints: block not yet mined"
        );
        return _checkpointsLookup(_linearInflationCheckpoints, blockNumber);
    }

    /** Access function to determine the token balance held by some address.
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        uint256 _linearInflation = _checkpointsLookup(
            _linearInflationCheckpoints,
            block.number
        );
        return _balances[_owner] / _linearInflation;
    }

    /** Returns the total (inflation corrected) token supply
     */
    function totalSupply() public view override returns (uint256) {
        uint256 _linearInflation = _checkpointsLookup(
            _linearInflationCheckpoints,
            block.number
        );
        return _totalSupply / _linearInflation;
    }

    /** Returns the total (inflation corrected) token supply at a specified block number
     */
    function totalSupplyAt(uint256 _blockNumber)
        public
        view
        override
        returns (uint256)
    {
        uint256 _linearInflation = getPastLinearInflation(_blockNumber);

        return getPastTotalSupply(_blockNumber) / _linearInflation;
    }

    /** Return historical voting balance (includes delegation) at given block number.
     *
     * If the latest block number for the account is before the requested
     * block then the most recent known balance is returned. Otherwise the
     * exact block number requested is returned.
     *
     * @param _owner The account to check the balance of.
     * @param _blockNumber The block number to check the balance at the start
     *                        of. Must be less than or equal to the present
     *                        block number.
     */
    function getPastVotes(address _owner, uint256 _blockNumber)
        public
        view
        override
        returns (uint256)
    {
        uint256 _linearInflation = getPastLinearInflation(_blockNumber);

        return getPastVotingGons(_owner, _blockNumber) / _linearInflation;
    }
}