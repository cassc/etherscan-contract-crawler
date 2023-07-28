// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// Interfaces
import {ISDYC} from "../../interfaces/ISDYC.sol";

// errors
import "../../config/errors.sol";

/**
 * @title   SDYCAggregator
 * @author  dsshap
 * @dev     Reports the balance of the Short Duration Yield Fund
 */
contract SDYCAggregator is OwnableUpgradeable, UUPSUpgradeable {
    /// @dev round data package
    struct RoundData {
        int56 answer;
        uint56 balance;
        uint32 interest;
        uint32 updatedAt;
    }

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev the erc20 token that is being reported on
    ISDYC public immutable sdyc;

    /// @dev the decimal for the underlying
    uint8 public immutable decimals;

    /// @dev desc of the pair, usually against USD
    string public description;

    /// @dev last id used to represent round data
    uint80 private lastRoundId;

    /// @dev assetId => asset address
    mapping(uint80 => RoundData) private rounds;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event BalanceReported(uint80 roundId, uint256 balance, uint256 interest, uint256 price, uint256 updatedAt);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _sdyc, uint8 _decimals, string memory _description) initializer {
        sdyc = ISDYC(_sdyc);
        decimals = _decimals;
        description = _description;
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner, string memory _description) external initializer {
        // solhint-disable-next-line reason-string
        if (_owner == address(0)) revert();
        _transferOwnership(_owner);

        description = _description;
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */

    function _authorizeUpgrade(address /*newImplementation*/ ) internal virtual override {
        _checkOwner();
    }

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice get data about a round
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is always equal to updatedAt
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     * @return answeredInRound is always equal to roundId
     */
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.answer, round.updatedAt, round.updatedAt, _roundId);
    }

    /**
     * @notice get data about the latest round
     * @return roundId is the round ID for which data was retrieved
     * @return answer is the answer for the given round
     * @return startedAt is always equal to updatedAt
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     * @return answeredInRound is always equal to roundId
     */
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint80 _roundId = lastRoundId;
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.answer, round.updatedAt, round.updatedAt, _roundId);
    }

    /**
     * @notice get detail data about a round
     * @return roundId is the round ID for which data was retrieved
     * @return balance the total balance USD (2 decimals)
     * @return interest the total interest accrued USD (2 decimals)
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     */
    function getRoundDetails(uint80 _roundId)
        public
        view
        returns (uint80 roundId, uint256 balance, uint256 interest, uint256 updatedAt)
    {
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.balance, round.interest, round.updatedAt);
    }

    /**
     * @notice get interest from the latest round
     * @return roundId is the round ID for which data was retrieved
     * @return balance the total balance USD (2 decimals)
     * @return interest the total interest accrued USD (2 decimals)
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     */
    function latestRoundDetails() external view returns (uint80 roundId, uint256 balance, uint256 interest, uint256 updatedAt) {
        return getRoundDetails(lastRoundId);
    }

    /**
     * @notice reports the balance of funds
     * @dev only callable by the owner, process SDYC fees if interest accrued
     * @param _principal is the balance with 2 decimals of precision
     * @param _interest is the balance with 2 decimals of precision
     * @return roundId of the new round data
     */
    function reportBalance(uint256 _principal, uint256 _interest) external returns (uint80 roundId) {
        _checkOwner();

        uint256 balance = _principal + _interest;
        if (_interest > type(uint32).max) revert Overflow();
        if (balance > type(uint56).max) revert Overflow();

        roundId = lastRoundId;
        RoundData memory round = rounds[roundId];

        // new balance and interest can never be the same as last round
        if (round.balance == balance && round.interest == _interest) revert RoundDataReported();

        if (_interest > 0) sdyc.processFees(_interest, uint256(uint56(round.answer)));

        lastRoundId = roundId += 1;

        round = rounds[roundId];
        if (round.answer != 0) revert RoundDataReported();

        // decimals calculated as {decimals|8} + {token.decimals|6} - {principal & interest decimals|2}
        uint256 answer = FixedPointMathLib.mulDivDown(balance, 1e12, sdyc.totalSupply());

        if (int256(answer) > type(int56).max) revert Overflow();

        rounds[roundId] = RoundData(int56(int256(answer)), uint56(balance), uint32(_interest), uint32(block.timestamp));

        emit BalanceReported(roundId, balance, _interest, answer, block.timestamp);
    }
}