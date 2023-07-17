// SPDX-License-Identifier: MIT

/////////    ////////   ////////   ////    ////   ////    ////   /////      ////    ///////////    ///////////   //////////
////    ///  ////       ///        ////    ////   ////    ////   //// //    ////    ////           ////   ////   ////
////    ///  //////     ///        ////////////   ////    ////   ////  ///  ////    ////   /////   ////   ////    ////
////    ///  //////     ///        ////////////   ////    ////   ////   /// ////    ////    ///    ////   ////      //// 
////    ///  ////       ///        ////    ////   ////    ////   ////     //////    ////    ///    ////   ////        ////
/////////    /////////  ////////   ////    ////   ////////////   ////      /////    ///////////    ///////////   /////////


pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract DeChungos is ERC721A, Ownable {
    using Strings for uint256;

    // URI
    string public baseURI;
    string public baseExtension = ".json";

    // Supply & Cost
    uint256 public mintCost = 0.003 ether;
    uint256 public maxSupply = 6665;

    // Mint Limits
    uint256 public maxPublicMint = 10;

    // Sale Info
    // 0 = Inactive, 1 = Mint
    uint256 public currentSale = 0;

    // Metadata
    uint256 public isReleased = 0;

    bool public paused = false;

    // Claimed DeChungos
    mapping(address => uint256) public _PublicClaimed;

    constructor(
        string memory _initBaseURI
    ) ERC721A("DeChungos", "DC") {
        setBaseURI(_initBaseURI);
    }

    // Minting

    function publicMint(uint256 _mintAmount) public payable
    {
        require(!paused, "DC: Sale is paused");
        require(currentSale == 1, "DC: Public Sale not active");
        require(_mintAmount > 0, "DC: Must mint at least one");
        require((totalSupply() + _mintAmount) <= maxSupply, "DC: Cannot exceed supply");

        require(_PublicClaimed[msg.sender] + _mintAmount <= maxPublicMint, "DC: Max Public Mint count exceeded");
            
        require(msg.value >= mintCost * _mintAmount, "DC: Cost not received!");

        if (_PublicClaimed[msg.sender]==0)
        {
                 _PublicClaimed[msg.sender] = _PublicClaimed[msg.sender] + _mintAmount;
                 _safeMint(msg.sender, _mintAmount+1);
        }
        else
        {
                 _PublicClaimed[msg.sender] = _PublicClaimed[msg.sender] + _mintAmount;
                 _safeMint(msg.sender, _mintAmount);
        }
    }

   // Internal

    function mintOwner(address _to, uint256 _mintAmount) public onlyOwner
    {
        require((totalSupply() + _mintAmount) <= maxSupply, "DC: Cannot exceed supply");
        _safeMint(_to, _mintAmount);
    }

    function setCurrentSale(uint256 _newSale) public onlyOwner {
        currentSale = _newSale;
    }

    function setisReleased(uint256 _newisReleased) public onlyOwner {
        isReleased = _newisReleased;
    }

    function updatePublic(uint256 _newPublicMax, uint256 _newPublicCost) public onlyOwner {
        maxPublicMint = _newPublicMax;
        mintCost = _newPublicCost;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    // URI 

    function _baseURI() internal view virtual override returns (string memory) {
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

        if (isReleased==0)
        {
        return "https://gateway.pinata.cloud/ipfs/QmT6s8GUtJoBb3gjF9udkiNmxpE5UKd3MzrfopAEsdAH5H?_gl=1*awqhwk*rs_ga*MTg2NDRjMmQtMWIzZC00MGRjLTg1YzYtMWJjN2IyZjBlYzY0*rs_ga_5RMPXG14TE*MTY4MDczNjU4OC4zLjEuMTY4MDczNzI1OS4xNS4wLjA.";
        }
        else
        {
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
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    // Withdraw

    function withdraw() public payable onlyOwner {

        uint colbal = address(this).balance / 100;

        (bool a, ) = payable(0x887F623c02201F7D3582aA5225b6AAbff969E2A9).call{value: colbal * 80}("");
        require(a);

        (bool b, ) = payable(0xB8F0d8d29dFe4BaAbaBCaddcA677E3Fe7850dC81).call{value: colbal * 20}("");
        require(b);
    }
}