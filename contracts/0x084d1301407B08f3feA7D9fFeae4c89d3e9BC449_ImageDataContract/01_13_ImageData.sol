// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "hardhat/console.sol";
//access control
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract ImageDataContract is AccessControl, Ownable{
    //defining the access roles
    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");

    //events
    event NavImagesUpdated(string newIpfs, string newCdn);
    event PionImagesUpdated(string newIpfs, string newCdn);
    event LegImagesUpdated(string newIpfs, string newCdn);
    event AnimationsUpdated(string animationUrl);

    //elements 
    string[] elements = ["Fire", "Water", "Air", "Space", "Pixel", "Earth"];
    
    //Image Maps 
    mapping(string=>string) _navIPFSImages;
    mapping(string=>string) _navCDNImages;
    mapping(string=>string) _navAnnimation;
    mapping(string=>string) _pionIPFSImages;
    mapping(string=>string) _pionCDNImages;
    mapping(string=>string) _legIPFSImages;
    mapping(string=>string) _legCDNImages;
    

    constructor(string[] memory navIpfs, string[] memory navCdn, address admin) {
        require(navIpfs.length == elements.length, "not enough images");
        for(uint i;i<elements.length;i++){
            _navIPFSImages[elements[i]] = navIpfs[i];
            _navCDNImages[elements[i]] = navCdn[i];
        }
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(UPDATER_ROLE, msg.sender);
        //mg = MetropolisWorldGenesis(_t);
    }

    //nav is navigator
    //pion is pioneer
    //leg is legend 

    function setNavImages(string[] calldata image, string[] calldata cdnImage)
        external
        onlyRole(UPDATER_ROLE)
    {
        require(image.length > 0, "Must pass some images??");
        require(image.length == elements.length, "not enough images");
        require(image.length == cdnImage.length, "not enough images.");
        //set the images which will be used for future mints
        for(uint i; i<elements.length;i++){
            _navIPFSImages[elements[i]] = image[i];
            _navCDNImages[elements[i]] = cdnImage[i];
        }
        emit NavImagesUpdated(image[0], cdnImage[0]);
    }

    function setPioneerImages(string[] calldata ipfs, string[] calldata cdn)
        external
        onlyRole(UPDATER_ROLE)
    {
        require(ipfs.length > 0, "Must pass some images??");
        require(ipfs.length == elements.length, "not enough images.");
        require(ipfs.length == cdn.length, "not enough images.");
        for(uint i; i<elements.length; i++){
            //set the images for the pioneer rank.
            _pionIPFSImages[elements[i]] = ipfs[i];
            _pionCDNImages[elements[i]] = cdn[i];
        }
        emit PionImagesUpdated(ipfs[0], cdn[0]);
    }

    function setLegendImages(string[] calldata ipfs, string[] calldata cdn)
        external
        onlyRole(UPDATER_ROLE)
    {
        //set the images for the legend rank.
        require(ipfs.length > 0, "Must pass some images??");
        require(ipfs.length == elements.length, "not enough images.");
        require(ipfs.length == cdn.length, "not enough images.");
        for(uint i; i<elements.length; i++){
            _legIPFSImages[elements[i]] = ipfs[i];
            _legCDNImages[elements[i]] = cdn[i];
        }
        emit LegImagesUpdated(ipfs[0], cdn[0]);
    }

    function setAnnimations(string[] calldata animations)
        external
        onlyRole(UPDATER_ROLE)
    {
        //set the images for the legend rank.
        require(animations.length == elements.length, "not enough images.");
        for(uint i; i<elements.length; i++){
            _navAnnimation[elements[i]] = animations[i];
        }
        emit AnimationsUpdated(animations[0]);
    }

    function getIPFSImageForElement(string calldata element, uint16 level)external view returns(string memory){
        if (level==1){
            return _navIPFSImages[element];
        }else if (level==2){
            return _pionIPFSImages[element];
        }else{
            return _legIPFSImages[element];
        }
    }
    function getCDNImageForElement(string calldata element, uint16 level)external view returns(string memory){
        if (level==1){
            return _navCDNImages[element];
        }else if (level==2){
            return _pionCDNImages[element];
        }else{
            return _legCDNImages[element];
        }
    }

    function getAnnimationForElement(string calldata element)external view returns(string memory){
            return _navAnnimation[element];
    }

}