// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract aKIDcalledBEAST is ERC721A,Ownable,ReentrancyGuard {
    using Strings for uint256;

    
    uint256 public maxSupply = 600;
    uint256 public freeMint = 600;
    uint256 public maxMint = 1;
    uint256 public mintPrice = 0.00 ether;

    string public _baseTokenURI;
    string public _baseTokenEXT;
    string public notRevealedUri = "ipfs://QmNbcaTuBuTTWqdpER3DHf9DA2nLpvc9f8BGDU7aK9Gxda/";

    bool public revealed = false;
    bool public paused = false;

    mapping(address => uint256) public _totalMinted;

    constructor() ERC721A("aKIDcalledBEAST","AKCB") {}

    function mint(uint256 _mintAmount) public payable nonReentrant {
        require(!paused,"1");
        require(_mintAmount <= maxMint,"2");
        uint256 price = getPrice(_mintAmount);
        require(msg.value >=price,"3");
        require(_mintAmount+_totalMinted[msg.sender] <= maxMint,"4" );
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply ,"5");
        _safeMint(msg.sender,_mintAmount);
        _totalMinted[msg.sender]+=_mintAmount;
    }

    function getPrice(uint256 _mintAmount) public view returns(uint256) {
        uint256 totalSupply = totalSupply();

        if(totalSupply +_mintAmount  <= freeMint){
            return 0;
        }
        else if(totalSupply +_mintAmount > freeMint && totalSupply < freeMint){
            uint256 freeQuantity = freeMint - totalSupply;
            return (_mintAmount- freeQuantity)* mintPrice;
        }
        return mintPrice * _mintAmount;
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