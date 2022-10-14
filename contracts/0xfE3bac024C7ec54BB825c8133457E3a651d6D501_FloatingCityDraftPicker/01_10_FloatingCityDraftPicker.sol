// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import './FloatingCityVRFHandler.sol';
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IFloatingCity {
    function unAllocatedTokens(uint256 i) external returns (uint256);
    function getUnAllocatedTokensLength() external returns (uint256);
}

/*


   ▄████████  ▄█        ▄██████▄     ▄████████     ███      ▄█  ███▄▄▄▄      ▄██████▄        ▄████████  ▄█      ███     ▄██   ▄       
  ███    ███ ███       ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄   ███    ███      ███    ███ ███  ▀█████████▄ ███   ██▄     
  ███    █▀  ███       ███    ███   ███    ███    ▀███▀▀██ ███▌ ███   ███   ███    █▀       ███    █▀  ███▌    ▀███▀▀██ ███▄▄▄███     
 ▄███▄▄▄     ███       ███    ███   ███    ███     ███   ▀ ███▌ ███   ███  ▄███             ███        ███▌     ███   ▀ ▀▀▀▀▀▀███     
▀▀███▀▀▀     ███       ███    ███ ▀███████████     ███     ███▌ ███   ███ ▀▀███ ████▄       ███        ███▌     ███     ▄██   ███     
  ███        ███       ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    █▄  ███      ███     ███   ███     
  ███        ███▌    ▄ ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    ███ ███      ███     ███   ███     
  ███        █████▄▄██  ▀██████▀    ███    █▀     ▄████▀   █▀    ▀█   █▀    ████████▀       ████████▀  █▀      ▄████▀    ▀█████▀      
             ▀                                                                                                                        
████████▄     ▄████████    ▄████████    ▄████████     ███             ▄███████▄  ▄█   ▄████████    ▄█   ▄█▄    ▄████████    ▄████████ 
███   ▀███   ███    ███   ███    ███   ███    ███ ▀█████████▄        ███    ███ ███  ███    ███   ███ ▄███▀   ███    ███   ███    ███ 
███    ███   ███    ███   ███    ███   ███    █▀     ▀███▀▀██        ███    ███ ███▌ ███    █▀    ███▐██▀     ███    █▀    ███    ███ 
███    ███  ▄███▄▄▄▄██▀   ███    ███  ▄███▄▄▄         ███   ▀        ███    ███ ███▌ ███         ▄█████▀     ▄███▄▄▄      ▄███▄▄▄▄██▀ 
███    ███ ▀▀███▀▀▀▀▀   ▀███████████ ▀▀███▀▀▀         ███          ▀█████████▀  ███▌ ███        ▀▀█████▄    ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   
███    ███ ▀███████████   ███    ███   ███            ███            ███        ███  ███    █▄    ███▐██▄     ███    █▄  ▀███████████ 
███   ▄███   ███    ███   ███    ███   ███            ███            ███        ███  ███    ███   ███ ▀███▄   ███    ███   ███    ███ 
████████▀    ███    ███   ███    █▀    ███           ▄████▀         ▄████▀      █▀   ████████▀    ███   ▀█▀   ██████████   ███    ███ 
             ███    ███                                                                           ▀                        ███    ███ 


*/
contract FloatingCityDraftPicker is FloatingCityVRFHandler {
    IFloatingCity public floatingCityContract;
    bool public latestRoundPicked = true;
    mapping(uint256 => uint256[]) public draftRoundPicks;
    uint256 public draftRound;

    constructor(uint64 _subscriptionId, address _vrfCoordinator, bytes32 _keyHash, IFloatingCity _floatingCityContract)
       FloatingCityVRFHandler(_subscriptionId, _vrfCoordinator, _keyHash)
    {
        floatingCityContract = _floatingCityContract;
    }

    function isLatestRoundReady() public view returns(bool) {
        return s_requests[lastRequestId].fulfilled;
    }

    function getDraftRoundPicks(uint256 round) public view returns(string[10] memory) {
        string[10] memory draftRoundPick;

        for(uint256 i = 0; i < 10; i++) {
            draftRoundPick[i] = Strings.toString(draftRoundPicks[round][i]);
        }

        return draftRoundPick;
    }


    function getLatestPicks() public view returns(string[10] memory) {
        return getDraftRoundPicks(draftRound);
    }


    // == ONLY OWNER FUNCTIONS ==

    function startNextRound() public onlyOwner{
        if(!latestRoundPicked) revert RoundInProgress();
        if(floatingCityContract.getUnAllocatedTokensLength() <= 10) revert NotEnoughTokensForDraft();

        requestRandomWords();
        latestRoundPicked = false;
        draftRound++;
    }

    function applyLatestPicks() public onlyOwner {
        if(!isLatestRoundReady()) revert VRFHasNotReturnedYet();
        if(latestRoundPicked) revert RoundAlreadyComplete();
        uint256[] memory randomNumbers = s_requests[lastRequestId].randomWords;
        
        latestRoundPicked = true;
        uint256 unallocatedTokensLength = floatingCityContract.getUnAllocatedTokensLength();
        for(uint i = 0; i < randomNumbers.length; i++) {
            uint256 randomIndex = randomNumbers[i];
            if(randomNumbers[i] >= unallocatedTokensLength){
                randomIndex = randomNumbers[i] % unallocatedTokensLength;
            }
            draftRoundPicks[draftRound].push(floatingCityContract.unAllocatedTokens(randomIndex));
        }
    }

    function setCallbackGasLimit(uint32 _limit) public onlyOwner {
        callbackGasLimit = _limit;
    }

    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function setFloatingCityContract(address _address) public onlyOwner {
        floatingCityContract = IFloatingCity(_address);
    }

    /* THIS IS ONLY CALLED IN THE EVENT CHAINLINK CALL FAILS */
    function restartNextRound() public onlyOwner{
        if(floatingCityContract.getUnAllocatedTokensLength() <= 10) revert NotEnoughTokensForDraft();

        requestRandomWords();
        latestRoundPicked = false;
    }


}

error VRFHasNotReturnedYet();
error RoundAlreadyComplete();
error RoundInProgress();
error LatestPicksNotAppliedYet();
error NotEnoughTokensForDraft();