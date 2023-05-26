// SPDX-License-Identifier: GPL-3.0
//
// :::::::::  ::   .:   ...    :::  .,-:::::/ .,::::::
// '`````;;; ,;;   ;;,  ;;     ;;;,;;-'````'  ;;;;''''
//     .n[[',[[[,,,[[[ [['     [[[[[[   [[[[[[/[[cccc
//   ,$$P"  "$$$"""$$$ $$      $$$"$$c.    "$$ $$""""
// ,888bo,_  888   "88o88    .d888 `Y8bo,,,o88o888oo,__
//  `""*UMM  MMM    YMM "YmmMMMM""   `'YMUP"YMM""""YUMMM
//
// 512 generative sketches exploring curl noise, colour and constraints.
// By MountVitruvius - http://mountvitruvius.art

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZHUGE_NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;

    uint256 public cost = 0.1 ether;
    uint256 public maxSupply = 512;
    uint256 public maxMintAmount = 4;
    bool public paused = true;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // For OpenSea
    function contractURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }

    //Owner funcs!
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}