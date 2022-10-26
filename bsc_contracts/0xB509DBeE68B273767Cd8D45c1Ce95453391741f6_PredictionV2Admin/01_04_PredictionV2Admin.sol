// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "./interfaces/IPrediction.sol";

contract PredictionV2Admin is Ownable {
    IPrediction public immutable PredictionContract;

    address public operatorAddress; // address of the operator

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operatorAddress, "Not operator/owner");
        _;
    }

    /**
     * @notice Constructor
     * @param _predictionContract: Prediction address
     */
    constructor(IPrediction _predictionContract) {
        PredictionContract = _predictionContract;
    }

    /**
     * @notice called by the owner to pause, triggers stopped state
     * @dev Callable by owner
     */
    function pause() external onlyOwner {
        PredictionContract.pause();
    }

    /**
     * @notice Claim all rewards in treasury
     * @dev Callable by owner
     */
    function claimTreasury() external onlyOwner {
        PredictionContract.claimTreasury();
        uint256 balance = address(this).balance;
        _safeTransferBNB(msg.sender, balance);
    }

    /**
     * @notice Set buffer and interval (in seconds)
     * @dev Callable by owner
     */
    function setBufferAndIntervalSeconds(uint256 _bufferSeconds, uint256 _intervalSeconds) external onlyOwner {
        PredictionContract.setBufferAndIntervalSeconds(_bufferSeconds, _intervalSeconds);
    }

    /**
     * @notice Set minBetAmount
     * @dev Callable by owner
     */
    function setMinBetAmount(uint256 _minBetAmount) external onlyOwner {
        PredictionContract.setMinBetAmount(_minBetAmount);
    }

    /**
     * @notice Set operator address
     * @dev Callable by owner
     */
    function setOperator(address _operatorAddress) external onlyOwner {
        PredictionContract.setOperator(_operatorAddress);
    }

    /**
     * @notice Set Oracle address
     * @dev Callable by owner
     */
    function setOracle(address _oracle) external onlyOwner {
        PredictionContract.setOracle(_oracle);
    }

    /**
     * @notice Set oracle update allowance
     * @dev Callable by owner
     */
    function setOracleUpdateAllowance(uint256 _oracleUpdateAllowance) external onlyOwner {
        PredictionContract.setOracleUpdateAllowance(_oracleUpdateAllowance);
    }

    /**
     * @notice Set treasury fee
     * @dev Callable by owner
     */
    function setTreasuryFee(uint256 _treasuryFee) external onlyOwner {
        PredictionContract.setTreasuryFee(_treasuryFee);
    }

    /**
     * @notice called by the operator or owner to unpause, returns to normal state
     * Reset genesis state. Once paused, the rounds would need to be kickstarted by genesis
     */
    function unpause() external onlyOwnerOrOperator {
        PredictionContract.unpause();
    }

    function setAdminOperator(address _operatorAddress) external onlyOwner {
        operatorAddress = _operatorAddress;
    }

    /**
     * @notice Transfer BNB in a safe way
     * @param to: address to transfer BNB to
     * @param value: BNB amount to transfer (in wei)
     */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED in V2 admin");
    }

    receive() external payable {}
}