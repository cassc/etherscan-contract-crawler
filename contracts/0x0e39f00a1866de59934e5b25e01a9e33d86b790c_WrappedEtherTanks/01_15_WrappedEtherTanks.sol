// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface EtherTanks {

    function getTankOwner(uint32 _ID) external returns (address);
    function _transfer (uint32 _tankID, address _receiver) external;
}

contract DropBox is Ownable {

    function sendTank(uint32 tankID, address to, EtherTanks tankInt) public onlyOwner {
        tankInt._transfer(tankID, to);
    }
}

contract WrappedEtherTanks is ERC721, ERC721Enumerable, Ownable {

    event DropBoxCreated(address indexed owner);
    event Rescued(uint32 indexed tankID, address indexed owner);
    event Wrapped(uint32 indexed tankID, address indexed owner);
    event Unwrapped(uint32 indexed tankID, address indexed owner);

    EtherTanks public tankInt = EtherTanks(0x336dB6C1EAd9cc4D5b0a33aC03C057E20640126A);
    
    string public baseTokenURI;
    
    mapping(address => address) public dropBoxes;
    
    uint256 constant maxTankID = 5301;
    
    constructor() ERC721("WrappedEtherTanks", "WET") {

        baseTokenURI = "https://tanks.ethyearone.com/";
    }

    function createDropBox() public {
        require(dropBoxes[msg.sender] == address(0), "Drop box already exists.");

        dropBoxes[msg.sender] = address(new DropBox());
        
        emit DropBoxCreated(msg.sender);
    }

    function rescue(uint32 tankID) public {
        address dropBox = dropBoxes[msg.sender];

        require(dropBox != address(0), "You do not have a dropbox"); 
        require(tankInt.getTankOwner(tankID) == dropBox, "Tank is not in dropbox");

        DropBox(dropBox).sendTank(tankID, msg.sender, tankInt);

        emit Rescued(tankID, msg.sender);
    }

    function wrap(uint32 tankID) public {  
        address dropBox = dropBoxes[msg.sender];
        
        require(dropBox != address(0), "You must create a drop box first"); 
        require(tankID >= 1 && tankID <= maxTankID, "Tank index out of range");
        require(tankInt.getTankOwner(tankID) == dropBox, "Tank is not in dropbox");
        require(!_exists(tankID), "Token already exists");

        DropBox(dropBox).sendTank(tankID, address(this), tankInt);
        _mint(msg.sender, tankID);

        emit Wrapped(tankID, msg.sender);
    }

    function unwrap(uint32 tankID) public {
        require(_exists(tankID), "Token does not exist");
        require(msg.sender == ownerOf(tankID), "You are not the owner");

        tankInt._transfer(tankID, msg.sender);
        _burn(tankID);
        
        emit Unwrapped(tankID, msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}