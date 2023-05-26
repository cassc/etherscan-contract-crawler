// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract PixelChainMax is ERC721, Ownable {
    event PixelChainCreated(uint256 indexed tokenId, bytes data, bytes palette, uint8 version);

    struct PixelChain {
        string name;
        address author;
        uint256 blockNumber;
    }

    struct NewPixelChain {
        string name;
        bytes data;
        bytes palette;
        uint8 version;
    }

    uint256 defaultMintPrice = 0;

    mapping(address => bool) addressBlacklist;
    mapping(address => bool) addressWhitelist;
    mapping(uint8 => bool) versionWhitelist;
    mapping(uint8 => uint256) mintPricePerVersion;

    PixelChain[] public pixelChains;

    constructor() ERC721("PixelChain Max", "PXCM") {}

    function create(NewPixelChain memory _pixelChain) external payable {
        uint256 mintPrice = defaultMintPrice;
        if (mintPricePerVersion[_pixelChain.version] > 0) {
            mintPrice = mintPricePerVersion[_pixelChain.version];
        }

        require(msg.value >= mintPrice, "Not enough ether to mint this token!");
        require(addressBlacklist[msg.sender] == false, "You are not allowed to create PXCM");
        require(versionWhitelist[_pixelChain.version] == false || addressWhitelist[msg.sender], "You are not allowed to create this type of PXCM");

        pixelChains.push(
            PixelChain(_pixelChain.name, msg.sender, block.number)
        );

        uint256 id = pixelChains.length - 1;
        _mint(msg.sender, id);

        emit PixelChainCreated(id, _pixelChain.data, _pixelChain.palette, _pixelChain.version);
    }

    function retrieveAll(uint256 _start, uint256 _end) external view returns (PixelChain[] memory) {
        uint256 end = _end;
        if (_end > pixelChains.length) {
            end = pixelChains.length;
        }

        uint256 arraySize;
        if (_start > end) {
            arraySize = 0;
        } else {
            arraySize = end - _start;
        }

        PixelChain[] memory response = new PixelChain[](arraySize);

        uint x = 0;
        for (uint i = _start; i < end; i++) {
            response[x] = pixelChains[i];
            x++;
        }

        return response;
    }

    function retrieve(uint256 _id) external view returns (PixelChain memory) {
        return pixelChains[_id];
    }

    function setBaseTokenURI(string memory _uri) external onlyOwner {
        _setBaseURI(_uri);
    }

    function withdraw() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setDefaultMintPrice(uint256 _price) external onlyOwner {
        defaultMintPrice = _price;
    }

    function setMintPricePerVersion(uint8 _version, uint256 _price) external onlyOwner {
        mintPricePerVersion[_version] = _price;
    }

    function addAddressToBlacklist(address _address) external onlyOwner {
        addressBlacklist[_address] = true;
    }

    function removeAddressFromBlacklist(address _address) external onlyOwner {
        addressBlacklist[_address] = false;
    }

    function addAddressToWhitelist(address _address) external onlyOwner {
        addressWhitelist[_address] = true;
    }

    function removeAddressFromWhitelist(address _address) external onlyOwner {
        addressWhitelist[_address] = false;
    }

    function addVersionToWhitelist(uint8 _version) external onlyOwner {
        versionWhitelist[_version] = true;
    }

    function removeVersionFromWhitelist(uint8 _version) external onlyOwner {
        versionWhitelist[_version] = false;
    }

    function baseTokenURI() external view returns (string memory) {
        return baseURI();
    }
}