// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

/*
* @author Niftydude
*/
contract OriginStoriesX is ERC721Enumerable, Ownable {
    uint256 immutable public EDITION_NR;

    mapping(uint256 => address) public osContracts;
    mapping(address => bool) public allowedBurners;

    bool allowedBurnersFinalized;

    uint128 windowOpen;
    uint128 windowClose;

    string uri;

    error MustBurnPreviousEdition();
    error SameLengthRequired();
    error SenderNotOwner();
    error BurnerNotAllowed();
    error WindowClosed();
    error BurnersFinalized();

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri,
        uint256 _EDITION_NR,
        uint128 _windowOpen,
        uint128 _windowClose, 
        address[] memory _osContracts
    ) ERC721(_name, _symbol) {
        EDITION_NR = _EDITION_NR;

        uri = _uri;

        windowOpen = _windowOpen;
        windowClose = _windowClose;

        for(uint256 i=1; i<=_osContracts.length; i++) {
            osContracts[i] = _osContracts[i-1];
        }
    }                      

    function mint(
        uint256[] calldata tokenIds,
        uint256 editionToBurn
    ) external {
        if(editionToBurn >= EDITION_NR) revert MustBurnPreviousEdition();
        if(block.timestamp < windowOpen || block.timestamp > windowClose) revert WindowClosed();

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
    ) external {
        if(tokenIds.length != editionToBurn.length) revert SameLengthRequired();
        if(block.timestamp < windowOpen || block.timestamp > windowClose) revert WindowClosed();

        for(uint256 i; i < tokenIds.length;) {
            IOS osContract = IOS(osContracts[editionToBurn[i]]);
            if(editionToBurn[i] >= EDITION_NR) revert MustBurnPreviousEdition();
            if(osContract.ownerOf(tokenIds[i]) != msg.sender) revert SenderNotOwner();

            osContract.burn(tokenIds[i]);
            _mint(msg.sender, tokenIds[i]);  

            unchecked {i++;}    
        } 
    }  

    function finalizeAllowedBurners() external onlyOwner {
        allowedBurnersFinalized = true;
    }

    function setAllowedBurner(address _address, bool _allowed) external onlyOwner {
        if(!allowedBurnersFinalized) {
            allowedBurners[_address] = _allowed;
        } else {
            revert BurnersFinalized();
        }
    }

    function setContract(uint256 editionNr, address contractAddress) external onlyOwner {
        osContracts[editionNr] = contractAddress;
    }

    function burn(uint256 tokenId) external {
        if(!allowedBurners[msg.sender] && !_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert BurnerNotAllowed();
        }

        _burn(tokenId);
    }

    function setWindow(uint128 _windowOpen, uint128 _windowClose) public onlyOwner {
        windowOpen = _windowOpen;
        windowClose = _windowClose;
    }   

    function setURI(string memory _uri) public onlyOwner {
        uri = _uri;    
    }        

    function _baseURI() internal view override returns (string memory) {
        return uri;
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