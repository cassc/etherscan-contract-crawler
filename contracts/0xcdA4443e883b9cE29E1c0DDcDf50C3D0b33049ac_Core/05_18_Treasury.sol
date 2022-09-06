// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { OwnershipToken } from "./tokens/OwnershipToken.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFuture } from "./interfaces/IFuture.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "./libs/Utils.sol";


contract Treasury is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @dev stores a mapping of streamName => bool
     * gets the treasury details attached to a particular stream
     * streamName is created by hashing <protocolName, underlying, duration>
     * */
    mapping(bytes32 => bool) public streamStatus;

    // yield stored per stream per future
    // meta => futureIndex =>yeild
    mapping(bytes32 => mapping(uint256 => uint256)) public yields;

    // Underlying stored per stream per future excluding the yield
    mapping(bytes32 => mapping(uint256 => uint256)) public underlyingForOt;

    /**
     * @dev this creates a new treasury which will hold tokens for each new
     * stream when it gets initialised
     *
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _durationSeconds: number of blocks the future will run before renewing
     */
    function createNewTreasuryStream(
        string memory _protocol,
        address _underlying,
        uint256 _durationSeconds
    ) external onlyOwner {
        bytes32 streamKey = getStreamKey(_protocol, _underlying, _durationSeconds);

        // add new stream status
        streamStatus[streamKey] = true;
    }

    /**
     * @dev renews a stream by expiring previous future and safeTransfering the remaining
     * amount of still subscrived underlying to this contract. Mints new OT such that
     * it inflates the price of the underlying per OT.
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _prevEpoch: index of the expired instance of future in a stream
     * @param _prevEpochAddr: address of the expired future instance
     */
    function renew(
        bytes32 _streamKey,
        uint256 _prevEpoch,
        address _prevEpochAddr
    ) external onlyOwner {
        require(streamExists(_streamKey), "incorrect streamKey, stream doesnt exist");
        IFuture prevEpochInstance = IFuture(_prevEpochAddr);
        uint256 yield = prevEpochInstance.yield();
        uint256 totalUnderlying = prevEpochInstance.totalBalanceUnderlying();
        prevEpochInstance.expire();
        yields[_streamKey][_prevEpoch] = yield;
        underlyingForOt[_streamKey][_prevEpoch] = totalUnderlying - yield;
    }

    /**
     * @dev this funds the future and kicks it off.
     * (ie: deposits the fund in underlying protocol)
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _durationSeconds: number of blocks the future will run before renewing
     * @param to: address of the future
     * @param _amountSubscribedInUnderlying: amount subscribed in underlying protocol.
     * @param _epoch: index of the future
     */
    function fundAndKickOffEpoch(
        string memory _protocol,
        address to,
        uint256 _durationSeconds,
        uint256 _amountSubscribedInUnderlying,
        uint256 _epoch
    ) external onlyOwner {
        IFuture future = IFuture(to);
        IERC20(future.underlying()).safeApprove(to, _amountSubscribedInUnderlying);
        future.start(_protocol, _durationSeconds, _amountSubscribedInUnderlying, _epoch);
    }

    /**
     * @dev claim yield for a particular user, stream and epoch
     * @param _streamKey: name of the stream, created by hashing protocol, underlying, duration
     * @param _shares: amount of YTs of the user for a given future
     * @param _supply: total supply of YT for a given future
     * @param _token: address of the underlying token
     * @param _user: address of the user whose yield needs to be claimed
     */
    function claimYield(
        bytes32 _streamKey,
        uint256 _epoch,
        uint256 _shares,
        uint256 _supply,
        address _token,
        address _user
    ) external onlyOwner returns (uint256 amountToSafeTransfer) {
        uint256 yieldRemaining = yields[_streamKey][_epoch];
        amountToSafeTransfer = (yieldRemaining * _shares) / _supply;
        yields[_streamKey][_epoch] -= amountToSafeTransfer;
        IERC20(_token).safeTransfer(_user, amountToSafeTransfer);
    }

    /**
     * @dev Deposit underlying token to current epoch vault
     * @param _epoch: address of the current epoch
     * @param _amount: amount of tokens to transfer
     */
    function deposit(
        address _epoch,
        uint256 _amount
    ) external onlyOwner {
        IFuture future = IFuture(_epoch);
        IERC20(future.underlying()).safeApprove(_epoch, _amount);
        future.depositInUnderlying(_amount);
    }

    /**
     * @dev Withdraw OT underlying token to an address (similar to: ERC20 token transfer)
     * @param _token: address of underlying token
     * @param _user: address of the user
     * @param _amount: amount of tokens to transfer
     */
    function withdraw(
        bytes32 _streamKey,
        address _token,
        address _user,
        uint256 _epoch,
        uint256 _supply,
        uint256 _amount
    ) external onlyOwner returns (uint256 amountToSafeTransfer) {
        uint256 underlyingRemaining = underlyingForOt[_streamKey][_epoch];
        amountToSafeTransfer = (underlyingRemaining * _amount) / _supply;
        underlyingForOt[_streamKey][_epoch] -= amountToSafeTransfer;
        IERC20(_token).safeTransfer(_user, amountToSafeTransfer);
    }

    // VIEW FUNCTIONS

    /**
     * @dev this checks if a given stream exists
     * @param _streamKey name of the stream, created by hashing protocol, underlying, duration
     * @return boolean indicating if the stream exists or not
     */
    function streamExists(bytes32 _streamKey) public view returns (bool) {
        require(_streamKey != bytes32(0), "streamkey cannot be zero");
        return streamStatus[_streamKey];
    }

    // PURE FUNCTIONS
    /**
     * @dev Get the unique name of the stream, created by hashing protocol, underlying, duration
     * @param _protocol: name of the protocol. eg - AAVE/COMP
     * @param _underlying: address of the token kept as underlying. eg - DAI
     * @param _duration: number of blocks the future will run before renewing
     * @return the hashed streamKey
     */
    function getStreamKey(
        string memory _protocol,
        address _underlying,
        uint256 _duration
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_protocol, _underlying, _duration));
    }
}