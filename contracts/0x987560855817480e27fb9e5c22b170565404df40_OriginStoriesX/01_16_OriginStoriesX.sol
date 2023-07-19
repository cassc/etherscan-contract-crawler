// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@pixelvault/contracts/PVERC721.sol";

/*
* @author Niftydude
*/
contract OriginStoriesX is PVERC721 {
    uint256 immutable public EDITION_NR;

    mapping(uint256 => address) public osContracts;

    IOS immutable OS1;

    error MustBurnPreviousEdition();
    error SameLengthRequired();
    error SenderNotOwner();

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        uint256 _EDITION_NR,
        address _addressOS1
    ) PVERC721(_name, _symbol, _uri) {
        EDITION_NR = _EDITION_NR;

        OS1 = IOS(_addressOS1);
    }                      

    function mintFromOS1(
        uint256[] calldata tokenIds
    ) external whenNotPaused {
        for(uint256 i; i < tokenIds.length;) {
            if(OS1.ownerOf(tokenIds[i]) != msg.sender) revert SenderNotOwner();

            OS1.burn(tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);  

            unchecked {i++;}    
        } 
    } 

    function mint(
        uint256[] calldata tokenIds,
        uint256 editionToBurn
    ) external whenNotPaused {
        if(editionToBurn >= EDITION_NR) revert MustBurnPreviousEdition();

        for(uint256 i; i < tokenIds.length;) {
            IOS osContract = IOS(osContracts[editionToBurn]);
            if(osContract.ownerOf(tokenIds[i]) != msg.sender) revert SenderNotOwner();

            osContract.burn(tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);  

            unchecked {i++;}    
        } 
    }       

    function mintFromMul(
        uint256[] calldata tokenIds,
        uint256[] calldata editionToBurn
    ) external whenNotPaused {
        if(tokenIds.length != editionToBurn.length) revert SameLengthRequired();

        for(uint256 i; i < tokenIds.length;) {
            IOS osContract = IOS(osContracts[editionToBurn[i]]);
            if(editionToBurn[i] >= EDITION_NR) revert MustBurnPreviousEdition();
            if(osContract.ownerOf(tokenIds[i]) != msg.sender) revert SenderNotOwner();

            osContract.burn(tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);  

            unchecked {i++;}    
        } 
    }  

    function setContract(uint256 editionNr, address contractAddress) external onlyOwner {
        osContracts[editionNr] = contractAddress;
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token. 
     */
    function tokenURI(uint256) public view override returns (string memory) {
        return uri;
    }             
}

interface IOS {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}