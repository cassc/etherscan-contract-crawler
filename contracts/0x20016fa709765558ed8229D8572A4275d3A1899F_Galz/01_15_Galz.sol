// SPDX-License-Identifier: MIT

/*
╋╋╋╋╋╋╋┏┓╋╋╋╋╋╋╋╋╋╋╋╋┏┓
╋╋╋╋╋╋╋┃┃╋╋╋╋╋╋╋╋╋╋╋╋┃┃
┏━━┳┓╋┏┫┗━┳━━┳━┳━━┳━━┫┃┏━━━┓
┃┏━┫┃╋┃┃┏┓┃┃━┫┏┫┏┓┃┏┓┃┃┣━━┃┃
┃┗━┫┗━┛┃┗┛┃┃━┫┃┃┗┛┃┏┓┃┗┫┃━━┫
┗━━┻━┓┏┻━━┻━━┻┛┗━┓┣┛┗┻━┻━━━┛
╋╋╋┏━┛┃╋╋╋╋╋╋╋╋┏━┛┃
╋╋╋┗━━┛╋╋╋╋╋╋╋╋┗━━┛
*/

// CyberGalz Legal Overview [https://cybergalznft.com/legaloverview]

pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721XX.sol";

abstract contract GalzRandomizer {
    function getTokenId(uint256 tokenId) public view virtual returns(uint256 resultId);
}

contract Galz is ERC721XX, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string private _baseURIextended;

    address randomizerAddress;
    address galzVendingMachineEthAddress;

    bool public contractLocked = false;

    event GalzRevealed(address indexed to, uint256 realId1, uint256 realId2);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory baseURI_,
        address _imx
    ) ERC721XX(_name, _ticker) {
        _baseURIextended = baseURI_;
        imx = _imx;
    }

    function mintTransfer(address to) public returns(uint256, uint256) {
        require(msg.sender == galzVendingMachineEthAddress, "Not authorized");
        
        GalzRandomizer tokenAttribution = GalzRandomizer(randomizerAddress);
        uint256 realId1 = tokenAttribution.getTokenId(_tokenIdCounter.current());
        
        _safeMint(to, realId1);
        _tokenIdCounter.increment();

        uint256 realId2 = tokenAttribution.getTokenId(_tokenIdCounter.current());

        _safeMint(to, realId2);
        _tokenIdCounter.increment();

        emit GalzRevealed(to, realId1, realId2);
        return (realId1, realId2);
    }

    function isRevealed(uint256 id) public view returns(bool) {
        if (abi.encodePacked(ownerOf(id)).length == 20) {return true;} else {return false;}
    }
    
    function setGalzVendingMachineEthAddress(address newAddress) public onlyOwner  { 
        galzVendingMachineEthAddress = newAddress;
    }

    function setRandomizerAddress(address newAddress) public onlyOwner {
        randomizerAddress = newAddress;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner  {
        require(contractLocked == false, "Contract has been locked and URI can't be changed");
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function lockContract() public onlyOwner {
        contractLocked = true;   
    }

}