// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface PassportInter{
    function attachWLSpot(uint wlId, uint passportId)external;
    function getWLSpots(uint passportId)external view returns(uint[] memory);
    function detachCityWLSpot(uint passportId, uint index)external;
}

contract CityWL is AccessControl{
    //other contracts we interact with 
    address private MAIN_PASSPORT_CONTRACT;
    PassportInter PassContract;
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
    //counter for IDS 
    using Counters for Counters.Counter;
    Counters.Counter private _wlIds;
    //events 
    event WLSpotAdded(uint256 tokenId, WLSpot spot);
    event WLSpotRemoved(
        uint256 tokenId,
        string city,
        uint32 buildignId
    );
    //data models 
    struct WLSpot {
        string city;
        uint32 buildingId;
        string buildingName;
    }

    //maps wlid to wl struct
    mapping(uint256 => WLSpot) wlspots;
    //list of Avatar options
    //string[] _avatars =["citizens","nomads"];

    constructor(address pasContractAd){
        require(pasContractAd != address(0));
        MAIN_PASSPORT_CONTRACT = pasContractAd;
        PassContract = PassportInter(MAIN_PASSPORT_CONTRACT);
        //to avoid the defualt value of 0
        _wlIds.increment();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(UPDATER_ROLE, msg.sender);
        _setupRole(CONTRACT_ROLE, msg.sender);
    }
    
    function addTheRolesForContractCalls(address winContract, address lotContract, address passContract)external onlyRole(UPDATER_ROLE){
        require(winContract != address(0));
        require(lotContract != address(0));
        _grantRole(CONTRACT_ROLE, winContract);
        _grantRole(CONTRACT_ROLE, lotContract);
        _grantRole(CONTRACT_ROLE, passContract);
    }

    /**
    @dev special to set the city contract role. 
    */
    function addCityContractRole(address cityContractAddress)external onlyRole(UPDATER_ROLE){
        _grantRole(CONTRACT_ROLE, cityContractAddress);
    }

    //cities WL spots. 
    // the floowoing functions refer to adding and remove WL spots to the passport 
    // these WL spots alow the owner of the passport to mint a specific property inside one of our cities 
    // There will be a number cites and WL spots are added and removed as required.  
    function addWLSpot(uint passportId, string calldata city, string calldata buildingName, uint32 buildingTokenId)external onlyRole(CONTRACT_ROLE){
        uint wlID = _wlIds.current();
        wlspots[wlID] = WLSpot({
            city: city,
            buildingName: buildingName,
            buildingId: buildingTokenId
        });
        PassContract.attachWLSpot(wlID, passportId);
        emit WLSpotAdded(passportId, wlspots[wlID]);
    }

    /**
    @dev called by the cities contract when the user mints thier property therefors using the WL spot. 

     */
    function removeCityWlSpot(uint passportId, string calldata city, uint32 buildingId)external onlyRole(CONTRACT_ROLE){
        //called once a user mints thier property and has therefore used thier WL spot. 
        uint index = _findWlSpot(passportId, city, buildingId);
        PassContract.detachCityWLSpot(passportId, index);
        emit WLSpotRemoved(passportId, city, buildingId);
    } 

    function _findWlSpot(uint passportId, string calldata city, uint32 buildingId)internal view returns(uint){
        // get list of wl spots fromm users passport 
        uint[] memory wlSp = PassContract.getWLSpots(passportId);
        //loop though the spots to check it they have the correct one 
        for (uint256 i; i < wlSp.length; i++) {
            WLSpot memory dropX = wlspots[wlSp[i]];
            if (
                keccak256(bytes(dropX.city)) == keccak256(bytes(city)) &&
                dropX.buildingId == buildingId
            ) {
                //return the index of the correct wl spot 
                return i;
            }
        }
        //return and index outside the range to indicate no match. 
        return wlSp.length;
    }

    function checkPassportHasWLSpot(uint passportId, string calldata city, uint32 buildingId)external view returns(bool){
        // get list of wl spots fromm users passport 
        uint[] memory wlSp = PassContract.getWLSpots(passportId);
        //called by the city NFT drop when user tries to mint. 
        uint index = _findWlSpot(passportId, city, buildingId);
        if (index==wlSp.length){
            return false;
        }else{
            return true;
        }
    }

    function wlSpotsList(uint passportId)external view returns(bytes memory){
        uint[] memory wlSp = PassContract.getWLSpots(passportId);
        bytes memory ls = '"},{ "trait_type": "City WL Names", "value": "';
        for(uint i; i<wlSp.length;i++){
            ls = abi.encodePacked(ls, wlspots[wlSp[i]].buildingName, " ");
        }
        return ls;
    }
}