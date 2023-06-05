pragma solidity 0.8.4;

import "./NiftyBuilderInstance.sol";
import "./ICircumnavigationURI.sol";

contract CircumnavigationCollection is NiftyBuilderInstance {

    ICircumnavigationURI public circumnavigationContract;

    constructor(        
        address niftyRegistryContract,
        address defaultOwner,
        address circumnavigationContractAddress) NiftyBuilderInstance(
            "Circumnavigation by Dave Pollot", 
            "CIRCUMNAVIGATION", 
            1, 
            6, 
            "", 
            "Dave Pollot", 
            niftyRegistryContract, 
            defaultOwner) {
        circumnavigationContract = ICircumnavigationURI(circumnavigationContractAddress);
    }
    
    function tokenURI(uint256 tokenId) external virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 niftyTypeId = _getNiftyTypeId(tokenId);
        require(niftyTypeId > 0 && niftyTypeId <= 6, "Incorrect Nifty Type");

        if(niftyTypeId == 1) {
            return circumnavigationContract.cIOneOfOneTokenURI();            
        } else if(niftyTypeId == 2) {
            return circumnavigationContract.cIIOneOfOneTokenURI();            
        } else if(niftyTypeId == 3) {
            return circumnavigationContract.cIITokenURI();            
        } else if(niftyTypeId == 4) {
            return circumnavigationContract.cIIITokenURI(0);
        } else if(niftyTypeId == 5) {
            return circumnavigationContract.cIIITokenURI(1);
        } else if(niftyTypeId == 6) {
            return circumnavigationContract.cIIITokenURI(2);
        } 

        return "Unable to find URI";
    }    
}