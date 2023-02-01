// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../interfaces/IAntfarmPosition.sol";
import "../interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";
import "../utils/PositionManagerErrors.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

/// @title Position Manager
/// @notice Let anyone create a set of rules to automate the dividends claiming
contract PositionManager {
    address public immutable antfarmPositions;
    address public immutable antfarmToken;

    struct Rules {
        address[] payees;
        uint256[] shares;
        uint256 executorShare; // 0-1000
    }

    mapping(address => Rules) public rules;

    event UpdatedRules(address indexed sender, Rules rules);

    error ExecutorShareTooHigh();
    error ZeroAddress();
    error WrongTotalAllocation();
    error WrongOwnerForPosition();
    error WrongNumOfShares();

    constructor(address _antfarmPositions, address _antfarmToken) {
        require(_antfarmPositions != address(0), "NULL_POSITIONS_ADDRESS");
        require(_antfarmToken != address(0), "NULL_ATF_ADDRESS");
        antfarmPositions = _antfarmPositions;
        antfarmToken = _antfarmToken;
    }

    function getRules(address _address)
        external
        view
        returns (Rules memory rule)
    {
        rule = rules[_address];
    }

    function setRules(
        address[] calldata _payees,
        uint256[] calldata _shares,
        uint256 _executorShare
    ) external {
        Rules memory _rules = Rules(_payees, _shares, _executorShare);
        rules[msg.sender] = _rules;

        if (_executorShare > 500) revert ExecutorShareTooHigh();

        uint256 numPayees = _payees.length;
        if (numPayees != _shares.length) revert WrongNumOfShares();

        uint256 totalAllocation;
        for (uint256 i; i < numPayees; ++i) {
            if (_payees[i] == address(0)) revert ZeroAddress();
            totalAllocation = totalAllocation + _shares[i];
        }

        if (totalAllocation != 1000) revert WrongTotalAllocation();

        emit UpdatedRules(msg.sender, _rules);
    }

    struct PositionsPerOwner {
        uint256[] positionIds;
        address owner;
    }

    function claimAndSplitProfits(
        PositionsPerOwner[] calldata positionsPerOwner
    ) external {
        uint256 positionsPerOwnerLength = positionsPerOwner.length;

        for (uint256 i; i < positionsPerOwnerLength; ++i) {
            uint256 numPositions = positionsPerOwner[i].positionIds.length;

            uint256[] memory ownerPositions = IAntfarmPosition(antfarmPositions)
                .getPositionsIds(positionsPerOwner[i].owner);
            uint256 ownerPositionsLength = ownerPositions.length;

            bool found;
            for (uint256 j; j < numPositions; ++j) {
                found = false;
                for (uint256 k; k < ownerPositionsLength; ++k) {
                    if (
                        positionsPerOwner[i].positionIds[j] == ownerPositions[k]
                    ) {
                        found = true;
                    }
                }
                if (!found) revert WrongOwnerForPosition();
            }

            uint256 amount = IAntfarmPosition(antfarmPositions)
                .claimDividendGrouped(positionsPerOwner[i].positionIds);

            splitProfits(positionsPerOwner[i].owner, amount);
        }
    }

    /// @notice Split and send rewards among payees
    function splitProfits(address owner, uint256 amountToSplit) internal {
        Rules memory ownerRules = rules[owner];

        uint256 sharesIncludingExecutor = 1000 + ownerRules.executorShare;

        uint256 amount;
        uint256 payeesLength = ownerRules.payees.length;
        for (uint256 i; i < payeesLength; ++i) {
            amount =
                (amountToSplit * ownerRules.shares[i]) /
                sharesIncludingExecutor;
            if (amount > 0) {
                TransferHelper.safeTransfer(
                    antfarmToken,
                    ownerRules.payees[i],
                    amount
                );
            }
        }

        amount =
            (amountToSplit * ownerRules.executorShare) /
            sharesIncludingExecutor;
        TransferHelper.safeTransfer(antfarmToken, msg.sender, amount);
    }
}