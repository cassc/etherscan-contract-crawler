// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "./interfaces/MCAGAggregatorInterface.sol";
import {Roles} from "./libraries/Roles.sol";

contract MCAGAggregator is MCAGAggregatorInterface {
    uint8 private constant _VERSION = 1;
    uint8 private constant _DECIMALS = 27;

    IAccessControl public immutable accessController;

    uint80 private _roundId;
    string private _description;
    int256 private _answer;
    int256 private _maxAnswer;
    uint256 private _updatedAt;

    modifier onlyRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    /**
     * @param description_ Description of the oracle - for example "10 YEAR US TREASURY".
     * @param maxAnswer_ Maximum sensible answer the contract should accept.
     * @param _accessController MCAG AccessController.
     */
    constructor(string memory description_, int256 maxAnswer_, IAccessControl _accessController) {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        _description = description_;
        _maxAnswer = maxAnswer_;
        accessController = _accessController;
    }

    /**
     * @notice Transmits a new price to the aggreator and updates the answer, round id and updated at.
     * @dev Can only be called by a registered transmitter.
     * @param answer New central bank rate as a per second cumualtive rate in 27 decimals.
     * For example a 5% annual linear rate would be converted to a per second cumulative rate as follow :
     * (1 + 5%)^(1 / 31536000) * 1e27 = 100000000578137865680459171
     */
    function transmit(int256 answer) external override onlyRole(Roles.MCAG_TRANSMITTER_ROLE) {
        if (answer > _maxAnswer) {
            revert Errors.TRANSMITTED_ANSWER_TOO_HIGH(answer, _maxAnswer);
        }

        ++_roundId;
        _updatedAt = block.timestamp;
        _answer = answer;

        emit AnswerTransmitted(msg.sender, _roundId, answer);
    }

    /**
     * @notice Sets a new max answer.
     * @dev Can only be called by MCAG Manager.
     * @param newMaxAnswer New maximum sensible answer the contract should accept.
     */
    function setMaxAnswer(int256 newMaxAnswer) external onlyRole(Roles.MCAG_MANAGER_ROLE) {
        emit MaxAnswerSet(_maxAnswer, newMaxAnswer);
        _maxAnswer = newMaxAnswer;
    }

    /**
     * @notice Returns round data per the Chainlink format.
     * @return roundId Latest _roundId.
     * @return answer Latest answer transmitted.
     * @return startedAt Unused variable here only to follow Chainlink format.
     * @return updatedAt Timestamp of the last transmitted answer.
     * @return answeredInRound Latest _roundId.
     */
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        roundId = _roundId;
        answer = _answer;
        updatedAt = _updatedAt;
        answeredInRound = _roundId;
    }

    /**
     * @return Description of the oracle - for example "10 YEAR US TREASURY".
     */
    function description() external view override returns (string memory) {
        return _description;
    }

    /**
     * @return Maximum sensible answer the contract should accept.
     */
    function maxAnswer() external view override returns (int256) {
        return _maxAnswer;
    }

    /**
     * @return Number of decimals used to get its user representation.
     */
    function decimals() external pure override returns (uint8) {
        return _DECIMALS;
    }

    /**
     * @return Contract version.
     */
    function version() external pure override returns (uint8) {
        return _VERSION;
    }
}