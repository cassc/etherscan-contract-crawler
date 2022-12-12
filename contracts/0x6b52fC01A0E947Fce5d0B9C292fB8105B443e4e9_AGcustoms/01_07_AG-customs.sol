// SPDX-License-Identifier: MIT

//Powered By Novus
/*

'  ....._...._......._..............____......................____.........._......................
'  ..../.\..|.|_.__.|.|__...__._.../.___|.__._._.__...__._.../.___|..._.___|.|_.___.._.__.___..___.
'  .../._.\.|.|.'_.\|.'_.\./._`.|.|.|.._./._`.|.'_.\./._`.|.|.|..|.|.|./.__|.__/._.\|.'_.`._.\/.__|
'  ../.___.\|.|.|_).|.|.|.|.(_|.|.|.|_|.|.(_|.|.|.|.|.(_|.|.|.|__|.|_|.\__.\.||.(_).|.|.|.|.|.\__.\
'  ./_/...\_\_|..__/|_|.|_|\__,_|..\____|\__,_|_|.|_|\__,.|..\____\__,_|___/\__\___/|_|.|_|.|_|___/
'  ...........|_|....................................|___/.........................................

*/

pragma solidity ^0.8.10;


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract AGcustoms is ERC721A, Ownable {

    mapping (address => bool) public mintLimiter;


    using Strings for uint256;
    
    uint256 public price;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;
    uint256 public maxMintAmountPerWallet;

    string public uriPrefix = "";
    string public uriSuffix = "";

    bool public paused = true;
    

   constructor(uint256 _price, uint256 _maxSupply, string memory _uriPrefix, uint256 _maxMintAmountPerTx, uint256 _maxMintAmountPerWallet) ERC721A("Alpha Gang Customs", "AGC") {

        uriPrefix = _uriPrefix;
        price = _price;
        maxSupply = _maxSupply;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxMintAmountPerWallet = _maxMintAmountPerWallet;
        

    }

    
    
    // ================== Mint Function =======================
    


  function mint(address to, uint256 _mintAmount) public payable {
    require(!paused, "The contract is paused!");
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(_totalMinted() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(msg.value == price * _mintAmount, "You dont have enough funds!");

    // Check if the total minted amount for the wallet is less than the max amount allowed
    require(!mintLimiter[to], "Cannot mint more than one NFT to the same wallet.");

    _safeMint(to, _mintAmount);
    mintLimiter[to] = true;
  }


 

    // ================== (Owner Only) ===============


    function ownerMint(address to, uint256 _mintAmount) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");

    _safeMint(to, _mintAmount);
  }


    function setPause(bool state) public onlyOwner {
        paused = state;
    }


    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setCostPrice(uint256 _cost) public onlyOwner{
        price = _cost;
    } 

    function setSupply(uint256 supply) public onlyOwner{
        maxSupply = supply;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    
   

    // =================== (View Only) ====================

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,_tokenId.toString(),uriSuffix)): "";
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }


    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }  
}
//Powered By Novus