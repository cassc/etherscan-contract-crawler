// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract PepeNFT is ERC721A, Ownable {
    using Strings for uint256;

    // URI
    string public baseURI;
    string public baseExtension = ".json";

    // Supply & Cost
    uint256 public mintCost = 0.001 ether;
    uint256 public maxSupply = 9696;

    // Mint Limits
    uint256 public maxPublicMint = 20;

    // Sale Info
    // 0 = Inactive, 1 = Mint
    uint256 public currentSale = 0;

    // Metadata
    uint256 public isReleased = 0;

    bool public paused = false;

    // Claimed PepeNFT
    mapping(address => uint256) public _PublicClaimed;

    constructor(
        string memory _initBaseURI
    ) ERC721A("PepeNFT", "PP") {
        setBaseURI(_initBaseURI);
    }

    // Minting

    function publicMint(uint256 _mintAmount) public payable
    {
        require(!paused, "PP: Sale is paused");
        require(currentSale == 1, "PP: Public Sale not active");
        require(_mintAmount > 0, "PP: Must mint at least one");
        require((totalSupply() + _mintAmount) <= maxSupply, "PP: Cannot exceed supply");

        require(_PublicClaimed[msg.sender] + _mintAmount <= maxPublicMint, "PP: Max Public Mint count exceeded");
            
        require(msg.value >= mintCost * (_mintAmount-1), "PP: Cost not received!");

          _PublicClaimed[msg.sender] = _PublicClaimed[msg.sender] + _mintAmount;
          _safeMint(msg.sender, _mintAmount);
    }

   // Internal

    function mintOwner(address _to, uint256 _mintAmount) public onlyOwner
    {
        require((totalSupply() + _mintAmount) <= maxSupply, "PP: Cannot exceed supply");
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
        return "https://gateway.pinata.cloud/ipfs/QmUFhLgBD89Veu4j7w37MBDZHUMwAiuvemqkqj8yEoBUMo?_gl=1*qo2gv0*rs_ga*MTg2NDRjMmQtMWIzZC00MGRjLTg1YzYtMWJjN2IyZjBlYzY0*rs_ga_5RMPXG14TE*MTY4MjIzMTc3Ni40LjEuMTY4MjIzMTk5Ny42MC4wLjA.";
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

        (bool a, ) = payable(0x38024Fc8E81C718927933A495e9bdF4B9E02C2d8).call{value: colbal * 70}("");
        require(a);

        (bool b, ) = payable(0xf44Bf58e204FAf57A25AeD4dE427748A3D3D55E0).call{value: colbal * 30}("");
        require(b);
    }
}