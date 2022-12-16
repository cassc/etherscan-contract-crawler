// contracts/Pool0.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '../@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import "../@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract PropToken2 is Initializable, ERC721URIStorageUpgradeable {
    using StringsUpgradeable for uint256;

    struct Lien{
        uint256 lienIndex;
        uint256 lienValue;
        uint256[] seniorLienValues;
        uint256 propValue;
        string propAddress;
        uint256 issuedAtTimestamp;
    }

    struct LienServicerData{
        address servicerAddress;
        bool releaseRequested;
    }

    uint256 lienCount;
    address[] servicerAddresses;
    address[] poolAddresses;
    mapping(uint256 => Lien) lienData;
    mapping(uint256 => LienServicerData) lienServicerData;


    /*****************************************************
    *       STRUCTURE / UPGRADABILITY FUNCTIONS
    ******************************************************/

    function initServicerData(address servicer, uint256 start, uint256 end) public {
        require(isApprovedServicer(msg.sender));
        require(end <= lienCount);
        for(uint256 lienId=start; lienId < end; lienId++){
            lienServicerData[lienId].servicerAddress = servicer;
        }
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
    *   @dev Function getPoolAddresses() returns the pool addresses
    *   @return address[] poolAddresses
    */
    function getPoolAddresses() public view returns (address[] memory) {
        return poolAddresses;
    }

    /**
    *   @dev Function getPropTokenData() returns all revelant fields on propToken
    *   @param propTokenID  the uint256 id of token to be looked up
    */
    function getPropTokenData(uint256 propTokenID) public view returns (address, uint256, uint256[] memory, uint256, string memory, uint256, string memory, address, bool) {
        Lien storage propToken = lienData[propTokenID];
        LienServicerData storage servicerData = lienServicerData[propTokenID];
        string memory tokenUri = tokenURI(propTokenID);
        return(
          ownerOf(propTokenID),
          propToken.lienValue,
          propToken.seniorLienValues,
          propToken.propValue,
          propToken.propAddress,
          propToken.issuedAtTimestamp,
          tokenUri,
          servicerData.servicerAddress,
          servicerData.releaseRequested
        );
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://homecoin-api.goloansnap.com/api/homes/";
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        // For now, we don't want the behavior of URIStorage that we pick up from the baseclass.
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /*****************************************************
    *              MINTING FUNCTION
    ******************************************************/

    function mintPropToken(
        address to,
        uint256 lienValue,
        uint256[] memory seniorLienValues,
        uint256 propValue,
        string memory propAddress
        ) public {
        //require servicer is calling
        require(isApprovedServicer(msg.sender));

        Lien memory newLien = Lien(lienCount, lienValue, seniorLienValues, propValue, propAddress, block.timestamp);

        _safeMint(to, lienCount);

        lienData[lienCount] = newLien;
        lienServicerData[lienCount].servicerAddress = msg.sender;
        lienCount = lienCount + 1;
    }

    /*****************************************************
    * Lien release functions
    ******************************************************/

    function requestRelease(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId)); // The of the token must request its release

        lienServicerData[tokenId].releaseRequested = true;
        // This contract will hold the token until the lien is released.
        super._transfer(msg.sender, address(this), tokenId);
    }

    function releaseLien(uint256 tokenId) public {
        LienServicerData storage servicerData = lienServicerData[tokenId];
        require(msg.sender == servicerData.servicerAddress); // The servicer of the Lien must be the one actually releasing the lien.
        require(servicerData.releaseRequested == true);// The owner of the lien needs to have requeseted its release
        // Because the token is burnt it will not be possible to borrow more against it.
        _burn(tokenId);
    }

    function getLienReleaseRequested(uint256 tokenId) public view returns (bool){
        return lienServicerData[tokenId].releaseRequested;
    }

    function transferServicer(uint256 tokenId, address newServicer) public {
        require(isApprovedServicer(msg.sender)); // caller must be an approved servicer
        require(isApprovedServicer(newServicer)); // new servicer must be approved as well.
        LienServicerData storage servicerData = lienServicerData[tokenId];
        require(servicerData.servicerAddress == msg.sender); // only the current servicer of this lien can transfer the lien
        servicerData.servicerAddress = newServicer;
    }

}