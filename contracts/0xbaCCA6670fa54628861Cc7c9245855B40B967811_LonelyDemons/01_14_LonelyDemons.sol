// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract LonelyDemons is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 1;
    uint256 public PUBLIC_SUPPLY = 1;
    uint256 public maxMintAmount;
    uint256 public pubSaleCost = 30000000000000000;
    uint256 public freeSaleCost = 0;

    address public artist;
    string public baseURI;
    string public unrevealedURI;
    string public uri;
    string public metaDataExt = ".json";

    mapping(address => uint256) public mintedPerAddress;
    mapping(uint256 => bool) public isTokenIdExisting;
    mapping(address => bool) public isWhitelisted;

    bool public mintable = true;
    bool public publicSale = false;
    bool public isRevealed = true;


    constructor(
        string memory name,
        string memory symbol,
        string memory URI,
        string memory UNREVEALED_URI,
        uint256 initialSupply,
        uint256 publicSupply,
        address _admin,
        uint256 _limitPerAddress
    ) ERC721(name, symbol) {
        transferOwnership(_admin);
        baseURI = URI;
        unrevealedURI = UNREVEALED_URI;

        maxMintAmount = _limitPerAddress;
        MAX_SUPPLY = initialSupply;
        PUBLIC_SUPPLY = publicSupply;
    }

    // return admin
    function getAdmin() public view returns (address)  {
        return owner();
    }


    //supply
    function getMaxSupply() public view returns (uint256)  {
        return MAX_SUPPLY;
    }

    function setMaxSupply(uint256 supply) onlyOwner public {
        MAX_SUPPLY = supply;
    }

    function setMaxMintAmount(uint256 _newmaxMintAmount) onlyOwner public {
        maxMintAmount = _newmaxMintAmount;
    }

    function getMaxMintAmount() public view returns (uint256) {
        return maxMintAmount;
    }

    //mint
    function mintTo(address _toAddress) onlyOwner external {
        _mint(_toAddress);
    }

    function mint() external payable {
        require(totalSupply() < PUBLIC_SUPPLY, "Exception: The public supply has been minted out.");
        require(mintedPerAddress[msg.sender] < maxMintAmount, "Exception: Reached the limit for each user. You can't mint no more");
        require(publicSale || isWhitelisted[msg.sender], "Exception: signer is not whitelisted");
        require(getCost(mintedPerAddress[msg.sender]) <= msg.value);
        _mint(msg.sender);
        mintedPerAddress[msg.sender] = SafeMath.add(mintedPerAddress[msg.sender], 1);
    }

    function _mint(address _toAddress) internal {
        require(totalSupply() < MAX_SUPPLY, "Exception: All was minted.");
        require(mintable, "Exception: This is not mintable.");

        uint256 tokenIdToBe = SafeMath.add(totalSupply(), 1);
        _safeMint(_toAddress, tokenIdToBe);

        isTokenIdExisting[tokenIdToBe] = true;
    }

    // mint flag
    function setMintable(bool mintFlag) onlyOwner public {
        mintable = mintFlag;
    }

    //base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory _newBaseURI) onlyOwner public {
        baseURI = _newBaseURI;
    }

    function setUnrevealedURI(string memory _newUnrevealedURI) onlyOwner public {
        unrevealedURI = _newUnrevealedURI;
    }

    function setMetaDataExt(string memory _newExt) onlyOwner public {
        metaDataExt = _newExt;
    }

    function setRevealed(bool _revealed) onlyOwner external {
        isRevealed = _revealed;
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
        if (isRevealed) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
            : "";
        } else {
            return unrevealedURI;
        }
    }

    function addWhitelisted(address _address) internal {
        isWhitelisted[_address] = true;
    }

    function addBatchWhitelisted(address[] calldata mintWhitelist) external onlyOwner {
        for(uint256 i=0; i<mintWhitelist.length; i++) {
            addWhitelisted(mintWhitelist[i]);
        }
    }

    function checkWhitelisted(address _address) external view returns (bool) {
        return isWhitelisted[_address];
    }

    function removeWhitelisted(address _address) external onlyOwner {
        isWhitelisted[_address] = false;
    }

    function setCost(uint256 _newCost) external onlyOwner {
        pubSaleCost = _newCost;
    }

    function getCost(uint256 _mintedAmount) public view returns(uint256) {
        if(_mintedAmount > 0) {
            return pubSaleCost;
        }
        return freeSaleCost;
    }

    function getSaleType() external view returns(bool) {
        return publicSale;
    }

    function setPublicSale(bool isPublic) external onlyOwner {
        publicSale = isPublic;
    }

    function withdraw() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTo(address _address) onlyOwner public {
        payable(_address).transfer(address(this).balance);
    }
}