// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

struct Metadata {
    uint8 evoNum;
    uint64 genes;
    uint8 anomalyNum;
}

interface IDOTS {
    function currentEvoDots(uint256,uint256) external returns (uint256);
}

contract AnomalyDOTS is AccessControl, VRFConsumerBaseV2 {

    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    VRFCoordinatorV2Interface immutable COORDINATOR;
    IDOTS immutable dots;

    bytes32 keyHash;
    uint64 subscriptionId;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;

    error InsufficientBaseAmount();

    mapping(uint256 => AnomalyRoll) public anomalyRolls;
    mapping(uint256 => uint256) public anomalyType;

    struct AnomalyRoll {
        uint64 evoStage;
        uint64 anomalyAmount;
        uint64 currentPopulation;
    }

    event AnomalyRolled(
        uint256 indexed tokenId,
        uint256 indexed anomalyNum
    );

    constructor(
        address adminWallet,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId,
        address _dotsContract
    ) VRFConsumerBaseV2(_vrfCoordinator)  {
        dots = IDOTS(_dotsContract);
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        _setupRole(DEFAULT_ADMIN_ROLE, adminWallet);
        _setupRole(ADMIN_ROLE, address(0xfd64b63D4A54e6b1a0Aa88e6623046c54F960D00));
    }
    /**
     * @notice admin function to initiate VRF transaction for anomaly distribution
     * @param _evoStage min evo stage for token to participate
     * @param _anomalyAmount amount of anomalies to distribute
     */
    function rollAnomalyDots(
        uint64 _evoStage,
        uint64 _anomalyAmount,
        uint64 _currentPopulation
    ) external onlyRole(ADMIN_ROLE) {
        uint256 _requestId = COORDINATOR.requestRandomWords(
          keyHash,
          subscriptionId,
          requestConfirmations,
          callbackGasLimit,
          1
        );

        anomalyRolls[_requestId] = AnomalyRoll({
            evoStage: _evoStage,
            anomalyAmount: _anomalyAmount,
            currentPopulation: _currentPopulation
        });
    }

    /**
     * @notice callback to retrieve random number for anomaly distribution
     * @param _requestId id of the request made by rollAnomalyDots
     * @param _randomWords the actual random number
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        AnomalyRoll memory anomalyRoll = anomalyRolls[_requestId];

        uint256 _nonce;
        uint256 _numAssigned;
        uint256 _tempAnomalyIdx;
        uint256 _tempAnomalyTokenId;
        uint256 _hashForAnomalyNum;
        uint256 _anomalyNum;

        while (_numAssigned < anomalyRoll.anomalyAmount) {
            _tempAnomalyIdx = uint256(keccak256(abi.encodePacked(_randomWords[0], _nonce))) % anomalyRoll.currentPopulation;
            _tempAnomalyTokenId = dots.currentEvoDots(anomalyRoll.evoStage, _tempAnomalyIdx);


            if(anomalyType[_tempAnomalyTokenId] == 0) {
                _hashForAnomalyNum = uint256(keccak256(abi.encodePacked(_randomWords[0], _tempAnomalyTokenId))) % 100;

                if (_hashForAnomalyNum < 10) _anomalyNum = 1;
                else if (_hashForAnomalyNum < 55) _anomalyNum = 2;
                else _anomalyNum = 3;

                anomalyType[_tempAnomalyTokenId] = _anomalyNum;

                unchecked { _numAssigned++; }

                emit AnomalyRolled(_tempAnomalyTokenId, _anomalyNum);
            }

            unchecked { _nonce++; }               
        }
    } 
}