// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
    
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CryptoVodniks is ERC721A, Ownable {
    using Strings for uint256;
    string private uriPrefix;
    string private uriSuffix = ".json";
    uint16 public maxSupply = 2420;
    uint16 private maxFreeMint = 2000;
    uint16 private mintedFree = 0;
    uint8 public freeNFT = 1;
    uint8 public twopackNFT = 2;
    uint8 public sixpackNFT = 6;                                 
    uint256 public costfortwo = 0.003 ether;
    uint256 public costforsix = 0.015 ether;
    bool public paused = true;
    mapping (address => bool) public FreePerAddress;
    constructor( string memory initBaseURI ) ERC721A("CryptoVodniks", "CVS") {
        uriPrefix = initBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function freeMint() public {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + freeNFT <= maxSupply, "Exceeds max supply.");
        require(mintedFree <= maxFreeMint, "Exceeds free supply");
        require(!paused, "The contract is paused!");
        require(!FreePerAddress[msg.sender], "You have free vodnik.");
        _safeMint(msg.sender, freeNFT);
        FreePerAddress[msg.sender] = true;
        mintedFree++;
        delete totalSupply;
    }

    function twopackMint() external payable {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + twopackNFT <= maxSupply, "Exceeds max supply.");
        require(!paused, "The contract is paused!");
        require(msg.value >= costfortwo, "Insufficient funds!");
        _safeMint(msg.sender , twopackNFT);
        delete totalSupply;
    }

    function sixpackMint() external payable {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + sixpackNFT <= maxSupply, "Exceeds max supply.");
        require(!paused, "The contract is paused!");
        require(msg.value >= costforsix, "Insufficient funds!");
        _safeMint(msg.sender , sixpackNFT);
        delete totalSupply;
    }
  
    function ownerMint(uint16 _mintAmount, address _receiver) external onlyOwner {
        uint16 totalSupply = uint16(totalSupply());
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply.");
        _safeMint(_receiver , _mintAmount);
        delete _mintAmount;
        delete _receiver;
        delete totalSupply;
    }
 
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string( abi.encodePacked( baseURI, Strings.toString(tokenId), ".json")) : "";
    }
    
    function toggleMint() external onlyOwner {
        paused = !paused;
    }
 
    function withdraw() external onlyOwner {
        uint _balance = address(this).balance;
        payable(msg.sender).transfer(_balance);   
    }

    function _baseURI() internal view  override returns (string memory) {
        return uriPrefix;
    }

}