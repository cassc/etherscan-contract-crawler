//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract SwarmPriceFeed is Ownable {
    string public description;

    uint256 private _latestOffchainTimestamp;

    uint256 public latestTimestamp;
    uint256 public latestAnswer;

    uint8 public decimals;

    event DescriptionUpdated(string oldDescription, string newDescription);
    event LatestAnswerUpdated(uint256 latestAnswer, uint256 latestTimestamp);
    event DecimalsUpdated(uint8 oldDecimals, uint8 newDecimals);

    constructor(
        string memory _initialDescription,
        uint256 _initialLatestAnswer,
        uint256 _initialLatestOffchainTimestamp,
        uint8 _initialDecimals
    ) {
        setDescription(_initialDescription);
        setLatestAnswer(_initialLatestAnswer, _initialLatestOffchainTimestamp);
        setDecimals(_initialDecimals);
    }

    function setDescription(string memory _description) public onlyOwner {
        emit DescriptionUpdated(description, _description);

        description = _description;
    }

    function setLatestAnswer(uint256 _answer, uint256 _offChaintimestamp) public onlyOwner {
        require(_offChaintimestamp > _latestOffchainTimestamp, "OFF_CHAIN_TIMESTAMP_TOO_OLD");
        require(_offChaintimestamp <= block.timestamp + 60, "OFF_CHAIN_TIMESTAMP_TOO_FAR_IN_FUTURE");

        emit LatestAnswerUpdated(_answer, block.timestamp);

        _latestOffchainTimestamp = _offChaintimestamp;

        latestAnswer = _answer;
        latestTimestamp = block.timestamp;
    }

    function setDecimals(uint8 _decimals) public onlyOwner {
        emit DecimalsUpdated(decimals, _decimals);

        decimals = _decimals;
    }

    function latestRoundData() external view returns (uint256, uint256, uint256, uint256, uint256) {
        return (0, latestAnswer, latestTimestamp, latestTimestamp, 0);
    }
}