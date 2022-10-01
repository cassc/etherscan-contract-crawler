// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./MainControllerInterface.sol";

contract MainControllerStorageV1 {

    /**
     * @notice split fee ratio of tech team 
     */
    address public techFee;

    /**
     * @notice split fee ratio of community team 
     */
    address public communityFee;

    /**
     * @notice administrator of operations, such as create a new match
     */
     address public admin;

    /**
     * @notice split fee ratio of direct referor 
     */
    uint public first_ref_fee;

    /**
     * @notice split fee ratio of second referor 
     */
    uint public second_ref_fee;

    /**
     * @notice USDT address 
     */
    address public usdt;

    struct Match {
	/// @notice isUsed
	bool isUsed;

	/// @notice Team number of first team
        uint teamA;
	/// @notice Team number of second team
	uint teamB;

	/// @notice start time in UNIX timestamp
	uint startTime;

	/// @notice close time in UNIX timestamp
	uint endTime;
    }

    /// @notice index date and team a and team b to match address 
    mapping (string =>mapping (uint8 => mapping (uint8 => address))) matches;


    /// VoteRecord
    mapping(address => MainControllerInterface.VoteRecord[]) public voteRecords;

    /// @notice A list of all matches
    address[] public matchesList;

    /**
     * @notice Official mapping of match address -> Match metadata
     * @dev Used e.g. to determine if a match is supported
     */
    mapping(address => Match) public matchInfos;

    /**
     * Team name dictonary
     */
    mapping(uint8 => string) public teamNamesDict;

    /**
     * upline dictonary
     */
    mapping(address => address) public uplineDict;
}