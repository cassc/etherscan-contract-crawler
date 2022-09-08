// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface DrawContInf{
    function verifyDraw(string calldata city, uint32 buildingId)external view returns(bool);
    function verifyWinner(string calldata city, uint32 buildingId, uint passportId)external view returns(bool);
}
interface PassContInf {
    function increaseWinChance(uint passportId, uint16 inc)external;
    function decreaseWinChance(uint passportId, uint16 dec)external;
}

contract WinChances is AccessControl {
    address private PROPERTY_DRAW_CONTRACT;
    DrawContInf DrawContract;
    address private PASSPORT_CONTRACT;
    PassContInf PassCont;
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");

    //events 
    event LoseIncreaseUpdated(uint16 increase);
    event ReferallIncrementUpdated(uint16 increase);
    event WinDecreaseUpdated(uint16 change);

    uint16 private _citiesDropped;
    mapping(uint=>uint16) _increasesClaimed; //record each time a passport claims increase, to avoid cheating
    mapping(string=>bool) _cityWinChancesStillClaimable;

    uint16 public _winDecrease = 1;
    uint16 public _loseIncrease = 1;
    uint16 public _referralIncrements = 2;

    constructor(address passport, address draw){
        require(passport != address(0));
        require(draw != address(0));
        PROPERTY_DRAW_CONTRACT = draw;
        DrawContract = DrawContInf(PROPERTY_DRAW_CONTRACT);
        PASSPORT_CONTRACT = passport;
        PassCont = PassContInf(PASSPORT_CONTRACT);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
        _setupRole(CONTRACT_ROLE, msg.sender);
    }

    function addTheRolesForContractCalls(address wlContract, address lotContract, address passContract)external onlyRole(UPDATER_ROLE){
        _grantRole(CONTRACT_ROLE, wlContract);
        _grantRole(CONTRACT_ROLE, lotContract);
        _grantRole(CONTRACT_ROLE, passContract);
    }

    function updateAfterLoss(uint passportId, string calldata city, uint32 buildingId)external onlyRole(CONTRACT_ROLE){
        //called by user to update thier win chances after they loose
        require(_cityWinChancesStillClaimable[city], "city closed for redemption of lossing win chance");
        require(DrawContract.verifyDraw(city, buildingId));
        require(DrawContract.verifyWinner(city, buildingId, passportId)==false,"You were a winner so you don't get more chances");
        require(_increasesClaimed[passportId] < _citiesDropped, "Already claimed you increase");
        PassCont.increaseWinChance(passportId, _loseIncrease);
        _increasesClaimed[passportId] += 1;
    }

    function updateAfterWin(uint passportId, string calldata city, uint32 buildingId)external onlyRole(CONTRACT_ROLE){
        //called by the draw function when a passport wins. 
        require(DrawContract.verifyDraw(city, buildingId),"Draw not taken place");
        require(DrawContract.verifyWinner(city, buildingId, passportId),"You were not a winner");
        //seting this to true so lossers can claim thier increase.  
        _cityWinChancesStillClaimable[city] = true;
        PassCont.decreaseWinChance(passportId, _winDecrease);
        _increasesClaimed[passportId] += 1;
    }

    function getReferalIncrease()external view returns(uint16){
        return _referralIncrements;
    }

    //set values
    function setLossIncrease(uint16 increase) external onlyRole(UPDATER_ROLE) {
        //set the amount you increase win chances by when you loose
        _loseIncrease = increase;
        emit LoseIncreaseUpdated(increase);
    }

    function setReferralIncrement(uint16 incr) external onlyRole(UPDATER_ROLE) {
        //set the amount a referal increases the win chances
        _referralIncrements = incr;
        emit ReferallIncrementUpdated(incr);
    }

    function setWinDecrease(uint16 decr) external onlyRole(UPDATER_ROLE) {
        // set the amount be which win chances are reduced after a win.
        _winDecrease = decr;
        emit WinDecreaseUpdated(decr);
    }

    function cityDrawsFinished()external onlyRole(UPDATER_ROLE){
        _citiesDropped ++;
    }

    function getCitiesDropped()external view returns(uint16){
        return _citiesDropped;
    }

    /**
     *@dev this function permantly closes a city for claiming the win chance increase after a loss. 
     *@notice it cannot be undone, so should be used with caution. Only callable by walllets with UPDATER_ROLE
     */
    function closeCityForWinLossRedemption(string calldata city)external onlyRole(UPDATER_ROLE){
        _cityWinChancesStillClaimable[city] = false;
    }

}