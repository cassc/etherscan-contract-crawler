// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./Base64.sol";

interface HACKERHAIKU {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface PLZBRO {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface OPENWIDEIMAGEURL {
    function imageBaseUrl(uint256 tokenId) external view returns (string memory);
}

contract OpenWide is ERC721, Ownable {
    using Strings for uint256;

    HACKERHAIKU hackerhaiku;
    PLZBRO plzbro;
    OPENWIDEIMAGEURL openwideimageurl;

    uint256 public Counter;
    uint256 public firstBlock;

    bool isExternalImageBaseUrl;
    bool isLive;

    mapping(address => bool) public claimed;
    mapping(address => uint256) public burned;

    string public imageBaseUrl;
    string public license = 'CC BY-NC 4.0';
    string public externalUrl = 'https://hackerhaiku.com/openwide';
    
    constructor(address hackerHaikuContract, address plzBroContract, string memory _imageBaseUrl) ERC721("OpenWide", "OpW") {
        hackerhaiku = HACKERHAIKU(hackerHaikuContract);
        plzbro = PLZBRO(plzBroContract);
        imageBaseUrl = _imageBaseUrl;
    }

    function setLive() public onlyOwner {
        isLive = true;
        firstBlock = block.number;
    }

    function mint(bytes32 magic) public payable {
        require(isLive, "Minting is not live yet.");
        require(block.number - firstBlock < 2600, "Minting has ended.");
        require(magic == keccak256(abi.encodePacked(msg.sender)), "Magic?");
        if (isQualifiedHolder(msg.sender) && !claimed[msg.sender]) {
            claimed[msg.sender] = true;
        } else {
            require(msg.value >= 0.01 ether, "You must pay 0.01 ETH to mint.");
        }
        
        Counter++;
    
        payable(owner()).transfer(msg.value);
        _safeMint(msg.sender, Counter);  
    }

    function burn(uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Caller is not owner nor approved");
        burned[msg.sender]++;
        _burn(_tokenId);
    }

    function setOpenWideImageUrlContract(address _address) public onlyOwner {
        openwideimageurl = OPENWIDEIMAGEURL(_address);
    }

    function updateExternalUrl(string memory _externalUrl) public onlyOwner {
        externalUrl = _externalUrl;
    }

    function updateImageBaseUrl(string memory _imageBaseUrl) public onlyOwner {
        imageBaseUrl = _imageBaseUrl;
    }

    function updateIsExternalImageBaseUrl(bool _isExternalImageBaseUrl) public onlyOwner {
        isExternalImageBaseUrl = _isExternalImageBaseUrl;
    }

    function isQualifiedHolder(address _address) public view returns (bool) {
        return hackerhaiku.balanceOf(_address) > 0 && plzbro.balanceOf(_address) > 0;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token doesn't exist.");

        string memory imageUrl;

        if (isExternalImageBaseUrl) {
            string memory _externalBaseUrl = openwideimageurl.imageBaseUrl(_tokenId);
            imageUrl = string(abi.encodePacked(_externalBaseUrl, Strings.toString(_tokenId), ".jpeg"));
        } else {
            imageUrl = string(abi.encodePacked(imageBaseUrl, Strings.toString(_tokenId), ".jpeg"));
        }
       
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "Open Wide #', Strings.toString(_tokenId), '",',
                '"description": "Generative Art NFTs mintable via face detection.",',
                '"image": "', imageUrl, '",',
                '"license": "', license, '",'
                '"external_url": "', externalUrl,
                '"}'
            )
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    receive() external payable { }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}