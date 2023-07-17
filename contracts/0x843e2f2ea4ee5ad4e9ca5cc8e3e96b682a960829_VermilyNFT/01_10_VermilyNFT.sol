//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract VermilyNFT is ERC721AQueryable, Ownable, ReentrancyGuard {

    uint256 public maxSupply;
   
    string public baseURI;
    
    string public defaultURI;
   
    uint256 public tokenCount;

    uint256 public publicMintPrice ;

    bool public revealed = false;

    using Strings for uint256;

    constructor(
        string memory _baseURI,
        string memory _defaultURI
    ) ERC721A("VermilyNFT", "VERMILYNFT") {
        uint256 _maxSupply = 2000;

        setBaseURI(_baseURI);
        publicMintPrice = 1.2 ether;
        maxSupply = _maxSupply;
        defaultURI = _defaultURI;        
    }

    modifier onlyAllowedQuantity(uint256 _num){
        require(totalSupply() + _num <= maxSupply, "Num must be less than maxSupply");
        _;
    }

     modifier checkPrice(uint256 _num){
        require(msg.value == publicMintPrice * _num, "Price  must eq publicMintPrice*num");
       _;
    }
    
    event ItemCreated (
        uint256 tokenNumber,
        address owner,
        address seller
    );


    function setPrice(
        uint256 _publicMintPrice     
    ) external onlyOwner {
        publicMintPrice = _publicMintPrice;
    }
  
    function mint(address _addresss, uint256 _num) internal nonReentrant {
        _safeMint(_addresss, _num);
        
        tokenCount += _num;

        emit ItemCreated(  
            tokenCount,        
            address(_addresss),
            msg.sender           
        );
    }

    function privateMint(address _addresss, uint256 _num) external payable onlyOwner  
    onlyAllowedQuantity(_num)
    {
       mint(_addresss, _num);
    }

   function publicMint(uint256 _num) external payable     
    onlyAllowedQuantity(_num)
    checkPrice(_num)
    {
        mint(msg.sender, _num);
    }
   
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner {
        defaultURI = _defaultURI;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId, true);
    }

    function reveal(bool _reveal) external onlyOwner {
        revealed = _reveal;
    }


    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

    if (revealed == false) {
            return defaultURI;
        } else {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString(), '.json')) : '';
        }
    }

    function getMaxTokenNum() public view returns(uint256) {
        return tokenCount;
    }

}