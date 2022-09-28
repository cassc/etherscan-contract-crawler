// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract TOYOcorp is ERC721A,Ownable,ReentrancyGuard {
    using Strings for uint256;

    
    uint256 public maxSupply = 777;
    uint256 public maxMint = 1;
    uint256 public mintPrice = 0.00 ether;

    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri = "ipfs://QmVpnqe72J2mZZELT6vTsYxz2bQymfen2Uy5JdMAAvexjn/";

    bool public revealed = false;
    bool public paused = true;

    mapping(address => uint256) public _totalMinted;

    constructor() ERC721A("TOYOcorp","TOYOcorp") {}

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(!paused,"");
        require(_mintAmount <= maxMint,"");
        require(msg.value >=mintPrice * _mintAmount,"");
        require(_mintAmount+_totalMinted[msg.sender] <= maxMint,"" );
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply ,"");
        _safeMint(msg.sender,_mintAmount);
        _totalMinted[msg.sender]+=_mintAmount;
    }

    

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        if (revealed == false) {
            return notRevealedUri;
        } else {
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,tokenId.toString(),_baseTokenEXT)) : "";
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }


    function toogleReveal() public onlyOwner{
        revealed = !revealed;
    }

    function tooglePause() public onlyOwner{
        paused = !paused;
    }

    function changePrice(uint256 _newPrice) public onlyOwner{
        mintPrice = _newPrice;
        
    }

    function changeURLParams(string memory _nURL,string memory _nBaseExt) public onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success,"Transfer failed.");
    }

}