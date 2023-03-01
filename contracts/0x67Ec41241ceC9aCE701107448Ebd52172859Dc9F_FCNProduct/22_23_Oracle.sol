// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { AggregatorV3Interface } from "./AggregatorV3Interface.sol";
import { RoundData } from "./Structs.sol";
import { CegaState } from "./CegaState.sol";

contract Oracle is AggregatorV3Interface {
    uint8 public decimals;
    string public description;
    uint256 public version = 1;
    CegaState public cegaState;
    RoundData[] public oracleData;
    uint80 public nextRoundId;

    /**
     * @notice Creates a new oracle for a given asset / data source pair
     * @param _cegaState is the address of the CegaState contract
     * @param _decimals is the number of decimals for the asset
     * @param _description is the aset
     */
    constructor(address _cegaState, uint8 _decimals, string memory _description) {
        cegaState = CegaState(_cegaState);
        decimals = _decimals;
        description = _description;
    }

    /**
     * @notice Asserts whether the sender has the SERVICE_ADMIN_ROLE
     */
    modifier onlyServiceAdmin() {
        require(cegaState.isServiceAdmin(msg.sender), "403:SA");
        _;
    }

    /**
     * @notice Asserts whether the sender has the TRADER_ADMIN_ROLE
     */
    modifier onlyTraderAdmin() {
        require(cegaState.isTraderAdmin(msg.sender), "403:TA");
        _;
    }

    /**
     * @notice Adds the pricing data for the next round
     * @param _roundData is the data to be added
     */
    function addNextRoundData(RoundData calldata _roundData) public onlyServiceAdmin {
        oracleData.push(_roundData);
        nextRoundId++;
    }

    /**
     * @notice Updates the pricing data for a given round
     * @param _roundData is the data to be updated
     */
    function updateRoundData(uint80 roundId, RoundData calldata _roundData) public onlyTraderAdmin {
        oracleData[roundId] = _roundData;
    }

    /**
     * @notice Gets the pricing data for a given round Id
     * @param _roundId is the id of the round
     */
    function getRoundData(
        uint80 _roundId
    )
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (
            _roundId,
            oracleData[_roundId].answer,
            oracleData[_roundId].startedAt,
            oracleData[_roundId].updatedAt,
            oracleData[_roundId].answeredInRound
        );
    }

    /**
     * @notice Gets the pricing data for the latest round
     */
    function latestRoundData()
        public
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        uint80 _roundId = nextRoundId - 1;
        return (
            _roundId,
            oracleData[_roundId].answer,
            oracleData[_roundId].startedAt,
            oracleData[_roundId].updatedAt,
            oracleData[_roundId].answeredInRound
        );
    }
}