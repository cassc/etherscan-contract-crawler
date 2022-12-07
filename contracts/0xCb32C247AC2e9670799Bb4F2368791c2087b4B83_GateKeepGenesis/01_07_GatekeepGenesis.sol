// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "https://github.com/chiru-labs/ERC721A/blob/main/contracts/ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/utils/Strings.sol";

contract GateKeepGenesis is ERC721A, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public price = 0.25 ether;
    uint256 public supply = 888;
    uint256 public supplyCount = 0;
    uint256 public maxMint = 1;

    bool public saleActive = true;
    bool public reserveCalled = false;

    address public deployer = 0x21096E97E9fA7c2d283E8C4356e2d9e1fE903dE7;

    string metadataUri = '';

    constructor() ERC721A("GateKeepGenesis", "GATEKEEP") {}

    function saleSwitch() external onlyOwner {
        saleActive = !saleActive;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No ETH");
        (bool succcess,) = deployer.call{value: address(this).balance}("");
        require(succcess, "Error withdrawing.");
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function mint(uint256 quantity) external payable {
        require(saleActive, "sale not live");
        require(supplyCount.add(quantity) <= supply, "Not enough supply for this mint amount");
        require(quantity <= maxMint, "max mint 1" );
        require(msg.value >= price.mul(quantity), "Not enough ether sent");

        supplyCount += quantity;
        _mint(msg.sender, quantity);
        return;        
    }

    function reservePasses() external onlyOwner {
        require(supplyCount.add(80) <= supply, "Not enough supply to reserve.");
        require(reserveCalled == false, "Passes already reserved.");

        reserveCalled = true;
        supplyCount += 80;
        _mint(msg.sender, 80);
        return;        
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = metadataUri;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    function setMetadataUri(string memory _uri) external onlyOwner {
        metadataUri = _uri;
    }
}