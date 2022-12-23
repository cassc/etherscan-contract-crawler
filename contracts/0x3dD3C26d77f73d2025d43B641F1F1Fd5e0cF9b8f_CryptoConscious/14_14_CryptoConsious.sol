// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/*
*  ░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░
* ██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗
* ██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║
* ██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║
* ╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝
* ░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░
* 
* ░█████╗░░█████╗░███╗░░██╗░██████╗░█████╗░██╗░█████╗░██╗░░░██╗░██████╗
* ██╔══██╗██╔══██╗████╗░██║██╔════╝██╔══██╗██║██╔══██╗██║░░░██║██╔════╝
* ██║░░╚═╝██║░░██║██╔██╗██║╚█████╗░██║░░╚═╝██║██║░░██║██║░░░██║╚█████╗░
* ██║░░██╗██║░░██║██║╚████║░╚═══██╗██║░░██╗██║██║░░██║██║░░░██║░╚═══██╗
* ╚█████╔╝╚█████╔╝██║░╚███║██████╔╝╚█████╔╝██║╚█████╔╝╚██████╔╝██████╔╝
* ░╚════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░░╚════╝░╚═╝░╚════╝░░╚═════╝░╚═════╝░
*/

contract CryptoConscious is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public baseExtension = ".json";
    uint256 public baseCost = 0.01 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 100;
    bool public paused = false;
    bool public revealed = true;
    string public notRevealedUri;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function dynamicCost(uint256 _supply) view internal returns (uint256 _cost){
        if (_supply < 1001) {
            return baseCost;
        }

        if (_supply < 2001) {
            return baseCost * 2 ether;
        }

        if (_supply < 3001) {
            return baseCost * 3 ether;
        }

        if (_supply < 4001) {
            return baseCost * 4 ether;
        }

        if (_supply < 5001) {
            return baseCost * 5 ether;
        }

        if (_supply < 6001) {
            return baseCost * 6 ether;
        }

        if (_supply < 7001) {
            return baseCost * 7 ether;
        }

        if (_supply < 8001) {
            return baseCost * 8 ether;
        }

        if (_supply < 9001) {
            return baseCost * 9 ether;
        }
        
        return baseCost * 10 ether;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(
                msg.value >= dynamicCost(supply) * _mintAmount,
                "Not enough funds"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBaseCost(uint256 _newCost) public onlyOwner {
        baseCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function removeBaseExtension() public onlyOwner
    {
        baseExtension = "";
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        // This will pay contributors and advisors 3% of the initial sale.
        uint256 kaShare = address(this).balance * 1 / 100;
        uint256 hsShare = address(this).balance * 1 / 100;
        uint256 chefShare = address(this).balance * 1 / 100;

        // This will pay the artist 10% of the initial sale.
        uint256 artistShare = address(this).balance * 10 / 100;

        // This will pay the dapp developers 10% of the initial sale.
        uint256 amitShare = address(this).balance * 5 / 100;
        uint256 nikhilShare = address(this).balance * 5 / 100;

        (bool ka, ) = payable(0x89FD2bA266c8bFbad9859281EA1ee2Aacd20eB80).call{value: kaShare}("");
        require(ka);

        (bool hs, ) = payable(0x943590A42C27D08e3744202c4Ae5eD55c2dE240D).call{value: hsShare}("");
        require(hs);

        (bool chef, ) = payable(0xeB23ecf1fa9911fca08ecAbe83d426b6bd525bB0).call{value: chefShare}("");
        require(chef);

        (bool artist, ) = payable(0xE2977Be3A42F3811a41ef33604C1c80B18635Be0).call{value: artistShare}("");
        require(artist);

        (bool amit, ) = payable(0xf6E9ee115CC43937EdbF5A7BCB76E3B0Bfad6266).call{value: amitShare}("");
        require(amit);

        (bool nikhil, ) = payable(0xb2cdcd4ed567A98199e40782D167DFC1d82B898A).call{value: nikhilShare}("");
        require(nikhil);

    
        // This will payout the owner 77% of the contract balance.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}