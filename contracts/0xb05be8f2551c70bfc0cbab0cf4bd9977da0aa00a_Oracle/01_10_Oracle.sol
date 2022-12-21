// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/oracle/IOracle.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Alkimiya Oracle
 * @author Alkimiya Team
 */
contract Oracle is AccessControl, IOracle {
    // Constants
    int8 public constant VERSION = 1;
    uint32 public lastIndexedDay;

    bytes32 public constant PUBLISHER_ROLE = keccak256("PUBLISHER_ROLE");
    bytes32 public constant CALCULATOR_ROLE = keccak256("CALCULATOR_ROLE");

    mapping(uint256 => AlkimiyaIndex) private index;

    string public name;

    struct AlkimiyaIndex {
        uint32 referenceBlock;
        uint32 timestamp;
        uint128 hashrate;
        uint64 difficulty;
        uint256 reward;
        uint256 fees;
    }

    constructor(string memory _name) {
        _setupRole(PUBLISHER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
    }

    /// @notice Function to update Oracle Index
    function updateIndex(
        uint256 _referenceDay,
        uint256 _referenceBlock,
        uint256 _hashrate,
        uint256 _reward,
        uint256 _fees,
        uint256 _difficulty,
        bytes memory signature
    ) public override returns (bool) {
        require(_hashrate <= type(uint128).max, "Hashrate cannot exceed max val");
        require(_difficulty <= type(uint64).max, "Difficulty cannot exceed max val");
        require(_referenceBlock <= type(uint32).max, "Reference block cannot exceed max val");

        require(hasRole(PUBLISHER_ROLE, msg.sender), "Update not allowed to everyone");

        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(_referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty))
            )
        );

        require(hasRole(CALCULATOR_ROLE, ECDSA.recover(messageHash, signature)), "Invalid signature");

        require(index[_referenceDay].timestamp == 0, "Information cannot be updated.");

        index[_referenceDay].timestamp = uint32(block.timestamp);
        index[_referenceDay].difficulty = uint64(_difficulty);
        index[_referenceDay].referenceBlock = uint32(_referenceBlock);
        index[_referenceDay].hashrate = uint128(_hashrate);
        index[_referenceDay].reward = _reward;
        index[_referenceDay].fees = _fees;

        if (_referenceDay > lastIndexedDay) {
            lastIndexedDay = uint32(_referenceDay);
        }

        emit OracleUpdate(msg.sender, _referenceDay, _referenceBlock, _hashrate, _reward, _fees, _difficulty, block.timestamp);

        return true;
    }

    /// @notice Function to return Oracle index on given day
    function get(uint256 _referenceDay)
        external
        view
        override
        returns (
            uint256 referenceDay,
            uint256 referenceBlock,
            uint256 hashrate,
            uint256 reward,
            uint256 fees,
            uint256 difficulty,
            uint256 timestamp
        )
    {
        require(index[_referenceDay].timestamp != 0, "Date not yet indexed");

        return (
            _referenceDay,
            index[_referenceDay].referenceBlock,
            index[_referenceDay].hashrate,
            index[_referenceDay].reward,
            index[_referenceDay].fees,
            index[_referenceDay].difficulty,
            index[_referenceDay].timestamp
        );
    }

    /// @notice Function to return array of oracle data between firstday and lastday (inclusive)
    function getInRange(uint256 _firstDay, uint256 _lastDay)
        external
        view
        override
        returns (uint256[] memory hashrateArray, uint256[] memory rewardArray)
    {
        uint256 numElements = _lastDay + 1 - _firstDay;

        rewardArray = new uint256[](numElements);
        hashrateArray = new uint256[](numElements);

        for (uint256 i = 0; i < numElements; i++) {
            AlkimiyaIndex memory indexCopy = index[_firstDay + i];
            rewardArray[i] = indexCopy.reward;
            hashrateArray[i] = indexCopy.hashrate;
        }
    }

    /// @notice Function to check if Oracle is updated on a given day
    function isDayIndexed(uint256 _referenceDay) external view override returns (bool) {
        return index[_referenceDay].timestamp != 0;
    }

    /// @notice Functino to return the latest day on which the Oracle is updated
    function getLastIndexedDay() external view override returns (uint32) {
        return lastIndexedDay;
    }
}