pragma solidity 0.8.4;

import "./NiftyBuilderInstance.sol";
import "./ICircumnavigationURI.sol";

contract CircumnavigationOpenEdition is NiftyBuilderInstance {

    ICircumnavigationURI public circumnavigationContract;

    constructor(        
        address niftyRegistryContract,
        address defaultOwner,
        address circumnavigationContractAddress) NiftyBuilderInstance(
            "Circumnavigation Collector Only Open Edition by Dave Pollot", 
            "CIRCUMNAVIGATION OE", 
            2, 
            1, 
            "", 
            "Dave Pollot", 
            niftyRegistryContract, 
            defaultOwner) {
        circumnavigationContract = ICircumnavigationURI(circumnavigationContractAddress);
    }
    
    function tokenURI(uint256 tokenId) external virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return circumnavigationContract.cITokenURI();
    }    
}