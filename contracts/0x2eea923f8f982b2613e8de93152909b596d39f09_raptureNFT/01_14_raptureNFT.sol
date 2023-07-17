// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";

contract raptureNFT is Ownable, ERC721{

    using SafeMath for uint256;
    
     // address private mainContract = "";
    
    bool public isURIFrozen = false;
    
    string public baseURI = "https://";
    
    uint256 public MAX_SUPPLY = 1000;
    
    bool public mintIsActive = true;
    
    uint256 public totalSupply = 0;
    
    address public openSea;

    bool public mtrac;
    
    uint256 public dta;
    
    bytes public dta2;
     
    mapping(uint256 => bool) public usedLumps;
    
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {
       
    }

    function _baseURI() internal view override returns (string memory)  {
        return baseURI;
    }
    
    function toggleURI() external onlyOwner {
        isURIFrozen = !isURIFrozen;
    }
    
    function toggleMint() external onlyOwner {
        mintIsActive = !mintIsActive;
    }
    
    function setBaseURI(string calldata newURI) external onlyOwner {
        require(!isURIFrozen, "URI is Frozen");
        baseURI = newURI;
    }
    
    function setOpensea(address openseaContract) external onlyOwner {
        openSea = openseaContract;
    }
    
    function burn(uint256 _tokenId) public {
        require(!mintIsActive, "Ongoing Sale");
        require(_exists(_tokenId), "Token Does Not Exist");
        require(msg.sender == ownerOf(_tokenId), "Unauthorised Burn");
        totalSupply -= 1;
        _burn(_tokenId);
    }
    
    function mintRapture(uint256 lumpId, uint256 lumpOsId) public {
        require(mintIsActive, "Mint Disabled");
        require(!_exists(lumpId), "Rapture Claimed Previously");
        require(lumpId > 0 && lumpId <= 500, "Unrecognised Lump Token");
        require(totalSupply.add(2) <= MAX_SUPPLY, "All Raptures minted");
        require(!usedLumps[lumpOsId], "Reused Lump");
        
        (bool success, bytes memory data) = openSea.call(
            abi.encodeWithSignature("balanceOf(address,uint256)", msg.sender, lumpOsId)
        );
        mtrac = success;
        dta = abi.decode(data, (uint256));
        
        require(success, "Minting Failed at Opensea OpenStore");
        require(dta > 0, "You dont own this lump");
        
        
        _safeMint(msg.sender, lumpId);
        uint voodoo = lumpId + 500;
        _safeMint(msg.sender, voodoo);
        totalSupply += 2;
        usedLumps[lumpOsId] = true;
    }
    
    function checkRapture(uint256 lumpId) public view returns (bool){
        return _exists(lumpId);
    }
    
    function burnAndMint(uint256 _tokenId) public {
        require(!mintIsActive, "Ongoing Sale");
        require(_exists(_tokenId), "Token Does Not Exist");
        require(msg.sender == ownerOf(_tokenId), "Unauthorised Burn");
        (bool success, bytes memory data) = openSea.call(
            abi.encodeWithSignature("mintNFT(uint256,address)", _tokenId, msg.sender)
        );
        
        require(success, "Minting Failed");
        mtrac = success;
        dta2 = data;
    
        totalSupply -= 1;
        _burn(_tokenId);
    }

    function withdrawAll(address treasury) external payable onlyOwner {
        require(payable(treasury).send(address(this).balance));
    }
}