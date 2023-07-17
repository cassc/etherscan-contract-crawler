// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../recovery/recovery.sol";
import "../interfaces/IRNG_single_requestor.sol";
import "../interfaces/IRNG_multi_requestor.sol";
import "../interfaces/IRNG2.sol";




// subscription ID on Rinkeby = 634

contract RandomV3 is VRFConsumerBaseV2, Ownable, IRNG2 { 
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // Rinkeby LINK token contract. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  address link;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  //bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  bytes32[] keys;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 2000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  event defaultGasLimitChanged(address admin,uint32 newLimit);
  event defaultConfsChanged(address admin,uint16 newConfs);

  constructor(uint64 subscriptionId, address _vrfCoordinator)  VRFConsumerBaseV2(_vrfCoordinator)  {
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 4) {
            keys = [
              bytes32(0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc)
            ];
            require(_vrfCoordinator == 0x6168499c0cFfCaCD319c818142124B7A15E857ab,"Incorrect VRF Coordinator for Rinkeby");
            link           = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

        } else if (id == 1) {
            link           = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
            require(_vrfCoordinator == 0x271682DEB8C4E0901D1a1550aD2e64D568E69909,"Incorrect VRF Coordinator for MAINNET");
            keys           = [
                bytes32(0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef),
                bytes32(0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92),
                bytes32(0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805)
            ];

        } else {
            require(false,"Invalid Chain");
        }
    
   
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link);

    s_subscriptionId = subscriptionId;
  }

  function fulfillRandomWords(
    uint256 requestId, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    multiword_responses[requestId] = randomWords;
    responded[requestId] = true;
    if (callbacks[requestId]!= address(0)) {
        IRNG_single_requestor(callbacks[requestId]).process(randomWords[0], requestId);
    }
    if (multiword_callbacks[requestId]!= address(0)) {
        IRNG_multi_requestor(multiword_callbacks[requestId]).multi_process(randomWords, requestId); 
    }
    emit RandomsReceived(requestId, randomWords);
  }

  // Assumes the subscription is funded sufficiently.
  function requestRandomWords(uint32 numberOfWords, uint speed) external override onlyAuth  returns (uint256) {
    // Will revert if subscription is not set and funded.
    return _requestRandomWords(numberOfWords, speed,callbackGasLimit, requestConfirmations);
  }

  function requestRandomWordsAdvanced(uint32 numberOfWords, uint speed , uint32 _callbackGasLimit, uint16 _requestConfirmations) external override onlyAuth  returns (uint256) {
    // Will revert if subscription is not set and funded.
    return _requestRandomWords(numberOfWords, speed,_callbackGasLimit, _requestConfirmations);
  }

  function requestRandomWordsWithCallback(uint32 numberOfWords, uint speed) external onlyAuth override returns (uint256) {
    // Will revert if subscription is not set and funded.
    return _requestRandomWordsAdvancedWithCallback(numberOfWords, speed,callbackGasLimit, requestConfirmations);
  }
  
  function requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyAuth override returns (uint256) {
    return _requestRandomWordsAdvancedWithCallback(numberOfWords, speed,_callbackGasLimit, _requestConfirmations);
  }


  function _requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) internal returns (uint256) {
    uint256 requestID =  _requestRandomWords(numberOfWords, speed,_callbackGasLimit, _requestConfirmations);
    multiword_callbacks[requestID] = msg.sender;
    emit MultiWordRequest(msg.sender,numberOfWords,speed,requestID);
    return requestID;
  }


  function _requestRandomWords(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) internal returns (uint256){
    require(speed < keys.length,"Invalid speed");
    bytes32 keyHash = keys[speed];
    uint256 reply = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      _requestConfirmations,
      _callbackGasLimit,
      numberOfWords
    );
    requestIDs.push(reply);
    return reply;
  }


  // from original random

    //mapping(bytes32=>uint256)   public responses;
    mapping(uint256=>uint256[]) public multiword_responses;
    mapping(uint256=>bool)      public responded;
    mapping(uint256=>address)   public callbacks;
    mapping(uint256=>address)   public multiword_callbacks;
    uint256[]                   public requestIDs; 

  
    event Request(address requestor, uint256 RequestID);
    event MultiWordRequest(address requestor,uint256 numberOfWords,uint256 speed,uint256 requestID);
    event RandomsReceived(uint256 requestId, uint256[] randomNumbers);
    event AuthChanged(address user,bool auth);
    event AdminChanged(address user,bool auth);


    mapping(address => bool)    public authorised;
    mapping(address => bool)    public admins;

    modifier onlyAuth {
        require(authorised[msg.sender],"Not Authorised");
        _;
    }
    modifier onlyAdmins {
        require(admins[msg.sender] || msg.sender == owner(),"Not an admin.");
        _;
    }

    function setAuth(address user, bool auth) public override onlyAdmins {
        authorised[user] = auth;
        emit AuthChanged(user,auth);
    }

    function setAdmin(address user, bool auth) public onlyAdmins {
        admins[user] = auth;
        emit AdminChanged(user,auth);
    }



    function requestRandomNumber( ) public onlyAuth override returns (uint256) {
       uint256 requestId = _requestRandomWords(1, 0, callbackGasLimit, requestConfirmations);
       emit Request(msg.sender, requestId);
       return (requestId);
    }

    function requestRandomNumberWithCallback( ) public onlyAuth override returns (uint256) {
       uint256 requestId = _requestRandomWords(1, 0, callbackGasLimit, requestConfirmations);
       callbacks[requestId] = msg.sender;
       emit Request(msg.sender, requestId);
       return requestId;
    }

    function isRequestComplete(uint256 requestId) external view override returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(uint256 requestId) external view override returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return multiword_responses[requestId][0];
    }

    function setGasLimit(uint32 newLimit) external onlyAdmins {
      callbackGasLimit = newLimit;
      emit defaultGasLimitChanged(msg.sender,newLimit);
    }
    function setRequestConfirmations(uint16 newConfs) external onlyAdmins {
      requestConfirmations = newConfs;
      emit defaultConfsChanged(msg.sender,newConfs);
    }
 
}