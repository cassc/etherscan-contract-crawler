// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.1;

import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

interface WLinf{
    function addWLSpot(uint passportId, string calldata city, string calldata buildingName, uint32 buildingTokenId)external;
}
interface WinChance{
    function updateAfterWin(uint passportId, string calldata city, uint32 buildingId)external;
}

contract PropertyDraw is AccessControl{
  address private WL_CONTRACT;
    WLinf WLCont;
    address WIN_CHANCE_CONTRACT;
    WinChance WinCont;
  //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

  mapping(string=>mapping(uint32=>bool)) _drawsDone;
  mapping(string=>mapping(uint32=>uint)) _winners;
  mapping(string=>mapping(uint32=>string)) _offChainRecordings;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(UPDATER_ROLE, msg.sender);
    _setupRole(CONTRACT_ROLE, msg.sender);
  }

  function addTheRolesForContractCalls(address winContract, address wlContract)public onlyRole(UPDATER_ROLE){
        require(winContract != address(0));
        require(wlContract != address(0));
        _grantRole(CONTRACT_ROLE, winContract);
        _grantRole(CONTRACT_ROLE, wlContract);
    }

  function setPartnerContracts(address wl, address win)public onlyRole(UPDATER_ROLE){
    require(wl != address(0));
    require(win != address(0));
      WL_CONTRACT = wl;
      WLCont = WLinf(WL_CONTRACT);
      WIN_CHANCE_CONTRACT = win;
      WinCont = WinChance(WIN_CHANCE_CONTRACT);
  }

  /**
  *@dev we use this to run a lottery off chain and record the winner. We save a recording of the draw on IPFS
   */
  function recordOffChainWinner(string calldata city, uint32 buildingId, string calldata buildingName, uint winnerId, string calldata recording)external onlyRole(UPDATER_ROLE){
    //add to mapping 
    _drawsDone[city][buildingId] = true;
    _winners[city][buildingId] = winnerId;
    _offChainRecordings[city][buildingId] = recording; 
    //add the wl to the passport 
    WLCont.addWLSpot(winnerId, city, buildingName, buildingId);
    //decrease win chances for winner 
    WinCont.updateAfterWin(winnerId, city, buildingId);
    //loosers claim thier own increases 
  }
 
  function viewDrawRecording(string calldata city, uint32 buildingId)external view returns(string memory){
    return _offChainRecordings[city][buildingId];
  }

  function verifyDraw(string calldata city, uint32 buildingId)external view returns(bool){
      //returns true or false if a draw for particular property has been done. 
      bool done = _drawsDone[city][buildingId];
      return done;
  }

  function verifyWinner(string calldata city, uint32 buildingId, uint passportId)external view returns(bool){
      if(_winners[city][buildingId] != passportId){
          return false;
      }else{
          return true;
      }
  }

}

 // function random(uint number) internal view returns(uint){
  //       return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
  //       msg.sender))) % number;
  // }

  // function pickPropertyWinner(string calldata city, uint32 buildingId, string calldata buildingName, uint[] calldata passportIds)external onlyRole(UPDATER_ROLE) returns(uint){
  //   require(_drawsDone[city][buildingId]!= true, "Already drawn this property");
  //   uint rand = random(passportIds.length);
  //   uint winner = passportIds[rand];
  //   //add to mapping 
  //   _drawsDone[city][buildingId] = true;
  //   _winners[city][buildingId] = winner;
  //   //add the wl to the passport 
  //   WLCont.addWLSpot(winner, city, buildingName, buildingId);
  //   //decrease win chances for winner 
  //   WinCont.updateAfterWin(winner, city, buildingId);
  //   //loosers claim thier own increases 
  //   return winner;
  // }

// contract PropertyDraw is VRFConsumerBaseV2, AccessControl {
//     address private WL_CONTRACT;
//     WLinf WLCont;
//     address WIN_CHANCE_CONTRACT;
//     WinChance WinCont;
//     //defining the access roles
//     bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
//     bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
//   VRFCoordinatorV2Interface COORDINATOR;

//   // Your subscription ID.
//   uint64 s_subscriptionId;

//   // Rinkeby coordinator. For other networks,
//   // see https://docs.chain.link/docs/vrf-contracts/#configurations
//   address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

//   // The gas lane to use, which specifies the maximum gas price to bump to.
//   // For a list of available gas lanes on each network,
//   // see https://docs.chain.link/docs/vrf-contracts/#configurations
//   bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

//   // Depends on the number of requested values that you want sent to the
//   // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
//   // so 100,000 is a safe default for this example contract. Test and adjust
//   // this limit based on the network that you select, the size of the request,
//   // and the processing of the callback request in the fulfillRandomWords()
//   // function.
//   uint32 callbackGasLimit = 100000;

//   // The default is 3, but you can set this higher.
//   uint16 requestConfirmations = 3;

//   // For this example, retrieve 2 random values in one request.
//   // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
//   uint32 numWords =  1;

//   uint256[] public s_randomWords;
//   uint256 public s_randomRange;
//   uint256 public s_requestId;
//   address s_owner;
//   uint256 private _start;
//   uint256 private _end;
  
//   mapping(string=>mapping(uint32=>bool)) _drawsDone;
//   mapping(string=>mapping(uint32=>uint)) _winners;

//   constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
//     COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
//     s_owner = msg.sender;
//     s_subscriptionId = subscriptionId;
//     _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//     _setupRole(UPDATER_ROLE, msg.sender);
//     _setupRole(CONTRACT_ROLE, msg.sender);
//   }
//   function addTheRolesForContractCalls(address winContract, address wlContract)public onlyRole(UPDATER_ROLE){
//         grantRole(CONTRACT_ROLE, winContract);
//         grantRole(CONTRACT_ROLE, wlContract);
//     }

//   function setPartnerContracts(address wl, address win)public onlyRole(UPDATER_ROLE){
//       WL_CONTRACT = wl;
//       WLCont = WLinf(WL_CONTRACT);
//       WIN_CHANCE_CONTRACT = win;
//       WinCont = WinChance(WIN_CHANCE_CONTRACT);
//   }

//   // Assumes the subscription is funded sufficiently.
//   function requestRandomWords() internal {
//     // Will revert if subscription is not set and funded.
//     s_requestId = COORDINATOR.requestRandomWords(
//       keyHash,
//       s_subscriptionId,
//       requestConfirmations,
//       callbackGasLimit,
//       numWords
//     );
//   }
  
//   function fulfillRandomWords(
//     uint256, /* requestId */
//     uint256[] memory randomWords
//   ) internal override {
//     uint256 plus = 1;
//     s_randomRange = (randomWords[0] % _end) + plus;
//   }

//   function pickPropertyWinner(string calldata city, uint32 buildingId, string calldata buildingName, uint[] calldata passportIds)external onlyRole(UPDATER_ROLE) returns(uint){
//     require(_drawsDone[city][buildingId]!= true, "Already drawn this property");
//       //chooses a winner for the property lottery. 
//     //set end of range to list.
//     _end = passportIds.length;
//     //get random number 
//     requestRandomWords();
//     uint winner = passportIds[s_randomRange];
//     //add the wl to the passport 
//     WLCont.addWLSpot(winner, city, buildingName, buildingId);
//     //decrease win chances for winner 
//     WinCont.updateAfterWin(winner, city, buildingId);
//     //loosers claim thier own increases 
//     //add to mapping 
//     _drawsDone[city][buildingId] = true;
//     _winners[city][buildingId] = winner;
//     return winner;
//   }

//     function verifyDraw(string calldata city, uint32 buildingId)external view returns(bool){
//         //returns true or false if a draw for particular property has been done. 
//         return _drawsDone[city][buildingId];
//     }

//     function verifyWinner(string calldata city, uint32 buildingId, uint passportId)external view returns(bool){
//         if(_winners[city][buildingId] != passportId){
//             return false;
//         }else{
//             return true;
//         }
//     }

// //   modifier onlyOwner() {
// //     require(msg.sender == s_owner);
// //     _;
// //   }
// }

// contract MockRandomDraw is AccessControl {
//     address private WL_CONTRACT;
//     WLinf WLCont;
//     address WIN_CHANCE_CONTRACT;
//     WinChance WinCont;
//     //defining the access roles
//     bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
//     bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

//     uint256[] public s_randomWords;
//     uint256 public s_randomRange;
//     uint256 public s_requestId;
//     address s_owner;
//     uint256 private _start;
//     uint256 private _end;
    
//     mapping(string=>mapping(uint32=>bool)) _drawsDone;
//     mapping(string=>mapping(uint32=>uint)) _winners;

//     constructor() {
//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _setupRole(UPDATER_ROLE, msg.sender);
//         _setupRole(CONTRACT_ROLE, msg.sender);
//     }
//     function setPartnerContracts(address wl, address win)public onlyRole(UPDATER_ROLE){
//       WL_CONTRACT = wl;
//       WLCont = WLinf(WL_CONTRACT);
//       WIN_CHANCE_CONTRACT = win;
//       WinCont = WinChance(WIN_CHANCE_CONTRACT);
//     }
//   function addTheRolesForContractCalls(address winContract, address wlContract)public onlyRole(UPDATER_ROLE){
//         grantRole(CONTRACT_ROLE, winContract);
//         grantRole(CONTRACT_ROLE, wlContract);
//     }

//     function pickPropertyWinner(string calldata city, uint32 buildingId, string calldata buildingName, uint[] calldata passportIds)external onlyRole(UPDATER_ROLE) returns(uint){
//         require(_drawsDone[city][buildingId]!= true, "Already drawn this property");
//         //chooses a winner for the property lottery. 
//         //set end of range to list.
//         _end = passportIds.length;
//         //get random number 
//         s_randomRange = 1;
//         uint winner = passportIds[s_randomRange];
//         //add to mapping 
//         _drawsDone[city][buildingId] = true;
//         _winners[city][buildingId] = winner;
//         //add the wl to the passport 
//         WLCont.addWLSpot(winner, city, buildingName, buildingId);
//         //decrease win chances for winner 
//         WinCont.updateAfterWin(winner, city, buildingId);
//         //loosers claim thier own increases 
        
//         return winner;
//   }

//     function verifyDraw(string calldata city, uint32 buildingId)external view returns(bool){
//         //returns true or false if a draw for particular property has been done. 
//         bool done = _drawsDone[city][buildingId];
//         return done;
//     }

//     function verifyWinner(string calldata city, uint32 buildingId, uint passportId)external view returns(bool){
//         if(_winners[city][buildingId] != passportId){
//             return false;
//         }else{
//             return true;
//         }
//     }
// }