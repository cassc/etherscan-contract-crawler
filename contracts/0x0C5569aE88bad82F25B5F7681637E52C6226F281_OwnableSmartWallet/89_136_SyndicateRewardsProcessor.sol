// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

error ZeroAddress();

/// @notice Allows a contract to receive rewards from a syndicate and distribute it amongst LP holders
abstract contract SyndicateRewardsProcessor is ETHTransferHelper {

    /// @notice Emitted when ETH is received by the contract and processed
    event ETHReceived(uint256 amount);

    /// @notice Emitted when ETH from syndicate is distributed to a user
    event ETHDistributed(address indexed user, address indexed recipient, uint256 amount);

    /// @notice Precision used in rewards calculations for scaling up and down
    uint256 public constant PRECISION = 1e24;

    /// @notice Total accumulated ETH per share of LP<>KNOT that has minted derivatives scaled to 'PRECISION'
    uint256 public accumulatedETHPerLPShare;

    /// @notice Total ETH claimed by all users of the contract
    uint256 public totalClaimed;

    /// @notice Last total rewards seen by the contract
    uint256 public totalETHSeen;

    /// @notice How much historical ETH had accrued to the LP tokens at time of minting derivatives of a BLS key
    mapping(bytes => uint256) public accumulatedETHPerLPAtTimeOfMintingDerivatives;

    /// @notice Total ETH claimed by a given address for a given token
    mapping(address => mapping(address => uint256)) public claimed;

    /// @dev Internal logic for previewing accumulated ETH for an LP user
    function _previewAccumulatedETH(
        address _sender,
        address _token,
        uint256 _balanceOfSender,
        uint256 _numOfShares,
        uint256 _unclaimedETHFromSyndicate
    ) internal view returns (uint256) {
        if (_balanceOfSender > 0) {
            uint256 claim = _getTotalClaimedForUserAndToken(_sender, _token, _balanceOfSender);

            uint256 received = totalRewardsReceived() + _unclaimedETHFromSyndicate;
            uint256 unprocessed = received - totalETHSeen;

            uint256 newAccumulatedETH = accumulatedETHPerLPShare + ((unprocessed * PRECISION) / _numOfShares);

            return ((newAccumulatedETH * _balanceOfSender) / PRECISION) - claim;
        }
        return 0;
    }

    /// @dev Any due rewards from node running can be distributed to msg.sender if they have an LP balance
    function _distributeETHRewardsToUserForToken(
        address _user,
        address _token,
        uint256 _balance,
        address _recipient
    ) internal virtual returns (uint256) {
        if (_recipient == address(0)) revert ZeroAddress();
        uint256 balance = _balance;
        uint256 due;
        if (balance > 0) {
            // Calculate how much ETH rewards the address is owed / due 
            due = ((accumulatedETHPerLPShare * balance) / PRECISION) - _getTotalClaimedForUserAndToken(_user, _token, balance);
            if (due > 0) {
                _increaseClaimedForUserAndToken(_user, _token, due, balance);

                totalClaimed += due;

                emit ETHDistributed(_user, _recipient, due);
            }
        }

        return due;
    }

    /// @dev Overrideable logic for fetching the amount of tokens claimed by a user
    function _getTotalClaimedForUserAndToken(
        address _user,
        address _token,
        uint256         // Optional balance for use where needed
    ) internal virtual view returns (uint256);

    /// @dev Overrideable logic for updating the amount of tokens claimed by a user
    function _increaseClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _increase,
        uint256             // Optional balance for use where needed
    ) internal virtual;

    /// @dev Internal logic for tracking accumulated ETH per share
    function _updateAccumulatedETHPerLP(uint256 _numOfShares) internal {
        if (_numOfShares > 0) {
            uint256 received = totalRewardsReceived();
            uint256 unprocessed = received - totalETHSeen;

            if (unprocessed > 0) {
                emit ETHReceived(unprocessed);

                // accumulated ETH per minted share is scaled to avoid precision loss. it is scaled down later
                accumulatedETHPerLPShare += (unprocessed * PRECISION) / _numOfShares;

                totalETHSeen = received;
            }
        }
    }

    /// @notice Total rewards received by this contract from the syndicate
    function totalRewardsReceived() public virtual view returns (uint256);

    /// @notice Allow the contract to receive ETH
    receive() external payable {}
}