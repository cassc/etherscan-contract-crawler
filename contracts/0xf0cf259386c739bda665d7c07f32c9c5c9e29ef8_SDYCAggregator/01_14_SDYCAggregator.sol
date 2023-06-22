// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// imported contracts and libraries
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

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
        int256 answer;
        uint256 interest;
        uint256 updatedAt;
    }

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    /// @dev the erc20 token that is being reported on
    IERC20 public immutable token;

    /// @dev the decimal for the underlying
    uint8 public immutable decimals;

    /// @dev desc of the pair, usually against USD
    string public description;

    /// @dev last id used to represent round data
    uint80 private lastRoundId;

    /// @dev assetId => asset address
    mapping(uint80 => RoundData) private rounds;

    uint256 public totalInterestAccrued;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event BalanceReported(uint80 roundId, uint256 balance, uint256 price, uint256 updatedAt);

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _token, uint8 _decimals, string memory _description) initializer {
        token = IERC20(_token);
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
        public
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
        return getRoundData(lastRoundId);
    }

    /**
     * @notice get interest data about a round
     * @return roundId is the round ID for which data was retrieved
     * @return interest the total accumulated interest in round
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     */
    function getRoundInterest(uint80 _roundId) public view returns (uint80 roundId, uint256 interest, uint256 updatedAt) {
        RoundData memory round = rounds[_roundId];

        return (_roundId, round.interest, round.updatedAt);
    }

    /**
     * @notice get interest from the latest round
     * @return roundId is the round ID for which data was retrieved
     * @return interest the total accumulated interest in round
     * @return updatedAt is the timestamp when the round last was updated (i.e. answer was last computed)
     */
    function latestRoundInterest() external view returns (uint80 roundId, uint256 interest, uint256 updatedAt) {
        return getRoundInterest(lastRoundId);
    }

    /**
     * @notice reports the balance of money market funds
     * @param _principal is the balance with 2 decimals of precision
     * @param _interest is the balance with 2 decimals of precision
     * @return roundId of the new round data
     */
    function reportBalance(uint256 _principal, uint256 _interest) external returns (uint80 roundId) {
        _checkOwner();

        roundId = lastRoundId += 1;

        RoundData memory round = rounds[roundId];
        if (round.answer != 0) revert RoundDataReported();

        // decimals calculated as {decimals|8} + {token.decimals|6} - {principal & interest decimals|2}
        uint256 answer = FixedPointMathLib.mulDivDown(_principal + _interest, 1e12, token.totalSupply());

        rounds[roundId] = RoundData(int256(answer), _interest, block.timestamp);

        // interest accrued in terms of SDYC (interest is 2 decimals, SDYC is 6 decimals)
        totalInterestAccrued += _interest * 1e4;

        emit BalanceReported(roundId, _principal, answer, block.timestamp);
    }
}