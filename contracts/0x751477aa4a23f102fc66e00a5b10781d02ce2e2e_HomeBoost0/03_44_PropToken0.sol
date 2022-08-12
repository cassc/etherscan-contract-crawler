// contracts/Pool0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '../@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '../@openzeppelin/contracts/utils/math/SafeMath.sol';
import '../@openzeppelin/contracts/utils/math/SignedSafeMath.sol';

contract PropToken0 is Initializable, ERC721URIStorageUpgradeable {
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    struct Lien{
        uint256 lienIndex;
        uint256 lienValue;
        uint256[] seniorLienValues;
        uint256 propValue;
        string propAddress;
        uint256 issuedAtTimestamp;
    }

    uint256 lienCount;
    address[] servicerAddresses;
    address[] poolAddresses;
    mapping(uint256 => Lien) lienData;


    /*****************************************************
    *       POOL STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    /** 
    *   @dev Function initialize replaces constructor in upgradable contracts
    *   - Calls the init function of the inherited ERC721 contract
    *   @param name Name of this particular ERC721 token
    *   @param symbol The ticker this token will go by
    */
    function initialize(string memory name, string memory symbol, address _poolAddress, address approvedServicer) public initializer {
        servicerAddresses.push(approvedServicer);
        poolAddresses.push(_poolAddress);
        ERC721Upgradeable.__ERC721_init(name, symbol);

        //set initial vars
        lienCount = 0;
    }

    /*****************************************************
    *                GETTER FUNCTIONS
    ******************************************************/

    /** 
    *   @dev Function isApprovedServicer() is an internal function that checks the array of approved addresses for the given address
    *   @param _address The address to be checked if it is approved
    *   @return isApproved is if the _addess is found in the list of servicerAddresses
    */
    function isApprovedServicer(address _address) internal view returns (bool) {
        bool isApproved = false;
        
        for (uint i = 0; i < servicerAddresses.length; i++) {
            if(_address == servicerAddresses[i]) {
                isApproved = true;
            }
        }

        return isApproved;
    }

    /**
    *   @dev Function get Lien Value 
    *   @param lienId is the ID of the lien being looked up
    *   @return the uint256 max value of the lien (to 6 decimal places)
    **/
    function getLienValue(uint256 lienId) public view returns (uint256) {
        return lienData[lienId].lienValue;
    }

    /** 
    *   @dev Function getPropTokenCount() returns the lien count
    *   @return lienCount uint256
    */
    function getPropTokenCount() public view returns (uint256) {
        return lienCount;
    }

    /**
    *   @dev Function getPoolAddresses() returns the lien count
    *   @return address[] poolAddresses
    */
    function getPoolAddresses() public view returns (address[] memory) {
        return poolAddresses;
    }

    /**
    *   @dev Function getPropTokenData() returns all revelant fields on propToken
    *   @param propTokenID  the uint256 id of token to be looked up
    */
    function getPropTokenData(uint256 propTokenID) public view returns (address, uint256, uint256[] memory, uint256, string memory, uint256, string memory) {
        Lien memory propToken = lienData[propTokenID];
        return(
          ownerOf(propTokenID),
          propToken.lienValue,
          propToken.seniorLienValues,
          propToken.propValue,
          propToken.propAddress,
          propToken.issuedAtTimestamp,
          tokenURI(propTokenID)
        );
    }

    /*****************************************************
    *              MINTING FUNCTION
    ******************************************************/

    function mintPropToken(
        address to,
        uint256 lienValue,
        uint256[] memory seniorLienValues,
        uint256 propValue,
        string memory propAddress,
        string memory propPhotoURI
        ) public {
        //require servicer is calling
        require(isApprovedServicer(msg.sender));

        Lien memory newLien = Lien(lienCount, lienValue, seniorLienValues, propValue, propAddress, block.timestamp);

        _safeMint(to, lienCount);
        _setTokenURI(lienCount, propPhotoURI);

        lienData[lienCount] = newLien;
        lienCount = lienCount + 1;
    }

}