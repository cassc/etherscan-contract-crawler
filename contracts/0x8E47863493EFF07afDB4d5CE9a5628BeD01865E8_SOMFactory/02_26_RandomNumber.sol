// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./Som.sol";
import "./Coward.sol";

contract RandomGenerator is VRFConsumerBase, Ownable {
    using Address for address;

    bytes32 internal keyHash;
    uint256 internal fee;

    address public SOMAddress;
    address public CowardAddress;

    bytes32 currentRequestID;

    mapping(bytes32 => uint256) public requestToRandom;
    mapping(bytes32 => bool) public hasReturned;

    /// @notice Event emitted when SOM address is changed
    event newSOM(address SOM);

    /// @notice Event emitted when chainlink verified random number arrived.
    event randomNumberArrived(
        bool arrived,
        uint256 randomNumber,
        bytes32 batchID
    );

    modifier onlySOM() {
        require(SOMAddress == msg.sender, "RNG: Caller is not the SOM address");
        _;
    }

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Chainlink VRF Coordinator address:   0x271682DEB8C4E0901D1a1550aD2e64D568E69909
     * LINK token address:                  0x514910771af9ca656af840dff83e8264ecf986ca
     * Key Hash:                          0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92
     * Fee : 1000000000000000000 LINK
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    )
        VRFConsumerBase(
            _vrfCoordinator,
            _link
        )
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    /**
     * @dev Public function to request randomness and returns request Id. This function can be called by only apporved games.
     */
    function requestRandomNumber() public returns (bytes32 requestID) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "RandomNumberConsumer: Not enough LINK - fill contract with faucet"
        );

        uint256 prevRandomNumber = requestToRandom[currentRequestID];

        emit randomNumberArrived(false, prevRandomNumber, currentRequestID);

        currentRequestID = requestRandomness(keyHash, fee);
        hasReturned[currentRequestID] = false;

        return currentRequestID;
    }

    /**
     * @dev Callback function used by VRF Coordinator. This function sets new random number with unique request Id.
     * @param _randomness Random Number
     */
    function fulfillRandomness(bytes32 requestID, uint256 _randomness)
        internal
        override
    {
        requestToRandom[requestID] = _randomness;
        hasReturned[requestID] = true;
        CowardGambit(CowardAddress).numbersDrawn(
            _randomness
        );
        emit randomNumberArrived(true, _randomness, requestID);
    }

    /**
     * @dev Public function to return verified random number. This function can be called by only SOM.
     * @param _reqeustId Batching Id of random number.
     */
    function getVerifiedRandomNumber(bytes32 _reqeustId)
        public
        view
        onlySOM
        returns (uint256)
    {
        require(
            hasReturned[_reqeustId] == true,
            "RandomGenerator: Random number is not arrived yet"
        );
        return requestToRandom[_reqeustId];
    }

    /**
     * @dev Public function to set SOM address. This function can be called by only owner.
     * @param _SOMAddr Address of SOM
     */
    function setSOMAddress(address _SOMAddr) public onlyOwner {
        require(
            _SOMAddr.isContract() == true,
            "RandomGenerator: This is not a Contract Address"
        );
        SOMAddress = _SOMAddr;
    }

    function setCowardAddress(address _address) public onlyOwner {
        require(
            _address.isContract() == true,
            "RandomGenerator: This is not a Contract Address"
        );
        CowardAddress = _address;
    }
}