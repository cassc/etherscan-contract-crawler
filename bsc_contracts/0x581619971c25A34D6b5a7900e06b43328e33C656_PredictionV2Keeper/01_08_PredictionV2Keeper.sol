// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "@chainlink-0.4.0/contracts/src/v0.8/KeeperCompatible.sol";
import "./interfaces/IPredictionV2Admin.sol";
import "./interfaces/IPrediction.sol";

contract PredictionV2Keeper is KeeperCompatibleInterface, Ownable {
    IPrediction public immutable PredictionContract;
    IPredictionV2Admin public immutable PredictionV2AdminContract;
    address public register;
    address public operator;

    uint256 public delay = 180;  // Delay unpause time.

    event NewRegister(address indexed register);
    event NewOperator(address indexed operator);
    event NewDelay(uint256 delay);

    /**
     * @notice Constructor
     * @param _predictionContract: Prediction address
     * @param _predictionV2AdminContract: Prediction V2 admin address
     */
    constructor(address _predictionContract, address _predictionV2AdminContract) {
        PredictionContract = IPrediction(_predictionContract);
        PredictionV2AdminContract = IPredictionV2Admin(_predictionV2AdminContract);
    }

    modifier onlyRegister() {
        require(msg.sender == register || register == address(0), "Not register");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Not operator");
        _;
    }

    //The logic is consistent with the following performUpkeep function, in order to make the code logic clearer.
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        bool paused = PredictionContract.paused();
        uint256 currentEpoch = PredictionContract.currentEpoch();
        IPrediction.Round memory round = IPrediction(PredictionContract).rounds(currentEpoch);
        uint256 lockTimestamp = round.lockTimestamp;
        if (paused && block.timestamp > lockTimestamp + delay) {
            //need to unpause
            upkeepNeeded = true;
        }
    }

    function performUpkeep(bytes calldata) external override onlyRegister {
        PredictionV2AdminContract.unpause();
    }

    function setRegister(address _register) external onlyOwner {
        //When register is address(0), anyone can execute performUpkeep function
        register = _register;
        emit NewRegister(_register);
    }

    function unpausePrediction() external onlyOperator {
        PredictionV2AdminContract.unpause();
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit NewOperator(_operator);
    }

    function setDelay(uint256 _delay) external onlyOperator {
        delay = _delay;
        emit NewDelay(_delay);
    }
}