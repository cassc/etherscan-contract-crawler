//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//.........................***************...***************......................
//.........................***..........**...**..........***......................
//..................**********..........*******..........***......................
//..................**.....***..........**...**..........***......................
//..................**.....***..........**...**..........***......................
//.........................***************...***************......................
//................................................................................
//................................................................................
//................................................................................
//................................................................................
//.......................%%########%%%%%%%%%%%%%%%%%********......................
//.......................%%%%%#######%%%%%%%%%%%%%*******%%%......................
//.......................%%%%%%%########%%%%%%%********%%%%%......................
//.......................%%%%%%%%%%#######%%%*******%%%%%%%%......................
//.......................%%%%%..%%%%%#####********%%%%%%%%%%......................
//.......................%%%%%..%%%%%%%%*******%%%%%%%%%%%%%......................
//.......................%%%%%..%%%%%***..........%%%%%%%%%%......................
//.......................%%%%%..////////../////...//////////......................
//.......................%%%%%..////////../////...//////////......................
//.......................*****..%%%%%%%%..........%%%%%%%%%%......................
//.......................*****..%%%%%%%%%%%%%%%%%%%%%%%%%%%%......................
//
// Forgotten Runes Wizard's Nouns
// Wizard x Noun NFTs for Forgotten Runes Wizard's Cult holders
// 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract WizardsNouns is 
    ERC721,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    string private _baseTokenURI;
    bool private _killSwitchEngaged;
    uint256 public mintsAllowedPerAddress = 1;
    uint256 public constant MAX_SUPPLY = 2500;
    mapping(address => uint) public minted;

    ERC721 wizards = ERC721(0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42);

    constructor(string memory initialBaseURI) 
        ERC721('WizardsNouns', 'WizardsNouns') 
    {  
        setBaseURI(initialBaseURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseTokenURI = _newBaseURI;
    }

    function setMintsAllowedPerAddress(uint256 _newMintsAllowedPerAddress) public onlyOwner {
        mintsAllowedPerAddress = _newMintsAllowedPerAddress;
    }

    function setKillSwitchEngaged(bool _newKillSwitchEngaged) public onlyOwner {
        require(!_killSwitchEngaged, "Cannot undo what has already been done");
        _killSwitchEngaged = _newKillSwitchEngaged;
    }

    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function claim(uint256 tokenId) public nonReentrant {
        require(totalSupply() < MAX_SUPPLY, "All tokens minted");
        require(!_killSwitchEngaged, "All tokens minted");
        require(wizards.ownerOf(tokenId) == msg.sender, "Not Wizard owner");
        require(minted[msg.sender] < mintsAllowedPerAddress, "Address already minted");
        
        minted[msg.sender] += 1;

        _safeMint(msg.sender, tokenId);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
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