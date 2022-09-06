//  ,888     8888    ,88'   8 8888
// 888^8     8888   ,88'    8 8888
//   8|8     8888  ,88'     8 8888
//   8N8     8888 ,88'      8 8888
//   8G8     888888<        8 8888
//   8U8     8888 `MP.      8 8888
//   8|8     8888   `JK.    8 8888
// /88888\   8888     `JO.  8888888888888

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract KindredSpiritsSpiritBox is ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 1;
    uint256 public maxMintAmount;

    string public baseURI;
    string public uri;
    string public metaDataExt = ".json";

    mapping(address => uint256) public mintedPerAddress;
    mapping(uint256 => bool) public isTokenIdExisting;
    mapping(address => bool) public isWhitelisted;

    bool public mintable = true;
    bool public isRevealed = false;


    constructor(
        string memory name,
        string memory symbol,
        string memory URI,
        uint256 initialSupply,
        address _admin,
        uint256 _limitPerAddress
    ) ERC721(name, symbol) {
        transferOwnership(_admin);
        baseURI = URI;

        maxMintAmount = _limitPerAddress;
        MAX_SUPPLY = initialSupply;
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

    function mint() external {
        require(mintedPerAddress[msg.sender] < maxMintAmount, "Exception: Reached the limit for each user. You can't mint no more");
        require(isWhitelisted[msg.sender], "Exception: signer is not whitelisted");
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
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), metaDataExt))
            : "";
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

    function withdraw() onlyOwner public {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTo(address _address) onlyOwner public {
        payable(_address).transfer(address(this).balance);
    }
}