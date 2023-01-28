// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interface/CrosschainFunctionCallInterface.sol";
import "./interface/IPosiBridge.sol";
import "./common/CbcDecVer.sol";
import "./interface/NonAtomicHiddenAuthParameters.sol";
import "./common/ResponseProcessUtil.sol";

contract CrosschainControl is
    CrosschainFunctionCallInterface,
    CbcDecVer,
    NonAtomicHiddenAuthParameters,
    ResponseProcessUtil,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // 	0x77dab611
    bytes32 internal constant CROSS_CALL_EVENT_SIGNATURE =
    keccak256("CrossCall(bytes32,uint256,address,uint256,address,bytes)");

    // How old events can be before they are not accepted.
    // Also used as a time after which crosschain transaction ids can be purged from the
    // replayProvention map, thus reducing the cost of the crosschain transaction.
    // Measured in seconds.
    uint256 public timeHorizon;

    // Used to prevent replay attacks in transaction.
    // Mapping of txId to transaction expiry time.
    mapping(bytes32 => uint256) public replayPrevention;

    uint256 public myBlockchainId;

    // Use to determine different transactions but have same calldata, block timestamp
    uint256 txIndex;

    /**
   * Crosschain Transaction event.
   *
   * @param _txId Crosschain Transaction id.
   * @param _timestamp The time when the event was generated.
   * @param _caller Contract or EOA that submitted the crosschain call on the source blockchain.
   * @param _destBcId Destination blockchain Id.
   * @param _destContract Contract to be called on the destination blockchain.
   * @param _destFunctionCall The function selector and parameters in ABI packed format.
   */
    event CrossCall(
        bytes32 _txId,
        uint256 _timestamp,
        address _caller,
        uint256 _destBcId,
        address _destContract,
        bytes _destFunctionCall
    );

    event CallFailure(string _revertReason);

    /**
     * @param _myBlockchainId Blockchain identifier of this blockchain.
     * @param _timeHorizon How old crosschain events can be before they are
     *     deemed to be invalid. Measured in seconds.
     */
    function initialize(
        uint256 _myBlockchainId,
        uint256 _timeHorizon
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __Pausable_init();

        myBlockchainId = _myBlockchainId;
        timeHorizon = _timeHorizon;
    }

    function crossBlockchainCall(
        // NOTE: can keep using _destBcId and _destContract to determine which blockchain is calling
        uint256 _destBcId,
        address _destContract,
        bytes calldata _destData
    ) external override {
        txIndex++;
        bytes32 txId = keccak256(
            abi.encodePacked(
                block.timestamp,
                myBlockchainId,
                _destBcId,
                _destContract,
                _destData,
                txIndex
            )
        );
        emit CrossCall(
            txId,
            block.timestamp,
            msg.sender,
            _destBcId,
            _destContract,
            _destData
        );
    }

    // For server
    function crossCallHandler(
        uint256 _sourceBcId,
        address _cbcAddress,
        bytes calldata _eventData,
        bytes calldata _signature
    ) public {
        address relayer = msg.sender;
        decodeAndVerifyEvent(
            _sourceBcId,
            _cbcAddress,
            CROSS_CALL_EVENT_SIGNATURE,
            _eventData,
            _signature,
            relayer
        );

        // Decode _eventData
        // Recall that the cross call event is:
        // CrossCall(bytes32 _txId, uint256 _timestamp, address _caller,
        //           uint256 _destBcId, address _destContract, bytes _destFunctionCall)
        bytes32 txId;
        uint256 timestamp;
        address caller;
        uint256 destBcId;
        address destContract;
        bytes memory functionCall;
        (txId, timestamp, caller, destBcId, destContract, functionCall) = abi
        .decode(
            _eventData,
            (bytes32, uint256, address, uint256, address, bytes)
        );

        require(replayPrevention[txId] == 0, "Transaction already exists");

        require(
            timestamp < block.timestamp,
            "Event timestamp is in the future"
        );
        require(timestamp + timeHorizon > block.timestamp, "Event is too old");
        replayPrevention[txId] = timestamp;

        require(
            destBcId == myBlockchainId,
            "Incorrect destination blockchain id"
        );

        // Add authentication information to the function call.
        bytes memory functionCallWithAuth = encodeNonAtomicAuthParams(
            functionCall,
            _sourceBcId,
            caller
        );

        bool isSuccess;
        bytes memory returnValueEncoded;
        (isSuccess, returnValueEncoded) = destContract.call(
            functionCallWithAuth
        );
        require(isSuccess, getRevertMsg(returnValueEncoded));

        // distribute relayer reward and system reward
        IPosiBridge(destContract).distributeReward(msg.sender);
    }

    function updateTimeHorizon(uint256 _newTimeHorizon) public onlyOwner {
        timeHorizon = _newTimeHorizon;
    }
}